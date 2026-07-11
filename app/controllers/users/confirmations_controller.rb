# frozen_string_literal: true

class Users::ConfirmationsController < Devise::ConfirmationsController
  protected

  def after_resending_confirmation_instructions_path_for(resource_name)
    return setting_path(tab: 'security') if signed_in?(resource_name)

    super
  end
end
