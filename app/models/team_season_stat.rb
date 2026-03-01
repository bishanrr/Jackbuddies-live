class TeamSeasonStat < ApplicationRecord
  belongs_to :season
  belongs_to :team

  validates :season_id, uniqueness: { scope: :team_id }
  validates :played, :wins, :losses, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
