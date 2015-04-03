class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :authenticate_user!

  rescue_from Exception do |exception|
    if Rails.env.test?
      raise exception
    else
      handle_exception(exception)
    end
  end

  def current_member_id
    session['member_id']
  end

  def current_member_name
    session['member_name']
  end

  private

  def after_sign_out_path_for(resource)
    root_path
  end

  def after_sign_in_path_for(resource)
    return user_session_select_member_path unless session['member_id'].present?
    stored_location_for(resource) || dashboard_path
  end

  def handle_exception(exception)
    Rails.logger.error exception
    Rails.logger.error exception.backtrace.join("\n")
    begin
      render 'error/500', layout: 'error', status: 500
    rescue => e
      render text: e, status: 500
    end
  end
end
