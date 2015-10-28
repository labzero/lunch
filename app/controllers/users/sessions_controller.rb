class Users::SessionsController < Devise::SessionsController
  layout 'external'

  skip_before_action :check_password_change, :check_terms

  def destroy
    super
    flash.discard(:notice)
  end

  def create
    super
    flash.discard(:notice)
  end
  
end
