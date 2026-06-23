class Users::DeviseMailer < Devise::Mailer
  private

  def initialize_from_record(record)
    super
    I18n.locale = @resource&.locale&.to_sym || I18n.default_locale
  end
end
