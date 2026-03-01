class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable

  enum :role, { user: 0, admin: 1 }, default: :user
  enum :status, { pending: 0, approved: 1, denied: 2 }, default: :pending

  has_many :picks, dependent: :destroy
  has_many :points_events, dependent: :destroy
  has_many :pick_audit_logs, dependent: :nullify

  belongs_to :approved_by, class_name: "User", optional: true
  belongs_to :denied_by, class_name: "User", optional: true

  scope :search, ->(term) {
    return all if term.blank?

    sanitized = "%#{term.to_s.strip.downcase}%"
    where("LOWER(COALESCE(display_name, '')) LIKE :q OR LOWER(email) LIKE :q", q: sanitized)
  }

  validates :display_name, length: { maximum: 80 }, allow_blank: true

  def name_or_email
    display_name.presence || email
  end

  def approved?
    status == "approved"
  end
end
