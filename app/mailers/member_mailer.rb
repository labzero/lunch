class MemberMailer < Devise::Mailer
  helper AssetHelper
  helper CustomFormattingHelper
  helper ContactInformationHelper
  include ContactInformationHelper
  include ActionView::Helpers::TextHelper
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

  def letter_of_credit_request(member_id, lc_as_json, user)
    @letter_of_credit_request = LetterOfCreditRequest.from_json(lc_as_json, nil)
    pdf_name = "letter_of_credit_request_#{@letter_of_credit_request.lc_number}"
    file = RenderLetterOfCreditPDFJob.perform_now(member_id, 'view', pdf_name, { letter_of_credit_request: {id: @letter_of_credit_request.id} })
    attachments[file.original_filename] = file.read
    mail(subject: I18n.t('letters_of_credit.email.subject'),
         to: "#{user.display_name} <#{user.email}>",
         bcc: InternalMailer::LETTER_OF_CREDIT_ADDRESS,
         from: t('emails.new_user.sender', email: ContactInformationHelper::NO_REPLY_EMAIL)
    )
  end

  def beneficiary_request(request, member_id, lc_as_json, user)
    @beneficiary_request = BeneficiaryRequest.from_json(lc_as_json, nil)
    @requested_by = user.display_name
    @created_at = Time.zone.now
    @contacts = member_contacts(request_obj: request, member_id: member_id)
    member_details = MembersService.new(request).member(member_id)
    if member_details
      @member_name_email = member_details[:name]
      @fhfa = member_details[:fhfa_number]
    end
    mail(subject: I18n.t('letters_of_credit.beneficiary_new.email_subject', member: @member_name_email),
         to: "#{user.display_name} <#{user.email}>",
         bcc: InternalMailer::LETTER_OF_CREDIT_ADDRESS,
         from: t('emails.new_user.sender', email: ContactInformationHelper::NO_REPLY_EMAIL)
    )
  end
end