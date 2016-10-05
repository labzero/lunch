class DocusignService

  POWERFORM_MAPPING = JSON.parse(ENV['DOCUSIGN_POWERFORMS']).freeze

  def initialize(request)
    @request = request
  end

  def request
    @request
  end

  def request_uuid
    @request.try(:uuid)
  end

  def get_url(form_name, user, member_id)
    user_name = user.display_name
    email = user.email
    phone = ''
    title = ''
    company = ''
    user = UsersService.new(request).user_details(email)
    if user
      phone = user[:phone]
      title = user[:title]
    end
    member = MembersService.new(request).member(member_id)
    company = member[:name] if member
    powerform_endpoint = ENV['DOCUSIGN_POWERFORM_ENDPOINT']
    powerform_path = ENV['DOCUSIGN_POWERFORM_PATH']
    powerform_id = POWERFORM_MAPPING[form_name]
    raise 'unknown powerform' unless powerform_id
    query = {
      :PowerFormId => powerform_id,
      :Applicant_UserName => user_name,
      :Applicant_Email => email,
      :UName => user_name,
      :UCompany => company,
      :UEmail => email,
      :UPhone => phone,
      :UTitle => title
    }
    url = URI::HTTPS.build(
      :host => powerform_endpoint,
      :path => powerform_path,
      :query => query.to_query
    )
    {link: url}
  end

end