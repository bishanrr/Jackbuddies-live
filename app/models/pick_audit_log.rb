class PickAuditLog < ApplicationRecord
  belongs_to :pick, optional: true
  belongs_to :match
  belongs_to :user
  belongs_to :editor_admin, class_name: "User"
  belongs_to :from_team, class_name: "Team", optional: true
  belongs_to :to_team, class_name: "Team"

  validates :reason, presence: true
end
