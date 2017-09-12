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

  describe '`securities_services_email` method' do
    it_behaves_like 'an email helper method', :securities_services_email, 'SECURITIES_SERVICES_EMAIL'
  end

  describe '`collateral_operations_email` method' do
    it_behaves_like 'an email helper method', :collateral_operations_email, 'COLLATERAL_OPERATIONS_EMAIL'
  end

  describe '`loc_email` method' do
    it_behaves_like 'an email helper method', :loc_email, 'LOC_EMAIL'
  end

  describe '`securities_services_email_text` method' do
    let(:call_method) { helper.send(:securities_services_email_text) }
    it 'responds to `securities_services_email_text`' do
      expect(helper).to respond_to(:securities_services_email_text)
    end
    it 'returns `SECURITIES_SERVICES_EMAIL`' do
      expect(call_method).to eq(described_class::SECURITIES_SERVICES_EMAIL)
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

  %i(web_support_phone_number service_desk_phone_number operations_phone_number mcu_phone_number accounting_phone_number securities_services_phone_number collateral_operations_phone_number member_services_phone_number collateral_fees_phone_number).each do |helper_method|
    describe "`#{helper_method}` method" do
      let(:call_method) {helper.send(helper_method) }
      it "responds to `#{helper_method}`" do
        expect(helper).to respond_to(helper_method)
      end
      include_examples 'phone number contact method', helper_method.to_s.upcase
    end
  end

  describe '`feedback_survey_url` method' do
    let(:display_name) { SecureRandom.hex }
    let(:email) { "#{SecureRandom.hex}@#{SecureRandom.hex}.com" }
    let(:user) { instance_double(User, display_name: display_name, email: email) }
    let(:member_name) { SecureRandom.hex }

    it 'raises an `ArgumentError` if `user` is `nil`' do
      expect { helper.send(:feedback_survey_url, nil, member_name) }.to raise_error(ArgumentError, "user parameter must not be nil")
    end

    it 'constructs an URL from the parameters passed in' do
      expect(helper.send(:feedback_survey_url, user, member_name)).to eq(
        "https://www.surveymonkey.com/r/7KYSNVN?#{{member: member_name, name: display_name, email: email}.to_query}")
    end
  end

  describe 'the `member_contacts` method' do
    let(:helper_instance) { mock_context(described_class, instance_methods: [:current_member_id, :request]) }
    let(:request_obj) { double('request') }
    let(:member_id) { double('member id') }
    let(:member_service) { instance_double(MembersService, member_contacts: nil) }
    let(:cached_contacts) { double('contacts') }
    let(:call_method) { helper_instance.member_contacts(request_obj: request_obj, member_id: member_id) }
    before do
      allow(helper_instance).to receive(:current_member_id).and_return(member_id)
      allow(helper_instance).to receive(:request).and_return(request_obj)
      allow(MembersService).to receive(:new).and_return(member_service)
    end

    it 'uses the `request` method to populate the `request` arg if none is provided' do
      expect(helper_instance).to receive(:request).and_return(request_obj)
      helper_instance.member_contacts(member_id: member_id)
    end
    it 'uses the `current_member_id` method to populate the `member_id` arg if none is provided' do
      expect(helper_instance).to receive(:current_member_id).and_return(member_id)
      helper_instance.member_contacts(request_obj: request_obj)
    end
    it 'fetches the value from the cache with the correct key' do
      expect(Rails.cache).to receive(:fetch).with(CacheConfiguration.key(:member_contacts, member_id), anything)
      call_method
    end
    it 'fetches the value from the cache with the correct expiration' do
      expect(Rails.cache).to receive(:fetch).with(anything, expires_in: CacheConfiguration.expiry(:member_contacts))
      call_method
    end
    it 'returns the result of accessing the cache' do
      allow(Rails.cache).to receive(:fetch).and_return(cached_contacts)
      expect(call_method).to eq(cached_contacts)
    end
    it 'returns an empty hash if calling the cache returns nil' do
      allow(Rails.cache).to receive(:fetch).and_return(nil)
      expect(call_method).to eq({})
    end
    describe 'when there is a cached value' do
      it 'does not create a new instance of MembersService' do
        call_method
        expect(MembersService).not_to receive(:new)
        call_method
      end
    end
    describe 'when there is no cached value' do
      it 'creates a new instance of MemberService with the request' do
        expect(MembersService).to receive(:new).with(request_obj).and_return(member_service)
        call_method
      end
      it 'calls `MemberService#member_contacts` with the `current_member_id`' do
        expect(member_service).to receive(:member_contacts).with(member_id)
        call_method
      end
      it 'caches the call to the service' do
        expect(member_service).to receive(:member_contacts).exactly(:once).and_return(cached_contacts)
        call_method
        call_method
      end
    end
  end
end