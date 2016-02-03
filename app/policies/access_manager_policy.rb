class AccessManagerPolicy < ApplicationPolicy
  def create?
    user.roles.include?(User::Roles::ACCESS_MANAGER)
  end

  def show?
    @user.roles.include?(User::Roles::ACCESS_MANAGER)
  end

  def edit?
    @user.roles.include?(User::Roles::ACCESS_MANAGER)
  end

  def lock?
    edit? && @user.id != @record.id
  end

  def delete?
    edit? && @user.id != @record.id
  end

end