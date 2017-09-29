class LettersOfCreditPolicy < ApplicationPolicy

  def request?
    user.intranet_user? || user.roles.include?(User::Roles::ADVANCE_SIGNER)
  end

  def execute?
    !user.intranet_user? && user.roles.include?(User::Roles::ADVANCE_SIGNER)
  end

  def amend_execute?
    !user.intranet_user? && user.roles.include?(User::Roles::ADVANCE_SIGNER)
  end

  def modify?
    record.owners.member?(user.id)
  end

  def add_beneficiary?
    record.owners.member?(user.id)
  end

end