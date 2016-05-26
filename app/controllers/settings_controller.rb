class SettingsController < ApplicationController

  before_action do
    @sidebar_options = [
        [t("settings.password.title"), settings_password_path]
    ]
    @sidebar_options << [t("settings.account.title"), settings_users_path] if policy(:access_manager).show?
    @sidebar_options << [t("settings.two_factor.title"), settings_two_factor_path]
  end

  before_action only: [:users] do
    authorize :access_manager, :show?
  end

  before_action only: [:new_user, :create_user] do
    authorize :access_manager, :create?
  end

  before_action only: [:edit_user, :update_user] do
    @user = User.find(params[:id])
    authorize @user, :edit?
  end

  before_action only: [:reset_password] do
    @user = User.find(params[:id])
    authorize @user, :reset_password?
  end

  before_action only: [:lock, :unlock] do
    @user = User.find(params[:id])
    authorize @user, :lock?
  end

  before_action only: [:delete_user, :confirm_delete] do
    @user = User.find(params[:id])
    authorize @user, :delete?
  end

  skip_before_action :check_password_change, only: [:expired_password, :update_expired_password]
  skip_before_action :check_terms, only: [:expired_password, :update_expired_password]

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
    if @user.unlock!
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
    if @user.lock!
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
  def new_user
    @user = User.new
    render json: {html: render_to_string(layout: false)}
  end

  # POST
  def create_user
    permitted_params = params.require(:user).permit(:given_name, :surname, :email, :email_confirmation, :username)
    if (@user = User.new(permitted_params)).valid?(:update) && # to avoid duplication of validation rules
       extranet_user = User.add_extranet_user( current_member_id, current_user.username, permitted_params[:username], permitted_params[:email], permitted_params[:given_name], permitted_params[:surname] )
      @user = extranet_user
      MemberMailer.new_user_instructions(@user, current_user, current_member_name, @user.send(:set_reset_password_token)).deliver_now
      render json: {html: render_to_string(layout: false), row_html: render_user_row(@user)}
    else
      render json: {html: render_to_string('new_user', layout: false)}, status: 500
    end
  end

  # GET
  def edit_user
    @user.email_confirmation = @user.email
    render json: {html: render_to_string(layout: false, locals: { actions: actions_for_user(@user) })}
  end

  # POST
  def update_user
    @user = User.find(params[:id])
    if @user.update_attributes!(params.require(:user).permit(:given_name, :surname, :email, :email_confirmation))
      render json: {html: render_to_string(layout: false), row_html: render_user_row(@user)}
    else
      render json: {}, status: 500
    end
  end

  # GET
  def confirm_delete
    render json: {
      html: render_to_string(layout: false)
    }
  end

  # DELETE
  def delete_user
    raise Pundit::NotAuthorizedError.new query: :delete?, record: @user if current_user.id == @user.id
    case params[:reason]
    when 'remove_access'
      reason = 'No longer a web user' # these strings should NOT be looked up from I18n here
    when 'left_institution'
      reason = 'No longer with this institution'
    else
      raise ActiveRecord::RecordInvalid.new(@user)
    end

    if @user.update_attribute(:deletion_reason, reason) && @user.destroy!
      render json: { html: render_to_string(layout: false) }
    else
      render json: {}, status: 500
    end
  end

  # GET
  def two_factor

  end

  # POST
  def new_pin
    securid = SecurIDService.new(current_user.username)
    begin
      securid.authenticate_without_pin(params[:securid_token])
      status = securid.status
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

  def reset_password
    @user.send_reset_password_instructions
    if @user.errors.empty?
      render json: { html: render_to_string(layout: false) }
    else
      render json: {}, status: 500
    end
  end

  def expired_password
    if session[SessionKeys::PASSWORD_EXPIRED]
      render layout: 'external'
    else
      redirect_to settings_path
    end
  end

  def change_password
    current_user.enable_virtual_validators!
  end

  def update_expired_password
    raise 'Updating non-expired password!' unless session[SessionKeys::PASSWORD_EXPIRED]

    current_user.password = params[:user][:password]
    current_user.password_confirmation = params[:user][:password_confirmation]

    if current_user.save
      session[SessionKeys::PASSWORD_EXPIRED] = false
      @next_location = after_sign_in_path_for(current_user)
      render :update_password_success, layout: 'external'
    else
      render :expired_password, layout: 'external'
    end
  end

  def update_password
    strategy = Devise::Strategies::LdapAuthenticatable.new(request.env)
    if current_user.valid_ldap_authentication?(params[:user][:current_password], strategy)
      current_user.password = params[:user][:password]
      current_user.password_confirmation = params[:user][:password_confirmation]

      if current_user.save
        flash[:notice] = t('devise.passwords.updated_not_active')
        redirect_to(settings_password_path)
      else
        render :change_password
      end
    else
      current_user.errors.add(:current_password)
      render :change_password
    end
  end

  private
  def roles_for_user(user)
    roles = user.roles.collect do |role|
      if role == User::Roles::ACCESS_MANAGER
        t('user_roles.access_manager.title')
      elsif role == User::Roles::AUTHORIZED_SIGNER
        t('user_roles.authorized_signer')
      end
    end
    roles.compact!
    roles.present? ? roles : [t('user_roles.user.title')]
  end

  def actions_for_user(user)
    {
      locked: user.locked?,
      locked_disabled: !policy(user).lock?,
      reset_disabled: !policy(user).reset_password?,
      edit_disabled: !policy(user).edit?,
      delete_disabled: !policy(user).delete?
    }
  end

  def render_user_row(user)
    render_to_string(partial: 'user_row',
                     locals: {
                         user: user,
                         roles: roles_for_user(user),
                         actions: actions_for_user(user)
                     })
  end
end