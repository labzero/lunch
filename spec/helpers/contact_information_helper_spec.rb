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

  describe '`web_support_phone_number` method' do
    let(:call_method) { helper.web_support_phone_number }
    it 'responds to `web_support_phone_number`' do
      expect(helper).to respond_to(:web_support_phone_number)
    end
    it 'calls `fhlb_formatted_phone_number` with the WEB_SUPPORT_PHONE_NUMBER' do
      phone_number = double('A Number')
      stub_const("#{described_class}::WEB_SUPPORT_PHONE_NUMBER", phone_number)
      expect(helper).to receive(:fhlb_formatted_phone_number).with(phone_number)
      call_method
    end
    it 'returns the formatted phone number' do
      formatted_phone_number = double('A Formatted Number')
      allow(helper).to receive(:fhlb_formatted_phone_number).and_return(formatted_phone_number)
      expect(call_method).to be(formatted_phone_number)
    end
  end

  describe '`service_desk_phone_number` method' do
    let(:call_method) { helper.service_desk_phone_number }
    it 'responds to `service_desk_phone_number`' do
      expect(helper).to respond_to(:service_desk_phone_number)
    end
    it 'calls `fhlb_formatted_phone_number` with the SERVICE_DESK_PHONE_NUMBER' do
      phone_number = double('A Number')
      stub_const("#{described_class}::SERVICE_DESK_PHONE_NUMBER", phone_number)
      expect(helper).to receive(:fhlb_formatted_phone_number).with(phone_number)
      call_method
    end
    it 'returns the formatted phone number' do
      formatted_phone_number = double('A Formatted Number')
      allow(helper).to receive(:fhlb_formatted_phone_number).and_return(formatted_phone_number)
      expect(call_method).to be(formatted_phone_number)
    end
  end
end