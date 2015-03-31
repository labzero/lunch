require 'spec_helper'

describe MembersService do
  let(:member_id) { 3 }
  subject { MembersService.new(double('request', uuid: '12345')) }
  it { expect(subject).to respond_to(:report_disabled?) }

  describe '`report_disabled?` method' do
    let(:report_flags) {[5, 7]}
    let(:response_object) { double('Response')}
    let(:report_disabled?) {subject.report_disabled?(member_id, report_flags)}

    it 'should return nil if there was an API error' do
      expect_any_instance_of(RestClient::Resource).to receive(:get).and_raise(RestClient::InternalServerError)
      expect(report_disabled?).to eq(nil)
    end
    it 'should return nil if there was a connection error' do
      expect_any_instance_of(RestClient::Resource).to receive(:get).and_raise(Errno::ECONNREFUSED)
      expect(report_disabled?).to eq(nil)
    end

    describe 'hitting the MAPI endpoint' do
      let(:request_object) {double('Request')}
      let(:overlapping_response) {[7, 9].to_json}
      let(:non_overlapping_response) {[2, 9].to_json}

      before do
        expect(request_object).to receive(:get).and_return(response_object)
        expect_any_instance_of(RestClient::Resource).to receive(:[]).with("member/#{member_id}/disabled_reports").and_return(request_object)
      end
      it 'returns true if any of the values it was passed in the report_flags array match any values returned by MAPI' do
        expect(response_object).to receive(:body).and_return(overlapping_response)
        expect(report_disabled?).to be(true)
      end
      it 'returns false if none of the values it was passed in the report_flags array match values returned by MAPI' do
        expect(response_object).to receive(:body).and_return(non_overlapping_response)
        expect(report_disabled?).to be(false)
      end
      it 'returns false if the MAPI endpoint passes back an empty array' do
        expect(response_object).to receive(:body).and_return([].to_json)
        expect(report_disabled?).to be(false)
      end
    end
  end

  describe '`all_members` method', :vcr do
    let(:members) { subject.all_members }
    it 'should return nil if there was an API error' do
      expect_any_instance_of(RestClient::Resource).to receive(:get).and_raise(RestClient::InternalServerError)
      expect(members).to eq(nil)
    end
    it 'should return nil if there was a connection error' do
      expect_any_instance_of(RestClient::Resource).to receive(:get).and_raise(Errno::ECONNREFUSED)
      expect(members).to eq(nil)
    end
    it 'returns an array of members on success' do
      expect(members).to be_kind_of(Array)
      expect(members.count).to be >= 1
      members.each do |member|
        expect(member).to be_kind_of(Hash)
        expect(member[:id]).to be_kind_of(Numeric)
        expect(member[:id]).to be > 0
        expect(member[:name]).to be_kind_of(String)
        expect(member[:name]).to be_present
      end
    end
  end
  describe '`member` method', :vcr do
    let(:member) { subject.member(member_id) }
    it 'should return nil if there was an API error' do
      expect_any_instance_of(RestClient::Resource).to receive(:get).and_raise(RestClient::InternalServerError)
      expect(member).to eq(nil)
    end
    it 'should return nil if there was a connection error' do
      expect_any_instance_of(RestClient::Resource).to receive(:get).and_raise(Errno::ECONNREFUSED)
      expect(member).to eq(nil)
    end
    it 'returns a member on success' do
      expect(member).to be_kind_of(Hash)
      expect(member[:id]).to be_kind_of(Numeric)
      expect(member[:id]).to be > 0
      expect(member[:name]).to be_kind_of(String)
      expect(member[:name]).to be_present
    end
  end
end
