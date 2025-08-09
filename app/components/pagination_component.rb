# frozen_string_literal: true

class PaginationComponent < ApplicationComponent
  def initialize(pagy:, full_result_option: false)
    super
    @pagy = pagy
    @full_result_option = full_result_option
  end

  private

  def pagination_links_class
    <<-TXT.squish
      relative inline-flex items-center py-2 border border-gray-300 bg-white
      text-sm font-medium text-gray-500 hover:bg-gray-50 focus:z-20
    TXT
  end

  def pagination_active_class(page)
    page_number = (params[:page].presence || 1).to_i
    "z-10 bg-primary-50 border-primary-500 text-primary-600" if page_number == page
  end

  def right_arrow_class
    "rounded-r-md" unless @full_result_option
  end

  def full_result_path
    current_path = request.fullpath.dup
    return current_path if current_path.include?("full_result=true")

    if current_path.include?("?")
      current_path["?"] = "?full_result=true&"
    else
      current_path << "?full_result=true"
    end

    current_path.sub!(/&page=\d/, "")

    current_path
  end

  def pagy_result_path
    current_path = request.fullpath.dup

    if current_path.include?("&")
      current_path.sub!("full_result=true&", "")
    else
      current_path.sub!("?full_result=true", "")
    end

    current_path
  end

  def full_result?
    params[:full_result] == "true"
  end

  def link_to_page(page)
    link_to page,
            helpers.pagy_url_for(@pagy, page),
            class: "#{pagination_links_class} #{pagination_active_class(page)} px-4"
  end

  def page_ellipsis
    @page_ellipsis ||= content_tag(:span, "…", class: ["px-3", pagination_links_class])
  end
end
