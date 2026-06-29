class OpenFoodFactsService
  BASE_URL = "https://world.openfoodfacts.org"

  # Macros obligatoires (toujours présents, .to_f garanti)
  REQUIRED_NUTRIMENTS = {
    calories:     "energy-kcal_100g",
    proteins:     "proteins_100g",
    carbs:        "carbohydrates_100g",
    fats:         "fat_100g",
    sugars:       "sugars_100g"
  }.freeze

  # Macros optionnels (peuvent être nil)
  OPTIONAL_NUTRIMENTS = {
    fiber:        "fiber_100g",
    saturated_fat: "saturated-fat_100g",
    salt:         "salt_100g"
  }.freeze

  # Micronutriments (stockés en JSONB, zéros exclus)
  MICRONUTRIENTS = {
    calcium:     "calcium_100g",
    iron:        "iron_100g",
    magnesium:   "magnesium_100g",
    potassium:   "potassium_100g",
    sodium:      "sodium_100g",
    zinc:        "zinc_100g",
    cholesterol: "cholesterol_100g",
    vitamin_c:   "vitamin-c_100g",
    vitamin_d:   "vitamin-d_100g",
    vitamin_b12: "vitamin-b12_100g",
    vitamin_a:   "vitamin-a_100g",
    vitamin_b9:  "vitamin-b9_100g",
    epa:         "eicosapentaenoic-acid_100g",
    dha:         "docosahexaenoic-acid_100g"
  }.freeze

  VALID_NS_GRADES  = %w[a b c d e].freeze
  VALID_ECO_GRADES = %w[a-plus a b c d e f].freeze

  # Champs tableau OFF (pattern: "{field}_tags" → colonne foods.{field})
  TAG_FIELDS = %i[allergens traces additives labels].freeze

  FIELDS = [
    "product_name", "brands", "nutriments",
    "nutriscore_grade", "nova_group", "id", "ecoscore_grade",
    "ingredients_text",
    *TAG_FIELDS.map { |f| "#{f}_tags" }
  ].join(",").freeze

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

    required = REQUIRED_NUTRIMENTS.transform_values { |k| n[k].to_f.round(1) }
    optional = OPTIONAL_NUTRIMENTS.transform_values { |k| n[k]&.to_f&.round(1) }

    micronutrients = MICRONUTRIENTS
      .transform_values { |k| n[k]&.to_f }
      .compact
      .reject { |_, v| v == 0.0 }

    tags = TAG_FIELDS.each_with_object({}) { |f, h| h[f] = parse_tags(product["#{f}_tags"]) }

    {
      off_id:           product["_id"] || product["id"],
      name:             product["product_name"].to_s.strip,
      brand:            product["brands"].to_s.split(",").first.to_s.strip.presence,
      nutriscore:       VALID_NS_GRADES.include?(product["nutriscore_grade"]&.downcase) ? product["nutriscore_grade"].downcase : nil,
      nova_group:       (1..4).include?(product["nova_group"]&.to_i) ? product["nova_group"].to_i : nil,
      ecoscore_grade:   VALID_ECO_GRADES.include?(product["ecoscore_grade"]&.downcase) ? product["ecoscore_grade"].downcase : nil,
      ingredients_text: product["ingredients_text"].to_s.strip.presence,
      micronutrients:   micronutrients.presence || {},
      **required,
      **optional,
      **tags
    }
  end
  private_class_method :normalize

  def self.parse_tags(tags)
    return [] unless tags.is_a?(Array)
    tags.map { |t| t.to_s.sub(/^[a-z]{2}:/, "") }.reject(&:blank?)
  end
  private_class_method :parse_tags
end
