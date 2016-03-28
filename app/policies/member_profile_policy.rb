class MemberProfilePolicy < ApplicationPolicy

  def show?
    user && user.roles.include?(::User::Roles::USER_WITH_EXTENDED_INFO_ACCESS)
  end

end