require "open-uri"

class Api::V1::AuthController < Api::V1::BaseController
  skip_before_action :authenticate_user!

  # Bundle ID is public information (visible in the App Store), not a secret —
  # a constant is fine. The web Services ID stays in credentials.
  IOS_BUNDLE_ID = "com.leif.Nutriflow".freeze

  # POST /api/v1/auth/apple
  # Body: { identity_token: "eyJ..." }
  def apple
    payload      = verify_apple_token(params[:identity_token])
    uid          = payload["sub"]
    email        = payload["email"]
    user, is_new = find_or_create_from_sso("apple", uid, email)
    token        = generate_jwt_for(user)
    render json: { token: token, user: { id: user.id, email: user.email, locale: user.locale }, is_new_user: is_new }
  rescue JWT::ExpiredSignature
    render json: { error: "Apple token expired" }, status: :unauthorized
  rescue JWT::DecodeError
    render json: { error: "Invalid Apple token" }, status: :unauthorized
  rescue ArgumentError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # POST /api/v1/auth/google
  # Body: { id_token: "eyJ..." }
  def google
    payload      = verify_google_token(params[:id_token])
    uid          = payload["sub"]
    email        = payload["email"]
    user, is_new = find_or_create_from_sso("google", uid, email)
    token        = generate_jwt_for(user)
    render json: { token: token, user: { id: user.id, email: user.email, locale: user.locale }, is_new_user: is_new }
  rescue ArgumentError => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue StandardError
    render json: { error: "Invalid Google token" }, status: :unauthorized
  end

  private

  def find_or_create_from_sso(provider, uid, email)
    identity = Identity.find_or_initialize_by(provider: provider, uid: uid)
    return [identity.user, false] if identity.persisted?

    raise ArgumentError, "Email required for new SSO user" if email.blank?

    user = User.find_or_create_by(email: email) { |u| u.password = Devise.friendly_token }
    identity.update!(user: user, email: email)
    [user, true]
  end

  def generate_jwt_for(user)
    Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first
  end

  def fetch_apple_jwks
    Rails.cache.fetch("apple_jwks", expires_in: 1.hour) do
      JSON.parse(URI.open("https://appleid.apple.com/auth/keys").read)
    end
  end

  def verify_apple_token(token)
    JWT.decode(
      token, nil, true,
      algorithms: %w[RS256],
      jwks:       fetch_apple_jwks,
      aud:        [Rails.application.credentials.dig(:apple, :client_id), IOS_BUNDLE_ID].compact,
      verify_aud: true
    ).first
  end

  def verify_google_token(token)
    response = URI.open("https://oauth2.googleapis.com/tokeninfo?id_token=#{token}").read
    JSON.parse(response)
  end
end
