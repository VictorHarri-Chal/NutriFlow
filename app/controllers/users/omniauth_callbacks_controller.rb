class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def apple
    handle_auth("Apple")
  end

  def google_oauth2
    handle_auth("Google")
  end

  private

  def handle_auth(provider_name)
    auth     = request.env["omniauth.auth"]
    identity = Identity.find_or_initialize_by(provider: auth.provider, uid: auth.uid)

    if identity.persisted?
      @user = identity.user
    else
      @user = User.find_or_create_by(email: auth.info.email) do |u|
        u.password = Devise.friendly_token
      end
      identity.update!(user: @user, email: auth.info.email)
    end

    sign_in_and_redirect @user, event: :authentication
  end
end
