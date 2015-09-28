class InternalMailer < ActionMailer::Base
  GENERAL_ALERT_ADDRESS = 'MemberPortalAlert@fhlbsf.com'
  layout 'mailer'
  default to: GENERAL_ALERT_ADDRESS, from: GENERAL_ALERT_ADDRESS


  def calypso_error(error, request_id, user, member)
    @error = error
    @request_id = request_id
    @user = user_name_from_user(user)
    @user ||= user.username
    @member = member

    mail(subject: I18n.t('errors.emails.calypso_error.subject'))
  end

  def stale_rate(rate_timeout, request_id, user)
    @rate_timeout = rate_timeout
    @request_id = request_id
    @user = user_name_from_user(user)
    mail(subject: I18n.t('errors.emails.stale_rate.subject'))
  end

  protected

  def user_name_from_user(user)
    begin
      name = user.display_name 
    rescue
      nil
    end
    name ||= user.username
  end

end