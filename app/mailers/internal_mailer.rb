class InternalMailer < ActionMailer::Base
  helper CustomFormattingHelper
  helper AssetHelper
  include CustomFormattingHelper
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
  
  def exceeds_rate_band(rate_info, request_id, user)
    @rate_info = rate_info
    @request_id = request_id
    @user = user_name_from_user(user)
    mail(subject: I18n.t('errors.emails.exceeds_rate_band.subject'))
  end

  def long_term_advance(advance)
    @advance = advance
    @confirmation_number = advance.confirmation_number
    @trade_date = advance.trade_date
    @funding_date = advance.funding_date
    @maturity_date = advance.maturity_date
    @signer = user_name_from_user(advance.signer)
    @type = advance.human_type
    @term = advance.human_term
    @rate = advance.rate
    @amount = advance.total_amount
    @member_id = advance.member_id
    @member_name = MembersService.new(advance.request || ActionDispatch::TestRequest.new).member(advance.member_id).try(:[], :name)
    mail(subject: I18n.t('emails.long_term_advance.subject', amount: fhlb_formatted_currency(@amount, html: false), term: @term))
  end

  protected

  def user_name_from_user(user)
    return user if user.is_a?(String)

    begin
      name = user.display_name 
    rescue
      nil
    end
    name ||= user.username
  end

end