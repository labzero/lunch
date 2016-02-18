require 'rails_helper'

describe ContactInformationHelper, type: :helper do
  RSpec.shared_examples 'an email helper method' do |method, constant|
    describe "`#{method}` method" do
      let(:call_method) { helper.send(method) }
      it "responds to `#{method}`" do
        expect(helper).to respond_to(method)
      end
      it 'returns a mailto URL' do
        uri = URI(call_method)
        expect(uri.scheme).to eq('mailto')
      end
      it "has the #{constant} as the primary To: email" do
        email = "#{SecureRandom.hex}@example.com"
        stub_const("#{described_class}::#{constant}", email)
        uri = URI(call_method)
        expect(uri.to).to eq(email)
      end
    end
  end

  describe '`web_support_email` method' do
    it_behaves_like 'an email helper method', :web_support_email, 'WEB_SUPPORT_EMAIL'
  end

  describe '`mpf_support_email` method' do
    it_behaves_like 'an email helper method', :mpf_support_email, 'MPF_SUPPORT_EMAIL'
  end

  describe '`membership_email` method' do
    it_behaves_like 'an email helper method', :membership_email, 'MEMBERSHIP_EMAIL'
  end

  shared_examples 'phone number contact method' do |constant|
    it "calls `fhlb_formatted_phone_number` with the #{constant}" do
      phone_number = double('A Number')
      stub_const("#{described_class}::#{constant}", phone_number)
      expect(helper).to receive(:fhlb_formatted_phone_number).with(phone_number)
      call_method
    end
    it 'returns the formatted phone number' do
      formatted_phone_number = double('A Formatted Number')
      allow(helper).to receive(:fhlb_formatted_phone_number).and_return(formatted_phone_number)
      expect(call_method).to be(formatted_phone_number)
    end
  end

  describe '`web_support_phone_number` method' do
    let(:call_method) { helper.web_support_phone_number }
    it 'responds to `web_support_phone_number`' do
      expect(helper).to respond_to(:web_support_phone_number)
    end
    include_examples 'phone number contact method', 'WEB_SUPPORT_PHONE_NUMBER' 
  end

  describe '`service_desk_phone_number` method' do
    let(:call_method) { helper.service_desk_phone_number }
    it 'responds to `service_desk_phone_number`' do
      expect(helper).to respond_to(:service_desk_phone_number)
    end
    include_examples 'phone number contact method', 'SERVICE_DESK_PHONE_NUMBER'
  end

  describe '`operations_phone_number` method' do
    let(:call_method) { helper.operations_phone_number }
    it 'responds to `operations_phone_number`' do
      expect(helper).to respond_to(:operations_phone_number)
    end
    include_examples 'phone number contact method', 'OPERATIONS_PHONE_NUMBER'
  end

  describe '`mcu_phone_number` method' do
    let(:call_method) { helper.mcu_phone_number }
    it 'responds to `mcu_phone_number`' do
      expect(helper).to respond_to(:mcu_phone_number)
    end
    include_examples 'phone number contact method', 'MCU_PHONE_NUMBER'
  end
end