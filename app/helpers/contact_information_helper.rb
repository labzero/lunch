module ContactInformationHelper

  WEB_SUPPORT_EMAIL = 'websupport@fhlbsf.com'
  MPF_SUPPORT_EMAIL = 'mpf@fhlbsf.com'
  MEMBERSHIP_EMAIL = 'membership@fhlbsf.com'
  OPERATIONS_EMAIL = 'portfoliooperations@fhlbsf.com'
  ACCOUNTING_EMAIL = 'capitalstock@fhlbsf.com'
  SECURITIES_SERVICES_EMAIL = 'securities@fhlbsf.com'
  WEB_SUPPORT_PHONE_NUMBER = '4156162610'
  SERVICE_DESK_PHONE_NUMBER = '8004443452'
  OPERATIONS_PHONE_NUMBER = '4156162559'
  MCU_PHONE_NUMBER = '4156162757'
  ACCOUNTING_PHONE_NUMBER = '4156162620'
  SECURITIES_SERVICES_PHONE_NUMBER = '4156162970'

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
end
