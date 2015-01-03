require 'spec_helper'

describe MAPI::ServiceApp do
  MEMBER_ID = 750
  FROM_DATE = '2014-01-01'
  TO_DATE = '2014-12-31'
  CAPSTOCK_DATE_FORMAT = /\A\d\d\d\d-(0\d|1[012])-([0-2]\d|3[01])\Z/
  before do
    header 'Authorization', "Token token=\"#{ENV['MAPI_SECRET_TOKEN']}\""
  end
  describe "member balance pledged collateral" do
    let(:pledged_collateral) { get "/member/#{MEMBER_ID}/balance/pledged_collateral"; JSON.parse(last_response.body) }
    it "should return json with keys mortgages, agency, aaa, aa" do
      expect(pledged_collateral.length).to be >= 1
      collateral_types = ['mortgages', 'agency', 'aaa', 'aa']
      collateral_types.each do |collateral_type|
        expect(pledged_collateral[collateral_type]).to be_kind_of(String)
      end
    end
  end

  describe "member balance total securities" do
    let(:total_securities) { get "/member/#{MEMBER_ID}/balance/total_securities"; JSON.parse(last_response.body) }
    it "should return json with keys mortgages, agency, aaa, aa" do
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

  describe "Capital Stock balances" do
    let(:capital_stock_balance) { get "/member/#{MEMBER_ID}/capital_stock_balance/#{FROM_DATE}"; JSON.parse(last_response.body) }
    it "header data should have value" do
      expect(capital_stock_balance.length).to be >= 1
      expect(capital_stock_balance['balance']).to be_kind_of(String)
      expect(capital_stock_balance['balance_date']).to match(CAPSTOCK_DATE_FORMAT)
    end
  end
  describe "Capital Stock Activities" do
    let(:capital_stock_activities) { get "/member/#{MEMBER_ID}/capital_stock_activities/#{FROM_DATE}/#{TO_DATE}"; JSON.parse(last_response.body) }
    it "activities data should have value" do
      capital_stock_activities['activities'].each do |activity|
        expect(activity['cert_id']).to be_kind_of(String)
        expect(activity['share_number']).to be_kind_of(String)
        expect(activity['trans_date']).to match(CAPSTOCK_DATE_FORMAT)
        expect(activity['trans_type']).to be_kind_of(String)
        expect(activity['dr_cr']) == ('C' || 'D')
      end
    end
  end
end
