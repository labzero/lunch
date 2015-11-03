require 'rails_helper'

describe ContactInformationHelper, type: :helper do
  describe '`web_support_email` method' do
    let(:call_method) { helper.web_support_email }
    it 'responds to `web_support_email`' do
      expect(helper).to respond_to(:web_support_email)
    end
    it 'returns a mailto URL' do
      uri = URI(call_method)
      expect(uri.scheme).to eq('mailto')
    end
    it 'has the WEB_SUPPORT_EMAIL as the primary To: email' do
      email = "#{SecureRandom.hex}@example.com"
      stub_const("#{described_class}::WEB_SUPPORT_EMAIL", email)
      uri = URI(call_method)
      expect(uri.to).to eq(email)
    end
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