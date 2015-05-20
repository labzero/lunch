class SettingsController < ApplicationController

  before_action do
    @sidebar_options = [
        [t("settings.account.title"), '#'],
        [t("settings.password.title"), '#'],
        [t("settings.quick_advance.title"), '#'],
        [t("settings.quick_report.title"), '#'],
        [t("settings.two_factor.title"), settings_two_factor_path],
        [t("settings.email.title"), settings_path]
    ]
  end

  def index
    @email_options = ['reports'] + CorporateCommunication::VALID_CATEGORIES
  end

  # POST
  def save
    # set cookies
    cookie_data = params[:cookies] || {}
    cookie_data.each do |key, value|
      cookies[key.to_sym] = value
    end
    # TODO add status once we have some concept of actually saving data
    now = Time.now
    json_response = {timestamp: now.strftime('%a %d %b %Y, %I:%M %p'), status: 200}.to_json
    render json: json_response
  end

  # GET
  def two_factor
    
  end

  # POST
  def reset_pin
    securid = SecurIDService.new(current_user.username)
    begin
      securid.authenticate(params[:securid_pin], params[:securid_token])
      status = securid.status
    rescue SecurIDService::InvalidPin => e
      status = 'invalid_pin'
    rescue SecurIDService::InvalidToken => e
      status = 'invalid_token'
    end
    if securid.change_pin?
      begin
        status = 'success' if securid.change_pin(params[:securid_new_pin])
      rescue SecurIDService::InvalidPin => e
        status = 'invalid_new_pin'
      end
    end
    render json: {status: status}
  end

  def resynchronize
    securid = SecurIDService.new(current_user.username)
    begin
      securid.authenticate(params[:securid_pin], params[:securid_token])
      status = securid.status
    rescue SecurIDService::InvalidPin => e
      status = 'invalid_pin'
    rescue SecurIDService::InvalidToken => e
      status = 'invalid_token'
    end
    if securid.resynchronize?
      begin
        securid.resynchronize(params[:securid_pin], params[:securid_next_token])
        status = 'success' if securid.authenticated? 
      rescue SecurIDService::InvalidPin => e
        status = 'invalid_pin'
      rescue SecurIDService::InvalidToken => e
        status = 'invalid_next_token'
      end
    end
    render json: {status: status}
  end

end