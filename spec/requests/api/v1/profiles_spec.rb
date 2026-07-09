require "rails_helper"

RSpec.describe "Api::V1::Profile", type: :request do
  describe "GET /api/v1/profile" do
    it "returns 401 without authentication" do
      get "/api/v1/profile", headers: json_headers

      expect(response).to have_http_status(:unauthorized)
      expect(json).to include("error")
    end

    context "with a complete profile" do
      let(:user) { create(:user) }
      let!(:profile) do
        create(:profile,
               owner: user,
               age: 30,
               weight: 80.0,
               height: 180.0,
               goal: "weight_loss",
               job_activity_level: "light_activity")
      end

      it "returns the iOS contract shape" do
        get "/api/v1/profile", headers: auth_headers_for(user)

        expect(response).to have_http_status(:ok)
        expect(json.keys).to include(
          "name", "age", "weight", "height", "goal_weight", "gender", "goal",
          "job_activity_level", "default_daily_steps", "water_goal_ml"
        )
        expect(json["expenditure"].keys).to match_array(
          %w[bmr job_neat steps_kcal steps_count workout_kcal tdee goal_delta]
        )
        expect(json["goals"].keys).to match_array(%w[calories proteins fats carbs])
        expect(json["weight"]).to be_a(Numeric)
        expect(json["weight"]).not_to be_a(String)
        expect(json["goals"]["proteins"]).to be_a(Numeric)
        expect(json["goals"]["proteins"]).not_to be_a(String)
      end

      it "returns post-Phase-2 enum strings" do
        create(:profile,
               owner: create(:user),
               age: 30,
               weight: 80.0,
               height: 180.0,
               goal: "maintain",
               job_activity_level: "sedentary")

        get "/api/v1/profile", headers: auth_headers_for(Profile.last.user)

        expect(response).to have_http_status(:ok)
        expect(json["goal"]).to eq("maintain")
        expect(json["job_activity_level"]).to eq("sedentary")
      end
    end
  end

  describe "PATCH /api/v1/profile" do
    let(:user) { create(:user) }

    before do
      create(:profile, owner: user, age: 30, weight: 80.0, height: 180.0)
    end

    it "updates and returns the profile" do
      patch "/api/v1/profile",
            params: { weight: 78.5 },
            headers: auth_headers_for(user),
            as: :json

      expect(response).to have_http_status(:ok)
      expect(json["weight"].to_f).to eq(78.5)
    end
  end
end
