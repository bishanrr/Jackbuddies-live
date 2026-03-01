class Team < ApplicationRecord
  has_many :home_matches, class_name: "Match", foreign_key: :home_team_id, dependent: :restrict_with_exception
  has_many :away_matches, class_name: "Match", foreign_key: :away_team_id, dependent: :restrict_with_exception
  has_many :winning_matches, class_name: "Match", foreign_key: :winner_team_id, dependent: :restrict_with_exception
  has_many :team_season_stats, dependent: :destroy

  validates :name, :short_name, presence: true
  validates :name, :short_name, uniqueness: true
end
