class Users::SessionsController < Devise::SessionsController
  layout 'external'
  skip_before_action :current_user_roles
end
