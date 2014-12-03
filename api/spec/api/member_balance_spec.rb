require 'spec_helper'

describe MAPI::ServiceApp do
  MEMBER_ID = 750
  describe "member balance pledged collateral" do
    let(:pledged_collateral) { get "/member/#{MEMBER_ID}/balance/pledged_collateral"; JSON.parse(last_response.body) }
    it "should return json with keys martgages, agency, aaa, aa" do
      expect(pledged_collateral.length).to be >= 1
      collateral_types = ['mortgages', 'agency', 'aaa', 'aa']
      collateral_types.each do |collateral_type|
        expect(pledged_collateral[collateral_type]).to be_kind_of(Numeric)
      end
    end
  end
end