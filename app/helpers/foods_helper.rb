module FoodsHelper
  # Génère un sort_link Ransack en préservant les params de recherche/filtre actifs
  def food_sort_link(attribute, label)
    extra = {}
    extra[:query]    = params[:query]    if params[:query].present?
    extra[:label_id] = params[:label_id] if params[:label_id].present?
    sort_link(@q, attribute, label,
              url: foods_path(extra),
              class: "text-ink-subtle hover:text-ink-muted cursor-pointer")
  end
end
