require 'rails_helper'

RSpec.describe InternalMailer, :type => :mailer do
  describe 'layout' do
    it 'should use the `mailer` layout' do
      expect(described_class._layout).to eq('mailer')
    end
  end

  describe '`calypso_error` email' do
    let(:error) { double('An Error', message: nil, backtrace: [], inspect: nil) }
    let(:request_id) { double('A Request ID') }
    let(:user) { double('A User', display_name: nil, username: nil) }
    let(:member) { double('A Member') }
    let(:build_mail) { mail :calypso_error, error, request_id, user, member }

    it 'assigns @error' do
      build_mail
      expect(assigns[:error]).to be(error)
    end
    it 'assigns @request_id' do
      build_mail
      expect(assigns[:request_id]).to be(request_id)
    end
    it 'assigns @member' do
      build_mail
      expect(assigns[:member]).to be(member)
    end
    it 'assigns @user to the `display_name` if found' do
      display_name = double('A Display Name')
      allow(user).to receive(:display_name).and_return(display_name)
      build_mail
      expect(assigns[:user]).to be(display_name)
    end
    it 'assigns @user to the `username` if display_name is not found' do
      username = double('A Username')
      allow(user).to receive(:username).and_return(username)
      build_mail
      expect(assigns[:user]).to be(username)
    end
    it 'assigns @user to the `username` if `display_name` raises an error' do
      username = double('A Username')
      allow(user).to receive(:display_name).and_raise('some error')
      allow(user).to receive(:username).and_return(username)
      build_mail
      expect(assigns[:user]).to be(username)
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
    it 'includes `@user` in the body' do
      allow(user).to receive(:display_name).and_return(SecureRandom.hex)
      build_mail
      expect(response.body).to match(user.display_name)
    end
    it 'includes `@request_id` in the body' do
      build_mail
      expect(response.body).to match(request_id.to_s)
    end
    it 'includes `@member` in the body' do
      build_mail
      expect(response.body).to match(member.to_s)
    end
    it 'sets the `subject` of the email' do
      build_mail
      expect(response.subject).to eq I18n.t('errors.emails.calypso_error.subject')
    end
    it 'sets the `to` of the email' do
      build_mail
      expect(response.to.first).to eq InternalMailer::GENERAL_ALERT_ADDRESS
    end
    it 'sets the `from` of the email' do
      build_mail
      expect(response.from.first).to eq InternalMailer::GENERAL_ALERT_ADDRESS
    end
  end
end