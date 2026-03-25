# NutriFlow

## Project Overview

NutriFlow is a personal nutrition tracking web application built with Rails 8. Users log daily food intake, create recipes, track macros and calories, and organize meals into groups. The app features ratings and comments on recipes. Interface and data are primarily in **French**.

## Tech Stack

| Component | Technology |
|-----------|-----------|
| **Framework** | Rails 8 |
| **Language** | Ruby |
| **Database** | PostgreSQL |
| **Frontend** | Hotwire (Turbo + Stimulus) + ViewComponent |
| **CSS** | Tailwind CSS v3 |
| **Asset Pipeline** | Propshaft |
| **Authentication** | Devise |
| **Background Jobs** | Solid Queue (in-process via Puma) |
| **Caching** | Solid Cache |
| **Search** | pg_search (full-text) + Ransack (filtering) |
| **Pagination** | Pagy |
| **Forms** | simple_form |
| **Calorie Math** | Dentaku (expression evaluator) |
| **Deployment** | Kamal (Docker) |

## Key Files — Where to Look

| What you want to know | Where to look |
|-----------------------|---------------|
| Models & associations | `app/models/*.rb` |
| Database structure | `db/schema.rb` — source of truth |
| Routes | `config/routes.rb` |
| Calorie/BMR calculations | `app/models/profile.rb` |
| Nutritional aggregation logic | `app/models/day_food.rb`, `app/models/recipe.rb` |
| Devise config | `config/initializers/devise.rb` |
| i18n strings | `config/locales/fr/`, `config/locales/en/` |
| Tailwind form config | `config/initializers/simple_form_tailwind.rb` |
| Deployment config | `config/deploy.yml` |
| Docker build | `Dockerfile` |
| Local dev processes | `Procfile.dev` |

## Architecture Decisions & Gotchas

### Data is always scoped to user
Every model with user data has a `user_id`. Never query without a user scope — there is no global food/recipe database, everything is per-user.

### Macros are stored per 100g
`Food` stores `calories`, `proteins`, `fats`, `carbs`, `sugars` per 100g. Scale by `quantity / 100` when computing actual intake. See `DayFood` for the pattern.

### Calorie formula lives in Profile, evaluated by Dentaku
The Harris-Benedict BMR formula is evaluated at runtime as an expression string via the Dentaku gem. Errors surface at runtime, not at load. Test any formula change manually.

### One Day record per user per date
Enforced by a unique index on `(date, user_id)`. Creating a duplicate raises `ActiveRecord::RecordNotUnique`.

### Recipe ratings: one per user per recipe
Enforced by a unique index on `(recipe_id, user_id)` and a DB check constraint for values 1–5.

### Solid Queue runs inside Puma (no separate worker)
Set via `SOLID_QUEUE_IN_PUMA=true` in `config/deploy.yml`. No separate worker process to manage in production.

### Multi-database in production
Four PostgreSQL databases: `primary`, `cache`, `queue`, `cable`. See `config/database.yml`. Locally, only `primary` is used.

## Internationalization

- **Default locale**: `fr`
- All user-facing strings go through `I18n.t()` — never hardcode text in views
- Add keys to both `config/locales/fr/` and `config/locales/en/` in sync
- Timezone: Paris

## ViewComponents

Reusable UI lives in `app/components/`. Prefer creating a component over duplicating markup in views.

When adding new reusable UI:
```bash
bin/rails generate component MyComponent prop1 prop2
```

## Git Workflow

Conventional commits:
```
feat: add food import via CSV
fix: correct calorie calculation for recipes
refactor: extract macro display into component
```

Branch naming: `feature/`, `fix/`, `refactor/` prefixes.

## Local Development

```bash
bin/dev                   # Starts web server + tailwind watcher
bin/rails db:migrate      # Run pending migrations
bin/rails db:seed         # Seed dev data
```

## Deployment (Kamal)

**Server**: single web server, SSL via Let's Encrypt. See `config/deploy.yml` for details.

```bash
kamal deploy              # Deploy to production
kamal app logs            # Tail production logs
kamal app exec -i bash    # Shell into running container
kamal env push            # Push updated env vars
```

Secrets in `.kamal/secrets` (gitignored). Required: `RAILS_MASTER_KEY`, `POSTGRES_PASSWORD`, `KAMAL_REGISTRY_PASSWORD`.

## Testing

No test suite configured yet. When adding tests, confirm RSpec vs Minitest preference first. System tests are disabled in generators.
