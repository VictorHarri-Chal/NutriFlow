# frozen_string_literal: true

module InputComponent
  def append(_wrapper_options = nil)
    template.content_tag(:span, options[:append], class: "whitespace-nowrap ml-2 text-sm font-semibold text-gray-700 ")
  end
end
