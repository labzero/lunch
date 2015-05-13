class AdvancePolicy < ApplicationPolicy

  def show?
    @user.roles.include?(User::Roles::ADVANCE_SIGNER)
  end

end