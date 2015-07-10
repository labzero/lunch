require 'spec_helper'

describe EtransactAdvancesService do
  subject { EtransactAdvancesService.new(double('request', uuid: '12345')) }
  it { expect(subject).to respond_to(:etransact_active?) }
  describe '`etransact_active? method`', :vcr do
    let(:status) {subject.etransact_active?}
    let(:json_response) { {etransact_advances_status: 'my_status'}.to_json }
    let (:mapi_response) {double('MAPI_response', body: json_response)}
    it 'returns the value of `etransact_advances_status` from a hash built from the JSON response' do
      expect_any_instance_of(RestClient::Resource).to receive(:get).and_return(mapi_response)
      expect(mapi_response).to receive(:body).and_return(json_response)
      expect(status).to eq('my_status')
    end
    it "should return false if there was an error" do
      expect_any_instance_of(RestClient::Resource).to receive(:get).and_raise(RestClient::InternalServerError)
      expect(status).to be false
    end
    it "should return false if the service was unreachable" do
      expect_any_instance_of(RestClient::Resource).to receive(:get).and_raise(Errno::ECONNREFUSED)
      expect(status).to be false
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
    let(:amount) { 100 }
    let(:quick_advance_validate) {subject.quick_advance_validate(member_id, amount, advance_type, advance_term, advance_rate, signer)}
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
end