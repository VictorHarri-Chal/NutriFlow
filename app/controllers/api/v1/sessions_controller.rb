class Api::V1::SessionsController < Devise::SessionsController
  protect_from_forgery with: :null_session
  skip_before_action :verify_authenticity_token, raise: false
  skip_before_action :authenticate_user!, only: [:create]
  respond_to :json

  def create
    self.resource = warden.authenticate!(auth_options)
    sign_in(resource_name, resource)
    token = request.env["warden-jwt_auth.token"]
    render json: {
      token: token,
      user:  { id: resource.id, email: resource.email, locale: resource.locale }
    }
  end

  def destroy
    sign_out(resource_name)
    head :no_content
  end

  private

  def respond_to_on_destroy
    head :no_content
  end
end
