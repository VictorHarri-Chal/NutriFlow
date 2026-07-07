class Api::V1::PasswordsController < Api::V1::BaseController
  # POST /api/v1/passwords — public, forgot password
  skip_before_action :authenticate_user!, only: [:create]

  def create
    User.send_reset_password_instructions(email: params[:email])
    render json: { message: "Email envoyé si le compte existe." }
  end

  # PATCH /api/v1/password
  def update
    if current_user.update_with_password(password_params)
      render json: { message: "Mot de passe mis à jour." }
    else
      render json: { errors: current_user.errors }, status: :unprocessable_entity
    end
  end

  private

  def password_params
    params.permit(:current_password, :password, :password_confirmation)
  end
end
