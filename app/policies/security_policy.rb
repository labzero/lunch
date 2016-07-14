class SecurityPolicy < ApplicationPolicy
  def authorize?
    user.roles.include?(User::Roles::SECURITIES_SIGNER)
  end
end