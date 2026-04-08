class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  include Pagy::Backend

  before_action :authenticate_user!
  before_action :set_locale

  private

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
