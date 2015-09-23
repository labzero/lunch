class Users::SessionsController < Devise::SessionsController
  layout 'external'

  skip_before_action :check_password_change

  def destroy
    super
    flash.discard(:notice)
  end
  
end
