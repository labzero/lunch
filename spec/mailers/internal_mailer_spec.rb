require 'rails_helper'
include ContactInformationHelper
include CustomFormattingHelper
include ActionView::Helpers::TextHelper

RSpec.describe InternalMailer, :type => :mailer do
  describe 'layout' do
    it 'should use the `mailer` layout' do
      expect(described_class._layout).to eq('mailer')
    end
  end

  shared_examples 'an internal error notification email' do |message_subject, address=InternalMailer::GENERAL_ALERT_ADDRESS|
    it 'assigns @user to the return of `user_name_from_user`' do
      a_name = double('Some Name')
      allow_any_instance_of(described_class).to receive(:user_name_from_user).and_return(a_name)
      build_mail
      expect(assigns[:user]).to be(a_name)
    end
    it 'assigns @request_id' do
      build_mail
      expect(assigns[:request_id]).to be(request_id)
    end
    it 'includes `@user` in the body' do
      allow(user).to receive(:display_name).and_return(SecureRandom.hex)
      build_mail
      expect(response.body).to match(user.display_name)
    end
    it 'includes `@request_id` in the body' do
      build_mail
      expect(response.body).to match(request_id.to_s)
    end
    it_behaves_like 'an internal notification email', message_subject, address
  end

  shared_examples 'an internal notification email' do |message_subject, address=InternalMailer::GENERAL_ALERT_ADDRESS|
    it 'sets the `to` of the email' do
      build_mail
      expect(response.to.first).to eq(address)
    end
    it 'sets the `from` of the email' do
      build_mail
      expect(response.from.first).to eq(address)
    end
    it 'sets the `subject` of the email' do
      build_mail
      expect(response.subject).to eq(message_subject)
    end
  end

  describe '`calypso_error` email' do
    let(:error) { double('An Error', message: nil, backtrace: [], inspect: nil) }
    let(:request_id) { double('A Request ID', to_s: SecureRandom.hex) }
    let(:user) { double('A User', display_name: nil, username: nil) }
    let(:member) { double('A Member', to_s: SecureRandom.hex) }
    let(:build_mail) { mail :calypso_error, error, request_id, user, member }

    it_behaves_like 'an internal error notification email', I18n.t('errors.emails.calypso_error.subject')

    it 'assigns @error' do
      build_mail
      expect(assigns[:error]).to be(error)
    end
    it 'assigns @member' do
      build_mail
      expect(assigns[:member]).to be(member)
    end
    [:message, :class, :inspect].each do |method|
      it "includes the `#{method}` of the error in the body" do
        allow(error).to receive(method).and_return(SecureRandom.hex)
        build_mail
        expect(response.body).to match(error.send(method))
      end
    end
    it 'includes the `backtrace` of the error in the body' do
      allow(error).to receive(:backtrace).and_return([SecureRandom.hex, SecureRandom.hex])
      build_mail
      expect(response.body).to match(error.send(:backtrace).join("\n"))
    end
    it 'includes `@member` in the body' do
      build_mail
      expect(response.body).to match(member.to_s)
    end
  end

  describe '`stale_rate` email' do
    let(:request_id) { double('A Request ID', to_s: SecureRandom.hex) }
    let(:user) { double('A User', display_name: nil, username: nil) }
    let(:rate_timeout) { double('A Rate Timeout', to_s: SecureRandom.hex) }
    let(:build_mail) { mail :stale_rate, rate_timeout, request_id, user }

    it_behaves_like 'an internal error notification email', I18n.t('errors.emails.stale_rate.subject')

    it 'assigns @rate_timeout' do
      build_mail
      expect(assigns[:rate_timeout]).to be(rate_timeout)
    end
    it 'includes `@rate_timeout` in the body' do
      build_mail
      expect(response.body).to match(rate_timeout.to_s)
    end
  end

  describe '`exceeds_rate_band` email' do
    let(:request_id) { double('A Request ID', to_s: SecureRandom.hex) }
    let(:user) { double('A User', display_name: nil, username: nil) }
    let(:rate_info) { double('Some rate info', :[] => nil) }
    let(:build_mail) { mail :exceeds_rate_band, rate_info, request_id, user }
    before { allow(rate_info).to receive(:[]).with(:rate_band_info).and_return({}) }

    it_behaves_like 'an internal error notification email', I18n.t('errors.emails.exceeds_rate_band.subject')

    it 'assigns @rate_info' do
      build_mail
      expect(assigns[:rate_info]).to be(rate_info)
    end
  end

  describe '`long_term_advance` email' do
    include CustomFormattingHelper
    formatted_amount = SecureRandom.hex
    term = SecureRandom.hex
    let(:advance) { double(AdvanceRequest) }
    let(:build_mail) { mail :long_term_advance, advance }
    let(:confirmation_number) { double('A Confirmation Number') }
    let(:trade_date) { Date.new(2012, 10, 11) }
    let(:funding_date) { Date.new(2012, 10, 12) }
    let(:maturity_date) { Date.new(2012, 10, 13) }
    let(:signer) { SecureRandom.hex }
    let(:type) { double('A Type') }
    let(:term) { term }
    let(:rate) { double('A Rate') }
    let(:amount) { rand(1000000..2000000) }
    let(:formatted_amount) { formatted_amount }
    let(:member_id) { double('A Member ID') }
    let(:member_name) { double('A Member Name') }
    let(:request) { double('A Request') }
    let(:members_service) { double(MembersService) }
    let(:formatted_amount_html) { fhlb_formatted_currency(amount) }
    let(:formatted_trade_date) { fhlb_date_standard_numeric(trade_date) }
    let(:formatted_maturity_date) { fhlb_date_standard_numeric(maturity_date) }
    let(:formatted_funding_date) { fhlb_date_standard_numeric(funding_date) }

    before do
      allow(advance).to receive(:confirmation_number).and_return(confirmation_number)
      allow(advance).to receive(:trade_date).and_return(trade_date)
      allow(advance).to receive(:funding_date).and_return(funding_date)
      allow(advance).to receive(:maturity_date).and_return(maturity_date)
      allow(advance).to receive(:signer).and_return(signer)
      allow(advance).to receive(:human_type).and_return(type)
      allow(advance).to receive(:human_term).and_return(term)
      allow(advance).to receive(:rate).and_return(rate)
      allow(advance).to receive(:total_amount).and_return(amount)
      allow(advance).to receive(:member_id).and_return(member_id)
      allow(advance).to receive(:request).and_return(request)
      allow(MembersService).to receive(:new).and_return(members_service)
      allow(members_service).to receive(:member).with(member_id).and_return({name: member_name})
      allow_any_instance_of(described_class).to receive(:fhlb_formatted_currency).with(amount, anything).and_return(formatted_amount)
    end

    it_behaves_like 'an internal notification email', I18n.t('emails.long_term_advance.subject', amount: formatted_amount, term: term), InternalMailer::WEB_TRADE_ALERT_ADDRESS
    [:advance, :confirmation_number, :trade_date, :funding_date, :maturity_date, :signer, :type, :term, :rate, :member_id, :member_name, :amount].each do |param|
      it "assigns @#{param}" do
        build_mail
        expect(assigns[param]).to eq(send(param))
      end
    end

    {
      confirmation_number: :confirmation_number,
      trade_date: :formatted_trade_date,
      funding_date: :formatted_funding_date,
      maturity_date: :formatted_maturity_date,
      signer: :signer,
      type: :type,
      term: :term,
      rate: :rate,
      member_id: :member_id,
      member_name: :member_name,
      amount: :formatted_amount_html
      }.each do |param, value|
        it "includes @#{param} in the message" do
          target_value = send(value)
          unless target_value.is_a?(String)
            string_value = SecureRandom.hex
            allow(target_value).to receive(:to_s).and_return(string_value)
            target_value = string_value
          end
          build_mail
          expect(response.body).to include(target_value)
        end
      end
  end

  describe '`quick_report_status` email' do
    completed = rand(1..499)
    total = rand(500..999)
    let(:start_time) { Time.zone.now }
    let(:end_time) { start_time + rand(1..5).minutes }
    let(:completed) { completed }
    let(:total) { total }
    let(:build_mail) { mail :quick_report_status, start_time, end_time, completed, total }

    it_behaves_like 'an internal notification email', I18n.t('emails.quick_report_status.subject', completed: completed, total: total)

    it 'assigns @start_time' do
      build_mail
      expect(assigns[:start_time]).to be(start_time)
    end
    it 'assigns @end_time' do
      build_mail
      expect(assigns[:end_time]).to be(end_time)
    end
    it 'assigns @completed' do
      build_mail
      expect(assigns[:completed]).to be(completed)
    end
    it 'assigns @total' do
      build_mail
      expect(assigns[:total]).to be(total)
    end
  end

  describe '`quick_report_long_run` email' do
    let(:completed) { rand(1..499) }
    let(:total) { rand(500..999) }
    let(:build_mail) { mail :quick_report_long_run, completed, total }

    it_behaves_like 'an internal notification email', I18n.t('emails.quick_report_long_run.subject')

    it 'assigns @completed' do
      build_mail
      expect(assigns[:completed]).to be(completed)
    end
    it 'assigns @total' do
      build_mail
      expect(assigns[:total]).to be(total)
    end
  end

  describe '`securities_request_authorized` email' do
    let(:kind) { SecuritiesRequest::KINDS.sample }
    let(:member_name) { SecureRandom.hex }
    let(:securities_request) { double(SecuritiesRequest,
                                      member_id: rand(9999..99999),
                                      kind: kind,
                                      is_collateral?: [true, false].sample ) }
    let(:member) { double(Member) }
    let(:members_service) { double(MembersService, member: member) }
    let(:build_mail) { mail :securities_request_authorized, securities_request }

    before do
      allow(MembersService).to receive(:new).and_return(members_service)
      allow(member).to receive(:[]).with(:name).and_return(member_name)
    end

    it 'assigns `@securites_request` to `securities_request`' do
      build_mail
      expect(assigns[:securities_request]).to eq(securities_request)
    end

    it 'assigns `@member_name`' do
      build_mail
      expect(assigns[:member_name]).to eq(member_name)
    end

    it 'assigns `@member_name` to a description of the member ID if the name could not be found' do
      allow(member).to receive(:[]).with(:name).and_return(nil)    
      build_mail
      expect(assigns[:member_name]).to eq(I18n.t('emails.securities_request.authorized.member_id', member_id: securities_request.member_id))
    end

    it 'sets the `To:` header to `InternalMailer::COLLATERAL_OPERATIONS` for pledged and transfered securities' do
      allow(securities_request).to receive(:is_collateral?).and_return(true)
      build_mail
      expect(response.to.first).to eq(InternalMailer::COLLATERAL_OPERATIONS)
    end

    it 'sets the `To:` header to `InternalMailer::SECURITIES_SERVICES` for safekept securities' do
      allow(securities_request).to receive(:is_collateral?).and_return(false)
      build_mail
      expect(response.to.first).to eq(InternalMailer::SECURITIES_SERVICES)
    end

    it 'sets the `From:` header' do
      build_mail
      expect(response.from.first).to eq(InternalMailer::WEB_SECURITIES)
    end

    it 'sets the `Subject:` header for pledged collateral' do
      allow(securities_request).to receive(:is_collateral?).and_return(true)
      build_mail
      expect(response.subject).to eq(I18n.t('emails.securities_request.authorized.subject',
        pledge_or_safekeeping: I18n.t('emails.securities_request.authorized.pledge').upcase))
    end

    it 'sets the `Subject:` header for safekept securities' do
      allow(securities_request).to receive(:is_collateral?).and_return(false)
      build_mail
      expect(response.subject).to eq(I18n.t('emails.securities_request.authorized.subject',
        pledge_or_safekeeping: I18n.t('emails.securities_request.authorized.safekeeping').upcase))
    end

    [ :pledge_release, 
      :safekept_release, 
      :pledge_intake, 
      :safekept_intake ].each do |kind|
      describe "setting the email body when `kind` is `#{kind}`" do
        let(:kind) { kind }

        it "assigns `@pledge_or_safekeeping` based on `kind`" do
          build_mail
          expect(assigns[:pledge_or_safekeeping]).to eq(I18n.t("emails.securities_request.authorized.#{kind}"))
        end

        it "produces the correct body for `#{kind}`" do
          build_mail
          expect(response.body.to_s).to match(I18n.t('emails.securities_request.authorized.body',
            member_name: member_name,
            pledge_or_safekeeping: I18n.t("emails.securities_request.authorized.#{kind}")))
        end
      end
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
                      issue_date: nil,
                      expiration_date: nil,
                      issuance_fee: nil,
                      maintenance_fee:nil
      )
    end
    let(:user) { instance_double(User) }
    let(:filename) { "letter_of_credit_request_#{letter_of_credit_request.lc_number}" }
    let(:file) { instance_double(StringIOWithFilename, original_filename: filename, read: File.read(Rails.root.join('spec', 'fixtures', 'letter_of_credit_request_sample.pdf'))) }
    let(:build_mail) { mail :letter_of_credit_request, member_id, letter_of_credit_json, user }
    let(:call_method) { InternalMailer.letter_of_credit_request(member_id, letter_of_credit_json, user) }

    before do
      allow(LetterOfCreditRequest).to receive(:from_json).and_return(letter_of_credit_request)
      allow(RenderLetterOfCreditPDFJob).to receive(:perform_now).and_return(file)
    end

    it 'sets the `to` of the email' do
      build_mail
      expect(response.to.first).to eq(described_class::GENERAL_ALERT_ADDRESS)
    end
    it 'sets the `from` of the email' do
      build_mail
      expect(response.from.first).to eq(ContactInformationHelper::WEB_SUPPORT_EMAIL)
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
      [:created_by, :lc_number, :beneficiary_name, :beneficiary_address, :maintenance_fee].each do |attr|
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

  describe '`user_name_from_user` protected method' do
    subject { described_class.send :new }
    let(:user) { double('A User', display_name: nil, username: nil)}
    let(:user_id) { rand(1000..10000).to_s }
    let(:call_method) { subject.send(:user_name_from_user, user) }

    shared_examples 'handles a `User` instance' do
      it 'return the `display_name` if found' do
        display_name = double('A Display Name')
        allow(user).to receive(:display_name).and_return(display_name)
        expect(call_method).to be(display_name)
      end

      it 'returns the `username` if display_name is not found' do
        username = double('A Username')
        allow(user).to receive(:username).and_return(username)
        expect(call_method).to be(username)
      end
      
      it 'returns the `username` if `display_name` raises an error' do
        username = double('A Username')
        allow(user).to receive(:display_name).and_raise('some error')
        allow(user).to receive(:username).and_return(username)
        expect(call_method).to be(username)
      end
    end

    include_examples 'handles a `User` instance'

    it 'returns the user directly if its a string' do
      user = double('A String')
      allow(user).to receive(:is_a?).with(String).and_return(true)
      expect(subject.send(:user_name_from_user, user)).to be(user)
    end

    it 'returns the global unknown string if passed nil' do
      expect(subject.send(:user_name_from_user, nil)).to eq(I18n.t('global.unknown'))
    end

    describe 'if a user ID is supplied' do
      let(:call_method) { subject.send(:user_name_from_user, user_id) }

      before do
        allow(User).to receive(:find).with(user_id).and_return(user)
      end

      it 'searches for the indicated user' do
        expect(User).to receive(:find).with(user_id).and_return(user)
        call_method
      end

      it 'returns the user ID if the user was not found' do
        allow(User).to receive(:find).with(user_id).and_raise(ActiveRecord::RecordNotFound)
        expect(call_method).to be(user_id)
      end

      include_examples 'handles a `User` instance'
    end
  end
end