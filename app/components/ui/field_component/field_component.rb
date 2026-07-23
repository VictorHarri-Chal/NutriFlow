module Ui
  class FieldComponent < ApplicationComponent
    def initialize(name:, label:, type: :text, value: nil, hint: nil, errors: [], **input_options)
      @name = name; @label = label; @type = type; @value = value
      @hint = hint; @errors = errors; @input_options = input_options
    end

    attr_reader :name, :label, :type, :value, :hint, :errors, :input_options
  end
end
