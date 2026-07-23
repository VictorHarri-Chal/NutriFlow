module IconsHelper
  # Single source of truth for icon glyphs per semantic action (Font Awesome 6).
  ICONS = {
    close:        "fa-times",
    edit:         "fa-pen",
    delete:       "fa-trash",
    add:          "fa-plus",
    check:        "fa-check",
    success:      "fa-circle-check",
    favorite:     "fa-star",
    chevron_down: "fa-chevron-down"
  }.freeze

  # Renders a Font Awesome <i>. `action` is a key of ICONS. `css` appends size/color classes.
  def ui_icon(action, style: "fas", css: "")
    glyph = ICONS.fetch(action)
    tag.i(class: [style, glyph, css].reject(&:blank?).join(" "))
  end
end
