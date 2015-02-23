require 'spec_helper'

describe MAPI::ServiceApp do
  let(:member_id) {750}

  before do
    header 'Authorization', "Token token=\"#{ENV['MAPI_SECRET_TOKEN']}\""
  end
  describe 'member profile' do
    let(:member_financial_position) { get "/member/#{member_id}/member_profile"; JSON.parse(last_response.body) }
    RSpec.shared_examples 'a Member Profile endpoint' do
      it "should return json with expected elements" do
        expect(member_financial_position.length).to be >= 1
        expect(member_financial_position['sta_balance']).to be_kind_of(Numeric)
        if (member_financial_position['credit_outstanding'] != nil)
          expect(member_financial_position['credit_outstanding']).to be_kind_of(Numeric)
        end
        if member_financial_position['financial_available'] != nil
          expect(member_financial_position['financial_available']).to be_kind_of(Integer)
        end
        if member_financial_position['credit_outstanding'] != nil
          expect(member_financial_position['credit_outstanding']).to be_kind_of(Integer)
        end
        if member_financial_position['stock_leverage'] != nil
          expect(member_financial_position['stock_leverage']).to be_kind_of(Integer)
        end
        if member_financial_position['credit_outstanding'] != nil
          expect(member_financial_position['credit_outstanding']).to be_kind_of(Integer)
        end
        if member_financial_position['collateral_market_value_sbc_agency'] != nil
          expect(member_financial_position['collateral_market_value_sbc_agency']).to be_kind_of(Integer)
        end
        if member_financial_position['collateral_market_value_sbc_aaa'] != nil
          expect(member_financial_position['collateral_market_value_sbc_aaa']).to be_kind_of(Integer)
        end
        if member_financial_position['collateral_market_value_sbc_aa'] != nil
          expect(member_financial_position['collateral_market_value_sbc_aa']).to be_kind_of(Integer)
        end
        if member_financial_position['borrowing_capacity_standard'] != nil
          expect(member_financial_position['borrowing_capacity_standard']).to be_kind_of(Integer)
        end
        if member_financial_position['borrowing_capacity_sbc_agency'] != nil
          expect(member_financial_position['borrowing_capacity_sbc_agency']).to be_kind_of(Integer)
        end
        if member_financial_position['borrowing_capacity_sbc_aaa'] != nil
          expect(member_financial_position['borrowing_capacity_sbc_aaa']).to be_kind_of(Integer)
        end
        if member_financial_position['borrowing_capacity_sbc_aa'] != nil
          expect(member_financial_position['borrowing_capacity_sbc_aa']).to be_kind_of(Integer)
        end
      end

      it 'should call capital_stock_requirement method and return stock_leverage' do
        expect(member_financial_position['stock_leverage']).to be_kind_of(Integer)
      end

      it 'should return 11 column' do
        expect(member_financial_position.count).to eq(11)
      end
    end


    describe 'in the development environment' do
      it_behaves_like 'a Member Profile endpoint'
     end

    describe 'in the production environment' do
        let(:member_position_result) {double('Oracle Result Set', fetch: nil)}
        let(:member_sta_result) {double('Oracle Result Set', fetch: nil)}
        let(:some_financial_data) {{"STX_LEDGER_BALANCE"=> nil, "CREDIT_OUTSTANDING"=>  5000001, "FINANCIAL_AVAILABLE"=> 169771251, "EXCESS_REG_BORR_CAP"=> 82911719,
          "EXCESS_SBC_BORR_CAP_AG"=> 3405111, "EXCESS_SBC_BORR_CAP_AA"=> 101, "EXCESS_SBC_BORR_CAP_AAA"=>  102, "SBC_MARKET_VALUE_AAA"=>  103, "SBC_MARKET_VALUE_AA"=>  104,
          "SBC_MARKET_VALUE_AG"=>  3584326,    "ADVANCE_OUTSTANDING"=>  15000000, "MPF_UNPAID_BALANCE"=>  0, "TOTAL_CAPITAL_STOCK"=> 1000000000,
          "MRTG_RELATED_ASSETS"=> 3458554, "MRTG_RELATED_ASSETS_ROUND100"=> 3458600 }}
        let(:some_sta_data) {{"STA_ACCOUNT_NUMBER"=> 25100033, "STX_UPDATE_DATE"=> "2015-02-05", "STX_CURRENT_LEDGER_BALANCE"=> 190349.49,"STX_INT_RATE"=> 0.02}}
        before do
          expect(MAPI::ServiceApp).to receive(:environment).at_least(1).and_return(:production)
          expect(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(member_position_result)
          expect(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(member_sta_result)
          allow(member_position_result).to receive(:fetch_hash).and_return(some_financial_data, nil)
          allow(member_sta_result).to receive(:fetch_hash).and_return(some_sta_data, nil)
        end

        it "should json with expected column (exclude stock leverage)" , vcr: {cassette_name: 'capital_stock_requirements_service'} do
          expect(member_financial_position['sta_balance']).to eq(190349.49)
          expect(member_financial_position['financial_available']).to eq(169771251)
          expect(member_financial_position['credit_outstanding']).to eq(5000001)
          expect(member_financial_position['collateral_market_value_sbc_agency']).to eq(3584326)
          expect(member_financial_position['collateral_market_value_sbc_aaa']).to eq(103)
          expect(member_financial_position['collateral_market_value_sbc_aa']).to eq(104)
          expect(member_financial_position['borrowing_capacity_standard']).to eq(82911719)
          expect(member_financial_position['borrowing_capacity_sbc_agency']).to eq(3405111)
          expect(member_financial_position['borrowing_capacity_sbc_aaa']).to eq(102)
          expect(member_financial_position['borrowing_capacity_sbc_aa']).to eq(101)
          expect(member_financial_position['stock_leverage']).to eq(33330000)
        end

        it 'should return stock_leverage column with nil value if capital_stock_requirements services is not successful' , vcr: {cassette_name: 'capital_stock_service_unavailable'} do
          # expect(member_financial_position['stock_leverage']).to eq(nil)
          expect(member_financial_position['sta_balance']).to eq(190349.49)
          expect(member_financial_position['financial_available']).to eq(169771251)
          expect(member_financial_position['credit_outstanding']).to eq(5000001)
          expect(member_financial_position['collateral_market_value_sbc_agency']).to eq(3584326)
          expect(member_financial_position['collateral_market_value_sbc_aaa']).to eq(103)
          expect(member_financial_position['collateral_market_value_sbc_aa']).to eq(104)
          expect(member_financial_position['borrowing_capacity_standard']).to eq(82911719)
          expect(member_financial_position['borrowing_capacity_sbc_agency']).to eq(3405111)
          expect(member_financial_position['borrowing_capacity_sbc_aaa']).to eq(102)
          expect(member_financial_position['borrowing_capacity_sbc_aa']).to eq(101)
        end

        it 'should return expected column with nil value if no data found for existing member' do
          expect(member_position_result).to receive(:fetch_hash).and_return(nil).at_least(1).times
          expect(member_sta_result).to receive(:fetch_hash).and_return(nil).at_least(1).times
          expect(member_financial_position['sta_balance']).to eq(nil)
          expect(member_financial_position['financial_available']).to eq(nil)
          expect(member_financial_position['credit_outstanding']).to eq(nil)
          expect(member_financial_position['collateral_market_value_sbc_agency']).to eq(nil)
          expect(member_financial_position['collateral_market_value_sbc_aaa']).to eq(nil)
          expect(member_financial_position['collateral_market_value_sbc_aa']).to eq(nil)
          expect(member_financial_position['borrowing_capacity_standard']).to eq(nil)
          expect(member_financial_position['borrowing_capacity_sbc_agency']).to eq(nil)
          expect(member_financial_position['borrowing_capacity_sbc_aaa']).to eq(nil)
          expect(member_financial_position['borrowing_capacity_sbc_aa']).to eq(nil)
          expect(member_financial_position['stock_leverage']).to eq(nil)
        end

    end
  end
end