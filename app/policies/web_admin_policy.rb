class WebAdminPolicy < ApplicationPolicy

  def show?
    user && user.intranet_user?
  end

  def edit_features?
    user && user.roles.include?(::User::Roles::ADMIN)
  end

  def edit_trade_rules?
    user && user.roles.include?(::User::Roles::ADMIN)
  end

  def edit_data_visibility?
    user && user.roles.include?(::User::Roles::ADMIN)
  end

  def modify_early_shutoff_request?
    record.owners.member?(user.id)
  end

end