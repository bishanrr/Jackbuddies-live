class DailyMatchEntry < ApplicationRecord
  belongs_to :season
  belongs_to :admin_user, class_name: "User"

  validates :match_no, :winner_team_short_name, :raw_text, :processed_at, presence: true
end
