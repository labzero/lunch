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

  describe '`operations_email` method' do
    it_behaves_like 'an email helper method', :operations_email, 'OPERATIONS_EMAIL'
  end
  describe '`accounting_email` method' do
    it_behaves_like 'an email helper method', :accounting_email, 'ACCOUNTING_EMAIL'
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

  %i(web_support_phone_number service_desk_phone_number operations_phone_number mcu_phone_number accounting_phone_number securities_services_phone_number).each do |helper_method|
    describe "`#{helper_method}` method" do
      let(:call_method) {helper.send(helper_method) }
      it "responds to `#{helper_method}`" do
        expect(helper).to respond_to(helper_method)
      end
      include_examples 'phone number contact method', helper_method.to_s.upcase
    end
  end
end