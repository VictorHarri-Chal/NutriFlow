class OpenFoodFactsService
  BASE_URL = "https://world.openfoodfacts.org"
  FIELDS   = "product_name,brands,nutriments,nutriscore_grade,nova_group,image_thumb_url,id"

  def self.search(query, page_size: 60)
    conn = Faraday.new(url: BASE_URL) do |f|
      f.options.timeout      = 5
      f.options.open_timeout = 3
    end

    response = conn.get("/cgi/search.pl", {
      search_terms:     query,
      search_simple:    1,
      action:           "process",
      json:             1,
      page_size:        page_size,
      fields:           FIELDS,
      lc:               "fr",
      sort_by:          "unique_scans_n",
      countries_tags_en: "france"
    })

    products = JSON.parse(response.body)["products"] || []
    normalized = products.filter_map { |p| normalize(p) }
    sort_by_relevance(normalized, query).first(20)
  rescue => e
    Rails.logger.error("OpenFoodFactsService error: #{e.message}")
    []
  end

  # Prioritise les produits dont le nom contient les termes de la recherche.
  # Les autres (match sur ingrédients, codes-barres, etc.) restent mais passent en dernier.
  def self.sort_by_relevance(products, query)
    # Normalise les pluriels simples (chien/chiens, suisse/suisses) pour aligner
    # les requêtes utilisateur avec les noms de produits OFF qui peuvent différer en nombre.
    terms = query.downcase.split(/\s+/).map { |t| t.sub(/s+\z/, "") }.reject { |t| t.length < 3 }
    return products if terms.empty?

    products
      .select { |p|
        text = "#{p[:name]} #{p[:brand]}".downcase
        terms.all? { |t| text.include?(t) }
      }
      .sort_by { |p| -terms.count { |t| p[:name].downcase.include?(t) } }
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
      nova_group: product["nova_group"]&.to_i,
      image_url:  product["image_thumb_url"]
    }
  end
  private_class_method :normalize, :sort_by_relevance
end
