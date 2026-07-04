require "open-uri"

class Api::V1::AuthController < Api::V1::BaseController
  skip_before_action :authenticate_user!

  # POST /api/v1/auth/apple
  # Body: { identity_token: "eyJ..." }
  def apple
    payload = verify_apple_token(params[:identity_token])
    uid     = payload["sub"]
    email   = payload["email"]
    user    = find_or_create_from_sso("apple", uid, email)
    token   = generate_jwt_for(user)
    render json: { token: token, user: { id: user.id, email: user.email, locale: user.locale } }
  rescue StandardError
    render json: { error: "Invalid Apple token" }, status: :unauthorized
  end

  # POST /api/v1/auth/google
  # Body: { id_token: "eyJ..." }
  def google
    payload = verify_google_token(params[:id_token])
    uid     = payload["sub"]
    email   = payload["email"]
    user    = find_or_create_from_sso("google", uid, email)
    token   = generate_jwt_for(user)
    render json: { token: token, user: { id: user.id, email: user.email, locale: user.locale } }
  rescue StandardError
    render json: { error: "Invalid Google token" }, status: :unauthorized
  end

  private

  def find_or_create_from_sso(provider, uid, email)
    identity = Identity.find_or_initialize_by(provider: provider, uid: uid)
    if identity.persisted?
      identity.user
    else
      user = User.find_or_create_by(email: email) { |u| u.password = Devise.friendly_token }
      identity.update!(user: user, email: email)
      user
    end
  end

  def generate_jwt_for(user)
    Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first
  end

  def verify_apple_token(token)
    jwks_raw  = URI.open("https://appleid.apple.com/auth/keys").read
    jwks_hash = JSON.parse(jwks_raw)
    JWT.decode(token, nil, true, algorithms: ["RS256"], jwks: jwks_hash).first
  end

  def verify_google_token(token)
    response = URI.open("https://oauth2.googleapis.com/tokeninfo?id_token=#{token}").read
    JSON.parse(response)
  end
end
