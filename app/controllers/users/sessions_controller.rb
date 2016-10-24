class Users::SessionsController < Devise::SessionsController
  layout 'external'

  skip_before_action :check_password_change, :check_terms

  def destroy
    current_user.clear_cache
    super
    flash.discard(:notice)
  end

  def create
    begin
      tries ||= 2
      super
    rescue ActiveRecord::RecordNotUnique => e
      tries -= 1
      if tries > 0
        retry
      else
        raise e
      end
    end
    flash.discard(:notice)
  end
  
end
