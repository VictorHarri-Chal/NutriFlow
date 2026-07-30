require "test_helper"

class PruneDataExportsJobTest < ActiveJob::TestCase
  test "enforces per-user retention: deletes finished exports beyond the newest RETENTION" do
    user   = create_user
    keep   = Array.new(DataExport::RETENTION_PER_USER) do |i|
      user.data_exports.create!(status: "completed", categories: [], created_at: (i + 1).days.ago)
    end
    oldest = user.data_exports.create!(status: "completed", categories: [], created_at: 100.days.ago)

    PruneDataExportsJob.perform_now

    assert_not DataExport.exists?(oldest.id), "export beyond the retention window is deleted"
    keep.each { |e| assert DataExport.exists?(e.id), "the newest RETENTION exports are kept" }
  end

  test "fails stuck in-progress exports but leaves recent ones running" do
    # Distinct users: a partial-unique index allows only one in-progress export per user.
    stuck  = create_user.data_exports.create!(status: "processing", categories: [], created_at: 2.hours.ago)
    recent = create_user.data_exports.create!(status: "pending", categories: [], created_at: 5.minutes.ago)

    PruneDataExportsJob.perform_now

    assert_equal "failed",  stuck.reload.status,  "a worker-died export is marked failed"
    assert_equal "pending", recent.reload.status, "a freshly-queued export keeps running"
  end
end
