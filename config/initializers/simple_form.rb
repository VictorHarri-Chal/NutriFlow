# frozen_string_literal: true

# Uncomment this and change the path if necessary to include your own
# components.
# See https://github.com/heartcombo/simple_form#custom-components to know
# more about custom components.
# Dir[Rails.root.join('lib/components/**/*.rb')].each { |f| require f }
#
# Use this setup block to configure all options available in SimpleForm.
SimpleForm.setup do |config|
  config.wrappers :default, class: 'mb-4' do |b|
    b.use :html5
    b.use :placeholder
    b.use :label, class: 'block text-sm font-medium text-gray-700'
    b.use :input,
          class: 'mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500'
    b.use :error, wrap_with: { tag: :p, class: 'mt-2 text-sm text-red-600' }
  end

  config.wrappers :numeric, class: 'mb-4' do |b|
    b.use :html5
    b.use :placeholder
    b.use :label, class: 'block text-sm font-medium text-gray-700'
    b.use :input,
          class: 'mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500', input_html: { step: :any }
    b.use :error, wrap_with: { tag: :p, class: 'mt-2 text-sm text-red-600' }
  end

  config.default_wrapper = :default
  config.boolean_style = :nested
  config.button_class = 'bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded'
  config.boolean_label_class = 'text-sm font-medium text-gray-700'
  config.label_text = ->(label, required, explicit_label) { "#{label} #{required}" }
  config.generate_additional_classes_for = []
  config.browser_validations = true
end
