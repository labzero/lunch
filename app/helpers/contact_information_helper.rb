module ContactInformationHelper

  WEB_SUPPORT_EMAIL = 'websupport@fhlbsf.com'
  WEB_SUPPORT_PHONE_NUMBER = '4156162610'

  def web_support_email
    "mailto:#{WEB_SUPPORT_EMAIL}"
  end

  def web_support_phone_number
    fhlb_formatted_phone_number(WEB_SUPPORT_PHONE_NUMBER)
  end
end