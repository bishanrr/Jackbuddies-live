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

  def self.default_admin_email
    ENV.fetch("DEFAULT_ADMIN_EMAIL", "vigrahalabishan3@gmail.com").downcase
  end

  def default_admin_email?
    email.to_s.downcase == self.class.default_admin_email
  end

  def ensure_default_admin_access!
    return unless default_admin_email?
    return if admin? && approved?

    update!(
      display_name: display_name.presence || "Bishan",
      role: :admin,
      status: :approved,
      approved_at: approved_at || Time.current,
      denied_at: nil,
      denied_by: nil,
      denial_reason: nil
    )
  end

  def name_or_email
    display_name.presence || email
  end

  def approved?
    status == "approved"
  end
end
