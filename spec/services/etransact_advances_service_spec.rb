require 'spec_helper'

describe EtransactAdvancesService do
  subject { EtransactAdvancesService.new(double('request', uuid: '12345')) }
  it { expect(subject).to respond_to(:etransact_active?) }
  describe '`etransact_active?` method', :vcr do
    let(:call_method) {subject.etransact_active?(status_object)}
    let(:status_object) { {etransact_advances_status: 'my_status'} }
    it 'returns the value of `etransact_advances_status` from the status object' do
      expect(call_method).to eq('my_status')
    end
    it 'should call EtransactAdvancesService#status if no status object is provided' do
      expect(subject).to receive(:status)
      subject.etransact_active?
    end
    it 'should return false if EtransactAdvancesService#status returns nil' do
      allow(subject).to receive(:status).and_return(nil)
      expect(subject.etransact_active?).to be(false)
    end
    it 'should not call EtransactAdvancesService#status if a status object is provided' do
      expect(subject).to_not receive(:status)
      call_method
    end
    it 'should use the supplied status object' do
      expect(status_object).to receive(:[]).with(:etransact_advances_status).and_return(status_object[:etransact_advances_status])
      call_method
    end
    it 'should use the returned status object if none is passed' do
      expect(status_object).to receive(:[]).with(:etransact_advances_status).and_return(status_object[:etransact_advances_status])
      allow(subject).to receive(:status).and_return(status_object)
      subject.etransact_active?
    end
  end
  describe '`signer_full_name` method', :vcr do
    let(:signer) {'signer'}
    let(:signer_full_name) {subject.signer_full_name(signer)}
    it 'should return signer full name' do
      expect(signer_full_name).to be_kind_of(String)
    end
    it 'should return nil if there was an API error' do
      expect_any_instance_of(RestClient::Resource).to receive(:get).and_raise(RestClient::InternalServerError)
      expect(signer_full_name).to eq(nil)
    end
    it 'should return nil if there was a connection error' do
      expect_any_instance_of(RestClient::Resource).to receive(:get).and_raise(Errno::ECONNREFUSED)
      expect(signer_full_name).to eq(nil)
    end
  end
  describe '`quick_advance_validate` method', :vcr do
    let(:signer) {'signer'}
    let(:member_id) {750}
    let(:advance_term) {'someterm'}
    let(:advance_type) {'sometype'}
    let(:advance_rate) {'0.17'}
    let(:check_capstock) {true}
    let(:amount) { 100 }
    let(:quick_advance_validate) {subject.quick_advance_validate(member_id, amount, advance_type, advance_term, advance_rate, check_capstock, signer)}
    it 'should return a hash back' do
      expect(quick_advance_validate).to be_kind_of(Hash)
    end
    it 'should return nil if there was an API error' do
      allow_any_instance_of(RestClient::Resource).to receive(:get).and_raise(RestClient::InternalServerError)
      expect(quick_advance_validate).to eq(nil)
    end
    it 'should return nil if there was a connection error' do
      allow_any_instance_of(RestClient::Resource).to receive(:get).and_raise(Errno::ECONNREFUSED)
      expect(quick_advance_validate).to eq(nil)
    end
    it 'returns nil if there is a JSON parsing error' do
      allow(JSON).to receive(:parse).and_raise(JSON::ParserError)
      allow(Rails.logger).to receive(:warn)
      expect(quick_advance_validate).to be(nil)
    end
    it 'should URL encode the signer' do
      expect(URI).to receive(:escape).with(signer)
      quick_advance_validate
    end
  end
  describe '`quick_advance_execute` method', :vcr do
    let(:signer) {'signer'}
    let(:member_id) {750}
    let(:advance_term) {'someterm'}
    let(:advance_type) {'sometype'}
    let(:advance_rate) {'0.17'}
    let(:amount) { 100 }
    let(:quick_advance_execute) {subject.quick_advance_execute(member_id, amount, advance_type, advance_term, advance_rate, signer)}
    it 'should return a hash back' do
      expect(quick_advance_execute).to be_kind_of(Hash)
    end
    it 'should set initiated_at' do
      expect(quick_advance_execute[:initiated_at]).to be_kind_of(DateTime)
    end
    it 'returns nil if there is a JSON parsing error' do
      allow(JSON).to receive(:parse).and_raise(JSON::ParserError)
      allow(Rails.logger).to receive(:warn)
      expect(quick_advance_execute).to be(nil)
    end
    it 'should return nil if there was an API error' do
      allow_any_instance_of(RestClient::Resource).to receive(:post).and_raise(RestClient::InternalServerError)
      expect(quick_advance_execute).to eq(nil)
    end
    it 'should return nil if there was a connection error' do
      allow_any_instance_of(RestClient::Resource).to receive(:post).and_raise(Errno::ECONNREFUSED)
      expect(quick_advance_execute).to eq(nil)
    end
    it 'should URL encode the signer' do
      expect(URI).to receive(:escape).with(signer)
      quick_advance_execute
    end
  end
  describe '`check_limits` method', :vcr do
    let(:advance_term) {'someterm'}
    let(:amount) { 100 }
    let(:check_limits) {subject.check_limits(amount, advance_term)}
    it 'should return a hash back' do
      expect(check_limits).to be_kind_of(Hash)
    end
    it 'should return nil if there was an API error' do
      allow_any_instance_of(RestClient::Resource).to receive(:get).and_raise(RestClient::InternalServerError)
      expect(check_limits).to eq(nil)
    end
    it 'should return nil if there was a connection error' do
      allow_any_instance_of(RestClient::Resource).to receive(:get).and_raise(Errno::ECONNREFUSED)
      expect(check_limits).to eq(nil)
    end
    it 'returns nil if there is a JSON parsing error' do
      allow(JSON).to receive(:parse).and_raise(JSON::ParserError)
      allow(Rails.logger).to receive(:warn)
      expect(check_limits).to be(nil)
    end
  end

  describe '`status` method', :vcr do
    let(:call_method) {subject.status}
    it_should_behave_like 'a MAPI backed service object method', :status
    it 'should return the MAPI response object' do
      response_object = double('A MAPI Response Object')
      allow(response_object).to receive(:with_indifferent_access).and_return(response_object)
      allow(JSON).to receive(:parse).and_return(response_object)
      expect(call_method).to be(response_object)
    end
  end

  describe '`has_terms?` method', :vcr do
    let(:call_method) {subject.has_terms?(status_object)}
    let(:status_object) { {all_loan_status: {foo: {bar: {trade_status: true, display_status: true}}}} }
    it 'should return true if at least one term is found, displayable, and tradeable' do
      expect(call_method).to be(true)
    end
    it 'should return false if none of the terms are found' do
      status_object[:all_loan_status] = {}
      expect(call_method).to be(false)
    end
    it 'should return false if none of the terms are displayable' do
      status_object[:all_loan_status] = {foo: {bar: {trade_status: true, display_status: false}}}
      expect(call_method).to be(false)
    end
    it 'should return false if none of the terms are tradeable' do
      status_object[:all_loan_status] = {foo: {bar: {trade_status: false, display_status: true}}}
      expect(call_method).to be(false)
    end
    it 'should call EtransactAdvancesService#status if no status object is provided' do
      expect(subject).to receive(:status)
      subject.has_terms?
    end
    it 'should return false if EtransactAdvancesService#status returns nil' do
      allow(subject).to receive(:status).and_return(nil)
      expect(subject.has_terms?).to be(false)
    end
    it 'should not call EtransactAdvancesService#status if a status object is provided' do
      expect(subject).to_not receive(:status)
      call_method
    end
    it 'should use the supplied status object' do
      expect(status_object).to receive(:[]).with(:all_loan_status).and_return(status_object[:all_loan_status])
      call_method
    end
    it 'should use the returned status object if none is passed' do
      expect(status_object).to receive(:[]).with(:all_loan_status).and_return(status_object[:all_loan_status])
      allow(subject).to receive(:status).and_return(status_object)
      subject.has_terms?
    end
  end
end