require "test_helper"

class SettingsResetTest < ActionDispatch::IntegrationTest
  # reset_data must offload the heavy cascade to a job (not run it inline on the
  # web thread) and redirect with an in-progress notice.
  test "reset_data enqueues ResetUserDataJob and redirects" do
    user = create_user
    sign_in user

    assert_enqueued_with(job: ResetUserDataJob, args: [user]) do
      delete reset_data_setting_path
    end
    assert_redirected_to root_path
  end
end
