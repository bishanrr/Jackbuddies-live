class ApprovalPolicy < Struct.new(:user, :record)
  def show?
    user.present?
  end
end
