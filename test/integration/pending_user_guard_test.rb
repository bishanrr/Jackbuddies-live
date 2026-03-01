require "test_helper"

class PendingUserGuardTest < ActionDispatch::IntegrationTest
  test "pending users are redirected to approval page" do
    sign_in users(:pending_user)

    get dashboard_path

    assert_redirected_to awaiting_approval_path
  end
end
