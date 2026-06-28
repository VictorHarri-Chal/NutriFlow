class OpenFoodFactsService
  BASE_URL = "https://world.openfoodfacts.org"
  FIELDS   = "product_name,brands,nutriments,nutriscore_grade,nova_group,id,ecoscore_grade,allergens_tags,traces_tags"

  def self.by_barcode(code)
    conn = Faraday.new(url: BASE_URL) do |f|
      f.options.timeout      = 5
      f.options.open_timeout = 3
    end

    response = conn.get("/api/v0/product/#{code}.json", { fields: FIELDS })
    data = JSON.parse(response.body)
    return nil if data["status"] != 1

    normalize(data["product"])
  rescue => e
    Rails.logger.error("OpenFoodFactsService barcode error: #{e.message}")
    nil
  end

  def self.normalize(product)
    return nil if product["product_name"].to_s.strip.empty?

    n = product["nutriments"] || {}
    return nil if n.empty?

    calories = n["energy-kcal_100g"].to_f

    micronutrients = {
      calcium:     n["calcium_100g"]&.to_f,
      iron:        n["iron_100g"]&.to_f,
      magnesium:   n["magnesium_100g"]&.to_f,
      potassium:   n["potassium_100g"]&.to_f,
      sodium:      n["sodium_100g"]&.to_f,
      zinc:        n["zinc_100g"]&.to_f,
      vitamin_c:   n["vitamin-c_100g"]&.to_f,
      vitamin_d:   n["vitamin-d_100g"]&.to_f,
      vitamin_b12: n["vitamin-b12_100g"]&.to_f,
      vitamin_a:   n["vitamin-a_100g"]&.to_f,
      vitamin_b9:  n["vitamin-b9_100g"]&.to_f,
      cholesterol: n["cholesterol_100g"]&.to_f,
      epa:         n["eicosapentaenoic-acid_100g"]&.to_f,
      dha:         n["docosahexaenoic-acid_100g"]&.to_f
    }.compact.reject { |_, v| v == 0.0 }

    {
      off_id:         product["_id"] || product["id"],
      name:           product["product_name"].to_s.strip,
      brand:          product["brands"].to_s.split(",").first.to_s.strip,
      calories:       calories.round(1),
      proteins:       n["proteins_100g"].to_f.round(1),
      carbs:          n["carbohydrates_100g"].to_f.round(1),
      fats:           n["fat_100g"].to_f.round(1),
      sugars:         n["sugars_100g"].to_f.round(1),
      fiber:          n["fiber_100g"]&.to_f&.round(1),
      saturated_fat:  n["saturated-fat_100g"]&.to_f&.round(1),
      salt:           n["salt_100g"]&.to_f&.round(1),
      nutriscore:     product["nutriscore_grade"],
      nova_group:     product["nova_group"]&.to_i,
      ecoscore_grade: product["ecoscore_grade"],
      allergens:      parse_tags(product["allergens_tags"]),
      traces:         parse_tags(product["traces_tags"]),
      micronutrients: micronutrients.presence || {}
    }
  end
  private_class_method :normalize

  def self.parse_tags(tags)
    return [] unless tags.is_a?(Array)
    tags.map { |t| t.to_s.sub(/^[a-z]{2}:/, "") }.reject(&:blank?)
  end
  private_class_method :parse_tags
end
