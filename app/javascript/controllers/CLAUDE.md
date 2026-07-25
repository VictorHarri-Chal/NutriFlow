# Stimulus Controllers — Rules

All Stimulus controllers live in this directory. Every controller must follow the patterns below.

## Lifecycle — connect / disconnect

Every controller that registers global event listeners must bind context in `connect()` and remove the listener in `disconnect()`. Turbo replaces frames without a full page reload — controllers that skip cleanup leak listeners and accumulate them across navigations.

```javascript
connect() {
  this._bound = this._handler.bind(this)
  document.addEventListener("click", this._bound)
}

disconnect() {
  document.removeEventListener("click", this._bound)
}
```

Never add a listener in `connect()` without a matching removal in `disconnect()`.

## Dropdown positioning — always `position: absolute`, never `position: fixed`

All dropdowns (comboboxes, autocompletes, custom selects) must use `position: absolute` within a `position: relative` parent. Never portal the dropdown to `<body>` with `position: fixed` — the dropdown freezes at its viewport coordinates when the page scrolls.

**HTML pattern (mandatory):**

```erb
<div data-controller="my-combobox" class="relative">
  <input ... data-my-combobox-target="input">
  <div class="hidden absolute z-50 w-full mt-1 bg-surface-raised border border-surface-border/60 rounded-lg shadow-2xl max-h-52 overflow-y-auto"
       data-my-combobox-target="dropdown"></div>
</div>
```

**JS pattern:** toggle `hidden` only — never set `style.position`, `style.top`, `style.left`, `style.width`, or `style.zIndex` in JS.

Exception: when the input sits at the bottom of a fixed-height container, compute open direction once via `getBoundingClientRect()` and set `style.top`/`style.bottom` with `calc(100% + 4px)` — still `absolute`, never `fixed`.

## Outside-click pattern

The "close on outside click" pattern is repeated across multiple controllers. Always implement it via a bound listener registered in `connect()` and removed in `disconnect()`:

```javascript
connect() {
  this._outsideBound = this._handleOutside.bind(this)
  document.addEventListener("click", this._outsideBound)
}
disconnect() {
  document.removeEventListener("click", this._outsideBound)
}
_handleOutside(e) {
  if (!this.element.contains(e.target)) this.close()
}
```

Never add a one-off click listener inside an `open()` method — it stacks on every call.

## Exclusive frame controller

When multiple action buttons on the same page can each open a different Turbo Frame form, use `exclusive_frame_controller.js` to ensure only one form is open at a time. Add `data-controller="exclusive-frame"` to the container and `data-action="click->exclusive-frame#clear"` on each trigger link alongside `data-turbo-frame`.

The controller empties all sibling frames (by setting `innerHTML = ""`) except the one being targeted. Clearing `innerHTML` removes the form content but leaves the `<turbo-frame>` element intact so Turbo can load into it.

## Confirmation dialogs

Never use `window.confirm()`. Use `delete_link_with_confirm()` (defined in `ApplicationHelper`) or trigger `confirm_controller.js` via `data-action="click->confirm#show"`.

## Nested forms

Dynamic nested fields use `nested_form_controller.js` with a `<template>` containing `NEW_RECORD` as the child index. Models must declare `accepts_nested_attributes_for …, allow_destroy: true`.

`updateEmptyState()` sets `addButtonTarget.style.display` directly in JS (`"flex"` once the list isn't empty, `"none"` when empty) — an inline style always wins over a CSS class. If you style that button with `text-center`, it will silently do nothing once the list has items, because the button is a flex container by then and `text-align` doesn't affect flex children. Use `justify-center`/`items-center` instead.

## Multi-select toggle pills (checkbox-backed)

For a group of independently toggleable pills — not the navigation "Filter pills" from the root CLAUDE.md, but pills the user can freely combine inside a form (e.g. tagging a workout set as both "Dead set" and "Drop-set") — back each pill with a hidden `<input type="checkbox">` and a sibling `<label for="...">` styled via `peer`/`peer-checked:`.

If more than one such checkbox lives in the same flat sibling list (e.g. 4 checkboxes for 4 types on one row), plain `peer`/`peer-checked:` is not enough: Tailwind compiles `peer-checked:` to a *general* sibling selector, so it matches **any** earlier checked `.peer`, not specifically the one right before it. Checking the first box can visually light up a later, unrelated pill instead of its own. Use **named peers** — `peer/<name>` on the checkbox, `peer-checked/<name>:` on its own label — one name per pill in the group:

```erb
<%= check_box_tag "...", type, checked, class: "hidden peer/#{type}" %>
<%= label_tag id, text, class: "... peer-checked/#{type}:bg-brand/20 ..." %>
```

## Preloaded JSON data

When a controller needs a large dataset (e.g. food list, exercise list), embed it server-side rather than fetching it:

```erb
<script id="foods-data" type="application/json"><%= json_escape(@foods.to_json) %></script>
```

Parse in `connect()`:

```javascript
connect() {
  const el = document.getElementById("foods-data")
  this._foods = el ? JSON.parse(el.textContent) : []
}
```

No extra AJAX call. The `type="application/json"` prevents the browser from executing it.
