module Ui
  class ModalComponent < ApplicationComponent
    renders_one :body
    renders_one :footer
    renders_one :title_accessory

    MAX_WIDTH   = { sm: "max-w-sm", md: "max-w-md", lg: "max-w-lg", xl: "max-w-xl" }.freeze
    MAX_HEIGHT  = { sm: "max-h-[80vh]", md: "max-h-[85vh]", lg: "max-h-[90vh]" }.freeze
    # :block scrolls the body itself; :flex makes the body a bounded, non-scrolling
    # flex-column so the caller can host its own internal scroll region (with a
    # sticky footer / pinned fade cue) via an unbroken flex chain from the panel.
    BODY_LAYOUT = { block: "overflow-y-auto min-h-0 flex-1", flex: "min-h-0 flex-1 flex flex-col" }.freeze

    def initialize(title:, subtitle: nil, icon: nil, max_width: :md, max_height: :sm, body_padding: "px-5 py-4", body_layout: :block, data: {})
      @title = title
      @subtitle = subtitle
      @icon = icon
      @max_width = MAX_WIDTH.fetch(max_width)
      @max_height = MAX_HEIGHT.fetch(max_height)
      @body_padding = body_padding
      @body_layout = BODY_LAYOUT.fetch(body_layout)
      @data = data
    end

    attr_reader :title, :subtitle, :icon, :max_width, :max_height, :body_padding, :body_layout

    # Merges the caller's data hash onto the root overlay while guaranteeing the
    # modal's own Stimulus wiring: the `modal` controller and its backdrop/escape
    # actions always come first, then whatever the caller passed (extra
    # controllers, actions, and arbitrary data-* values) is preserved untouched.
    def root_data
      merged = @data.dup
      merged[:controller] = token_list("modal", merged[:controller])
      merged[:action] = token_list(
        "click->modal#handleBackdropClick keydown@document->modal#handleEscape",
        merged[:action]
      )
      merged
    end
  end
end
