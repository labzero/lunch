class Users::PasswordsController < Devise::PasswordsController
  layout 'external'
  
  skip_before_action :check_terms

  def create
    self.resource = resource_class.find_or_create_if_valid_login(resource_params)
    if resource && UserPolicy.new(resource, nil).change_password?
      resource.send_reset_password_instructions
    end
    flash.discard(:notice)
  end

  def edit
    self.resource = resource_class.with_reset_password_token(params[:reset_password_token]) || resource_class.new
    set_minimum_password_length
    resource.reset_password_token = params[:reset_password_token]
    render :timeout unless self.resource.reset_password_period_valid?
  end

  def update
    super do
      if resource.errors.include?(:reset_password_token)
        render :timeout 
        return
      end
    end
  end
end
