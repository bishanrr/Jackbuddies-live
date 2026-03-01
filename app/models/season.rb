class Season < ApplicationRecord
  has_many :matches, -> { order(:match_datetime) }, dependent: :destroy
  has_many :points_rules, dependent: :destroy
  has_many :points_events, dependent: :destroy
  has_many :team_season_stats, dependent: :destroy

  validates :year, presence: true, uniqueness: true
  validates :name, presence: true
  validates :default_lock_minutes, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 120 }

  after_create :ensure_default_points_rules

  def points_for_stage(stage_name)
    points_rules.find_by(stage: stage_name)&.points_for_correct || 0
  end

  private

  def ensure_default_points_rules
    {
      "league" => 2,
      "qualifier" => 3,
      "eliminator" => 3,
      "final" => 5
    }.each do |stage, points|
      points_rules.find_or_create_by!(stage: stage) { |rule| rule.points_for_correct = points }
    end
  end
end
