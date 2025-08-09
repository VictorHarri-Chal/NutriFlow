# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  before_action :authenticate_user!
  before_action :configure_account_update_params, only: [:update]

  # PUT /resource
  def update
    self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)
    prev_unconfirmed_email = resource.unconfirmed_email if resource.respond_to?(:unconfirmed_email)

    resource_updated = update_resource(resource, account_update_params)
    yield resource if block_given?
    if resource_updated
      set_flash_message_for_update(resource, prev_unconfirmed_email)
      bypass_sign_in resource, scope: resource_name if sign_in_after_change_password?

      # Redirection personnalisée vers la page des paramètres
      redirect_to setting_path, notice: 'Votre mot de passe a été mis à jour avec succès.'
    else
      clean_up_passwords resource
      set_minimum_password_length

      # Sauvegarder les erreurs en session pour les afficher
      session[:user_errors] = resource.errors.to_hash

      # Redirection vers la page des paramètres même en cas d'erreur pour afficher les erreurs
      redirect_to setting_path
    end
  end

  protected

  # If you have extra params to permit, append them to the sanitizer.
  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [:current_password, :password, :password_confirmation])
  end

  # The path used after sign up.
  def after_sign_up_path_for(resource)
    calendars_path
  end

  # The path used after sign up for inactive accounts.
  def after_inactive_sign_up_path_for(resource)
    calendars_path
  end

  def sign_in_after_change_password?
    true
  end
end
