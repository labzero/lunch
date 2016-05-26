class ApplicationController < ActionController::Base
  include Pundit
  include FlipperHelper
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :authenticate_user!, :check_password_change, :check_terms, :save_render_time, :set_default_format
  helper_method :current_member_name, :current_member_id, :new_announcements_count, :set_active_nav, :get_active_nav

  HTTP_404_ERRORS = [ActionController::RoutingError, ActionController::UnknownController, ::AbstractController::ActionNotFound, ActiveRecord::RecordNotFound]

  module SessionKeys
    MEMBER_ID = 'member_id'.freeze
    MEMBER_NAME = 'member_name'.freeze
    SECURID_AUTHENTICATED = 'securid_authenticated'.freeze
    PASSWORD_EXPIRED = 'password_expired'.freeze
    NEW_ANNOUNCEMENT_COUNT = 'new_announcements_count'.freeze
    SIGNER_FULL_NAME = 'signer_full_name'.freeze
    CACHE_KEY = 'cache_key'.freeze
    WARDEN_USER = 'warden.user.user.key'.freeze
  end

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
    session[SessionKeys::MEMBER_ID]
  end

  def current_member_name
    session[SessionKeys::MEMBER_NAME] ||= MembersService.new(request).member(current_member_id).try(:[], :name) if current_member_id
    session[SessionKeys::MEMBER_NAME]
  end

  # Returns a boolean indicating if the current session has successfully gone
  # through the elevated authentication flow with SecureID.
  def session_elevated?
    !!session[SessionKeys::SECURID_AUTHENTICATED]
  end

  def session_elevate!
    session[SessionKeys::SECURID_AUTHENTICATED] = true
  end

  def current_user
    user = super
    if user
      # we don't use the session ID here because we renew the ID during login to avoid session fixation attacks
      user.cache_key = session[SessionKeys::CACHE_KEY] || SecureRandom.hex
      session[SessionKeys::CACHE_KEY] ||= user.cache_key
    end
    user
  end

  def check_password_change
    redirect_to user_expired_password_path if session[SessionKeys::PASSWORD_EXPIRED]
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

  def new_announcements_count
    session[SessionKeys::NEW_ANNOUNCEMENT_COUNT] ||= current_user.new_announcements_count if current_user
    session[SessionKeys::NEW_ANNOUNCEMENT_COUNT] || 0
  end

  def reset_new_announcements_count
    session.delete(SessionKeys::NEW_ANNOUNCEMENT_COUNT)
  end

  def set_active_nav(name)
    @active_nav = name
  end

  def get_active_nav
    @active_nav
  end

  def signer_full_name
    session[SessionKeys::SIGNER_FULL_NAME] ||= EtransactAdvancesService.new(request).signer_full_name(current_user.username)
  end

  alias_method_chain :authenticate_user!, :authentication_flag

  private

  def after_sign_out_path_for(resource)
    logged_out_path
  end

  def after_sign_in_path_for(resource)
    user = current_user
    # We care about the presence of the 'password_expired' key, as well as its value,
    # as we only want to check for password expiration once per session.
    password_expired = session[SessionKeys::PASSWORD_EXPIRED]
    password_expired = user.password_expired? unless session.has_key?(SessionKeys::PASSWORD_EXPIRED)
    if password_expired
      session[SessionKeys::PASSWORD_EXPIRED] = true
      user_expired_password_path
    else
      session[SessionKeys::MEMBER_ID] = user.member_id if !session[SessionKeys::MEMBER_ID].present? && user && !user.member_id.nil?
      if user.accepted_terms?
        if session[SessionKeys::MEMBER_ID].present?
          stored_location_for(resource) || dashboard_path
        elsif user && user.intranet_user?
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
      text = Rails.configuration.consider_all_requests_local ? e : 'Something went wrong!'
      render text: text, status: 500
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

  def set_default_format
    request.format = :html unless Mime::SET.include?(request.format)
  end
end
