# Component Library conventions

## The one decision rule

- A **value** (color, radius, shadow, spacing) -> a **token** in `config/tailwind.config.js`. Never a raw hex, never a raw Tailwind color (`bg-zinc-*`, `text-amber-*`...), never `rounded-lg/xl/2xl` on a library component (use `rounded-control/card/panel`).
- A **single styled element** with no internal structure or logic -> a **CSS `@apply` class** in `application.tailwind.css` (`.input-dark`, `.label-dark`, `.btn-*`).
- **Internal structure, variants, slots, or conditional logic** -> a **ViewComponent** under `app/components/ui/` (`Ui::` namespace).

## Before building anything new
1. Search `app/components/ui/` — does a component already cover it? Reuse/extend it.
2. Check the Lookbook catalog at `/lookbook` for the visual reference.
3. Icons: inside a component, call `helpers.ui_icon(:action, css: "...")` — `IconsHelper` is NOT mixed into `ApplicationComponent`, so a bare `ui_icon` raises `NoMethodError`. Never hardcode `fa-*` glyphs for close/edit/delete/add/check/favorite/chevron_down.

## Authoring a component
- Directory: `app/components/ui/<name>_component/` with `<name>_component.rb` + optional `.html.erb`.
- Class: `Ui::<Name>Component < ApplicationComponent`. Suffix `-Component` always.
- Name by what it RENDERS (`BadgeComponent`), not what it accepts.
- Composition over inheritance — wrap components, never subclass one component from another.
- Variants: expose a `variant:` keyword mapping to a token-based class lookup (a frozen Hash constant), never string-interpolate Tailwind classes (Tailwind can't compile interpolated class names).
- `call`-based (pure Ruby) is fine for simple components; use an `.html.erb` template when there's real markup structure. Never create an empty `.html.erb` for a `call`-based component.
- **Zeitwerk**: the sidecar dir `app/components/ui/<name>_component/<name>_component.rb` autoloads as `Ui::<Name>Component` (not doubly-nested) thanks to `Rails.autoloaders.main.collapse("#{root}/app/components/ui/*")` in `config/application.rb`. Don't add an extra module wrapper.
- **Caller class/attrs merge**: a `call`-based component that accepts `**options` should append the caller's `class:` and merge `data:`/`aria:` so callers can add utilities/Stimulus without clobbering the base — `extra = @options.delete(:class); tag.x(..., class: [BASE, extra].compact.join(" "), **@options)`. See `ButtonComponent` / `BadgeComponent` / `PanelComponent`.
- **`icon:` arg convention**: expose it as a `ui_icon` key (Symbol) when the icons are recurring actions (rendered via `helpers.ui_icon`); as a raw glyph String when they're domain icons (`<i class="fas #{icon}">`). State which in the arg name/doc.
- **Slots**: a slotted component is called with a block — `<%= render Ui::X.new(...) do |c| %><% c.with_slotname do %>…<% end %><% end %>`. Declare with `renders_one :slotname`; guard optional slots with `slotname?` before yielding.
- Every component gets a Lookbook preview under `spec/components/previews/ui/` (**not** `test/`). Generate with `bin/rails generate component Ui::Name arg1 arg2`, then MOVE the generated preview from `test/components/previews/` to `spec/components/previews/ui/` (this app pins previews there — `config/environments/development.rb`).

## Non-negotiables (from the app-level CLAUDE.md)
- French UI text via `I18n.t`, no hardcoded strings, no em dashes.
- Never toggle `.hidden` on an element carrying `fa-*` classes (Font Awesome cascade wins). Wrap the icon in a plain element and toggle that.
- Dropdowns: custom Stimulus, never a visible native `<select>`.
