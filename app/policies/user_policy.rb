class UserPolicy < ApplicationPolicy

  def change_password?
    !user.intranet_user?
  end

end