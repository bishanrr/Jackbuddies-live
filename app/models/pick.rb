class Pick < ApplicationRecord
  belongs_to :user
  belongs_to :match
  belongs_to :team
  belongs_to :updated_by_admin, class_name: "User", optional: true

  has_many :points_events, dependent: :nullify

  validates :user_id, uniqueness: { scope: :match_id }
  validate :team_must_belong_to_match

  delegate :season, to: :match

  def editable_by_user?
    !match.locked?
  end

  private

  def team_must_belong_to_match
    return if team_id.blank? || match.blank?

    return if [match.home_team_id, match.away_team_id].include?(team_id)

    errors.add(:team, "must be one of the match teams")
  end
end
