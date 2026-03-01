class PointsRule < ApplicationRecord
  enum :stage, Match.stages

  belongs_to :season

  validates :stage, presence: true, uniqueness: { scope: :season_id }
  validates :points_for_correct, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 50 }
end
