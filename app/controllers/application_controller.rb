class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  include Pagy::Backend

  before_action :authenticate_user!

  private

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
