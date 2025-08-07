module ApplicationHelper
  def sortable_header(column, title = nil, options = {})
    title ||= column.to_s.humanize

    data_attributes = {
      action: "click->sortable-table#sort",
      column: column,
      sortable_table_target: "header"
    }

    classes = "cursor-pointer transition-colors flex items-center justify-between"
    classes += " #{options[:class]}" if options[:class]

    content_tag :div, data: data_attributes, class: classes do
      content_tag(:span, title) + sort_icon(column)
    end
  end

  private

  def sort_icon(column)
    icon_class = if currently_sorted_by?(column)
      current_direction == 'asc' ? 'fa-sort-up' : 'fa-sort-down'
    else
      'fa-sort'
    end

    content_tag(:i, '', class: "fas #{icon_class} sort-icon ml-1")
  end

  def currently_sorted_by?(column)
    params[:sort_by].to_s == column.to_s
  end

  def current_direction
    params[:direction] || 'asc'
  end
end
