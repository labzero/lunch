class InternalMailer < ActionMailer::Base
  GENERAL_ALERT_ADDRESS = 'MemberPortalAlert@fhlbsf.com'
  layout 'mailer'
  default to: GENERAL_ALERT_ADDRESS, from: GENERAL_ALERT_ADDRESS


  def calypso_error(error, request_id, user, member)
    @error = error
    @request_id = request_id
    @user = begin
      user.display_name 
    rescue
      nil
    end
    @user ||= user.username
    @member = member

    mail(subject: I18n.t('errors.emails.calypso_error.subject'))
  end

end