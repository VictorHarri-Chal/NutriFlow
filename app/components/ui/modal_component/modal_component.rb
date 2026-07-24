module Ui
  class ModalComponent < ApplicationComponent
    renders_one :body
    renders_one :footer

    MAX_WIDTH  = { sm: "max-w-sm", md: "max-w-md", lg: "max-w-lg", xl: "max-w-xl" }.freeze
    MAX_HEIGHT = { sm: "max-h-[80vh]", md: "max-h-[85vh]", lg: "max-h-[90vh]" }.freeze

    def initialize(title:, icon: nil, max_width: :md, max_height: :sm, body_padding: "px-5 py-4", data: {})
      @title = title
      @icon = icon
      @max_width = MAX_WIDTH.fetch(max_width)
      @max_height = MAX_HEIGHT.fetch(max_height)
      @body_padding = body_padding
      @data = data
    end

    attr_reader :title, :icon, :max_width, :max_height, :body_padding

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
