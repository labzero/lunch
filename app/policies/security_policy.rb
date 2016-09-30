class SecurityPolicy < ApplicationPolicy
  def authorize_securities?
    !user.intranet_user? && user.roles.include?(User::Roles::SECURITIES_SIGNER)
  end

  def authorize_collateral?
    !user.intranet_user? && user.roles.include?(User::Roles::COLLATERAL_SIGNER)
  end

  def delete?
    !user.intranet_user? && user.roles.include?(User::Roles::SECURITIES_SIGNER)
  end

  def submit?
    !user.intranet_user?
  end
end