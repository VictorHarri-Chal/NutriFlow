class Api::V1::RegistrationsController < Devise::RegistrationsController
  respond_to :json

  def create
    build_resource(sign_up_params)
    resource.save
    if resource.persisted?
      sign_up(resource_name, resource)
      token = request.env["warden-jwt_auth.token"]
      render json: {
        token: token,
        user:  { id: resource.id, email: resource.email, locale: resource.locale }
      }, status: :created
    else
      render json: { errors: resource.errors }, status: :unprocessable_entity
    end
  end

  private

  def sign_up_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end
end
