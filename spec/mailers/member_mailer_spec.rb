require 'rails_helper'

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
end