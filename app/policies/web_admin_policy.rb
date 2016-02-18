class WebAdminPolicy < ApplicationPolicy

  def show?
    user && user.roles.include?(::User::Roles::ADMIN)
  end

end