module AuthHelpers
  def json_headers
    {
      "Accept" => "application/json",
      "User-Agent" => "Mozilla/5.0 (compatible; RSpec)"
    }
  end

  # Devise-JWT: encode a real token the API middleware will accept
  def auth_headers_for(user)
    token, _payload = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)
    json_headers.merge("Authorization" => "Bearer #{token}")
  end

  def json
    JSON.parse(response.body)
  end
end
