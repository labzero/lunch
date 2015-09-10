require 'rails_helper'

RSpec.describe FHLBMailer, :type => :mailer do
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
end