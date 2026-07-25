# API iOS — Stability Rules

The iOS app (Carlos) consumes `/api/v1/`. It is an **external contract**: once deployed, any breaking change silently crashes the mobile app for all users. Apply these rules to every task that touches models, controllers, or routes — even tasks that appear unrelated to the API.

## The one rule that overrides everything else

**Never remove or rename a field that exists in a jbuilder view under `app/views/api/v1/`.** Adding new fields is always safe. Removing or renaming breaks every iOS client that has already shipped. If a rename is truly necessary, keep the old key as an alias and add the new one alongside it, then coordinate with Carlos before dropping the old key.

## When touching a model

- Adding a column → safe. Expose it in the relevant jbuilder partial if iOS needs it.
- Removing a column → first remove it from every `app/views/api/v1/` file that references it, then drop the column.
- Renaming a column → keep the old jbuilder key pointing to the new column name. Never change the JSON key name unilaterally.
- Changing a column's type (e.g. integer → string) → treat as a breaking change. Coordinate with Carlos first.
- Changing a computed method that the jbuilder calls (e.g. `total_calories`, `bmr`, `effective_steps`) → the return type and key must stay identical. A behaviour change (different number) is acceptable; a type or key change is not.

## When touching routes

- Never rename or delete a route under `namespace :api` that is already in the plan (`.claude/plans/api_v1_ios.md`).
- Never change the HTTP verb of an existing API endpoint (e.g. PATCH → PUT). iOS hardcodes verbs.
- Never move a nested route to a different parent (e.g. `workout_sets` nested under `days` instead of `workout_sessions`). iOS builds URLs from the nesting.
- Adding new routes is always safe.

## When touching authentication

- Never change `jwt.secret`, `jwt.dispatch_requests`, or `jwt.revocation_requests` in `config/initializers/devise.rb` without invalidating all active iOS sessions first (coordinate with Carlos). Changing the secret logs out every iOS user instantly.
- Never change `jwt.expiration_time` silently — Carlos may have coded assumptions around the 30-day lifetime.
- Never add `skip_before_action :authenticate_user!` to any `Api::V1::` controller without an explicit security justification. The only allowed exceptions are `passwords#create` (forgot password) and `sessions#create` / `registrations#create`.

## When touching jbuilder views

- Always use `includes` / `preload` when rendering associations in a jbuilder loop. Never iterate over an association without eager-loading it — every extra query multiplies by the number of records (N+1).
- Never use `render json:` directly in an API controller — always go through the jbuilder view. This keeps the response format auditable in one place.
- The error response shapes are fixed contracts:
  - `{ "error": "..." }` for 401, 404
  - `{ "errors": { "field": ["msg"] } }` for 422
  Never change these shapes.

## Before any significant Rails change, ask

1. Is this model exposed in `app/views/api/v1/`? → Check before renaming columns or methods.
2. Does this route exist in the API namespace? → Check `config/routes.rb` under `namespace :api` before modifying.
3. Does this controller concern or ApplicationController method affect `Api::V1::BaseController`? → Changing shared behaviour (auth, locale, error handling) can silently break all API responses.

## When a breaking change is truly necessary

Create `/api/v2/` alongside `/api/v1/`. Never modify an existing v1 endpoint in a backward-incompatible way. `/api/v1/` must remain functional until Carlos ships an iOS update and all users have migrated.
