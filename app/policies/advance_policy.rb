class AdvancePolicy < ApplicationPolicy

  def show?
    user.intranet_user? || (user.member && !user.member.requires_dual_signers? && user.roles.include?(User::Roles::ADVANCE_SIGNER))
  end

  def execute?
    !user.intranet_user? && user.member && !user.member.requires_dual_signers? && user.roles.include?(User::Roles::ADVANCE_SIGNER)
  end

  def modify?
    record.owners.member?(user.id)
  end

end