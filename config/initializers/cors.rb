Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins Rails.env.production? ? ["https://nutriflow.in", "https://www.nutriflow.in"] : "*"
    resource "/api/*",
      headers: :any,
      methods: [:get, :post, :patch, :put, :delete, :options, :head],
      expose:  ["Authorization"]
  end
end
