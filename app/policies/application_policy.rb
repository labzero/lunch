class ApplicationPolicy < Struct.new(:user, :record)
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

end
