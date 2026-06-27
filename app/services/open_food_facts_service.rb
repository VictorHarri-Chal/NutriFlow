class OpenFoodFactsService
  BASE_URL = "https://world.openfoodfacts.org"
  FIELDS   = "product_name,brands,nutriments,nutriscore_grade,nova_group,id"

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

    {
      off_id:     product["_id"] || product["id"],
      name:       product["product_name"].to_s.strip,
      brand:      product["brands"].to_s.split(",").first.to_s.strip,
      calories:   calories.round(1),
      proteins:   n["proteins_100g"].to_f.round(1),
      carbs:      n["carbohydrates_100g"].to_f.round(1),
      fats:       n["fat_100g"].to_f.round(1),
      sugars:     n["sugars_100g"].to_f.round(1),
      nutriscore: product["nutriscore_grade"],
      nova_group: product["nova_group"]&.to_i
    }
  end
  private_class_method :normalize
end
