module ContactInformationHelper

  WEB_SUPPORT_EMAIL = 'websupport@fhlbsf.com'
  WEB_SUPPORT_PHONE_NUMBER = '4156162610'
  SERVICE_DESK_PHONE_NUMBER = '8004443452'
  OPERATIONS_PHONE_NUMBER = '4156162559'

  def web_support_email
    "mailto:#{WEB_SUPPORT_EMAIL}"
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
end