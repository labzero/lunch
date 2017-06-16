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

  describe '`letter_of_credit_request` email' do
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
                      attention: nil,
                      issue_date: nil,
                      expiration_date: nil,
                      issuance_fee: nil,
                      maintenance_fee:nil
      )
    end
    let(:user) { instance_double(User, email: "#{SecureRandom.hex}@example.com", display_name: SecureRandom.hex) }
    let(:filename) { "letter_of_credit_request_#{letter_of_credit_request.lc_number}" }
    let(:file) { instance_double(StringIOWithFilename, original_filename: filename, read: File.read(Rails.root.join('spec', 'fixtures', 'letter_of_credit_request_sample.pdf'))) }
    let(:build_mail) { mail :letter_of_credit_request, member_id, letter_of_credit_json, user }
    let(:call_method) { InternalMailer.letter_of_credit_request(member_id, letter_of_credit_json, user) }

    before do
      allow(LetterOfCreditRequest).to receive(:from_json).and_return(letter_of_credit_request)
      allow(RenderLetterOfCreditPDFJob).to receive(:perform_now).and_return(file)
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
      build_mail
      expect(response.subject).to eq(I18n.t('letters_of_credit.email.subject'))
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
    it 'calls `RenderLetterOfCreditPDFJob.perform_now` with `view` specified as its action' do
      expect(RenderLetterOfCreditPDFJob).to receive(:perform_now).with(anything, 'view', any_args).and_return(file)
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
        expect(email_body).to include(simple_format(I18n.t('letters_of_credit.email.body', phone_number: member_services_phone_number)))
      end
      it 'includes the correctly formatted `created_at` datetime' do
        allow(letter_of_credit_request).to receive(:created_at).and_return(datetime_sentinel)
        expect(email_body).to include(fhlb_datetime_standard_numeric_with_at(datetime_sentinel))
      end
      [:created_by, :lc_number, :beneficiary_name, :beneficiary_address, :maintenance_fee, :attention].each do |attr|
        it "includes the `#{attr}` attribute" do
          allow(letter_of_credit_request).to receive(attr).and_return(string_sentinel)
          expect(email_body).to include(string_sentinel)
        end
      end
      [:amount, :issuance_fee].each do |attr|
        it "includes the correctly formatted `#{attr}` attribute" do
          allow(letter_of_credit_request).to receive(attr).and_return(integer_sentinel)
          expect(email_body).to include(fhlb_formatted_currency_whole(integer_sentinel))
        end
      end
      [:issue_date, :expiration_date].each do |attr|
        it "includes the correctly formatted `#{attr}` attribute" do
          allow(letter_of_credit_request).to receive(attr).and_return(datetime_sentinel)
          expect(email_body).to include(fhlb_date_standard_numeric(datetime_sentinel))
        end
      end
    end
  end
end