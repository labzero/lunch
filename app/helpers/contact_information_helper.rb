module ContactInformationHelper

  WEB_SUPPORT_EMAIL = 'websupport@fhlbsf.com'
  MPF_SUPPORT_EMAIL = 'mpf@fhlbsf.com'
  MEMBERSHIP_EMAIL = 'membership@fhlbsf.com'
  OPERATIONS_EMAIL = 'portfoliooperations@fhlbsf.com'
  ACCOUNTING_EMAIL = 'capitalstock@fhlbsf.com'
  SECURITIES_SERVICES_EMAIL = 'securitiesservices@fhlbsf.com'
  COLLATERAL_OPERATIONS_EMAIL = 'collateraloperations@fhlbsf.com'
  WEB_SUPPORT_PHONE_NUMBER = '4156162610'
  SERVICE_DESK_PHONE_NUMBER = '8004443452'
  OPERATIONS_PHONE_NUMBER = '4156162559'
  MCU_PHONE_NUMBER = '4156162757'
  ACCOUNTING_PHONE_NUMBER = '4156162620'
  SECURITIES_SERVICES_PHONE_NUMBER = '4156162970'
  COLLATERAL_OPERATIONS_PHONE_NUMBER = '4156162980'
  FEEDBACK_SURVEY_URL = 'https://www.surveymonkey.com/r/7KYSNVN'
  MEMBER_SERVICES_PHONE_NUMBER = '4156162500'

  def web_support_email
    "mailto:#{WEB_SUPPORT_EMAIL}"
  end

  def mpf_support_email
    "mailto:#{MPF_SUPPORT_EMAIL}"
  end

  def membership_email
    "mailto:#{MEMBERSHIP_EMAIL}"
  end

  def operations_email
    "mailto:#{OPERATIONS_EMAIL}"
  end

  def accounting_email
    "mailto:#{ACCOUNTING_EMAIL}"
  end

  def securities_services_email
    "mailto:#{SECURITIES_SERVICES_EMAIL}"
  end

  def collateral_operations_email
    "mailto:#{COLLATERAL_OPERATIONS_EMAIL}"
  end

  def securities_services_email_text
    SECURITIES_SERVICES_EMAIL
  end

  def web_support_phone_number
    fhlb_formatted_phone_number(WEB_SUPPORT_PHONE_NUMBER)
  end

  def service_desk_phone_number
    fhlb_formatted_phone_number(SERVICE_DESK_PHONE_NUMBER)
  end

  def operations_phone_number
    fhlb_formatted_phone_number(OPERATIONS_PHONE_NUMBER)
  end

  def mcu_phone_number
    fhlb_formatted_phone_number(MCU_PHONE_NUMBER)
  end

  def accounting_phone_number
    fhlb_formatted_phone_number(ACCOUNTING_PHONE_NUMBER)
  end

  def securities_services_phone_number
    fhlb_formatted_phone_number(SECURITIES_SERVICES_PHONE_NUMBER)
  end

  def collateral_operations_phone_number
    fhlb_formatted_phone_number(COLLATERAL_OPERATIONS_PHONE_NUMBER)
  end

  def member_services_phone_number
    fhlb_formatted_phone_number(MEMBER_SERVICES_PHONE_NUMBER)
  end

  def feedback_survey_url(user, member_name)
    raise ArgumentError, 'user parameter must not be nil' unless user.present?
    "#{FEEDBACK_SURVEY_URL}?#{{ member: member_name, name: user.display_name, email: user.email }.to_query}"
  end

  def member_contacts(request_obj: request, member_id: current_member_id)
    Rails.cache.fetch(CacheConfiguration.key(:member_contacts, member_id),
                                  expires_in: CacheConfiguration.expiry(:member_contacts)) do
      MembersService.new(request_obj).member_contacts(member_id)
    end || {}
  end
end