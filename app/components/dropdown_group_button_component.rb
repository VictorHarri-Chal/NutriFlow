# frozen_string_literal: true

class DropdownGroupButtonComponent < ApplicationComponent
  renders_many :buttons, 'DropdownGroupButtonComponent::SubButtonComponent'

  # @param primary [Boolean] if true, the main button will be in primary color
  # @param align [Symbol] :right, :left - alignment of the menu relatively to the main button
  # @param dropdown [Boolean] if true, the main button toggles the menu instead of triggering first action
  def initialize(primary: false, align: :right, dropdown: false)
    super()
    @primary = primary
    @align = align
    @dropdown = dropdown
  end

  def first_button_tag
    first_button = buttons.first
    content = first_button.build_content

    if @dropdown
      return helpers.button_tag(class: first_button_classes(first_button.classes),
                                type: 'button',
                                data: { action: 'click->dropdown-group-button#openButtonList' }) { content }
    end

    case first_button.type
    when :link
      helpers.link_to(first_button.path,
                      class: first_button_classes(first_button.classes),
                      data: first_button.data) { content }
    when :button
      helpers.button_tag(class: first_button_classes(first_button.classes),
                         type: 'button',
                         data: first_button.data) { content }
    when :button_to
      helpers.button_to(first_button.path, method: first_button.method,
                        class: first_button_classes(first_button.classes),
                        data: first_button.data) { content }
    end
  end

  private

  def option_menu_button_id
    helpers.nested_dom_id(:option_menu_button, hash)
  end

  def right?
    @align == :right
  end

  def first_button_classes(additionnal_classes = nil)
    if @primary
      "#{'rounded-r-none' if buttons.size > 1} btn btn-primary #{additionnal_classes} border-0"
    else
      <<~TXT
        relative inline-flex items-center
        #{buttons.size > 1 ? 'rounded-l-md' : 'rounded-md'} bg-white
        px-3 py-2
        text-sm font-semibold text-gray-900
        ring-1 ring-inset ring-gray-300
        hover:bg-gray-50
        #{additionnal_classes}
      TXT
    end
  end

  def chevron_button_classes
    if @primary
      <<~TXT
        relative text-center items-center
        rounded-l-none btn btn-primary p-2 h-full
        border-0 border-l border-white
        focus:ring-0 focus:border-0
      TXT
    else
      <<~TXT
        relative text-center items-center
        rounded-r-md bg-white p-2 text-gray-400
        ring-1 ring-inset ring-gray-300
        hover:bg-gray-50
      TXT
    end
  end

  class SubButtonComponent < ApplicationComponent
    attr_reader :type, :path, :method, :text, :classes, :data, :custom_content

    # @param type [Symbol] :link, :button, :button_to
    # @param path [String] optional path for link/button_to
    # @param method [Symbol] optional HTTP verb for button_to
    # @param text [String]
    # @param classes [String]
    # @param data [Hash]
    def initialize(type:, text: nil, path: nil, method: nil, classes: nil, data: {}, custom_content: nil)
      super()
      @type = type.to_sym
      @path = path
      @method = method
      @text = text
      @classes = classes
      @data = data || {}
      @custom_content = custom_content
    end

    # Used by the main button to build content
    def build_content
      text
    end
  end
end
