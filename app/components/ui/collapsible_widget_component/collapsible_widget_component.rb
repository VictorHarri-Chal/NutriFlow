module Ui
  class CollapsibleWidgetComponent < ApplicationComponent
    renders_one :content_body
    renders_one :header_action

    def initialize(title:, storage_key:, force_open: false)
      @title = title; @storage_key = storage_key; @force_open = force_open
    end

    attr_reader :title, :storage_key, :force_open
  end
end
