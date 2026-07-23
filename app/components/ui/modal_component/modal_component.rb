module Ui
  class ModalComponent < ApplicationComponent
    renders_one :body
    renders_one :footer

    MAX_WIDTH  = { sm: "max-w-sm", md: "max-w-md", lg: "max-w-lg", xl: "max-w-xl" }.freeze
    MAX_HEIGHT = { sm: "max-h-[80vh]", md: "max-h-[85vh]", lg: "max-h-[90vh]" }.freeze

    def initialize(title:, max_width: :md, max_height: :sm)
      @title = title
      @max_width = MAX_WIDTH.fetch(max_width)
      @max_height = MAX_HEIGHT.fetch(max_height)
    end

    attr_reader :title, :max_width, :max_height
  end
end
