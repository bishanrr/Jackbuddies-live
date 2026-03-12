require "test_helper"

class ApplicationControllerSeasonSelectionTest < ActionDispatch::IntegrationTest
  test "defaults to the current year season when available" do
    user = users(:admin)
    sign_in user

    get dashboard_path

    assert_response :success
    assert_includes response.body, "Season 2026 Jackpot Fill"
  end

  test "allows explicit season switching" do
    user = users(:admin)
    sign_in user
    season_2026 = seasons(:season_2026)

    get dashboard_path(season_id: season_2026.id)

    assert_response :success
    assert_includes response.body, "Season #{season_2026.year} Jackpot Fill"
  end
end
