class Users::SessionsController < Devise::SessionsController
  layout 'external'

  def destroy
    super
    flash.discard(:notice)
  end
  
end
