class MatchPolicy < ApplicationPolicy
  def index?
    user&.approved?
  end

  def show?
    user&.approved?
  end

  def create?
    user&.admin?
  end

  def update?
    user&.admin?
  end

  def destroy?
    user&.admin?
  end
end
