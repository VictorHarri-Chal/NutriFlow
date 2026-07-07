# PR #4 API v1 Review Findings

**Branch:** `pr-4-api-review`
**Reviewer:** Deep automated audit vs. iOS contract
**Date:** 2026-07-05
**Commits reviewed:** 14 commits, 95 files changed, +4285 / −370 lines

---

## 1. Summary

PR #4 delivers a substantial API surface — 29 controllers, 14 Jbuilder views, JWT auth with JTI revocation, Apple/Google SSO, and full CORS configuration. The foundation is architecturally sound: auth scoping is correct on every controller, JTI revocation is properly wired, and the error-response shape is consistent. However, **9 critical issues** will prevent the iOS app from integrating without changes. The profile response shape is completely wrong (flat keys instead of two nested objects), two enum values don't match the contract (`maintenance` / `desk_job`), the foods index returns the wrong root key (`data` not `foods`), the barcode filter and `favorite` toggle endpoint are both wrong, and Apple SSO lives at the wrong URL. There are also **5 moderate** findings (DELETE /sessions status, pantry toggle response, missing conflict handling, CORS wildcard, recipe food_id unscoped) and **7 minor/style** items. No tests exist for any API controller.

**Critical:** 9 | **Moderate:** 5 | **Minor/style:** 7

---

## 2. Critical Findings (breaks iOS integration)

### C-1 · Profile response shape — flat keys instead of nested `expenditure` and `goals` objects

**File:** `app/views/api/v1/profiles/show.json.jbuilder`

**What the code does (lines 15–21):**
```ruby
json.bmr                      profile.bmr
json.base_tdee                profile.base_tdee
json.daily_calorie_target     profile.calories_needed_for_goal
json.daily_protein_goal       profile.daily_protein_goal
json.daily_fats_goal          profile.daily_fats_goal
json.daily_carbs_goal         profile.daily_carbs_goal
json.computed_water_goal_ml   profile.computed_water_goal_ml
```

**What iOS expects:**
```json
{
  "expenditure": { "bmr": ..., "job_neat": ..., "steps_kcal": ..., "steps_count": ..., "workout_kcal": ..., "tdee": ..., "goal_delta": ... },
  "goals": { "calories": ..., "proteins": ..., "fats": ..., "carbs": ... }
}
```

**Issues:**
1. Keys are flat, not nested under `expenditure` / `goals`.
2. Key names don't match: `daily_calorie_target` ≠ `goals.calories`; `daily_protein_goal` ≠ `goals.proteins`; `daily_fats_goal` ≠ `goals.fats`; `daily_carbs_goal` ≠ `goals.carbs`.
3. `expenditure.job_neat`, `expenditure.steps_kcal`, `expenditure.steps_count`, `expenditure.workout_kcal`, `expenditure.tdee`, and `expenditure.goal_delta` are all entirely absent.

**Suggested fix:**
```ruby
# app/views/api/v1/profiles/show.json.jbuilder
json.expenditure do
  json.bmr           profile.bmr
  json.job_neat      Profile::JOB_NEAT_KCAL[profile.job_activity_level&.to_sym] || 0
  json.steps_kcal    profile.neat_from_steps(profile.default_daily_steps || 6_000)
  json.steps_count   profile.default_daily_steps
  json.workout_kcal  0  # no today's Day in profile context; iOS uses today's day data
  json.tdee          profile.base_tdee
  json.goal_delta    profile.base_tdee.present? ? (profile.calories_needed_for_goal - profile.base_tdee) : nil
end

json.goals do
  json.calories  profile.calories_needed_for_goal
  json.proteins  profile.daily_protein_goal
  json.fats      profile.daily_fats_goal
  json.carbs     profile.daily_carbs_goal
end
```
Remove the seven flat keys above.

---

### C-2 · `goal` enum value: `maintenance` in model, iOS expects `maintain`

**File:** `app/models/profile.rb:5`

```ruby
GOALS = %i[weight_loss maintenance muscle_gain].freeze
```

The `enumerize` gem serializes to the symbol string. The value stored and returned in JSON is `"maintenance"`. iOS decodes against `"maintain"`. These strings do not match — the iOS decoder will treat any `maintenance` profile as having an unknown goal.

**Suggested fix:** Rename the enum value in the model (and update all references, existing rows, and locale keys):
```ruby
GOALS = %i[weight_loss maintain muscle_gain].freeze

# Also update GOAL_MULTIPLIERS:
GOAL_MULTIPLIERS = {
  weight_loss:  0.85,
  maintain:     1.0,
  muscle_gain:  1.10
}.freeze
```
Run a data migration: `Profile.where(goal: "maintenance").update_all(goal: "maintain")`.

---

### C-3 · `job_activity_level` enum value: `desk_job` in model, iOS expects `sedentary`

**File:** `app/models/profile.rb:7`

```ruby
JOB_ACTIVITY_LEVELS = %i[desk_job light_activity standing_job physical_job].freeze
```

The value returned in JSON is `"desk_job"`. iOS expects `"sedentary"`. Same decode failure as C-2.

**Suggested fix:**
```ruby
JOB_ACTIVITY_LEVELS = %i[sedentary light_activity standing_job physical_job].freeze

JOB_NEAT_KCAL = {
  sedentary:      150,
  light_activity: 300,
  standing_job:   500,
  physical_job:   800
}.freeze

WATER_ACTIVITY_OFFSET_ML = {
  sedentary:      0,
  light_activity: 300,
  standing_job:   500,
  physical_job:   700
}.freeze
```
Run a data migration: `Profile.where(job_activity_level: "desk_job").update_all(job_activity_level: "sedentary")`.

---

### C-4 · Foods index: wrong root key (`data` instead of `foods`)

**File:** `app/views/api/v1/foods/index.json.jbuilder:1`

```ruby
json.data @foods do |food|       # ← returns { "data": [...] }
```

iOS expects `{ "foods": [...] }`.

**Suggested fix:**
```ruby
json.foods @foods do |food|
  json.partial! "api/v1/foods/food", food: food
end
```

---

### C-5 · `GET /api/v1/foods?barcode=XXXX` not implemented on the index endpoint

**Files:** `config/routes.rb:36–44`, `app/controllers/api/v1/foods_controller.rb:5–22`

The contract specifies an exact-match barcode filter on the `index` action. The current `index` action has no `params[:barcode]` branch. There is a separate `GET /api/v1/foods/lookup?barcode=XXXX` action (line 70–94), but:
1. It hits Open Food Facts live — it does **not** filter the user's saved foods.
2. It returns a bare hash with different keys (`allergens_tags:`, `traces_tags:`, etc.) rather than a `FoodResponse` object with `id`, `favorite`, `in_pantry`.
3. The lookup response does not go through the `_food` partial and is not wrapped in the contract shape.

**Suggested fix:** Add a barcode filter to `index`:
```ruby
# app/controllers/api/v1/foods_controller.rb, inside index action
scope = scope.where(barcode: params[:barcode]) if params[:barcode].present?
```
And add `barcode` to the foods schema (see C-8).

---

### C-6 · Favorite toggle: wrong route and partial response

**File:** `config/routes.rb:41–43`, `app/controllers/api/v1/foods_controller.rb:102–105`

Contract: `POST /api/v1/foods/:id/favorite` → returns full updated `FoodResponse`.

Current code:
```ruby
# routes.rb:42
patch :toggle_favorite   # ← PATCH, not POST; path is /toggle_favorite not /favorite

# foods_controller.rb:102–105
def toggle_favorite
  @food.update!(favorite: !@food.favorite)
  render json: { favorite: @food.favorite }   # ← returns only { favorite: bool }
end
```

Two issues: (1) HTTP verb is PATCH not POST; (2) response is `{ favorite: }` not the full food object.

**Suggested fix:**
```ruby
# config/routes.rb — replace patch :toggle_favorite with:
member do
  post :favorite
  patch :toggle_pantry
end

# app/controllers/api/v1/foods_controller.rb
def favorite
  @food.update!(favorite: !@food.favorite)
  render :show   # returns full food via the _food partial
end
```

---

### C-7 · Apple SSO lives at wrong URL

**File:** `config/routes.rb:23`

```ruby
post "auth/apple",  to: "auth#apple"   # → POST /api/v1/auth/apple
```

iOS contract expects: `POST /api/v1/sessions/apple`.

**Suggested fix:**
```ruby
# config/routes.rb — replace the auth block with:
post "sessions/apple",  to: "auth#apple"
post "sessions/google", to: "auth#google"   # for symmetry
```

---

### C-8 · FoodResponse field naming mismatches and missing fields

**Files:** `app/views/api/v1/foods/_food.json.jbuilder`, `db/schema.rb`

The `_food` partial and DB schema diverge from the iOS contract in four naming mismatches and three entirely absent fields:

| Contract field | Actual response field | Status |
|---|---|---|
| `allergens_tags` | `allergens` | ⚠️ Wrong key name |
| `traces_tags` | `traces` | ⚠️ Wrong key name |
| `additives_tags` | `additives` | ⚠️ Wrong key name |
| `labels_tags` | `labels` | ⚠️ Wrong key name |
| `food_label_ids` (Array of Int) | `food_labels` (nested objects) | ⚠️ Wrong shape |
| `barcode` | *(absent — no column)* | ❌ Missing |
| `image_url` | *(absent — no column)* | ❌ Missing |

**Column naming:** The DB columns are `allergens`, `traces`, `additives`, `labels`. iOS looks for `allergens_tags` etc. and will get `null`/missing.

**Suggested fix for the partial** (after adding DB columns — see below):
```ruby
# app/views/api/v1/foods/_food.json.jbuilder
json.barcode          food.barcode
json.allergens_tags   food.allergens
json.traces_tags      food.traces
json.additives_tags   food.additives
json.labels_tags      food.labels
json.food_label_ids   food.food_label_ids
json.image_url        food.image_url
```
Remove the `food_labels` block or keep it as an extra field.

**Migration needed:**
```ruby
add_column :foods, :barcode,   :string
add_column :foods, :image_url, :string
add_index  :foods, :barcode
```

Also update `food_params` in `FoodsController` to permit `:barcode, :image_url` and use `allergens_tags:`, `traces_tags:`, etc. consistently, OR keep internal column names and only alias in the view (the latter is cleaner).

---

### C-9 · Settings PATCH: flat strong params, iOS sends nested under `"user"` key

**File:** `app/controllers/api/v1/settings_controller.rb:11–16`

```ruby
def settings_params
  params.permit(
    :locale,
    :show_day_note, :show_workout_section, :show_cardio_section,
    :show_water_tracking, :show_tdee_breakdown, :show_weight_tracking
  )
end
```

iOS sends: `{ "user": { "show_day_note": false } }`. The fields are nested under `params[:user]`. Rails will find `params[:user][:show_day_note]` but the `permit` above looks only at the top level — `params[:show_day_note]` will be `nil`. Every PATCH to settings will silently do nothing.

**Suggested fix:**
```ruby
def settings_params
  params.require(:user).permit(
    :show_day_note, :show_workout_section, :show_cardio_section,
    :show_water_tracking, :show_tdee_breakdown, :show_weight_tracking
  )
end
```
Or, if you want to support both iOS (nested) and other clients (flat), use `params.fetch(:user, params).permit(...)`.

---

## 3. Moderate Findings

### M-1 · DELETE /sessions returns 200 + body, contract requires 204 empty

**File:** `app/controllers/api/v1/sessions_controller.rb:14–23`

```ruby
def destroy
  sign_out(resource_name)
  render json: { message: "Signed out." }   # ← 200, body present
end

def respond_to_on_destroy
  render json: { message: "Signed out." }   # ← same
end
```

iOS expects HTTP 204 with no body. Some iOS decoders treat a non-empty 204 body as an error.

**Fix:**
```ruby
def destroy
  sign_out(resource_name)
  head :no_content
end

def respond_to_on_destroy
  head :no_content
end
```

---

### M-2 · toggle_pantry returns partial response, not full food object

**File:** `app/controllers/api/v1/foods_controller.rb:107–110`

```ruby
def toggle_pantry
  @food.update!(in_pantry: !@food.in_pantry)
  render json: { in_pantry: @food.in_pantry }   # ← partial
end
```

Contract: `PATCH /api/v1/foods/:id/toggle_pantry` returns the updated full `FoodResponse`. iOS uses the return value to refresh the displayed food card.

**Fix:** `render :show`

---

### M-3 · Apple SSO: missing 409 conflict handling and `/identities/apple/link` endpoint

**File:** `app/controllers/api/v1/auth_controller.rb:44–50`

```ruby
def find_or_create_from_sso(provider, uid, email)
  identity = Identity.find_or_initialize_by(provider: provider, uid: uid)
  return [identity.user, false] if identity.persisted?

  user = User.find_or_create_by(email: email) { |u| u.password = Devise.friendly_token }
  identity.update!(user: user, email: email)
  [user, true]
end
```

When a user already has an account with email + password and signs in via Apple with the same email, the code silently creates a new identity linked to that existing account. It never issues the 409 response iOS expects:
```json
{ "error": "needs_password_to_link", "email": "user@example.com" }
```

The `POST /api/v1/identities/apple/link` endpoint (accepts `identity_token` + `password` to confirm the link) is absent entirely.

**Fix (conflict detection):**
```ruby
def find_or_create_from_sso(provider, uid, email)
  identity = Identity.find_or_initialize_by(provider: provider, uid: uid)
  return [identity.user, false] if identity.persisted?

  existing = User.find_by(email: email)
  if existing && Identity.where(user: existing).none? && existing.encrypted_password.present?
    raise PasswordLinkRequired.new(email: email)
  end

  user = existing || User.create!(email: email, password: Devise.friendly_token)
  identity.update!(user: user, email: email)
  [user, true]
end
```
Then in `apple`:
```ruby
rescue PasswordLinkRequired => e
  render json: { error: "needs_password_to_link", email: e.email }, status: :conflict
```
And add the link endpoint per the contract.

---

### M-4 · CORS: `origins "*"` is too permissive for production

**File:** `config/initializers/cors.rb:4`

```ruby
origins "*"
```

Wildcard CORS exposes the API to any origin. This allows browser-based CSRF from any website (though JWT-based auth mitigates the worst outcomes). Should be locked to the production domain(s) before launch.

**Fix:**
```ruby
origins Rails.env.production? ? "https://nutriflow.in" : "*"
```

---

### M-5 · Recipe item `food_id` not scoped to `current_user.foods`

**File:** `app/controllers/api/v1/recipe_items_controller.rb:9`

```ruby
def create
  @recipe_item = @recipe.recipe_items.build(recipe_item_params)  # food_id unvalidated
```

An authenticated user can pass any `food_id` (including another user's private food) and link it to their recipe. There's no ownership check. This leaks other users' food names via `recipe_item_json` which calls `item.food.name`.

**Fix:**
```ruby
if params[:food_id].present?
  food = current_user.foods.find(params[:food_id])  # raises 404 if not owned
  @recipe_item = @recipe.recipe_items.build(recipe_item_params.merge(food: food))
else
  @recipe_item = @recipe.recipe_items.build(recipe_item_params)
end
```

---

## 4. Minor / Style / Suggestions

1. **`SessionsController` and `RegistrationsController` inherit from Devise, not `BaseController`** — they don't get `protect_from_forgery with: :null_session` or `skip_before_action :verify_authenticity_token`. In practice this is fine (Devise's `DeviseController` handles CSRF for these), but it's worth explicitly adding `skip_before_action :verify_authenticity_token` to both for clarity and Rails-version safety.

2. **Misleading comment in `BaseController:6`** — "Override ApplicationController's allow_browser which is HTML-only" — there is no actual `skip_before_action :allow_browser` call. The `allow_browser versions: :modern` inherited from `ApplicationController` is never skipped. In practice iOS native apps with non-browser User-Agents pass through (the `browser` gem treats unknown UAs as allowed), but the comment is wrong. Either add `skip_before_action :allow_browser` or remove the comment.

3. **Settings view returns `locale` (line 1)** — not in the iOS contract for settings. Extra fields don't break decoding but add noise. Separate concerns: settings for display preferences vs. locale belongs on the profile or account object.

4. **`micronutrients: {}` in strong params** — `params.permit(micronutrients: {})` allows an arbitrary hash, meaning a client can store any key-value pairs in the JSONB column. Consider explicitly permitting only the 14 contract keys: `micronutrients: [:calcium, :iron, :magnesium, :potassium, :sodium, :zinc, :vitamin_c, :vitamin_d, :vitamin_b12, :vitamin_a, :vitamin_b9, :cholesterol, :epa, :dha]`.

5. **French-language error strings in English API context** — `render json: { error: "Barcode requis" }` (`foods_controller.rb:71`) and `render json: { error: "Produit non trouvé" }` (line 76) mix French into an otherwise English JSON API. iOS may display these to the user.

6. **`days/show.json.jbuilder` double-loads the Day record** — line 1 assigns `day = @day`, then line 18 does `current_user.days.includes(...).find(day.id)`. This fires a second DB query for the same record. Consider eager-loading in `set_day` or passing the preloaded record.

7. **`SettingsController` permits `:locale`** — the contract scope for `/settings` is the 6 boolean display preferences. Allowing locale changes via the settings endpoint conflates two concerns. If intentional, document it; if not, remove `:locale` from `settings_params`.

---

## 5. Contract Checklist

| # | Endpoint / Feature | Status | Notes |
|---|---|---|---|
| 1 | `POST /api/v1/sessions` — nested `{ "user": { "email", "password" } }` | ✅ | Devise handles nesting internally |
| 2 | Sign-in success — token in JSON body | ✅ | `sessions_controller.rb:8` |
| 3 | Sign-in failure — 401 `{ "error": ... }` | ✅ | Warden failure app in `devise.rb` |
| 4 | `DELETE /api/v1/sessions` — 204 empty | ⚠️ | Returns 200 + `{ message: }` instead (M-1) |
| 5 | `Authorization: Bearer <token>` accepted | ✅ | devise-jwt warden strategy |
| 6 | 401 response shape on expired/invalid token | ✅ | `{ "error": "Unauthorized" }` |
| 7 | `GET /api/v1/profile` — correct shape | ❌ | Flat keys; nested `expenditure`/`goals` absent (C-1); two enum values wrong (C-2, C-3) |
| 8 | `PATCH /api/v1/profile` — partial update | ✅ | Returns correct view |
| 9 | `GET /api/v1/settings` — 6 boolean prefs | ✅ | Extra `locale` field present but harmless |
| 10 | `PATCH /api/v1/settings` — nested under `"user"` | ❌ | Flat params, iOS nested payload ignored (C-9) |
| 11 | `GET /api/v1/foods` — wrapped in `"foods"` key | ❌ | Wrapped in `"data"` key (C-4) |
| 12 | `GET /api/v1/foods?barcode=XXXX` — filter on index | ❌ | Not implemented; `lookup` is different (C-5) |
| 13 | `GET /api/v1/foods/:id` — single bare object | ✅ | |
| 14 | `POST /api/v1/foods` — 201 + bare object | ✅ | |
| 15 | `PATCH /api/v1/foods/:id` — bare object | ✅ | |
| 16 | `DELETE /api/v1/foods/:id` — 204 | ✅ | |
| 17 | `POST /api/v1/foods/:id/favorite` — full object | ❌ | PATCH not POST, wrong path, partial response (C-6) |
| 18 | `PATCH /api/v1/foods/:id/toggle_pantry` — full object | ⚠️ | Route OK; returns `{ in_pantry: }` not full food (M-2) |
| 19 | FoodResponse shape — all fields | ❌ | `barcode`, `image_url` absent; tag fields wrong names (C-8); `food_label_ids` vs `food_labels` |
| 20 | POST/PATCH foods — all fields accepted | ⚠️ | `barcode` not in `food_params`; tag field names mismatched |
| 21 | `POST /api/v1/sessions/apple` — correct URL | ❌ | Lives at `/api/v1/auth/apple` (C-7) |
| 22 | 409 conflict `needs_password_to_link` | ❌ | Not implemented (M-3) |
| 23 | `POST /api/v1/identities/apple/link` | ❌ | Not in PR |
| 24 | Non-2xx error shapes consistent | ✅ | `{ error }` / `{ errors }` throughout |

**Summary: 11 ✅ · 2 ⚠️ · 11 ❌**

---

## 6. Security Review

### 25 — Auth scoping: all controllers scope to `current_user` ✅

Every `find` / `build` in every controller is scoped through an association on `current_user`. No plain `Food.find(params[:id])` style lookups. Spot-checked:
- `FoodsController:set_food` — `current_user.foods.find(params[:id])`
- `DayFoodsController:set_day` — `current_user.days.find_or_create_by!(date: ...)`
- `WorkoutSetsController:set_workout_session` — through day scoped to current_user
- `ProgramExercisesController:set_program` — `current_user.workout_programs.find(...)`
- `RecipeRatingsController:set_rating` — `find_by!(id: ..., user: current_user)`

One exception: **RecipeItemsController `food_id` is unvalidated** (see M-5).

### 26 — Strong parameters ⚠️

Generally correct. Two concerns:
1. `micronutrients: {}` permits arbitrary JSONB keys (minor, see item 4 above).
2. `ProfilesController#profile_params` permits params without `require(:profile)` — this is intentional (flat update) and correct given the contract, but differs from the registrations pattern.

### 27 — N+1 queries ⚠️

- `FoodsController#index` includes `:food_labels` ✅
- `days/show.json.jbuilder` eager-loads via `includes(day_foods: [...], ...)` on a second query for the same record. Not a true N+1 but an unnecessary round-trip on the hottest endpoint in the app (called on every launch).
- `RecipeRatingsController` has no eager load concern at the ratings level — acceptable given low cardinality.

### 28 — devise-jwt / JTI revocation ✅

Correctly wired:
- `User` includes `Devise::JWT::RevocationStrategies::JTIMatcher` (`user.rb:3`)
- `jti` column exists with `NOT NULL` and unique index (`schema.rb`)
- Migration backfills existing users before adding the unique index (`20260704000001`)
- `dispatch_requests` and `revocation_requests` point at the correct `/api/v1/sessions` paths
- `jwt.expiration_time = 30.days`

### 29 — CSRF ✅ (with caveat)

`BaseController` uses `protect_from_forgery with: :null_session` + `skip_before_action :verify_authenticity_token` which disables CSRF for all API controllers. `SessionsController` and `RegistrationsController` inherit from Devise, not `BaseController` — but Devise's `DeviseController` itself handles CSRF safely. Worth adding explicit skips for belt-and-suspenders clarity (Minor item 1 above).

### 30 — CORS ⚠️

`origins "*"` — see M-4. For a pre-launch app this is acceptable temporarily but must be restricted before production.

### 31 — Migrations ✅ (no data risk)

Three migrations in this PR:
- `20260629000001`: Adds nullable `additives`, `labels` arrays and `ingredients_text`. Fully safe.
- `20260704000001`: Adds `jti` column with `default: ""`, backfills all users via `find_each`, then adds unique index. Correct order. Safe.
- `20260704000002`: Creates `identities` table with unique index on `[provider, uid]`. Safe.

### 32 — Tests ❌

No test files exist for any of the 29 API controllers. Running:
```
find . -path "*/test*" -name "*controller*"
find . -path "*/spec*" -name "*controller*"
```
Both return empty. There is zero test coverage for auth, profile, settings, or foods — the four most critical iOS integration surfaces.

### 33 — Routes namespace ✅

All 29 controllers live under `namespace :api do; namespace :v1 do`. No collisions with the web routes namespace. The `resources :days, param: :date` correctly uses date-based params to avoid numeric ID assumptions.

---

## 7. What's NOT in This PR

Absent endpoints that are **expected to be missing** (future work):

| Endpoint | Expected later? |
|---|---|
| `POST /api/v1/identities/apple/link` | ❌ Should be in same PR as Apple SSO (M-3) |
| `GET /api/v1/foods?barcode=XXXX` on index | ❌ Critical — should be in this PR (C-5) |

Absent endpoints that are **acceptable for a later PR** (the days/day_foods/workout surface is present but contract shape needs verification in a follow-up review once the critical items above are resolved):

- Per-day `expenditure` breakdown (today's actual steps + workouts, not profile defaults)
- Push notification token registration
- `GET /api/v1/days/:date` TDEE breakdown using actual day data (currently `profile.base_tdee` uses profile defaults, not the real day's workout calories)
