class HistoryPolicy < Struct.new(:user, :record)
  def show?
    user&.approved?
  end
end
