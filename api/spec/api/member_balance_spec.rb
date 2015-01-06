require 'spec_helper'

describe MAPI::ServiceApp do
  MEMBER_ID = 750
  FROM_DATE = '2014-01-01'
  TO_DATE = '2014-12-31'
  CAPSTOCK_DATE_FORMAT = /\A\d\d\d\d-(0\d|1[012])-([0-2]\d|3[01])\Z/
  before do
    header 'Authorization', "Token token=\"#{ENV['MAPI_SECRET_TOKEN']}\""
  end
  describe 'member balance pledged collateral' do
    let(:pledged_collateral) { get "/member/#{MEMBER_ID}/balance/pledged_collateral"; JSON.parse(last_response.body) }
    it "should return json with keys mortgages, agency, aaa, aa" do
      expect(pledged_collateral.length).to be >= 1
      collateral_types = ['mortgages', 'agency', 'aaa', 'aa']
      collateral_types.each do |collateral_type|
        expect(pledged_collateral[collateral_type]).to be_kind_of(String)
      end
    end
  end

  describe 'member balance total securities' do
    let(:total_securities) { get "/member/#{MEMBER_ID}/balance/total_securities"; JSON.parse(last_response.body) }
    it "should return json with keys mortgages, agency, aaa, aa" do
      expect(total_securities.length).to be >= 1
      expect(total_securities['pledged_securities']).to be_kind_of(String)
      expect(total_securities['safekept_securities']).to be_kind_of(String)
    end
  end

  describe 'member balance effective borrowing capacity' do
    let(:effective_borrowing_capacity) { get "/member/#{MEMBER_ID}/balance/effective_borrowing_capacity"; JSON.parse(last_response.body) }
    it "should return json with keys total_capacity, unused_capacity" do
      expect(effective_borrowing_capacity.length).to be >= 1
      effective_borrowing_capacity_type = ['total_capacity', 'unused_capacity']
      effective_borrowing_capacity_type.each do |effective_borrowing_capacity_type|
        expect(effective_borrowing_capacity[effective_borrowing_capacity_type]).to be_kind_of(Numeric)
      end
    end
  end

  describe 'capital stock balances' do
    let(:capital_stock_balance) { get "/member/#{MEMBER_ID}/capital_stock_balance/#{FROM_DATE}"; JSON.parse(last_response.body) }
    RSpec.shared_examples 'a capital stock balance endpoint' do
      it 'should return a number for the balance' do
        expect(capital_stock_balance['balance']).to be_kind_of(Numeric)
      end
      it 'should return a date for the balance_date' do
        expect(capital_stock_balance['balance_date']).to match(CAPSTOCK_DATE_FORMAT)
      end
    end
    describe 'in the production environment' do
      let!(:some_balance) {123.4}
      let(:result_set) {double('Oracle Result Set', fetch: nil)}
      before do
        expect(MAPI::ServiceApp).to receive(:environment).at_least(1).times.and_return(:production)
        allow(ActiveRecord::Base).to receive(:connection).and_return(double('OCI8 Connection'))
        expect(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(result_set)
        allow(result_set).to receive(:fetch).and_return([some_balance], nil)
      end
      it 'should return zero for balance if no balance was found' do
        expect(result_set).to receive(:fetch).and_return(nil)
        expect(capital_stock_balance['balance']).to eq(0)
      end
      it 'should return the first balance found (first column of first row)' do
        expect(capital_stock_balance['balance']).to eq(some_balance)
      end
      it 'should not return the second column found' do
        expect(result_set).to receive(:fetch).and_return([124.5, some_balance], nil).at_least(1).times
        expect(capital_stock_balance['balance']).not_to eq(some_balance)
      end
      it 'should not return the second row found' do
        expect(result_set).to receive(:fetch).and_return([124.5], [some_balance], nil).at_least(1).times
        expect(capital_stock_balance['balance']).not_to eq(some_balance)
      end
      it_behaves_like 'a capital stock balance endpoint'
    end
    describe 'in the development environment' do
      it_behaves_like 'a capital stock balance endpoint'
    end
    it 'invalid param result in 404 error message' do
      get "/member/#{MEMBER_ID}/capital_stock_balance/12-12-2014"
      expect(last_response.status).to eq(404)
    end
  end
  describe 'capital stock Activities' do
    let(:capital_stock_activities) { get "/member/#{MEMBER_ID}/capital_stock_activities/#{FROM_DATE}/#{TO_DATE}"; JSON.parse(last_response.body) }
    it 'should return expected hash and data type in development' do
      capital_stock_activities['activities'].each do |activity|
        expect(activity['cert_id']).to be_kind_of(String)
        expect(activity['share_number']).to be_kind_of(Numeric)
        expect(activity['trans_date'].to_s).to match(CAPSTOCK_DATE_FORMAT)
        expect(activity['trans_type']).to be_kind_of(String)
        expect(activity['dr_cr']) == ('C' || 'D')
      end
    end
    it 'invalid param result in 404 error message' do
      get "/member/#{MEMBER_ID}/capital_stock_activities/12-12-2014/#{TO_DATE}"
      expect(last_response.status).to eq(404)
      get "/member/#{MEMBER_ID}/capital_stock_activities/#{FROM_DATE}/12-12-2014"
      expect(last_response.status).to eq(404)
    end
    describe 'in the production environment' do
      let!(:some_activity) {['12345','549','2014-11-11','-','D']}
      let(:result_set) {double('Oracle Result Set', fetch: nil)}
      before do
        expect(MAPI::ServiceApp).to receive(:environment).at_least(1).and_return(:production)
        allow(ActiveRecord::Base).to receive(:connection).and_return(double('OCI8 Connection'))
        expect(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(result_set)
        allow(result_set).to receive(:fetch).and_return(some_activity, nil)
      end
      it 'should return empty activities array if no activity record found' do
        expect(result_set).to receive(:fetch).and_return(nil)
        expect(capital_stock_activities['activities']).to eq([])
      end
      it 'should return expected hash and data type' do
        # expect(result_set).to receive(:fetch).and_return(some_activity, nil)
        capital_stock_activities['activities'].each do |activity|
          expect(activity['cert_id']).to be_kind_of(String)
          expect(activity['share_number']).to be_kind_of(Numeric)
          expect(activity['trans_date'].to_s).to match(CAPSTOCK_DATE_FORMAT)
          expect(activity['trans_type']).to be_kind_of(String)
          expect(activity['dr_cr']) == ('C' || 'D')
        end
      end
      it 'should return only 5 column hash even when fetch returns more than 5 columns' do
        expect(result_set).to receive(:fetch).and_return(['12345','549','2014-11-11','-','D','2222'], nil).at_least(1).times
        expect(capital_stock_activities['activities']).to eq([{"cert_id"=>"12345", "share_number"=>549.0, "trans_date"=>"2014-11-11", "trans_type"=>"-", "dr_cr"=>"D"}])
      end
      it 'should return both hash in the activities' do
        expect(result_set).to receive(:fetch).and_return(some_activity, ['22345','2549','2014-12-11','-','C'], nil).at_least(1).times
        expect(capital_stock_activities['activities'].count()).to eq(2)
      end
    end
  end
end
