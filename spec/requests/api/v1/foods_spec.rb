require "rails_helper"

RSpec.describe "Api::V1::Foods", type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers_for(user) }

  describe "GET /api/v1/foods" do
    it "returns foods under the foods root key" do
      create_list(:food, 3, user: user)

      get "/api/v1/foods", headers: headers

      expect(response).to have_http_status(:ok)
      expect(json["foods"]).to be_an(Array)
      expect(json["foods"].length).to eq(3)
      expect(json).not_to have_key("data")
    end

    it "scopes foods to the current user" do
      mine = create(:food, user: user, name: "Mine")
      other_user = create(:user)
      other_food = create(:food, user: other_user, name: "Theirs")

      get "/api/v1/foods", headers: headers

      ids = json["foods"].map { |food| food["id"] }
      expect(ids).to include(mine.id)
      expect(ids).not_to include(other_food.id)

      get "/api/v1/foods/#{other_food.id}", headers: headers

      expect(response).to have_http_status(:not_found)
    end

    it "filters by barcode" do
      create(:food, user: user, name: "With barcode", barcode: "XYZ")
      create(:food, user: user, name: "Without barcode")

      get "/api/v1/foods", params: { barcode: "XYZ" }, headers: headers

      expect(response).to have_http_status(:ok)
      expect(json["foods"].length).to eq(1)
      expect(json["foods"].first["barcode"]).to eq("XYZ")
    end

    it "returns more than 25 foods without silent truncation" do
      create_list(:food, 30, user: user)

      get "/api/v1/foods", headers: headers

      expect(response).to have_http_status(:ok)
      expect(json["foods"].length).to eq(30)
    end
  end

  describe "POST /api/v1/foods" do
    it "creates a food with contract fields and *_tags mapping" do
      post "/api/v1/foods",
           params: {
             name: "Contract Food",
             calories: 100,
             proteins: 10,
             carbs: 10,
             fats: 5,
             barcode: "123456",
             image_url: "https://example.com/img.jpg",
             allergens_tags: ["en:gluten"]
           },
           headers: headers,
           as: :json

      expect(response).to have_http_status(:created)
      expect(json).to be_a(Hash)
      expect(json.keys).to include(
        "id", "name", "favorite", "in_pantry", "barcode", "image_url", "food_label_ids",
        "allergens_tags", "traces_tags", "additives_tags", "labels_tags",
        "micronutrients", "source"
      )
      expect(json["allergens_tags"]).to eq(["en:gluten"])
      expect(json["barcode"]).to eq("123456")
      expect(json["image_url"]).to eq("https://example.com/img.jpg")
    end
  end

  describe "member actions" do
    let!(:food) { create(:food, user: user, favorite: false, in_pantry: true) }

    it "toggles favorite via POST /favorite and returns the full food object" do
      post "/api/v1/foods/#{food.id}/favorite", headers: headers

      expect(response).to have_http_status(:ok)
      expect(json["id"]).to eq(food.id)
      expect(json["favorite"]).to be(true)
    end

    it "toggles pantry via PATCH /toggle_pantry and returns the full food object" do
      patch "/api/v1/foods/#{food.id}/toggle_pantry", headers: headers

      expect(response).to have_http_status(:ok)
      expect(json["id"]).to eq(food.id)
      expect(json["in_pantry"]).to be(false)
    end

    it "deletes the food with 204" do
      delete "/api/v1/foods/#{food.id}", headers: headers

      expect(response).to have_http_status(:no_content)

      get "/api/v1/foods/#{food.id}", headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end
end
