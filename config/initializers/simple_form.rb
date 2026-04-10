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
    b.use :label, class: 'label-dark'
    b.use :input, class: 'input-dark'
    b.use :error, wrap_with: { tag: :p, class: 'mt-1 text-sm text-status-danger' }
  end

  config.wrappers :numeric, class: 'mb-4' do |b|
    b.use :html5
    b.use :placeholder
    b.use :label, class: 'label-dark'
    b.use :input, class: 'input-dark', input_html: { step: :any }
    b.use :error, wrap_with: { tag: :p, class: 'mt-1 text-sm text-status-danger' }
  end

  config.default_wrapper = :default
  config.boolean_style = :nested
  config.button_class = 'btn-primary'
  config.boolean_label_class = 'text-sm font-medium text-ink-muted'
  config.label_text = ->(label, required, explicit_label) { "#{label} #{required}" }
  config.generate_additional_classes_for = []
  config.browser_validations = true
end
