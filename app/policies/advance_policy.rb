class AdvancePolicy < ApplicationPolicy

  def show?
    user.member && !user.member.requires_dual_signers? && user.roles.include?(User::Roles::ADVANCE_SIGNER)
  end

  def modify?
    record.owners.member?(user.id)
  end

end