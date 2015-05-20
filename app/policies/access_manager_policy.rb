class AccessManagerPolicy < ApplicationPolicy

  def show?
    @user.roles.include?(User::Roles::ACCESS_MANAGER)
  end

end