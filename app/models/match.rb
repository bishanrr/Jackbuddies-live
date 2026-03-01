class Match < ApplicationRecord
  enum :stage, { league: 0, qualifier: 1, eliminator: 2, final: 3 }
  enum :status, { scheduled: 0, completed: 1, cancelled: 2 }

  belongs_to :season
  belongs_to :home_team, class_name: "Team"
  belongs_to :away_team, class_name: "Team"
  belongs_to :winner_team, class_name: "Team", optional: true

  has_many :picks, dependent: :destroy
  has_many :points_events, dependent: :nullify

  validates :match_datetime, :stage, :status, presence: true
  validates :match_no, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :match_no, uniqueness: { scope: :season_id }, allow_nil: true
  validate :teams_must_be_distinct
  validate :winner_belongs_to_match_teams

  scope :for_season, ->(season) { where(season: season) }

  def lock_time
    match_datetime - season.default_lock_minutes.minutes
  end

  def locked?
    Time.current >= lock_time
  end

  def display_name
    title.presence || "#{home_team.short_name} vs #{away_team.short_name}"
  end

  private

  def teams_must_be_distinct
    return if home_team_id.blank? || away_team_id.blank? || home_team_id != away_team_id

    errors.add(:away_team, "must be different from home team")
  end

  def winner_belongs_to_match_teams
    return if winner_team_id.blank?
    return if [home_team_id, away_team_id].include?(winner_team_id)

    errors.add(:winner_team, "must be one of the match teams")
  end
end
