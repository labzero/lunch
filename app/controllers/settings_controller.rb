class SettingsController < ApplicationController

  before_action do
    @sidebar_options = [
        [t("settings.password.title"), '#'],
        [t("settings.quick_advance.title"), '#'],
        [t("settings.quick_report.title"), '#'],
        [t("settings.two_factor.title"), settings_two_factor_path],
        [t("settings.email.title"), settings_path]
    ]
    @sidebar_options.unshift([t("settings.account.title"), settings_users_path]) if policy(:access_manager).show?
  end

  before_action only: [:users] do
    authorize :access_manager, :show?
  end

  before_action only: [:unlock, :lock, :edit_user, :update_user] do
    authorize :access_manager, :edit?
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
  def users
    @users = MembersService.new(request).users(current_member_id).try(:sort_by, &:display_name) || []
    @roles = {}
    @actions = {}
    @users.each do |user|
      @roles[user.id] = roles_for_user(user)
      @actions[user.id] = actions_for_user(user)
    end
  end

  # POST
  def unlock
    @user = User.find(params[:id])
    if @user.id != current_user.id && @user.unlock!
      render json: {
        html: render_to_string(layout: false),
        row_html: render_to_string(partial: 'user_row', locals: {
          user: @user,
          roles: roles_for_user(@user),
          actions: actions_for_user(@user)
        })
      }
    else
      render json: {}, status: 500
    end
  end

  # POST
  def lock
    @user = User.find(params[:id])
    if @user.id != current_user.id && @user.lock!
      render json: {
        html: render_to_string(layout: false),
        row_html: render_to_string(partial: 'user_row', locals: {
          user: @user,
          roles: roles_for_user(@user),
          actions: actions_for_user(@user)
        })
      }
    else
      render json: {}, status: 500
    end
  end

  # GET
  def edit_user
    @user = User.find(params[:id])
    @user.email_confirmation = @user.email
    render json: {html: render_to_string(layout: false)}
  end

  # POST
  def update_user
    @user = User.find(params[:id])
    @user.update_attributes!(params.require(:user).permit(:given_name, :surname, :email, :email_confirmation))
    render json: {
      html: render_to_string(layout: false),
      row_html: render_to_string(partial: 'user_row', locals: {
        user: @user,
        roles: roles_for_user(@user),
        actions: actions_for_user(@user)
      })
    }
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

  private

  def roles_for_user(user)
    roles = user.roles.collect do |role|
      if role == User::Roles::ACCESS_MANAGER
        t('settings.account.roles.access_manager')
      elsif role == User::Roles::AUTHORIZED_SIGNER
        t('settings.account.roles.authorized_signer')
      end
    end
    roles.compact!
    roles.present? ? roles : [t('user_roles.user.title')]
  end

  def actions_for_user(user)
    is_current_user = user.id == current_user.id
    {
      locked: user.locked?,
      locked_disabled: is_current_user,
      reset_disabled: is_current_user
    }
  end

end