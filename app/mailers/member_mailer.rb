class MemberMailer < Devise::Mailer
  layout 'mailer'

  def reset_password_instructions(record, token, opts={})
    if record.member_id
      member_details = MembersService.new(ActionDispatch::TestRequest.new).member(record.member_id)
      @member_name = member_details[:name] if member_details
    end
    super
  end

end