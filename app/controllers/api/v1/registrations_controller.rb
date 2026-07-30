class Api::V1::RegistrationsController < Devise::RegistrationsController
  respond_to :json

  def create
    build_resource(sign_up_params)
    resource.save
    if resource.persisted?
      if resource.active_for_authentication?
        sign_up(resource_name, resource)
        token = request.env["warden-jwt_auth.token"]
        render json: {
          token: token,
          user:  { id: resource.id, email: resource.email, locale: resource.locale }
        }, status: :created
      else
        # Mirrors the website's Devise::RegistrationsController#create: an unconfirmed
        # user is persisted but not signed in, so no JWT is issued here either — the
        # same account must confirm by email before it can authenticate on any client,
        # keeping web and iOS sign-up behavior consistent.
        render json: {
          confirmation_required: true,
          user: { id: resource.id, email: resource.email }
        }, status: :created
      end
    else
      render json: { errors: resource.errors }, status: :unprocessable_entity
    end
  end

  private

  def sign_up_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end
end
