Rack::Attack.cache.store = Rails.cache

# All traffic goes through Cloudflare — real visitor IP is in HTTP_CF_CONNECTING_IP,
# not REMOTE_ADDR (which would be a Cloudflare edge node).
module Rack
  class Attack
    class Request < ::Rack::Request
      def real_ip
        env["HTTP_CF_CONNECTING_IP"] || ip
      end
    end
  end
end

# --- Login ---

Rack::Attack.throttle("logins/ip", limit: 5, period: 20.seconds) do |req|
  req.real_ip if req.path == "/users/sign_in" && req.post?
end

Rack::Attack.throttle("logins/email", limit: 10, period: 1.hour) do |req|
  if req.path == "/users/sign_in" && req.post?
    req.params.dig("user", "email")&.downcase&.strip
  end
end

# --- Password reset ---

Rack::Attack.throttle("passwords/ip", limit: 5, period: 1.hour) do |req|
  req.real_ip if req.path == "/users/password" && req.post?
end

Rack::Attack.throttle("passwords/email", limit: 3, period: 1.hour) do |req|
  if req.path == "/users/password" && req.post?
    req.params.dig("user", "email")&.downcase&.strip
  end
end

# --- Registration ---

Rack::Attack.throttle("registrations/ip", limit: 5, period: 1.day) do |req|
  req.real_ip if req.path == "/users" && req.post?
end

# --- Response ---

Rack::Attack.throttled_responder = lambda do |_req|
  [429, { "Content-Type" => "text/plain" }, ["Trop de tentatives. Réessayez dans quelques minutes."]]
end

# --- Logging ---

ActiveSupport::Notifications.subscribe("throttle.rack_attack") do |*, payload|
  req = payload[:request]
  Rails.logger.warn "[Rack::Attack] #{payload[:match_type]}: #{payload[:match_discriminator]} (#{req.real_ip})"
end
