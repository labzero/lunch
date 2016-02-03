class MemberMailer < Devise::Mailer
  helper AssetHelper
  helper CustomFormattingHelper
  helper ContactInformationHelper
  layout 'mailer'

  def reset_password_instructions(record, token, opts={})
    if record.member_id
      member_details = MembersService.new(ActionDispatch::TestRequest.new).member(record.member_id)
      @member_name = member_details[:name] if member_details
    end
    super
  end

  def new_user_instructions(user, manager, institution, token)
    @resource = user
    @manager = manager
    @member_name = institution
    @token = token
    mail( to: "#{user.display_name} <#{user.email}>", subject: t('emails.new_user.subject'), from: t('emails.new_user.sender', email: ContactInformationHelper::WEB_SUPPORT_EMAIL) )
  end
end