# frozen_string_literal: true

class SettingsController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
    @minimum_password_length = User.password_length.min
  end

  private
end
