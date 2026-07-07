require "rails_helper"

RSpec.describe "Api::V1::Sessions", type: :request do
  describe "POST /api/v1/sessions" do
    let(:user) { create(:user, email: "signin@example.com", password: "password123") }

    it "returns a JWT token for valid nested credentials" do
      post "/api/v1/sessions",
           params: { user: { email: user.email, password: "password123" } },
           headers: json_headers,
           as: :json

      expect(response).to have_http_status(:ok)
      expect(json["token"]).to be_a(String)
      expect(json["token"]).not_to be_empty
    end

    it "returns 401 with an error for invalid credentials" do
      post "/api/v1/sessions",
           params: { user: { email: user.email, password: "wrong-password" } },
           headers: json_headers,
           as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(json).to include("error")
    end
  end

  describe "DELETE /api/v1/sessions" do
    let(:user) { create(:user) }
    let(:headers) { auth_headers_for(user) }

    it "returns 204 with an empty body and revokes the token" do
      delete "/api/v1/sessions", headers: headers

      expect(response).to have_http_status(:no_content)
      expect(response.body).to be_blank

      get "/api/v1/profile", headers: headers

      expect(response).to have_http_status(:unauthorized)
      expect(json).to include("error")
    end
  end
end
