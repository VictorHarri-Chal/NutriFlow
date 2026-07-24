class ExportsController < ApplicationController
  # Kicks off an async .xlsx generation (Solid Queue) and renders the "en cours"
  # state; the browser then polls #show until the file is ready. Heavy exports
  # (thousands of rows, several seconds) no longer tie up a web thread.
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

    # One generation at a time per user: a running export can't be piled on
    # (each is a heavy multi-second job). Re-show the in-flight one instead of
    # enqueuing another — this absorbs rapid double-submits / spam. The DB
    # partial-unique index is the airtight backstop for concurrent requests that
    # both pass this check (see the rescue below).
    running = current_user.data_exports.in_progress.recent.first
    return respond_with_export(running) if running

    export = current_user.data_exports.create!(
      status: "pending",
      categories: categories.map { |c| c[:key] },
      period_kind: period.kind,
      date_from: period.date_from,
      date_to: period.date_to
    )
    prune_old_exports
    DataExportJob.perform_later(export)

    respond_with_export(export)
  rescue ActiveRecord::RecordNotUnique
    # Lost a race: a concurrent request already created the in-flight export.
    respond_with_export(current_user.data_exports.in_progress.recent.first)
  end

  # Polled by export_poller_controller. JSON drives the client; the turbo_stream
  # variant re-renders the status region in place.
  def show
    export = current_user.data_exports.find(params[:id])

    respond_to do |format|
      format.json { render json: status_payload(export) }
      format.turbo_stream { render_status_stream(export) }
    end
  end

  def download
    export = current_user.data_exports.find(params[:id])

    unless export.completed? && export.file.attached?
      redirect_to setting_path(tab: "export"), alert: t("controllers.exports.not_ready")
      return
    end

    # Stream through the app (authenticated, scoped to current_user) rather than
    # exposing the file's public R2/CDN URL — this is the user's private data.
    send_data export.file.download,
              filename: export.file.filename.to_s,
              type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
              disposition: "attachment"
  end

  private

  # Renders the export's current status region (turbo_stream) or falls back to
  # the tab (html). Tolerates a nil export (e.g. the racing one already finished).
  def respond_with_export(export)
    respond_to do |format|
      format.turbo_stream { render_status_stream(export) }
      format.html { redirect_to setting_path(tab: "export") }
    end
  end

  def render_status_stream(export)
    render turbo_stream: turbo_stream.replace(
      "export_status", partial: "settings/export_status", locals: { export: export }
    )
  end

  def status_payload(export)
    {
      status: export.status,
      ready: export.completed?,
      failed: export.failed?,
      download_url: export.completed? ? download_export_path(export) : nil
    }
  end

  # Prune only finished exports beyond the retention limit — never an in-flight
  # one, so a queued/processing job can't have its record deleted mid-build.
  def prune_old_exports
    current_user.data_exports.finished.recent.offset(DataExport::RETENTION_PER_USER).destroy_all
  end

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
