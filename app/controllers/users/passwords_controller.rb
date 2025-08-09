# frozen_string_literal: true

class Users::PasswordsController < Devise::PasswordsController
  # POST /resource/password
  def create
    self.resource = resource_class.send_reset_password_instructions(resource_params)
    yield resource if block_given?

    if successfully_sent?(resource)
      redirect_to setting_path, notice: 'Un email de réinitialisation de mot de passe a été envoyé à votre adresse email.'
    else
      redirect_to setting_path, alert: 'Une erreur est survenue lors de l\'envoi de l\'email de réinitialisation.'
    end
  end

  # GET /resource/password/edit?reset_password_token=abcdef
  def edit
    super
  end

  # PUT /resource/password
  def update
    super
  end

  protected

  def after_resetting_password_path_for(resource)
    calendars_path
  end

  # The path used after sending reset password instructions
  def after_sending_reset_password_instructions_path_for(resource_name)
    setting_path
  end
end
