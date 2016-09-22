class SecurityPolicy < ApplicationPolicy
  def authorize?
    user.roles.include?(User::Roles::SECURITIES_SIGNER)
  end

  def delete?
    !user.intranet_user? && user.roles.include?(User::Roles::SECURITIES_SIGNER)
  end

  def submit?
    !user.intranet_user?
  end
end