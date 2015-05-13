require 'spec_helper'

describe MAPIService do
  subject { MAPIService.new(double('request', uuid: '12345')) }
  describe '`ping` method' do
    let(:status) { subject.ping }
    let(:json_response) { {'foo' => 'bar'} }
    let (:mapi_response) {double('MAPI_response', body: json_response.to_json)}
    it 'returns the value of `etransact_advances_status` from a hash built from the JSON response' do
      allow_any_instance_of(RestClient::Resource).to receive(:get).and_return(mapi_response)
      expect(status).to eq(json_response)
    end
    it "should return false if there was an error" do
      allow_any_instance_of(RestClient::Resource).to receive(:get).and_raise(RestClient::InternalServerError)
      expect(status).to eq(false)
    end
    it "should return false if the service was unreachable" do
      allow_any_instance_of(RestClient::Resource).to receive(:get).and_raise(Errno::ECONNREFUSED)
      expect(status).to eq(false)
    end
  end
end