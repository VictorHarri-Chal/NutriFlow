# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  skip_before_action :authenticate_user!, only: [:new, :create]
  before_action :configure_account_update_params, only: [:update]

  def destroy
    resource.destroy
    Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
    flash[:notice] = t("devise.registrations.destroyed")
    redirect_to root_path, status: :see_other
  end

  def update
    self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)
    resource_updated = update_resource(resource, account_update_params)
    yield resource if block_given?

    change_type = params[:change_type]

    if resource_updated
      bypass_sign_in resource, scope: resource_name if sign_in_after_change_password?
      notice = change_type == 'email' ? t("controllers.users.registrations.email_updated") : t("controllers.users.registrations.password_updated")
      redirect_to setting_path(tab: 'security'), notice: notice
    else
      clean_up_passwords resource
      set_minimum_password_length
      error_key = change_type == 'email' ? :email_errors : :password_errors
      session[error_key] = resource.errors.to_hash
      redirect_to setting_path(tab: 'security')
    end
  end

  protected

  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [:current_password, :password, :password_confirmation, :email])
  end

  def after_sign_up_path_for(resource)
    calendars_path
  end

  def after_inactive_sign_up_path_for(resource)
    calendars_path
  end

  def sign_in_after_change_password?
    true
  end
end
