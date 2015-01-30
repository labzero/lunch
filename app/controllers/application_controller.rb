class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :authenticate_user!

  rescue_from Exception do |exception|
    Rails.logger.error exception
    render :text => exception, :status => 500
  end

  private

  def after_sign_out_path_for(resource)
    root_path
  end

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || dashboard_path
  end
end
