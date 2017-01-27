class LettersOfCreditPolicy < ApplicationPolicy

  def request?
    user.intranet_user? || user.roles.include?(User::Roles::ADVANCE_SIGNER)
  end

end