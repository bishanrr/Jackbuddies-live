require "test_helper"

class LeaderboardQueryTest < ActiveSupport::TestCase
  test "returns rows for imported and non imported seasons" do
    [seasons(:season_2026), Season.find_by(year: 2024)].compact.each do |season|
      rows = LeaderboardQuery.call(season)

      assert rows.any?, "expected leaderboard rows for season #{season.year}"
      assert rows.all? { |row| row.user.present? }
    end
  end

  test "ranks rows by points then accuracy" do
    season = seasons(:season_2026)

    rows = LeaderboardQuery.call(season)

    assert_equal rows.sort_by { |row| [-row.points, -row.accuracy, row.user.name_or_email.downcase] }.map { |row| row.user.id }, rows.map { |row| row.user.id }
  end
end
