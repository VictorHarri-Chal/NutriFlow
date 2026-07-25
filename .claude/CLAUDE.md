# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> **Scoped CLAUDE.md files** — additional rules are loaded automatically by directory:
> - `app/controllers/api/v1/CLAUDE.md` — iOS API contract (never break)
> - `app/javascript/controllers/CLAUDE.md` — Stimulus lifecycle, dropdowns, dialogs
> - `app/components/CLAUDE.md` — component library: the 3-tier decision rule + authoring conventions

# NutriFlow

NutriFlow is a personal nutrition tracking Rails 8 app. Users log food intake, create recipes, track macros/calories, and organize meals. Interface and data are in **French**.

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Framework | Rails 8 |
| Database | PostgreSQL |
| Frontend | Hotwire (Turbo + Stimulus) + ViewComponent |
| CSS | Tailwind CSS v3 |
| Authentication | Devise |
| Search | pg_search + Ransack |
| Pagination | Pagy |
| Forms | simple_form |
| File Storage | Active Storage + Cloudflare R2 (aws-sdk-s3) + image_processing |
| Enums | enumerize |
| Error Tracking | Sentry (sentry-ruby + sentry-rails) |
| Deployment | Kamal (Docker) |

## Common Commands

```bash
# Development
bin/rails server
bin/rails console
bin/rails db:migrate
bin/rails db:seed

# Generate a new ViewComponent
bin/rails generate component ComponentName

# CSS (Tailwind watch mode runs alongside the server via Procfile.dev)
bin/dev
```

## Prérequis système (dev)

- **libvips** — requis pour `image_processing` (Active Storage variants) : `brew install vips`

## Architecture

### Data Model

All nutrition, fitness, and recipe data is **per-user**. The one exception: `Exercise` records are global (`custom_user_id = nil`) and shared across all users, unless created by a specific user (`custom_user_id` set).

```
User
├── has_one  Profile              # BMR/TDEE goals, gender, job_activity_level, goal (enumerize)
├── has_many Foods                # Nutritional data per 100g
│   └── has_and_belongs_to_many FoodLabels
├── has_many FoodLabels           # Tags applied to Foods (HABTM)
├── has_many Recipes
│   ├── has_many RecipeItems      # Food + quantity (scales macros by gram_factor)
│   └── has_many RecipeRatings    # 1–5 stars, one per user (unique constraint) — ratings RECEIVED on the user's own recipes
├── has_many RecipeRatings        # Direct association — ratings GIVEN by this user to any recipe
├── has_many Days                 # One per date (unique constraint)
│   ├── has_many DayFoods         # Food logged (optional DayFoodGroup)
│   ├── has_many DayRecipes       # Recipe logged (optional DayFoodGroup)
│   ├── has_many WorkoutSessions
│   │   └── has_many WorkoutSets  # Exercise + sets/reps/weight, MET-based calorie burn
│   └── has_many CardioSessions
│       └── has_many CardioBlocks # Machine, duration, intensity (ACSM equations)
├── has_many DayFoodGroups        # Named meal slots (e.g. "Petit-déjeuner")
├── has_many WeightEntries        # Body weight tracking, one per date
├── has_many BodyMeasurements     # Waist/hips/etc., one per date, optional photo
├── has_many ExerciseFavorites    # → Exercise (HABTM-style)
├── has_many Exercises            # Custom exercises this user created (custom_user_id) — see Exercise below
├── has_many WorkoutPrograms
│   └── has_many ProgramDays
│       └── has_many ProgramExercises  # Exercise + order/sets/reps
└── has_many ShoppingLists
    └── has_many ShoppingListItems     # Optional Food reference

Exercise                              # Global (custom_user_id = nil) or per-user
├── belongs_to :custom_user (User), optional: true
├── has_many :exercise_favorites
└── has_one_attached :image           # variants: :thumbnail (400×400), :medium (800×800)
```

### Nutrition Calculation Pattern

Macros are stored per 100g on `Food`. Every entry model (`DayFood`, `DayRecipe`, `RecipeItem`) scales by a `gram_factor = quantity / 100.0` to produce actual intake. `Recipe` aggregates all its `RecipeItem` totals and memoizes them in `@computed_totals`. Never read raw macro columns for display — always call the `total_*` helpers.

### Dual Entry System

Both `DayFood` and `DayRecipe` expose the same duck-typed interface (`total_calories`, `total_proteins`, `total_fats`, `total_carbs`, `total_sugars`, `food_name`) so views can render them uniformly without knowing the type.

### Fitness & Workout Tracking

- **WorkoutSession** (linked to a `Day`) contains `WorkoutSets` (Exercise + sets/reps/weight). Calorie burn is estimated via MET values per body part.
- **CardioSession** (linked to a `Day`) contains `CardioBlocks` (machine type, duration, intensity); each `CardioBlock` computes its own calorie burn via ACSM metabolic equations with machine-specific MET lookups — `CardioSession` itself just sums its blocks' totals.
- **WorkoutProgram** is a reusable training template: `ProgramDays` → `ProgramExercises`. It is not directly linked to `Day`; users log actual sessions from a program.
- **Exercise** is global (custom_user_id = nil) or user-created (custom_user_id set). The scope `Exercise.accessible_to(user)` returns both global and user-owned records. Always use this scope in exercise queries — never query global exercises directly without checking user access.

### Calorie Goals (Profile)

`Profile` computes BMR via the Mifflin-St Jeor formula as hardcoded Ruby math. `tdee(day:)`, `calories_needed_for_goal`, and `daily_calorie_target(day:)` are derived methods — never read raw goal columns for display. `job_activity_level`, goal, and gender are `enumerize` values; `job_activity_level`'s constants (`JOB_NEAT_KCAL`, `JOB_BASELINE_STEPS`) are additive kcal/day offsets, not multipliers — changing them must be tested manually against known values.

### Turbo & Stimulus

Controllers return Turbo Stream responses for in-place updates (food/recipe addition, inline edits, rating). For Stimulus controller rules (lifecycle, dropdowns, dialogs), see `app/javascript/controllers/CLAUDE.md`.

**Turbo Stream response pattern** — always update multiple DOM regions in one stream response (form reset, list update, counters, badges). Never refresh a whole page when a targeted multi-replace works.

**Turbo Frame conventions:**
- Inline add/edit forms use **domain-specific frame IDs**, never a generic shared name. Name the frame after its widget context: `workout_item_form`, `cardio_item_form`, `food_item_form`. Place the `turbo_frame_tag` **immediately after** its corresponding widget partial so the form appears visually below the right section.
- Every place that references a frame must use the exact same ID: `turbo_frame_tag`, `data-turbo-frame`, `turbo_stream.replace`, and controller inline streams. A mismatch causes silent failure or the form rendering in the wrong position.
- On success the frame is cleared (replaced with an empty frame); on validation error the form partial is re-rendered inside the same frame.
- Per-row frames are named `"{resource}_{id}"` (e.g. `"recipe_#{@recipe.id}"`), allowing silent no-op on pages where the frame doesn't exist.
- When multiple FABs or action buttons can each open a different form on the same page, use `exclusive_frame_controller.js` to ensure only one form is open at a time.

**force_open pattern for collapsible widgets:**
When a Turbo Stream re-renders a collapsible widget after a create action, pass `force_open: true` to the widget partial. The partial checks `local_assigns[:force_open]` (never bare `force_open` — raises if not passed) and conditionally renders `data-collapsible-force-open`. The collapsible controller detects this in `connect()` and opens the section.

```erb
<%# Widget partial %>
<div data-controller="collapsible"
     <%= 'data-collapsible-force-open' if local_assigns[:force_open] %>
     ...>

<%# create.turbo_stream.erb %>
<%= turbo_stream.replace "food_widget" do %>
  <%= render "calendars/food_widget", ..., force_open: true %>
<% end %>
```

### ViewComponents

All reusable markup lives in `app/components/`. Generate new ones with `bin/rails generate component`. The base class is `ApplicationComponent < ViewComponent::Base`.

### Locale Files

Locale keys live under `config/locales/{fr,en}/`. Keys must be added to **both** locale files in sync. User locale preference is stored on the `users` table; fallback is browser detection.

**Per-model activerecord split files** — `activerecord.models`, `activerecord.attributes`, and `activerecord.errors` for a given model live in their own file, not in the monolithic `fr.yml`/`en.yml`:

```
config/locales/fr/activerecord/{model}.fr.yml
config/locales/en/activerecord/{model}.en.yml
```

- Never split a model's keys across both `fr.yml` and `{model}.fr.yml` — consolidate everything into the per-model file.
- The EN mirror must always be created at the same time as the FR file. Never ship one without the other.
- Never define `activerecord.errors.models.{model}` in `fr.yml` when a `{model}.fr.yml` exists.

**Page title vs card heading** — when a locale key feeds both `content_for :page_title` (navbar) and an `<h1>` inside a card, split into two keys:
- `views.{resource}.title` → navbar text
- `views.{resource}.heading` → card h1 text

### Active Storage — Images & CDN

NutriFlow uses a two-tool stack for every model that has attached images. **Both tools must be applied together** whenever image attachment is added to a model.

#### Tool 1 — `image_processing` (named variants)

```ruby
has_one_attached :image do |attachable|
  attachable.variant :thumbnail, resize_to_fill: [400, 400]
  attachable.variant :medium,    resize_to_limit: [800, 800]
end
```

- `:thumbnail` (400×400, fill) — cards, lists, compact displays
- `:medium` (800×800, limit) — detail/show pages

#### Tool 2 — Cloudflare R2 CDN (`cdn.nutriflow.in`)

Active Storage is backed by Cloudflare R2 with a public custom domain at `https://cdn.nutriflow.in`. The custom service class `ActiveStorage::Service::CloudflareR2Service` overrides `public_url` to point directly to the CDN — bypassing the Rails redirect controller.

**URL generation rule — always use `.processed.url`:**

```ruby
# Never — routes through Rails redirect controller
url_for(attachment.variant(:thumbnail))

# Always — direct CDN URL
attachment.variant(:thumbnail).processed.url
exercise_image_url(exercise, variant: :thumbnail)  # via model helper
```

#### Checklist — adding image support to a new model

1. Add `has_one_attached :image` with both `:thumbnail` and `:medium` variants (copy from `Exercise`)
2. Add a `{model}_image_url(record, variant: nil)` helper — follow `ExercisesHelper#exercise_image_url`
3. Use the helper everywhere in views — never call `.variant()` inline
4. Permit `:image` (and `:remove_image`) in strong params
5. Forms: `variant: :thumbnail` — Show pages: `variant: :medium`

#### Current models with image support

| Model | Variants | Helper |
|---|---|---|
| `Exercise` | `:thumbnail`, `:medium` | `ExercisesHelper#exercise_image_url` |
| `BodyMeasurement` | `:thumbnail`, `:medium` | `BodyMeasurementsHelper#body_measurement_image_url` |

---

### Data Export (Excel)

Users export their data as a single `.xlsx` from **Réglages → Export**. All export code lives in `app/services/exports/`. **Whenever you add a new user-facing data type — or a new field/column to something already exported — you must also wire it into the export**, or the "download a copy of my data" promise silently rots.

**How it fits together:**
- **One exporter per category** (`app/services/exports/<name>_exporter.rb`): `initialize(user:, period:)` + `#sheets`, returning normalized sheets `[{ name:, tables: [{ title:, headers:, rows:, prune? }] }]`. `Exports::Sheet.simple(name:, headers:, rows:)` builds the common single-table shape.
- **`Exports::CategoryRegistry`** is the single source of truth (`CATEGORIES`): each entry is `{ key:, section:, exporter:, dated:, guard: }`. The settings checkboxes AND `ExportsController` both read it — never keep a second list. `guard` is a lambda on a user preference toggle (nil = always available); `visible_for(user)` applies it.
- **`Exports::ExcelBuilder`** merges any exporters' sheets into the workbook, applies date/datetime cell formats, and **prunes fully empty/zero columns** from detail tables (≥2 rows) — summaries are protected by `prune: false` on the table.
- **Async**: `ExportsController#create` enqueues `DataExportJob` (Solid Queue), stores the file on the `DataExport` record (`has_one_attached :file`), the browser polls `#show`, then downloads via the authenticated `#download` (`send_data`, scoped to `current_user` — never the public R2/CDN URL). One in-flight export per user (DB partial-unique index + controller guard); retention 5.

**Checklist — add a NEW export category:**
1. Create `app/services/exports/<name>_exporter.rb`. Scope every query to `user` (never other users' rows). Add `includes` covering the full depth the rows read (N+1 on a multi-year export is real). If time-based, accept `period:` and filter by `@period&.range` (nil range = full history).
2. Register it in `Exports::CategoryRegistry::CATEGORIES` (key, section, exporter, `dated:`, `guard:` — add a guard lambda if the data's section can be toggled off in preferences, mirroring the existing ones).
3. Add the category label to **both** locales under `views.settings.export.categories.<key>`. If it's a new section, add it to `SECTIONS` and `views.settings.export.sections.<section>`. The checkbox then renders automatically.

**Checklist — add a field/column to an EXISTING category:** add it to that exporter's `headers` AND `rows` (keep them the same length). Then apply the conventions below.

**Export conventions (learned, non-obvious):**
- **Column headers are hardcoded French strings in the exporter, NOT i18n** (deliberate: a French-only tabular export). Only the settings-UI category/section *labels* are i18n. Don't i18n the sheet headers.
- **Translate enum values to French**, reusing existing keys, with a blank guard to avoid the trailing-dot i18n gotcha — e.g. food category via `t("views.shopping_lists.categories.#{c}")` (`return nil if c.blank?`), machine/split/protocol likewise. Never dump the raw English enum key.
- **Put real `Date`/`Time` objects in rows**, not pre-formatted strings — `ExcelBuilder` formats them (`dd/mm/yyyy`, incl. time) and keeps them sortable/typed.
- **Coerce `BigDecimal` before string-interpolating** a quantity (`qty == qty.to_i ? qty.to_i : qty.to_f`) or it renders in scientific notation.
- **Exercise names**: `exercise&.name_fr.presence || exercise&.name`.
- **Summary / key-value tables**: set `prune: false` on the table so a legitimately-zero value isn't dropped by empty-column pruning.
- **Prefer flat, human-readable sheets** (inline lists, denormalized) over many linked tables — the export targets beginners/intermediates, not analysts.
- **The job must be deterministic and re-runnable**; it re-filters stored category keys through `visible_for` at run time, so a since-disabled category can't slip in.

---

## Rules

### Data scoping

Every query on user-owned data must be scoped to `current_user`. The only exception: `Exercise` — use `Exercise.accessible_to(current_user)` which returns both global and user-owned records. Never query `Exercise.all` directly.

**Deep associations** — `User` has no direct `has_many` to resources nested more than one level deep. Never assume `current_user.day_recipes` exists — it doesn't. Always traverse via joins:

```ruby
# WRONG — NoMethodError
current_user.day_recipes

# CORRECT
DayRecipe.joins(:day).where(days: { user_id: current_user.id })
```

**IDOR on join-found resources** — when finding a resource via a join, scope **both** the join table AND the resource's own `user_id` column:

```ruby
# WRONG — scopes only the parent recipe, not the rating row
RecipeRating.joins(:recipe).where(recipes: { user_id: current_user.id }).find(params[:id])

# CORRECT
RecipeRating.joins(:recipe)
            .where(recipes: { user_id: current_user.id })
            .where(recipe_ratings: { user_id: current_user.id })
            .find(params[:id])
```

### Nutritional values
Macros (`calories`, `proteins`, `fats`, `carbs`, `sugars`) are stored per 100g. Scale by `quantity / 100` for actual intake.

### BMR formula
The Mifflin-St Jeor formula is hardcoded Ruby math on `Profile`. Any change to the formula or `job_activity_level`'s additive kcal/day offsets (`JOB_NEAT_KCAL`, `JOB_BASELINE_STEPS`) must be tested manually against known values.

### Form field character limits
For a new name/title text input backed by a model, default to `maxlength: 80` (not 50 — too short for real recipe/food/program names) unless the model already has its own `validates ... length: { maximum: N }` to match instead. Search-query inputs (not saved to a model) can stay at 50. Free-text notes/description fields can go much higher (300–500+). Whatever `maxlength` is chosen client-side, check there's no stricter (lower) server-side length validation that would reject it after the fact.

### Unique constraints
- One `Day` record per user per date
- One rating per user per recipe (values 1–5)

**DB index → model validation**: every unique index in `db/schema.rb` must have a matching `validates … uniqueness:` on the model. For user-scoped resources always use `scope: :user_id`:

```ruby
validates :name, uniqueness: { scope: :user_id, case_sensitive: false }
```

### Internationalization
- Default locale: `fr`
- Never hardcode user-facing text — always use `I18n.t()`
- Add keys to both `fr` and `en` locales in sync
- Timezone: Paris
- Never use an em dash (—) in user-facing copy (locale strings, UI text) — it reads as AI-generated. Rephrase with a period, comma, or parenthesis instead.
- Match the existing register of the page being edited (`vous` is the app's dominant convention — check surrounding keys in the same file/section before writing new copy, don't introduce `tu` where the page already uses `vous`, or vice versa).
- Exception: explanatory/help content that reads like professional advice (tooltips explaining methodology, coaching-style hints, RPE/technique guidance) always uses `vous` and a professional tone, even inside a section whose action copy otherwise uses `tu`. `tu` is for UI actions ("Ajoute une série"); `vous` is for teaching the user something.

### UI components
Prefer a ViewComponent over duplicating markup. Create new components with `bin/rails generate component`.

### Search & Filtering
The **Food** list combines **both** search tools (`app/controllers/foods_controller.rb`):
- **pg_search** (`.search_by_name(params[:query])`) for full-text name search.
- **Ransack** (`@q = scope.ransack(params[:q])`) for attribute-based filters.
- Semantic boolean toggles (favorites, in-stock) as plain `where` clauses chained after Ransack.

Never replace one with the other on Food — use the combination.

The **Recipe** list (`app/controllers/recipes_controller.rb`) currently uses pg_search only, no Ransack — there's no attribute-based recipe filter yet. If one is added, follow the Food pattern (combine both) rather than introducing a different approach.

### Pagination
Always use the `PaginationComponent` (not raw Pagy helpers). The `ApplicationController#pagy` override supports a `full_result=true` param that bypasses the limit — keep this behavior intact.

Only render the component when there are multiple pages:

```erb
<% if @pagy&.pages&.> 1 %>
  <div class="mt-6 flex justify-center">
    <%= render PaginationComponent.new(pagy: @pagy) %>
  </div>
<% end %>
```

### N+1 queries
- Use `.size` (not `.count`) on associations that may already be loaded — `.size` uses the cache, `.count` always hits the DB.
- After `pagy()` materializes a collection, use Ruby enumerable methods (`.reject`, `.map`) — do not re-query with `.count` or `.where`.
- Use `.loaded?` to check if an association is already in memory before accessing it in a loop.
- Every `includes` must cover the full depth accessed in views. If a component calls `record.association.sub_association`, the controller's `includes` must reach `association: :sub_association`.

### Replacing a flat column with a child table
When a column (e.g. `sets`/`reps_target`) is split off into its own `has_many` (e.g. `program_exercise_sets`), do it as three migrations — create the table, backfill existing rows, then drop the old columns — and before dropping anything, `grep` the **whole app** for the old column names. The obvious call sites (the model, its controller) are never the only ones: duplicate/copy actions (`copy_exercises_to!`), any "pre-fill from a template" logic, and every `.includes` that renders the old association are easy to miss and will raise `NoMethodError` or `PG::UndefinedColumn` in production instead of at review time.

### Nested attributes (`accepts_nested_attributes_for`)
Validation errors on a nested attribute need their own i18n translation, in a non-obvious key format: `activerecord.attributes.<parent_model>/<association_name>.<attribute>` — a **literal `/`** in the key, not a nested YAML hash under the parent model. Example, for `ProgramExercise has_many :program_exercise_sets`:

```yaml
activerecord:
  attributes:
    program_exercise/program_exercise_sets:
      reps_target: "Répétitions"
```

Without this exact key, `errors.full_messages` silently falls back to the humanized English attribute name (e.g. "Program exercise sets reps target") even under the `fr` locale.

### Validation error display
When a save fails, render every message in `record.errors.full_messages.uniq` (a bullet list), never just `.first`. The user should see every problem in one pass, not fix-and-resubmit one field at a time.

### Manual verification gotchas
- Tailwind is not watched by a plain `bin/rails server` — run `bin/rails tailwindcss:build` before checking any new class in a browser, or use `bin/dev` (which runs the watcher alongside the server).
- A long-running dev server predating a migration has a stale ActiveRecord schema cache — it will still reference dropped/added columns and fail with `PG::UndefinedColumn` or silently use old defaults. Restart it after every migration before testing in a browser.
- Creating a confirmed test user via `bin/rails runner` can raise inside Devise's confirmation mailer (`Devise::Mapping.find_scope!`). This happens *after* the record is already saved, so it's safe to ignore — just force-confirm afterward with `user.update_column(:confirmed_at, Time.current)`.

### Development tooling
`bullet` gem is active in development. Keep `Bullet.add_footer = false` — `true` injects raw HTML into Turbo Stream XML responses and corrupts them. N+1 alerts appear in the Rails log; resolve them before shipping.

### Controller data-loading
Controllers that return Turbo Stream responses must call data-loading concern helpers (e.g. `load_calendar_data`, `load_month_heatmap`) **before** the `respond_to` block, in both success and error paths.

### Inline form design standard (calendar widgets)
All inline add/edit forms inside calendar turbo frames use this exact pattern:

```erb
<div class="bg-surface-raised border border-surface-border/40 rounded-2xl p-5 mt-4 mb-4">
  <div class="flex items-center justify-between mb-5">
    <h3 class="text-sm font-semibold text-ink-primary"><%= t("...") %></h3>
    <button type="button"
            data-controller="close-frame"
            data-action="click->close-frame#close"
            class="p-1.5 text-ink-subtle/50 hover:text-ink-primary transition-colors rounded">
      <i class="fas fa-times text-sm"></i>
    </button>
  </div>
</div>
```

Never use `rounded-xl shadow-sm p-6` or `text-lg` titles for these forms — those belong to page-level cards.

---

## Design System

NutriFlow uses a fully custom dark-first token system defined in `config/tailwind.config.js` and component classes in `app/assets/stylesheets/application.tailwind.css`.

### Color tokens — always use these, never raw Tailwind colors

| Token | Purpose |
|---|---|
| `surface-base` (#18181B) | Page background, inner containers |
| `surface-raised` (#27272A) | Cards, panels |
| `surface-hover` (#3F3F46) | Hover states, subtle fills |
| `surface-border` (#52525B) | Borders and dividers |
| `brand` (#EAB308) | Primary CTA, active states, accent |
| `brand-hover` (#FDE047) | Hover on brand elements |
| `brand-muted` (#713F12) | Brand background fill (low contrast) |
| `brand-dim` (#854D0E) | Defined but currently unused anywhere — don't reach for it without a real need |
| `ink-primary` (#F4F4F5) | Primary text |
| `ink-muted` (#A1A1AA) | Secondary text, labels |
| `ink-subtle` (#71717A) | Placeholder, tertiary text |
| `macro-calories/proteins/carbs/fats/sugars` | Macro-specific colors only |
| `status-success/warning/danger/info` | System feedback |
| `status-*-dim` (e.g. `status-danger-dim` #450A0A) | Darker/low-contrast variant of each status color — used for subtle background fills |

### CSS component classes — use these, don't reinvent them

| Class | Use |
|---|---|
| `.card` | Outer page card (`bg-surface-raised rounded-xl border border-surface-border/50 shadow-lg`) |
| `.card-section` | Inner section inside a card |
| `.btn-primary` | Main CTA (amber bg, zinc-900 text) |
| `.btn-secondary` | Secondary action (surface-hover bg, border) |
| `.btn-danger` | Destructive action |
| `.btn-ghost` | Tertiary/icon-only actions |
| `.input-dark` | All text inputs |
| `.label-dark` | Form labels |
| `.table-dark` | Data tables with hover rows |
| `.nav-link` / `.nav-link-active` | Sidebar navigation |
| `.macro-card` | Macro stat blocks |
| `.progress-track` | Progress bars |

### Visual patterns

- **Font**: Syne (defined in Tailwind config — never change)
- **Icons**: Font Awesome (`fas fa-*`, `far fa-*`) — no other icon library
- **Page container**: `max-w-6xl mx-auto mt-16 card p-8` — use consistently
- **Empty states**: dashed border container → centered circle icon → `text-brand` icon → `text-ink-primary` title → `text-ink-muted` description → CTA button
- **Filter pills**: `rounded-full text-xs font-medium border transition-colors` with `bg-brand/20 text-brand border-brand/50` for active state
- **No box-shadows** on interior elements — use borders (`border-surface-border/40`) for separation
- **Opacity modifiers** (`/50`, `/40`, `/20`) are the standard for softer variants — don't create new opaque color classes

### Rules
- Never use raw Tailwind colors (no `bg-zinc-900`, `text-gray-100`, etc.) — always use the token aliases above.
- Never introduce a new visual pattern without checking if one already exists in the codebase.
- Check `app/assets/stylesheets/application.tailwind.css` before styling anything new.
- When a feature needs more distinct semantic colors than `brand` + `status-danger` (e.g. 3-4 states to tell apart at a glance, like set types or status badges), reach for the remaining `status-*` tokens (`success`, `warning`, `info`) before ever introducing a new color. Never repurpose `macro-*` colors outside a nutrition-macro context — they're reserved.
- **Never `truncate`/`line-clamp-*` on a name or title displayed in a detail view, header, or single-item card/modal identity section** — the user needs to read the full text there. Only use `truncate`/`line-clamp-*` in a genuinely compact list/table/grid/dropdown row where uniform row height is a real layout constraint. Default to `break-words` (plus `min-w-0` on the flex ancestor so it can actually shrink/wrap) wherever the full name matters.
- **Never toggle Tailwind's `.hidden` class directly on an element that also carries Font Awesome classes** (`fas`/`far`/`fab`/`fa-*`). `fontawesome/all.min.css` loads *after* `tailwind.css` in `app/views/layouts/application.html.erb`, and FA's base rule sets its own `display` at the same specificity as `.hidden` — the later-loaded FA rule wins the cascade, so the icon stays visible. Wrap the icon in a plain `<div>`/`<span>` with no FA classes and toggle `hidden` on that wrapper instead.
- Modals containing a camera/media view must size their default (pre-interaction) content to fit inside the modal's `max-h-[Nvh]` without requiring scroll — don't reuse a full-page camera container's height (e.g. `h-[calc(100vh-Xrem)]`) inside a modal context; give it a fixed, modal-appropriate height instead.

### UI Component Conventions
- **Dropdowns**: Always custom (Stimulus + Tailwind) — never a *visible* native `<select>`. A real `<select>` may still exist as a `sr-only` accessible backing element for the custom dropdown (the established `custom-select` pattern), but the user must never see or interact with the native control directly. See `app/javascript/controllers/CLAUDE.md` for implementation rules.
- **Tooltips**: Just set a normal `title="..."` attribute. A global script (`app/javascript/tooltip.js`) auto-converts every `title` into a custom-styled, auto-positioned, viewport-clamped tooltip and strips the native browser one — no manual `data-tooltip` wiring needed. For multi-topic content, separate topics with a blank line (`\n\n`) in the i18n string (use a YAML `|-` block scalar); the tooltip is `white-space: pre-line` and renders each as its own paragraph. Never build a bespoke tooltip element for a simple hover hint.
- **Confirmation dialogs**: Always custom modals — never `window.confirm()`. See `app/javascript/controllers/CLAUDE.md`.

### Component Library (`Ui::` ViewComponents)

Reusable UI components live in `app/components/ui/` (namespace `Ui::`). **Always prefer these over hand-rolling markup.** Visual catalog at `/lookbook` (dev). Authoring rules (how to build/extend one): `app/components/CLAUDE.md`. The 3-tier rule: a **value** → a token; a **single styled element** → a CSS `@apply` class; **structure/variants/slots/logic** → a `Ui::` component.

| Component | Use it for | Key args / slots |
|---|---|---|
| `Ui::ButtonComponent` | buttons, icon-buttons, CTAs (renders `<button>` or `<a>`) | `label:`, `variant:` (primary/secondary/danger/ghost), `size:` (sm/md/lg), `icon:` (ui_icon key), `href:`, `method:`, `aria_label:` |
| `Ui::BadgeComponent` | non-interactive status labels + simple pills | `label`, `variant:` (brand/success/warning/danger/info/neutral), `style:` (badge/pill), `size:` (sm/md), `active:`, `icon:` |
| `Ui::EmptyStateComponent` | empty / zero-data states (dashed box, circle icon, title, hint, CTA) | `icon:` (raw glyph), `title:`, `hint:`, `size:` (lg/md/sm), `icon_color:` (default `text-brand`; pass a status color for semantic states), `cta` slot |
| `Ui::PanelComponent` | `bg-surface-raised rounded-panel` container (the stat-panel look, distinct from `.card`) | `padding:` |
| `Ui::StatCardComponent` | KPI block (label + big value + unit) | `label:`, `value:`, `unit:`, `value_color:` |
| `Ui::ModalComponent` | modal dialogs (wraps the `modal` Stimulus controller) | `title:`, `subtitle:`, `icon:`, `max_width:` (sm/md/lg/xl), `max_height:` (sm/md/lg), `body_padding:`, `body_layout:` (block/flex), `data:` (extra controllers/actions merged onto root); slots `body`, `footer`, `title_accessory` |
| `Ui::CustomSelectComponent` | custom dropdown select (wraps `custom-select`) | `name:`, `choices:`, `selected:` |
| `Ui::CollapsibleWidgetComponent` | collapsible calendar-style widget (wraps `collapsible`) | `title:`, `storage_key:`, `force_open:`; slots `content_body`, `header_action` |
| `Ui::FieldComponent` | label + input + hint + inline errors | `name:`, `label:`, `type:`, `value:`, `hint:`, `errors:` |
| `Ui::IconCircleComponent` | icon inside a circle (avatar-like) | `icon:`, `size:`, `bg:`, `color:` |
| `Ui::ProgressBarComponent` | progress bar (wraps `.progress-track`) | `percent:`, `color:`, `height:` |

**Established usage norms (apply consistently in new code):**
- **Modal footer with 2 buttons** → wrapper `flex items-center gap-3`, both buttons `flex-1 text-sm`, the affirmative action on the RIGHT. `confirm_controller.js` dialogs follow the same layout.
- **Recurring-action icons** → `ui_icon(:close | :edit | :delete | :add | :check | :success | :favorite | :chevron_down)` (`IconsHelper`), never a hardcoded glyph. Domain icons (utensils, dumbbell, house, cart…) stay raw `<i>`. **Same domain concept ⇒ same glyph everywhere** it appears (filter pill, empty state, action button, row toggle). E.g. pantry-in-stock = `fa-house` (green), to-rebuy = `fa-bag-shopping` (red).
- **Favorite accent** → `text-star` / `bg-star` / `border-star` token, never raw `amber-400`.
- **Design tokens** (added in this refactor) → `rounded-control` (inputs/buttons), `rounded-card` (cards), `rounded-panel` (panels/modals); `shadow-card`, `shadow-modal`; `star` color. Never `rounded-lg/xl/2xl` on a library component.
- **Chart colours in JS** → import from `app/javascript/chart_palette.js` (single source), never hardcode hex.

**Intentionally NOT componentized — do not try to force these into a `Ui::` component:**
- **Filter / sort pills** (`foods/index`, `recipes/index`) — specialized filter links (query-param hrefs + per-filter semantic active colours).
- **Nested-form empty placeholders** (`data-nested-form-target="emptyState"`) — JS-toggled form-item placeholders, not page empty states.
- **Confirmation dialogs** — generated in JS by `confirm_controller.js` (future `ConfirmModal` candidate).
- **Bottom-sheets** (`calendars/index` FAB, `workout_programs/_tension_balance_panel`) — future `BottomSheetComponent` candidate.
- **Chart placeholders** (statistics: bare icon + one text line + fixed height, no circle) — a distinct pattern from `EmptyStateComponent`; future `ChartPlaceholderComponent`.
- **Landing page** (`home/index.html.erb`) — deliberate public-marketing exception, outside the app design system.

---

## Git Workflow

Conventional commits (`feat:`, `fix:`, `refactor:`). Branch prefixes: `feature/`, `fix/`, `refactor/`.

## Testing

No test suite yet. When introduced: **Minitest** (Rails default). System tests are disabled in generators.