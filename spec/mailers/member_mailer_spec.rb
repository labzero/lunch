require 'rails_helper'
include ContactInformationHelper
include CustomFormattingHelper
include ActionView::Helpers::TextHelper

RSpec.describe MemberMailer, :type => :mailer do
  describe 'layout' do
    it 'should use the `mailer` layout' do
      expect(described_class._layout).to eq('mailer')
    end
  end

  describe '`reset_password_instructions` email' do
    let(:record) { double('A Record', member_id: nil) }
    let(:token) { double('A Token') }
    let(:options) { double('Some Options') }
    let(:build_mail) { mail :reset_password_instructions, record, token, options }
    before do
      allow_any_instance_of(Devise::Mailer).to receive(:reset_password_instructions).and_return(nil)
    end
    it 'calls `super`' do
      expect_any_instance_of(Devise::Mailer).to receive(:reset_password_instructions).with(record, token, options)
      build_mail
    end
    it 'checks for a `member_id` on the record' do
      expect(record).to receive(:member_id)
      build_mail
    end
    describe 'if the record has a `member_id`' do
      let(:member_id) { double('A Member ID') }
      before do
        allow(record).to receive(:member_id).and_return(member_id)
        allow_any_instance_of(MembersService).to receive(:member).with(member_id)
      end
      it 'fetchs the member details' do
        expect_any_instance_of(MembersService).to receive(:member).with(member_id)
        build_mail
      end
      it 'assigns @member_name to the name of the member if found' do
        name = double('A Member Name')
        member_details = double('Some Member Details')
        allow_any_instance_of(MembersService).to receive(:member).with(member_id).and_return(member_details)
        allow(member_details).to receive(:[]).with(:name).and_return(name)
        build_mail
        expect(assigns[:member_name]).to be(name)
      end
      it '@member_name is undefined if the member was not found' do
        build_mail
        expect(assigns).to_not include(:member_name)
      end
    end
  end

  describe 'new_user_instructions email' do
    let(:display_name){ SecureRandom.hex }
    let(:email){ "#{SecureRandom.hex}@#{SecureRandom.hex}.com" }
    let(:firstname){ SecureRandom.hex }
    let(:username){ SecureRandom.hex }
    let(:given_name){ SecureRandom.hex }
    let(:user){ double( 'user', display_name: display_name, email: email, firstname: firstname, username: username, given_name: given_name) }
    let(:manager_display_name){ SecureRandom.hex }
    let(:manager){ double('manager', display_name: manager_display_name) }
    let(:institution){ SecureRandom.hex }
    let(:token){ SecureRandom.hex }
    let(:call_method){ mail :new_user_instructions, user, manager, institution, token }

    it 'should call mail with the appropriate params' do
      expect_any_instance_of(Devise::Mailer).to receive(:mail).with(to: "#{display_name} <#{email}>", subject: I18n.t('emails.new_user.subject'), from: I18n.t('emails.new_user.sender', email: ContactInformationHelper::WEB_SUPPORT_EMAIL) )
      call_method
    end

    it 'calls mail with @resource set' do
      call_method
      expect(assigns[:resource]).to be(user)
    end

    it 'calls mail with @manager set' do
      call_method
      expect(assigns[:manager]).to be(manager)
    end

    it 'calls mail with @member_name set' do
      call_method
      expect(assigns[:member_name]).to be(institution)
    end

    it 'calls mail with @token set' do
      call_method
      expect(assigns[:token]).to be(token)
    end

    it 'produces an email containing given_name' do
      call_method
      expect(response.body).to match(given_name)
    end

    it 'produces an email containing manager_display_name' do
      call_method
      expect(response.body).to match(manager_display_name)
    end

    it 'produces an email containing token' do
      call_method
      expect(response.body).to match(token)
    end
  end

  shared_examples 'a letter of credit request email' do |method|
    let(:letter_of_credit_json) { double('loc as json') }
    let(:lc_number) { SecureRandom.hex }
    let(:member_id) { instance_double(String) }
    let(:id) { instance_double(String) }
    let(:letter_of_credit_request) do
      instance_double(LetterOfCreditRequest,
                      lc_number: lc_number,
                      id: id,
                      created_at: nil,
                      created_by: nil,
                      beneficiary_name: nil,
                      beneficiary_address: nil,
                      amount: nil,
                      amended_amount: nil,
                      attention: nil,
                      issue_date: nil,
                      expiration_date: nil,
                      amended_expiration_date: nil,
                      amendment_date: nil,
                      issuance_fee: nil,
                      maintenance_fee:nil,
                      amendment_fee: nil
      )
    end
    let(:user) { instance_double(User, email: "#{SecureRandom.hex}@example.com", display_name: SecureRandom.hex) }
    let(:filename) { method.to_s.eql?('letter_of_credit_request') ? "letter_of_credit_request_#{letter_of_credit_request.lc_number}" : "letter_of_credit_request_amendment_confirmation_#{letter_of_credit_request.lc_number}"}
    let(:file) { instance_double(StringIOWithFilename, original_filename: filename, read: File.read(Rails.root.join('spec', 'fixtures', 'letter_of_credit_request_sample.pdf'))) }
    let(:build_mail) { mail method, member_id, letter_of_credit_json, user }

    let(:member_id) { double('A Member ID') }
    let(:member_details) { double('Some Member Details') }
    let(:name) { double('A Member Name') }
    let(:fhfa_number) { rand( 1..1000) }

    before do
      allow(LetterOfCreditRequest).to receive(:from_json).and_return(letter_of_credit_request)
      allow(RenderLetterOfCreditPDFJob).to receive(:perform_now).and_return(file)
      allow_any_instance_of(MembersService).to receive(:member).with(member_id).and_return(member_details)
      allow(member_details).to receive(:[]).with(:name).and_return(name)
      allow(member_details).to receive(:[]).with(:fhfa_number).and_return(fhfa_number)
    end

    describe 'fetches the member details' do
      if method.to_s.eql?('letter_of_credit_request_amendment')
        it 'fetches the member details' do
          expect_any_instance_of(MembersService).to receive(:member).with(member_id)
          build_mail
        end
        it 'assigns @member_name' do
          build_mail
          expect(assigns[:member_name]).to eq(name)
        end
        it 'assigns @fhfa_number' do
          build_mail
          expect(assigns[:member_fhfa]).to eq(fhfa_number)
        end
      end
    end

    it 'includes the display name of the user in the `to` field' do
      build_mail
      expect(response.header_fields.select{ |header| header.name == 'To'}.first.value).to include(user.display_name)
    end
    it 'sends the email to the email address of the user' do
      build_mail
      expect(response.to.first).to eq(user.email)
    end
    it 'bcc\'s the bank on the sent email' do
      build_mail
      expect(response.bcc.first).to eq(InternalMailer::LETTER_OF_CREDIT_ADDRESS)
    end
    it 'sets the `from` of the email' do
      build_mail
      expect(response.from.first).to eq(ContactInformationHelper::NO_REPLY_EMAIL)
    end
    it 'sets the `subject` of the email' do
      subject = method.to_s.eql?('letter_of_credit_request') ?
        I18n.t('letters_of_credit.email.subject') :
        I18n.t('letters_of_credit.request.amend.email.subject', lc_number: lc_number)
      build_mail
      expect(response.subject).to eq(subject)
    end
    it 'constructs a LetterOfCreditRequest from the supplied JSON' do
      expect(LetterOfCreditRequest).to receive(:from_json).with(letter_of_credit_json, nil).and_return(letter_of_credit_request)
      build_mail
    end
    it 'assigns the new instance of LetterOfCreditRequest to @letter_of_credit_request' do
      build_mail
      expect(assigns[:letter_of_credit_request]).to eq(letter_of_credit_request)
    end
    it 'calls `RenderLetterOfCreditPDFJob.perform_now` with the member_id' do
      expect(RenderLetterOfCreditPDFJob).to receive(:perform_now).with(member_id, any_args).and_return(file)
      build_mail
    end
    it 'calls `RenderLetterOfCreditPDFJob.perform_now` with the appropriate view specified as its action' do
      view = method.to_s.eql?('letter_of_credit_request') ? 'view' : 'amend_view'
      expect(RenderLetterOfCreditPDFJob).to receive(:perform_now).with(anything, view, any_args).and_return(file)
      build_mail
    end
    it 'calls `RenderLetterOfCreditPDFJob.perform_now` with a pdf name that includes the lc_number' do
      expect(RenderLetterOfCreditPDFJob).to receive(:perform_now).with(anything, anything, filename, any_args).and_return(file)
      build_mail
    end

    it 'calls `RenderLetterOfCreditPDFJob.perform_now` with the letter of credit request id parameter' do
      expect(RenderLetterOfCreditPDFJob).to receive(:perform_now).with(anything, anything, anything, { letter_of_credit_request: {id: id} }).and_return(file)
      build_mail
    end
    describe 'attachments' do
      let(:attachment) { build_mail; response.attachments.first }
      it 'has one attachment' do
        build_mail
        expect(response.attachments.length).to be 1
      end
      it 'has a filename that includes the lc_number' do
        expect(attachment.filename).to eq(filename)
      end
    end
    describe 'email body' do
      let(:string_sentinel) { SecureRandom.hex }
      let(:datetime_sentinel) { Time.zone.today + rand(1..30).days }
      let(:integer_sentinel) { rand(1000..99999) }
      let(:email_body) { build_mail; response.body.parts.last.body.raw_source }
      it 'includes messaging with the `member_services_phone_number`' do
        body = method.to_s.eql?('letter_of_credit_request') ?
          simple_format(I18n.t('letters_of_credit.email.body', phone_number: member_services_phone_number)) :
          simple_format(I18n.t('letters_of_credit.request.amend.email.body', phone_number: member_services_phone_number))
        expect(email_body).to include(body)
      end

      if method.to_s.eql?('letter_of_credit_request')
        info_fields = [:created_by, :lc_number, :beneficiary_name, :beneficiary_address, :maintenance_fee, :attention]
        amount_fields = [:amount, :issuance_fee]
        date_fields = [:issue_date, :expiration_date]
      else
        info_fields = [:created_by, :lc_number, :beneficiary_name, :maintenance_fee]
        amount_fields = [:amount, :amended_amount, :amendment_fee]
        date_fields = [:created_at, :expiration_date, :amended_expiration_date, :amendment_date]
      end
      info_fields.each do |attr|
        it "includes the `#{attr}` attribute" do
          allow(letter_of_credit_request).to receive(attr).and_return(string_sentinel)
          expect(email_body).to include(string_sentinel)
        end
      end
      amount_fields.each do |attr|
        it "includes the correctly formatted `#{attr}` attribute" do
          allow(letter_of_credit_request).to receive(attr).and_return(integer_sentinel)
          expect(email_body).to include(fhlb_formatted_currency_whole(integer_sentinel))
        end
      end
      date_fields.each do |attr|
        it "includes the correctly formatted `#{attr}` attribute" do
          allow(letter_of_credit_request).to receive(attr).and_return(datetime_sentinel)
          expect(email_body).to include(fhlb_date_standard_numeric(datetime_sentinel))
        end
      end
    end
  end

  describe '`letter_of_credit_request` email' do
    let(:call_method) { InternalMailer.letter_of_credit_request(member_id, letter_of_credit_json, user) }
    it_behaves_like 'a letter of credit request email', :letter_of_credit_request
  end

  describe '`letter_of_credit_amendment_request` email' do
    let(:call_method) { InternalMailer.letter_of_credit_amendment_request(member_id, letter_of_credit_json, user) }
    it_behaves_like 'a letter of credit request email', :letter_of_credit_request_amendment
  end

  describe '`beneficiary_request` email' do
    let(:beneficiary_json) { double('loc as json') }
    let(:member_id) { instance_double(String) }
    let(:id) { instance_double(String) }
    let(:request) { instance_double(String) }
    let(:contacts) { instance_double(String) }
    let(:member_id) { SecureRandom.hex }
    let(:name) { SecureRandom.hex }
    let(:fhfa_number) { SecureRandom.hex }
    let(:member_details) { instance_double(String) }
    let(:beneficiary_request) do
      instance_double(BeneficiaryRequest,
                      id: id,
                            name: nil,
                            street_address: nil,
                            city: nil,
                            state: nil,
                            zip: nil,
                            care_of: nil,
                            department: nil
      )
    end
    let(:display_name) { SecureRandom.hex }
    let(:user) { instance_double(User, email: "#{SecureRandom.hex}@example.com", display_name: display_name) }
    let(:build_mail) { mail :beneficiary_request, request, member_id, beneficiary_json, user }
    let(:call_method) { InternalMailer.beneficiary_request(request, member_id, beneficiary_json, user) }
    let(:rm) {{
      email: SecureRandom.hex,
      phone_number: ('1234567890'),
      full_name: SecureRandom.hex
    }}
    before do
      allow(BeneficiaryRequest).to receive(:from_json).and_return(beneficiary_request)
      allow_any_instance_of(MemberMailer).to receive(:member_contacts).and_return({rm: rm})
      allow_any_instance_of(MembersService).to receive(:member).with(member_id)
    end

    it 'includes the display name of the user in the `to` field' do
      build_mail
      expect(response.header_fields.select{ |header| header.name == 'To'}.first.value).to include(user.display_name)
    end
    it 'sends the email to the email address of the user' do
      build_mail
      expect(response.to.first).to eq(user.email)
    end
    it 'bcc\'s the bank on the sent email' do
      build_mail
      expect(response.bcc.first).to eq(InternalMailer::ADD_BENEFICIARY_ADDRESS)
    end
    it 'sets the `from` of the email' do
      build_mail
      expect(response.from.first).to eq(ContactInformationHelper::NO_REPLY_EMAIL)
    end
    it 'constructs a BeneficiaryRequest from the supplied JSON' do
      expect(BeneficiaryRequest).to receive(:from_json).with(beneficiary_json, nil).and_return(beneficiary_request)
      build_mail
    end
    it 'assigns the new instance of LetterOfCreditRequest to @letter_of_credit_request' do
      build_mail
      expect(assigns[:beneficiary_request]).to eq(beneficiary_request)
    end
    it 'assigns @requested_by to user.display_name' do
      build_mail
      expect(assigns[:requested_by]).to eq(display_name)
    end
    it 'assigns @created_at to now' do
      now = Time.zone.now
      allow(Time).to receive_message_chain(:zone, :now).and_return(now)
      build_mail
      expect(assigns[:created_at]).to eq(now)
    end
    describe 'member is found' do
      before do
        allow_any_instance_of(MembersService).to receive(:member).with(member_id).and_return(member_details)
        allow(member_details).to receive(:[]).with(:name).and_return(name)
        allow(member_details).to receive(:[]).with(:fhfa_number).and_return(fhfa_number)
      end
      it 'assigns @member_name_email to the name of the member if found' do
        build_mail
        expect(assigns[:member_name_email]).to be(name)
      end
      it 'assigns @fhfa to the fhfa_number of the member if found' do
        build_mail
        expect(assigns[:fhfa ]).to be(fhfa_number)
      end
    end
  end
end