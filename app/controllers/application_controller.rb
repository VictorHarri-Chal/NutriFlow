class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  include Pagy::Backend

  before_action :authenticate_user!
  around_action :set_time_zone
  before_action :set_locale
  before_action :set_sentry_context
  before_action :require_onboarding_complete!
  before_action :set_active_storage_url_options

  private

  # Required for Active Storage direct URL generation (.variant(...).processed.url,
  # .url) outside the built-in redirect controller — without it, the Disk service
  # raises ArgumentError in development/test. Production (Cloudflare R2) doesn't
  # need this since CloudflareR2Service builds URLs from a fixed CDN host instead.
  def set_active_storage_url_options
    ActiveStorage::Current.url_options = { host: request.host, port: request.port, protocol: request.protocol }
  end

  def set_time_zone(&block)
    if user_signed_in?
      Time.use_zone(current_user.time_zone, &block)
    else
      block.call
    end
  end

  def require_onboarding_complete!
    return unless user_signed_in?
    return if devise_controller?
    return if controller_path == "onboarding"
    return if current_user.profile.onboarding_complete?

    redirect_to edit_onboarding_path
  end

  def set_sentry_context
    return unless current_user
    Sentry.set_user(id: current_user.id, email: current_user.email)
  end

  def set_locale
    I18n.locale = if user_signed_in? && I18n.available_locales.include?(current_user.locale.to_sym)
      current_user.locale.to_sym
    else
      browser_locale
    end
  end

  def browser_locale
    accepted = request.env["HTTP_ACCEPT_LANGUAGE"].to_s
                       .scan(/[a-z]{2}(?=-|,|;|$)/i)
                       .map { |l| l.downcase.to_sym }
    accepted.find { |l| I18n.available_locales.include?(l) } || I18n.default_locale
  end

  def after_sign_in_path_for(resource)
    calendars_path
  end

  def pagy(collection, vars = {})
    return super(collection, vars) unless params[:full_result] == "true"

    items_limit = collection.count(:all)
    items_limit = items_limit.size if items_limit.is_a?(Hash)
    super(collection, vars.merge({ items: items_limit, count: items_limit }))
  end
end
