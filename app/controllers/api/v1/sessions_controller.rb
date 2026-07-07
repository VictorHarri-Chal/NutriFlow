class Api::V1::SessionsController < Devise::SessionsController
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
    render json: { message: "Signed out." }
  end

  private

  def respond_to_on_destroy
    render json: { message: "Signed out." }
  end
end
