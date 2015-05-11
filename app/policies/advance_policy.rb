class AdvancePolicy < ApplicationPolicy

  def show?
    @user.roles.include?('signer-advances')
  end

end