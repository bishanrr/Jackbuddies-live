class AdminPolicy < Struct.new(:user, :record)
  def access?
    user&.approved? && user&.admin?
  end
end
