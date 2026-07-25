# Component Library conventions

## The one decision rule

- A **value** (color, radius, shadow, spacing) -> a **token** in `config/tailwind.config.js`. Never a raw hex, never a raw Tailwind color (`bg-zinc-*`, `text-amber-*`...), never `rounded-lg/xl/2xl` on a library component (use `rounded-control/card/panel`).
- A **single styled element** with no internal structure or logic -> a **CSS `@apply` class** in `application.tailwind.css` (`.input-dark`, `.label-dark`, `.btn-*`).
- **Internal structure, variants, slots, or conditional logic** -> a **ViewComponent** under `app/components/ui/` (`Ui::` namespace).

## Before building anything new
1. Search `app/components/ui/` — does a component already cover it? Reuse/extend it.
2. Check the Lookbook catalog at `/lookbook` for the visual reference.
3. Icons: use `ui_icon(:action, css: "...")` (IconsHelper). Never hardcode `fa-*` glyphs for close/edit/delete/add/check/favorite/chevron_down.

## Authoring a component
- Directory: `app/components/ui/<name>_component/` with `<name>_component.rb` + optional `.html.erb`.
- Class: `Ui::<Name>Component < ApplicationComponent`. Suffix `-Component` always.
- Name by what it RENDERS (`BadgeComponent`), not what it accepts.
- Composition over inheritance — wrap components, never subclass one component from another.
- Variants: expose a `variant:` keyword mapping to a token-based class lookup (a frozen Hash constant), never string-interpolate Tailwind classes (Tailwind can't compile interpolated class names).
- `call`-based (pure Ruby) is fine for simple components; use an `.html.erb` template when there's real markup structure. Never create an empty `.html.erb` for a `call`-based component.
- Every component gets a Lookbook preview under `spec/components/previews/ui/`.

## Non-negotiables (from the app-level CLAUDE.md)
- French UI text via `I18n.t`, no hardcoded strings, no em dashes.
- Never toggle `.hidden` on an element carrying `fa-*` classes (Font Awesome cascade wins). Wrap the icon in a plain element and toggle that.
- Dropdowns: custom Stimulus, never a visible native `<select>`.
