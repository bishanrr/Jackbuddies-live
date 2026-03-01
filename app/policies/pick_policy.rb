class PickPolicy < ApplicationPolicy
  def create?
    return false unless user&.approved?
    return true if user.admin?

    record.user_id == user.id && !record.match.locked?
  end

  def update?
    create?
  end

  def index?
    user&.admin?
  end

  def edit?
    user&.admin?
  end
end
