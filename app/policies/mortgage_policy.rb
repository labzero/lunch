class MortgagePolicy < ApplicationPolicy

  def request?
    user.intranet_user? || user.roles.include?(User::Roles::COLLATERAL_SIGNER)
  end

end