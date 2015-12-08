class AdvancePolicy < ApplicationPolicy

  def show?
    user.roles.include?(User::Roles::ADVANCE_SIGNER)
  end

  def modify?
    record.owners.member?(user.id)
  end

end