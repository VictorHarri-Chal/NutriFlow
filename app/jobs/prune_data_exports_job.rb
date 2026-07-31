class PruneDataExportsJob < ApplicationJob
  queue_as :default

  # A generation whose worker died stays "processing" forever otherwise, showing
  # a perpetual "en cours" to the user.
  STUCK_AFTER = 1.hour

  # Runs daily (config/recurring.yml).
  def perform
    fail_stuck_exports
    enforce_retention
  end

  private

  def fail_stuck_exports
    DataExport.in_progress.where(created_at: ..STUCK_AFTER.ago).find_each do |export|
      export.update_columns(status: "failed", error_message: "stuck", updated_at: Time.current)
    end
  end

  # Global backstop for ExportsController#prune_old_exports: keep the newest
  # RETENTION_PER_USER finished exports per user, delete the rest so generated
  # files (and their R2 blobs, purged via #destroy) don't accumulate. Same policy
  # as the on-create prune, so a low-activity user never loses their only export.
  def enforce_retention
    ranked = DataExport.finished.select(
      "id, ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_at DESC, id DESC) AS position"
    ).to_sql

    DataExport
      .where("id IN (SELECT id FROM (#{ranked}) ranked WHERE ranked.position > #{DataExport::RETENTION_PER_USER})")
      .find_each(&:destroy)
  end
end
