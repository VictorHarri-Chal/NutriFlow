module FoodsHelper
  def food_sort_link(attribute, label, default_order: :desc)
    current_attr, current_dir = params.dig(:q, :s).to_s.split(" ")
    is_active = current_attr == attribute.to_s && params[:sort_usages].blank?

    if is_active
      next_dir   = current_dir == "desc" ? "asc" : "desc"
      icon       = current_dir == "desc" ? "fa-sort-down" : "fa-sort-up"
      link_class = "inline-flex items-center gap-1.5 text-brand transition-colors cursor-pointer whitespace-nowrap"
      icon_class = "fas #{icon} text-xs text-brand"
    else
      next_dir   = default_order.to_s
      icon       = "fa-sort"
      link_class = "inline-flex items-center gap-1.5 hover:text-ink-primary transition-colors cursor-pointer group whitespace-nowrap"
      icon_class = "fas #{icon} text-xs text-ink-subtle/40 group-hover:text-ink-muted transition-colors"
    end

    url = foods_path(sortable_food_params.merge(q: { s: "#{attribute} #{next_dir}" }))
    link_to url, class: link_class do
      tag.span(label) + tag.i("", class: icon_class)
    end
  end

  def food_usages_sort_link(label)
    current   = params[:sort_usages]
    is_active = current.present?

    if is_active
      next_dir   = current == "desc" ? "asc" : "desc"
      icon       = current == "desc" ? "fa-sort-down" : "fa-sort-up"
      link_class = "inline-flex items-center gap-1.5 text-brand transition-colors cursor-pointer whitespace-nowrap"
      icon_class = "fas #{icon} text-xs text-brand"
    else
      next_dir   = "desc"
      icon       = "fa-sort"
      link_class = "inline-flex items-center gap-1.5 hover:text-ink-primary transition-colors cursor-pointer group whitespace-nowrap"
      icon_class = "fas #{icon} text-xs text-ink-subtle/40 group-hover:text-ink-muted transition-colors"
    end

    # On omet q[s] pour que le tri Ransack soit effacé quand on trie par utilisations
    url = foods_path(sortable_food_params.merge(sort_usages: next_dir))
    link_to url, class: link_class do
      tag.span(label) + tag.i("", class: icon_class)
    end
  end

  private

  def sortable_food_params
    params.permit(:query, :label_id, :favorites, :in_stock, :out_of_stock, :category, :full_result).to_h.compact
  end
end
