require 'spec_helper'

describe MAPI::ServiceApp do
  MEMBER_ID = 750
  describe "member balance pledged collateral" do
    let(:pledged_collateral) { get "/member/#{MEMBER_ID}/balance/pledged_collateral"; JSON.parse(last_response.body) }
    it "should return json with keys martgages, agency, aaa, aa" do
      expect(pledged_collateral.length).to be >= 1
      collateral_types = ['mortgages', 'agency', 'aaa', 'aa']
      collateral_types.each do |collateral_type|
        expect(pledged_collateral[collateral_type]).to be_kind_of(String)
      end
    end
  end

  describe "member balance total securities" do
    let(:total_securities) { get "/member/#{MEMBER_ID}/balance/total_securities"; JSON.parse(last_response.body) }
    it "should return json with keys martgages, agency, aaa, aa" do
      expect(total_securities.length).to be >= 1
      expect(total_securities['pledged_securities']).to be_kind_of(String)
      expect(total_securities['safekept_securities']).to be_kind_of(String)
    end
  end

  describe "member balance effective borrowing capacity" do
    let(:effective_borrowing_capacity) { get "/member/#{MEMBER_ID}/balance/effective_borrowing_capacity"; JSON.parse(last_response.body) }
    it "should return json with keys total_capacity, unused_capacity" do
      expect(effective_borrowing_capacity.length).to be >= 1
      effective_borrowing_capacity_type = ['total_capacity', 'unused_capacity']
      effective_borrowing_capacity_type.each do |effective_borrowing_capacity_type|
        expect(effective_borrowing_capacity[effective_borrowing_capacity_type]).to be_kind_of(Numeric)
      end
    end
  end
end
