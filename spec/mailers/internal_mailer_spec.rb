require 'rails_helper'

RSpec.describe InternalMailer, :type => :mailer do
  describe 'layout' do
    it 'should use the `mailer` layout' do
      expect(described_class._layout).to eq('mailer')
    end
  end

  shared_examples 'an internal notification email' do |message_subject|
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
    let(:request_id) { double('A Request ID') }
    let(:user) { double('A User', display_name: nil, username: nil) }
    let(:member) { double('A Member') }
    let(:build_mail) { mail :calypso_error, error, request_id, user, member }

    it_behaves_like 'an internal notification email', I18n.t('errors.emails.calypso_error.subject')

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
    let(:request_id) { double('A Request ID') }
    let(:user) { double('A User', display_name: nil, username: nil) }
    let(:rate_timeout) { double('A Rate Timeout') }
    let(:build_mail) { mail :stale_rate, rate_timeout, request_id, user }

    it_behaves_like 'an internal notification email', I18n.t('errors.emails.stale_rate.subject')

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
    let(:request_id) { double('A Request ID') }
    let(:user) { double('A User', display_name: nil, username: nil) }
    let(:rate_info) { double('Some rate info', :[] => nil) }
    let(:build_mail) { mail :exceeds_rate_band, rate_info, request_id, user }
    before { allow(rate_info).to receive(:[]).with(:rate_band_info).and_return({}) }

    it_behaves_like 'an internal notification email', I18n.t('errors.emails.exceeds_rate_band.subject')
    
    it 'assigns @rate_info' do
      build_mail
      expect(assigns[:rate_info]).to be(rate_info)
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