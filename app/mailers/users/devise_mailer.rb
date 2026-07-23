class Users::DeviseMailer < Devise::Mailer
  def new_device_sign_in(record, ip, opts = {})
    @ip = ip
    devise_mail(record, :new_device_sign_in, opts)
  end

  private

  def initialize_from_record(record)
    super
    I18n.locale = @resource&.locale&.to_sym || I18n.default_locale
  end
end
