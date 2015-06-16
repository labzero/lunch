class ApplicationController < ActionController::Base
  include Pundit
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :authenticate_user!

  rescue_from Exception do |exception|
    unless Rails.env.production?
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

  # Returns a boolean indicating if the current session has successfully gone
  # through the elevated authentication flow with SecureID.
  def session_elevated?
    !!session['securid_authenticated']
  end

  def session_elevate!
    session['securid_authenticated'] = true
  end

  def current_user_roles
    return [] unless current_user
    session['roles'] ||= current_user.roles(request)
    current_user.roles = session['roles']
  end

  private

  def after_sign_out_path_for(resource)
    root_path
  end

  def after_sign_in_path_for(resource)
    session['member_id'] = current_user.member_id if !session['member_id'].present? && current_user && !current_user.member_id.nil?
    if session['member_id'].present?
      stored_location_for(resource) || dashboard_path
    elsif current_user && current_user.ldap_domain == 'intranet'
      members_select_member_path
    else
      raise 'Sign in error: Only intranet users can select a bank.  The current_user is not an intranet user but is also not associated with a member bank.'
    end
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
