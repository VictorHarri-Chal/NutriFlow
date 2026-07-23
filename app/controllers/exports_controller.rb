class ExportsController < ApplicationController
  def create
    categories = allowed_categories
    period     = build_period

    if categories.empty?
      redirect_to setting_path(tab: "export"), alert: t("controllers.exports.no_category_selected")
      return
    end

    if period.kind == "custom" && !period.valid?
      redirect_to setting_path(tab: "export"), alert: t("controllers.exports.invalid_period")
      return
    end

    sheets = categories.flat_map { |c| c[:exporter].new(user: current_user, period: period).sheets }
    xlsx   = Exports::ExcelBuilder.new(sheets).build

    send_data xlsx,
              filename: "nutriflow-export-#{Date.today.iso8601}.xlsx",
              type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
              disposition: "attachment"
  end

  private

  def build_period
    Exports::Period.new(
      kind: params[:period],
      date_from: parse_date(params[:date_from]),
      date_to: parse_date(params[:date_to])
    )
  end

  def parse_date(value)
    Date.parse(value)
  rescue ArgumentError, TypeError
    nil
  end

  # Never trust the client-submitted category list: filter it against the
  # registry (existence) and the current user's own toggles (visibility) —
  # a forged request for a hidden category is silently dropped, not a 500.
  def allowed_categories
    requested = Array(params[:categories])
    Exports::CategoryRegistry.visible_for(current_user).select { |c| requested.include?(c[:key]) }
  end
end
