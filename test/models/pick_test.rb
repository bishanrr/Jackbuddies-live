require "test_helper"

class PickTest < ActiveSupport::TestCase
  test "enforces unique user pick per match" do
    duplicate = Pick.new(user: users(:approved_user), match: matches(:upcoming), team: teams(:two))

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "has already been taken"
  end
end
