# frozen_string_literal: true

class PaginationComponent < ApplicationComponent
  def initialize(pagy: nil, full_result_option: false)
    super
    @pagy = pagy
    @full_result_option = full_result_option
  end

  private

  def pagination_links_class
    <<-TXT.squish
      relative inline-flex items-center py-2 border border-surface-border
      bg-surface-raised text-sm font-medium text-ink-muted
      hover:bg-surface-hover hover:text-ink-primary focus:z-20 transition-colors
    TXT
  end

  def pagination_active_class(page)
    return unless @pagy
    page_number = (params[:page].presence || 1).to_i
    "z-10 bg-brand-muted border-brand text-brand" if page_number == page
  end

  def right_arrow_class
    "rounded-r-md" unless @full_result_option
  end

  def full_result_path
    build_path(request.query_parameters.except("page").merge("full_result" => "true"))
  end

  def pagy_result_path
    build_path(request.query_parameters.except("full_result", "page"))
  end

  def build_path(query_params)
    uri = URI.parse(request.path)
    uri.query = query_params.present? ? URI.encode_www_form(query_params) : nil
    uri.to_s
  end

  def full_result?
    params[:full_result] == "true"
  end

  def link_to_page(page)
    return unless @pagy
    link_to page,
            helpers.pagy_url_for(@pagy, page),
            class: "#{pagination_links_class} #{pagination_active_class(page)} px-4"
  end

  def page_ellipsis
    @page_ellipsis ||= content_tag(:span, "…", class: ["px-3", pagination_links_class])
  end
end
