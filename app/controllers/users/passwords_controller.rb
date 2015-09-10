class Users::PasswordsController < Devise::PasswordsController
  layout 'external'

  def create
    self.resource = resource_class.find_or_create_if_valid_login(resource_params)
    self.resource.send_reset_password_instructions if self.resource
    
    unless resource && successfully_sent?(resource)
      set_flash_message :error, :username_not_found if is_flashing_format?
      redirect_to(new_password_path(resource || resource_class.new))
    end
  end

  def edit
    super
    render :timeout unless self.resource.reset_password_period_valid?
  end
end
