class UserPolicy < ApplicationPolicy
  def index?
    user&.approved?
  end

  def show?
    user&.approved?
  end

  def update?
    user&.admin?
  end

  def approve?
    user&.admin?
  end

  def deny?
    user&.admin?
  end
end
