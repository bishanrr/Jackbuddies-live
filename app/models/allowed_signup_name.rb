class AllowedSignupName < ApplicationRecord
  validates :first_name, presence: true, uniqueness: { case_sensitive: false }

  before_validation :normalize_first_name

  scope :matching_first_name, ->(name) { where("LOWER(first_name) = ?", name.to_s.strip.downcase) }

  private

  def normalize_first_name
    self.first_name = first_name.to_s.strip
  end
end
