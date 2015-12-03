class ApplicationController < ActionController::Base
  include Pundit
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :authenticate_user!
  before_action :check_password_change
  before_action :check_terms
  before_action :save_render_time
  helper_method :current_member_name

  HTTP_404_ERRORS = [ActionController::RoutingError, ActionController::UnknownController, ::AbstractController::ActionNotFound, ActiveRecord::RecordNotFound]

  rescue_from Exception do |exception|
    case exception
    when ActionController::InvalidAuthenticityToken
      handle_bad_csrf
    else
      unless Rails.env.production?
        raise exception
      else
        handle_exception(exception)
      end
    end
  end

  def save_render_time
    @render_time = Time.zone.now
  end

  def current_member_id
    session['member_id']
  end

  def current_member_name
    session['member_name'] ||= MembersService.new(request).member(current_member_id).try(:[], :name) if current_member_id
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

  def check_password_change
    redirect_to user_expired_password_path if session['password_expired']
  end
  
  def check_terms
    if current_user
      redirect_to terms_path unless current_user.accepted_terms?
    end
  end

  def authenticate_user_with_authentication_flag!(*args, &block)
    @authenticated_action = true unless instance_variable_defined?(:@authenticated_action)
    authenticate_user_without_authentication_flag!(*args, &block)
  end

  alias_method_chain :authenticate_user!, :authentication_flag

  private

  def after_sign_out_path_for(resource)
    logged_out_path
  end

  def after_sign_in_path_for(resource)
    # We care about the presence of the 'password_expired' key, as well as its value,
    # as we only want to check for password expiration once per session.
    password_expired = session['password_expired']
    password_expired = current_user.password_expired? unless session.has_key?('password_expired')
    if password_expired
      session['password_expired'] = true
      user_expired_password_path
    else
      session['member_id'] = current_user.member_id if !session['member_id'].present? && current_user && !current_user.member_id.nil?
      if current_user.accepted_terms?
        if session['member_id'].present?
          stored_location_for(resource) || dashboard_path
        elsif current_user && current_user.ldap_domain == 'intranet'
          members_select_member_path
        else
          raise 'Sign in error: Only intranet users can select a bank.  The current_user is not an intranet user but is also not associated with a member bank.'
        end
      else
        terms_path
      end
    end
  end

  def handle_exception(exception)
    Rails.logger.error exception
    Rails.logger.error exception.backtrace.join("\n")
    begin
      if HTTP_404_ERRORS.include?(exception.class)
        render 'error/404', layout: 'error', status: 404
      elsif exception.is_a?(Pundit::NotAuthorizedError)
        render 'error/403', layout: 'error', status: 403
      else
        render 'error/500', layout: 'error', status: 500
      end
    rescue => e
      render text: e, status: 500
    end
  end

  def skip_timeout_reset
    request.env["devise.skip_trackable"] = true # tells Warden not to reset Timeoutable timer for this request
    yield
    request.env["devise.skip_trackable"] = false
  end

  def handle_bad_csrf
    reset_session
    redirect_to(logged_out_path)
  end

end
