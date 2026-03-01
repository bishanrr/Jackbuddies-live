require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "allows sign up when first name is in allowlist" do
    user = User.new(
      email: "sreekanth@example.com",
      password: "Password123!",
      password_confirmation: "Password123!",
      display_name: "Praveen Kumar"
    )

    assert user.valid?
  end

  test "blocks sign up when first name is not in allowlist" do
    user = User.new(
      email: "someone@example.com",
      password: "Password123!",
      password_confirmation: "Password123!",
      display_name: "Unknown Person"
    )

    assert_not user.valid?
    assert_includes user.errors[:display_name], "first name is not on the private league allowlist"
  end
end
