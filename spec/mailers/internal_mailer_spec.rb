require 'rails_helper'

RSpec.describe InternalMailer, :type => :mailer do
  describe 'layout' do
    it 'should use the `mailer` layout' do
      expect(described_class._layout).to eq('mailer')
    end
  end

  shared_examples 'an internal error notification email' do |message_subject|
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
    it_behaves_like 'an internal notification email', message_subject
  end

  shared_examples 'an internal notification email' do |message_subject|
    it 'sets the `to` of the email' do
      build_mail
      expect(response.to.first).to eq InternalMailer::GENERAL_ALERT_ADDRESS
    end
    it 'sets the `from` of the email' do
      build_mail
      expect(response.from.first).to eq InternalMailer::GENERAL_ALERT_ADDRESS
    end
    it 'sets the `subject` of the email' do
      build_mail
      expect(response.subject).to eq message_subject
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

    it_behaves_like 'an internal notification email', I18n.t('emails.long_term_advance.subject', amount: formatted_amount, term: term)
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

  describe '`user_name_from_user` protected method' do
    subject { described_class.send :new }
    let(:user) { double('A User', display_name: nil, username: nil)}
    let(:call_method) { subject.send(:user_name_from_user, user) }

    it 'returns the user directly if its a string' do
      user = double('A String')
      allow(user).to receive(:is_a?).with(String).and_return(true)
      expect(subject.send(:user_name_from_user, user)).to be(user)
    end
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
end