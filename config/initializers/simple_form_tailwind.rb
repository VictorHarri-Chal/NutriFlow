# frozen_string_literal: true

Dir[Rails.root.join('lib/components/**/*.rb')].each { |f| require f }
SimpleForm.include_component(InputComponent)

LABEL_CLASSES = 'label-dark'
INPUT_CLASSES = 'input-dark'

BUTTON_CLASSES = 'btn-primary cursor-pointer'

SimpleForm.setup do |config| # rubocop:disable Metrics/BlockLength
  # No `b.use :error` here — the app shows one aggregate error box per form
  # (see app/views/shared/_form_errors.html.erb) instead of a per-field message,
  # so a field's own inline error text would just duplicate that box. The
  # `error_class:` options below are kept: they still drive the red
  # border/label highlighting on the invalid field itself.
  config.wrappers :default, class: 'min-h-fit' do |b|
    b.use :html5
    b.use :placeholder
    b.use :label, class: LABEL_CLASSES, error_class: 'text-status-danger'
    b.wrapper tag: "div", class: "flex items-center" do |ba|
      ba.use :input, class: INPUT_CLASSES,
                    error_class: 'border-status-danger focus:ring-status-danger/50 focus:border-status-danger'
      ba.optional :append
    end
  end

  # Same as :default, but keeps the inline per-field error message — for the
  # compact turbo-frame row forms (e.g. editing a food label or meal group
  # in place) that have no room for a top-level aggregate error box.
  config.wrappers :default_with_inline_error, class: 'min-h-fit' do |b|
    b.use :html5
    b.use :placeholder
    b.use :label, class: LABEL_CLASSES, error_class: 'text-status-danger'
    b.wrapper tag: "div", class: "flex items-center" do |ba|
      ba.use :input, class: INPUT_CLASSES,
                    error_class: 'border-status-danger focus:ring-status-danger/50 focus:border-status-danger'
      ba.optional :append
    end
    b.use :error, wrap_with: { tag: :p, class: 'mt-1 text-sm text-status-danger' }
  end

  config.wrappers :boolean, class: 'flex items-center' do |b|
    b.use :html5
    b.use :input, class: 'h-4 w-4 text-brand focus:ring-brand/50 border-surface-border rounded bg-surface-hover'

    b.use :label, class: 'ml-2 block text-sm text-ink-muted',
                  error_class: 'underline decoration-status-danger decoration-2 underline-offset-4 decoration-dashed'
  end

  config.wrappers :radio_buttons, item_wrapper_class: 'flex items-center',
                                  item_label_class: 'ml-3 block text-sm font-medium text-ink-muted',
                                  tag: 'fieldset',
                                  class: '' do |b|
    b.use :html5
    b.wrapper :legend_tag, tag: 'legend', class: LABEL_CLASSES do |ba|
      ba.use :label_text
    end
    b.wrapper :radios, class: 'space-y-4' do |ba|
      ba.use :input, class: 'h-4 w-4 border-surface-border text-brand focus:ring-brand/50 bg-surface-hover', error_class: ''
    end
  end

  config.wrappers :inline_radio_buttons, item_wrapper_class: 'flex items-center',
                                         item_label_class: 'ml-3 block text-sm font-medium text-ink-muted',
                                         class: 'flex items-center space-x-4' do |b|
    b.use :html5
    b.wrapper :legend_tag, class: "#{LABEL_CLASSES} mb-0" do |ba|
      ba.use :label_text
    end
    b.wrapper :radios, class: 'flex space-x-4' do |ba|
      ba.use :input, class: 'h-4 w-4 border-surface-border text-brand focus:ring-brand/50 bg-surface-hover', error_class: ''
    end
  end
end

SimpleForm.setup do |config|
  config.default_wrapper = :default
  config.wrapper_mappings = {
    boolean: :boolean,
    radio_buttons: :radio_buttons
  }

  # Default configuration
  config.generate_additional_classes_for = []
  config.default_form_class = 'space-y-6'
  config.button_class = BUTTON_CLASSES
  config.label_text = ->(label, _required, _explicit_label) { label }

  config.error_notification_tag = :div
  config.error_notification_class = 'error_notification'
  config.error_method = :to_sentence

  config.browser_validations = false
  config.boolean_style = :inline
end
