Sentry.init do |config|
  config.dsn = ENV["SENTRY_DSN"]
  config.enabled_environments = %w[production]
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]
  config.send_default_pii = false
  # Mettre à 0.1 pour activer le performance monitoring (10% des requêtes, compte dans le quota)
  config.traces_sample_rate = 0.0
end
