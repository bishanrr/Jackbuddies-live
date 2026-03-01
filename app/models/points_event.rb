class PointsEvent < ApplicationRecord
  IMPORT_REASON = "import".freeze

  enum :event_type, { match_result: 0, manual_adjustment: 1 }

  belongs_to :user
  belongs_to :season
  belongs_to :match, optional: true
  belongs_to :pick, optional: true
  belongs_to :created_by_admin, class_name: "User", optional: true
  belongs_to :voided_by_admin, class_name: "User", optional: true

  scope :active, -> { where(voided_at: nil) }
  scope :imported, -> { where(reason: IMPORT_REASON) }

  validates :points, :reason, presence: true
end
