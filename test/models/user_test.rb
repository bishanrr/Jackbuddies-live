require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "default admin email is auto-promoted to approved admin" do
    user = User.create!(
      email: User.default_admin_email,
      password: "Password123!",
      password_confirmation: "Password123!",
      display_name: "Bishan",
      role: :user,
      status: :pending
    )

    user.ensure_default_admin_access!
    user.reload

    assert user.admin?
    assert user.approved?
  end
end
