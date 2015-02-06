
require 'spec_helper'

describe MAPI::ServiceApp do
  MEMBER_ID = 750

  before do
    header 'Authorization', "Token token=\"#{ENV['MAPI_SECRET_TOKEN']}\""
  end
  describe 'member balance pledged collateral' do
    collateral_types = ['mortgages', 'agency', 'aaa', 'aa']
    let(:pledged_collateral) { get "/member/#{MEMBER_ID}/balance/pledged_collateral"; JSON.parse(last_response.body) }
    it "should return json with keys mortgages, agency, aaa, aa" do
      expect(pledged_collateral.length).to be >= 1
      collateral_types.each do |collateral_type|
        expect(pledged_collateral[collateral_type]).to be_kind_of(Numeric)
      end
    end
    describe 'in the production environment' do
      let(:some_values) {[300, 400, 500]}
      let(:result_set) {double('Oracle Result Set', fetch: nil)}
      let(:result_set2) {double('Oracle Result Set', fetch: nil)}
      before do
        expect(MAPI::ServiceApp).to receive(:environment).at_least(1).and_return(:production)
        expect(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(result_set)
        expect(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(result_set2)
        allow(result_set).to receive(:fetch).and_return(10, nil)
        allow(result_set2).to receive(:fetch).and_return(some_values, nil)
      end
      it 'should return json with keys mortgages, agency, aaa, aa' do
        expect(pledged_collateral.length).to be >= 1
        collateral_types.each do |collateral_type|
          expect(pledged_collateral[collateral_type]).to be_kind_of(Numeric)
        end
      end
      it 'should not return the second row found' do
        expect(result_set).to receive(:fetch).and_return([1000], [20], nil).at_least(1).times
        expect(result_set2).to receive(:fetch).and_return([2000, 3000, 40000], some_values,  nil).at_least(1).times
        expect(pledged_collateral['mortgages']).to eq(1000)
        expect(pledged_collateral['agency']).to eq(2000)
        expect(pledged_collateral['aaa']).to eq(3000)
        expect(pledged_collateral['aa']).to eq(40000)
      end
    end
  end

  describe 'member balance total securities' do
    let(:total_securities) { get "/member/#{MEMBER_ID}/balance/total_securities"; JSON.parse(last_response.body) }
    it "should return json with keys pledge_securities, safekept_securities" do
      expect(total_securities.length).to be >= 1
      expect(total_securities['pledged_securities']).to be_kind_of(Numeric)
      expect(total_securities['safekept_securities']).to be_kind_of(Numeric)
    end
    describe 'in the production environment' do
      let!(:some_activity) {[12345, 54911, 99999]}
      let(:result_set1) {double('Oracle Result Set', fetch: nil)}
      let(:result_set2) {double('Oracle Result Set', fetch: nil)}
      before do
        expect(MAPI::ServiceApp).to receive(:environment).at_least(1).and_return(:production)
        expect(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(result_set1)
        expect(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(result_set2)
        allow(result_set1).to receive(:fetch).and_return(some_activity, nil)
        allow(result_set2).to receive(:fetch).and_return(some_activity, nil)
      end
      it 'should return jason wth keys pledged_securities, safekept_securities with the first column for each of the execute fetch returned' do
        expect(total_securities['pledged_securities']).to eq(12345)
        expect(total_securities['safekept_securities']).to eq(12345)
      end
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
    describe 'in the production environment' do
      let!(:some_activity) {[12345, 54911, 99999]}
      let(:result_set) {double('Oracle Result Set', fetch: nil)}
      before do
        expect(MAPI::ServiceApp).to receive(:environment).at_least(1).and_return(:production)
        expect(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(result_set)
        allow(result_set).to receive(:fetch).and_return(some_activity, nil)
      end
      it 'should return jason wth keys total_capacity, unused_capacity with the first 2 columns returned' do
        expect(effective_borrowing_capacity['total_capacity']).to eq(12345)
        expect(effective_borrowing_capacity['unused_capacity']).to eq(54911)
      end
    end
  end

  describe 'capital stock balances' do
    let(:capital_stock_balance) { get "/member/#{MEMBER_ID}/capital_stock_balance/2014-01-01"; JSON.parse(last_response.body) }

   RSpec.shared_examples 'a capital stock balance endpoint' do
      it 'should return a number for the balance' do
        expect(capital_stock_balance['open_balance']).to be_kind_of(Numeric)
        expect(capital_stock_balance['close_balance']).to be_kind_of(Numeric)
      end
      it 'should return a date for the balance_date' do
        expect(capital_stock_balance['balance_date']).to match(MAPI::Shared::Constants::REPORT_PARAM_DATE_FORMAT)
      end
    end
    describe 'in the production environment' do
      let!(:some_balance) {123.4}
      let!(:close_balance) {456.4}
      let(:result_set) {double('Oracle Result Set', fetch: nil)}
      let(:result_set2) {double('Oracle Result Set', fetch: nil)}
      before do
        expect(MAPI::ServiceApp).to receive(:environment).at_least(1).times.and_return(:production)
        expect(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(result_set)
        expect(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(result_set2)
        allow(result_set).to receive(:fetch).and_return([some_balance], nil)
        allow(result_set2).to receive(:fetch).and_return([close_balance], nil)
      end
      it 'should return zero for balance if no balance was found' do
        expect(result_set).to receive(:fetch).and_return(nil)
        expect(result_set2).to receive(:fetch).and_return(nil)
        expect(capital_stock_balance['open_balance']).to eq(0)
        expect(capital_stock_balance['close_balance']).to eq(0)
      end
      it 'should return the first balance found (first column of first row)' do
        expect(capital_stock_balance['open_balance']).to eq(some_balance)
        expect(capital_stock_balance['close_balance']).to eq(close_balance)
      end
      it 'should not return the second column found' do
        expect(result_set).to receive(:fetch).and_return([124.5, some_balance], nil).at_least(1).times
        expect(result_set2).to receive(:fetch).and_return([224.5, close_balance], nil).at_least(1).times
        expect(capital_stock_balance['open_balance']).not_to eq(some_balance)
        expect(capital_stock_balance['close_balance']).not_to eq(close_balance)
      end
      it 'should not return the second row found' do
        expect(result_set).to receive(:fetch).and_return([124.5], [some_balance], nil).at_least(1).times
        expect(result_set2).to receive(:fetch).and_return([224.5], [close_balance], nil).at_least(1).times
        expect(capital_stock_balance['open_balance']).not_to eq(some_balance)
        expect(capital_stock_balance['close_balance']).not_to eq(close_balance)
      end
      it_behaves_like 'a capital stock balance endpoint'
    end
    describe 'in the development environment' do
      it_behaves_like 'a capital stock balance endpoint'
    end
    it 'invalid param result in 400 error message' do
      get "/member/#{MEMBER_ID}/capital_stock_balance/12-12-2014"
      expect(last_response.status).to eq(400)
    end
  end
  describe 'capital stock Activities' do
    let(:from_date) {'2014-01-01'}
    let(:to_date) {'2014-12-31'}
    let(:capital_stock_activities) { get "/member/#{MEMBER_ID}/capital_stock_activities/#{from_date}/#{to_date}"; JSON.parse(last_response.body) }
    it 'should return expected hash and data type in development' do
      capital_stock_activities['activities'].each do |activity|
        expect(activity['cert_id']).to be_kind_of(String)
        expect(activity['share_number']).to be_kind_of(Numeric)
        expect(activity['trans_date'].to_s).to match(MAPI::Shared::Constants::REPORT_PARAM_DATE_FORMAT)
        expect(activity['trans_type']).to be_kind_of(String)
        expect(activity['dr_cr']) == ('C' || 'D')
      end
    end
    it 'invalid param result in 400 error message' do
      get "/member/#{MEMBER_ID}/capital_stock_activities/12-12-2014/#{to_date}"
      expect(last_response.status).to eq(400)
      get "/member/#{MEMBER_ID}/capital_stock_activities/#{from_date}/12-12-2014"
      expect(last_response.status).to eq(400)
    end
    describe 'in the production environment' do
      let!(:some_activity) {['12345','549','2014-12-24 12:00:00','-','D']}
      let(:result_set) {double('Oracle Result Set', fetch: nil)}
      before do
        expect(MAPI::ServiceApp).to receive(:environment).at_least(1).and_return(:production)
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
          expect(activity['trans_date'].to_s).to match(MAPI::Shared::Constants::REPORT_PARAM_DATE_FORMAT)
          expect(activity['trans_type']).to be_kind_of(String)
          expect(activity['dr_cr']) == ('C' || 'D')
        end
      end
      it 'should return only 5 column hash even when fetch returns more than 5 columns' do
        expect(result_set).to receive(:fetch).and_return(['12345','549','2014-11-11 12:00:00','-','D','2222'], nil).at_least(1).times
        expect(capital_stock_activities['activities']).to eq([{"cert_id"=>"12345", "share_number"=>549.0, "trans_date"=>"2014-11-11", "trans_type"=>"-", "dr_cr"=>"D"}])
      end
      it 'should return both hash in the activities' do
        expect(result_set).to receive(:fetch).and_return(some_activity, ['22345','2549','24-Nov-2014 12:00:00 AM','-','C'], nil).at_least(1).times
        expect(capital_stock_activities['activities'].count()).to eq(2)
      end
    end
  end

  describe 'borrowing capacity details' do
    let(:as_of_date) {'2015-01-14'}
    let(:borrowing_capacity_details) { get "/member/#{MEMBER_ID}/borrowing_capacity_details/#{as_of_date}"; JSON.parse(last_response.body) }

    it 'invalid param result in 400 error message' do
      get "/member/#{MEMBER_ID}/borrowing_capacity_details/12-12-2014"
      expect(last_response.status).to eq(400)
    end

    RSpec.shared_examples 'a borrowing capacity detail endpoint' do
      it "should return all the expected columns with the correct datatype" do
        expect(borrowing_capacity_details['date'].to_s).to match(MAPI::Shared::Constants::REPORT_PARAM_DATE_FORMAT)

        result_standard_collateral = borrowing_capacity_details['standard']['collateral']

        result_standard_collateral.each do |row|
          expect(row['type']).to be_kind_of(String)
          expect(row['count']).to be_kind_of(Integer)
          expect(row['original_amount']).to be_kind_of(Integer)
          expect(row['unpaid_principal']).to be_kind_of(Integer)
          expect(row['market_value']).to be_kind_of(Integer)
          expect(row['borrowing_capacity']).to be_kind_of(Integer)
        end

        result_standard_excluded = borrowing_capacity_details['standard']['excluded']
        expect(result_standard_excluded['blanket_lien']).to be_a_kind_of(Integer)
        expect(result_standard_excluded['bank']).to be_a_kind_of(Integer)
        expect(result_standard_excluded['regulatory']).to be_a_kind_of(Integer)

        result_standard_utilized = borrowing_capacity_details['standard']['utilized']
        expect(result_standard_utilized['advances']).to be_a_kind_of(Integer)
        expect(result_standard_utilized['letters_of_credit']).to be_a_kind_of(Integer)
        expect(result_standard_utilized['swap_collateral']).to be_a_kind_of(Integer)
        expect(result_standard_utilized['sbc_type_deficiencies']).to be_a_kind_of(Integer)
        expect(result_standard_utilized['payment_fees']).to be_a_kind_of(Integer)
        expect(result_standard_utilized['other_collateral']).to be_a_kind_of(Integer)
        expect(result_standard_utilized['mpf_ce_collateral']).to be_a_kind_of(Integer)

        result_sbc_collateral = borrowing_capacity_details['sbc']['collateral']
        result_sbc_collateral.each do |row|
          expect(row['type']).to be_kind_of(String)
          expect(row['total_market_value']).to be_a_kind_of(Integer)
          expect(row['total_borrowing_capacity']).to be_a_kind_of(Integer)
          expect(row['advances']).to be_a_kind_of(Integer)
          expect(row['standard_credit']).to be_a_kind_of(Integer)
          expect(row['remaining_market_value']).to be_a_kind_of(Integer)
          expect(row['remaining_borrowing_capacity']).to be_a_kind_of(Integer)
        end
        expect(borrowing_capacity_details['sbc']['utilized']['other_collateral']).to be_kind_of(Integer)
        expect(borrowing_capacity_details['sbc']['utilized']['excluded_regulatory']).to be_kind_of(Integer)
      end
    end

    describe 'in the development environment' do
      it_behaves_like 'a borrowing capacity detail endpoint'
    end

    describe 'in the development environment' do
      let(:as_of_date) {'2015-01-14'}
      let(:bc_balances) {{"UPDATE_DATE"=> "12-JAN-2015 03:18 PM", "STD_EXCL_BL_BC"=> 20.5, "STD_EXCL_BANK_BC"=> 30.4, "STD_EXCL_REG_BC"=> 40, "STD_SECURITIES_BC"=> 0,
                         "STD_ADVANCES"=> 15000099, "STD_LETTERS_CDT_USED"=> 20, "STD_SWAP_COLL_REQ"=> 10, "STD_COVER_OTHER_PT_DEF"=> 99, "STD_PREPAY_FEES"=> 260,
                         "STD_OTHER_COLL_REQ"=> 70, "STD_MPF_CE_COLL_REQ"=> 155, "STD_COLL_EXCESS_DEF"=> 82911718, "SBC_MV_AA"=> 1, "SBC_BC_AA"=> 2, "SBC_ADVANCES_AA"=> 3,
                         "SBC_COVER_OTHER_AA"=> 4, "SBC_MV_COLL_EXCESS_DEF_AA"=> 5, "SBC_COLL_EXCESS_DEF_AA"=> 6, "SBC_MV_AAA"=> 7, "SBC_BC_AAA"=> 8, "SBC_ADVANCES_AAA"=> 9,
                         "SBC_COVER_OTHER_AAA"=> 10, "SBC_MV_COLL_EXCESS_DEF_AAA"=> 11.4, "SBC_COLL_EXCESS_DEF_AAA"=> 12.5, "SBC_MV_AG"=> 3584326, "SBC_BC_AG"=> 3405110,
                         "SBC_ADVANCES_AG"=> 19, "SBC_COVER_OTHER_AG"=> 1, "SBC_MV_COLL_EXCESS_DEF_AG"=> 3584326, "SBC_COLL_EXCESS_DEF_AG"=> 3584326.6, "SBC_OTHER_COLL_REQ"=>77,
                         "SBC_COLL_EXCESS_DEF"=> 3405110, "STD_TOTAL_BC"=> 97911718, "SBC_BC" => 3405110, "SBC_MV"=> 3584326, "SBC_ADVANCES"=> 0, "SBC_MV_COLL_EXCESS_DEF"=> 3584326}}
      let(:bc_breakdown) {{"COLLATERAL_TYPE" =>"BL SUMMARY - RESIDENTIAL",  "STD_COUNT"=> 1,"STD_ORIGINAL_AMOUNT"=> 61335099,
                          "STD_UNPAID_BALANCE" => 58403242, "STD_MARKET_VALUE" => 51394853.5, "STD_BORROWING_CAPACITY" =>40601935.4, "COLLATERAL_SORT_ID"=>"C10"}}
      let(:bc_breakdown2) {{"COLLATERAL_TYPE" =>"BL SUMMARY - MULTIFAMILY",  "STD_COUNT"=> 2,"STD_ORIGINAL_AMOUNT"=> 61335099,
                           "STD_UNPAID_BALANCE" => 58403242, "STD_MARKET_VALUE" => 51394853, "STD_BORROWING_CAPACITY" =>40601935, "COLLATERAL_SORT_ID"=>"C12"}}
      let(:result_set1) {double('Oracle Result Set', fetch_hash: nil)}
      let(:result_set2) {double('Oracle Result Set', fetch_hash: nil)}
      before do
        expect(MAPI::ServiceApp).to receive(:environment).at_least(1).times.and_return(:production)
        expect(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(result_set1)
        expect(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(result_set2)
        allow(result_set1).to receive(:fetch_hash).and_return(bc_balances, nil)
        allow(result_set2).to receive(:fetch_hash).and_return(bc_breakdown, bc_breakdown2, nil)
      end
      it_behaves_like 'a borrowing capacity detail endpoint'

      it 'should returns the 2 rows of standard collateral' do
        result_standard_collateral = borrowing_capacity_details['standard']['collateral']
        expect(result_standard_collateral.count).to eq(2)
      end

      it 'should return 3 rows of sbc collateral' do
        result_sbc_collateral = borrowing_capacity_details['sbc']['collateral']
        expect(result_sbc_collateral.count).to eq(3)
      end

      it 'should return the expected value for Standard collateral hash' do
        result_standard_collateral = borrowing_capacity_details['standard']['collateral']
        # check the first row
        row = result_standard_collateral[0]
        expect(row['type']).to eq('BL SUMMARY - RESIDENTIAL')
        expect(row['count']).to eq(1)
        expect(row['original_amount']).to eq(61335099)
        expect(row['unpaid_principal']).to eq(58403242)
        expect(row['market_value']).to eq(51394854)
        expect(row['borrowing_capacity']).to eq(40601935)
      end
      it 'should return the expected value for Standard Excluded' do
        result_standard_excluded = borrowing_capacity_details['standard']['excluded']
        expect(result_standard_excluded['blanket_lien']).to eq(21)
        expect(result_standard_excluded['bank']).to eq(30)
        expect(result_standard_excluded['regulatory']).to eq(40)
      end

      it 'should return the expected value for Standard Utilized' do
        result_standard_utilized = borrowing_capacity_details['standard']['utilized']
        expect(result_standard_utilized['advances']).to eq(15000099)
        expect(result_standard_utilized['letters_of_credit']).to eq(20)
        expect(result_standard_utilized['swap_collateral']).to eq(10)
        expect(result_standard_utilized['sbc_type_deficiencies']).to eq(99)
        expect(result_standard_utilized['payment_fees']).to eq(260)
        expect(result_standard_utilized['other_collateral']).to eq(70)
        expect(result_standard_utilized['mpf_ce_collateral']).to eq(155)
      end

      it 'should return the expected value for SBC utilized' do
        expect(borrowing_capacity_details['sbc']['utilized']['other_collateral']).to eq(77)
        expect(borrowing_capacity_details['sbc']['utilized']['excluded_regulatory']).to eq(0)
      end

      it 'should return the expected values for SBC collateral' do
        result_sbc_collateral = borrowing_capacity_details['sbc']['collateral']

        result_sbc_collateral.each do |row|
          if  row['type'] == 'AA'
            expect(row['total_market_value']).to eq(1)
            expect(row['total_borrowing_capacity']).to eq(2)
            expect(row['advances']).to eq(3)
            expect(row['standard_credit']).to eq(4)
            expect(row['remaining_market_value']).to eq(5)
            expect(row['remaining_borrowing_capacity']).to eq(6)
          elsif row['type'] == 'AAA'
            expect(row['total_market_value']).to eq(7)
            expect(row['total_borrowing_capacity']).to eq(8)
            expect(row['advances']).to eq(9)
            expect(row['standard_credit']).to eq(10)
            expect(row['remaining_market_value']).to eq(11)
            expect(row['remaining_borrowing_capacity']).to eq(13)
          elsif row['type'] == 'Agency'
            expect(row['total_market_value']).to eq(3584326)
            expect(row['total_borrowing_capacity']).to eq(3405110)
            expect(row['advances']).to eq(19)
            expect(row['standard_credit']).to eq(1)
            expect(row['remaining_market_value']).to eq(3584326)
            expect(row['remaining_borrowing_capacity']).to eq(3584327)
          end
        end
      end

      it 'should return date and 0 values with empty hash for collateral for standard and sbc if no data returned' do
        expect(result_set1).to receive(:fetch_hash).and_return(nil)
        expect(result_set2).to receive(:fetch_hash).and_return(nil)
        expect(borrowing_capacity_details['date'].to_s).to match(MAPI::Shared::Constants::REPORT_PARAM_DATE_FORMAT)
        expect(borrowing_capacity_details['standard']['collateral']).to eq([])
        result_standard_excluded = borrowing_capacity_details['standard']['excluded']
        expect(result_standard_excluded['blanket_lien']).to eq(0)
        expect(result_standard_excluded['bank']).to eq(0)
        expect(result_standard_excluded['regulatory']).to eq(0)
        result_standard_utilized = borrowing_capacity_details['standard']['utilized']
        expect(result_standard_utilized['advances']).to eq(0)
        expect(result_standard_utilized['letters_of_credit']).to eq(0)
        expect(result_standard_utilized['swap_collateral']).to eq(0)
        expect(result_standard_utilized['sbc_type_deficiencies']).to eq(0)
        expect(result_standard_utilized['payment_fees']).to eq(0)
        expect(result_standard_utilized['other_collateral']).to eq(0)
        expect(result_standard_utilized['mpf_ce_collateral']).to eq(0)
        expect(borrowing_capacity_details['sbc']['utilized']['other_collateral']).to eq(0)
        expect(borrowing_capacity_details['sbc']['utilized']['excluded_regulatory']).to eq(0)
        result_sbc_collateral = borrowing_capacity_details['sbc']['collateral']
        result_sbc_collateral.each do |row|
          if  row['type'] == 'AA'
            expect(row['total_market_value']).to eq(0)
            expect(row['total_borrowing_capacity']).to eq(0)
            expect(row['advances']).to eq(0)
            expect(row['standard_credit']).to eq(0)
            expect(row['remaining_market_value']).to eq(0)
            expect(row['remaining_borrowing_capacity']).to eq(0)
          elsif row['type'] == 'AAA'
            expect(row['total_market_value']).to eq(0)
            expect(row['total_borrowing_capacity']).to eq(0)
            expect(row['advances']).to eq(0)
            expect(row['standard_credit']).to eq(0)
            expect(row['remaining_market_value']).to eq(0)
            expect(row['remaining_borrowing_capacity']).to eq(0)
          elsif row['type'] == 'Agency'
            expect(row['total_market_value']).to eq(0)
            expect(row['total_borrowing_capacity']).to eq(0)
            expect(row['advances']).to eq(0)
            expect(row['standard_credit']).to eq(0)
            expect(row['remaining_market_value']).to eq(0)
            expect(row['remaining_borrowing_capacity']).to eq(0)
          end
        end
      end

    end
  end

  describe 'STA activities' do
    let(:from_date) {'2014-01-01'}
    let(:to_date) {'2014-12-31'}
    let(:sta_activities) { get "/member/#{MEMBER_ID}/sta_activities/#{from_date}/#{to_date}"; JSON.parse(last_response.body) }
    RSpec.shared_examples 'a STA activities endpoint' do
      it 'should return a number for the balance' do
        expect(sta_activities['start_balance']).to be_kind_of(Numeric)
        expect(sta_activities['end_balance']).to be_kind_of(Numeric)
      end
      it 'should return a date for the balance_date' do
        expect(sta_activities['start_date']).to match(MAPI::Shared::Constants::REPORT_PARAM_DATE_FORMAT)
        expect(sta_activities['end_date']).to match(MAPI::Shared::Constants::REPORT_PARAM_DATE_FORMAT)
      end
      it 'should return expected hash and data type or nil in development' do
        sta_activities['activities'].each do |activity|
          expect(activity['trans_date'].to_s).to match(MAPI::Shared::Constants::REPORT_PARAM_DATE_FORMAT)
          if (activity['refnumber'] != nil )
           expect(activity['refnumber']).to be_kind_of(String)
          end
          if (activity['descr'] != nil )
            expect(activity['descr']).to be_kind_of(String)
          end
          if (activity['debit'] != nil )
            expect(activity['debit']).to be_kind_of(Numeric)
          end
          if (activity['credit'] != nil )
            expect(activity['credit']).to be_kind_of(Numeric)
          end
          if (activity['balance'] != nil )
            expect(activity['balance']).to be_kind_of(Numeric)
          end
          expect(activity['rate']).to be_kind_of(Numeric)
        end
      end
    end
    it 'invalid param result in 400 error message' do
      get "/member/#{MEMBER_ID}/sta_activities/12-12-2014/#{to_date}"
      expect(last_response.status).to eq(400)
      get "/member/#{MEMBER_ID}/sta_activities/#{from_date}/12-12-2014"
      expect(last_response.status).to eq(400)
    end
    describe 'in the development environment' do
      it_behaves_like 'a STA activities endpoint'

      it 'should has 2 rows of activities based on the fake data' do
        expect(sta_activities['activities'].count).to eq(3)
      end
    end
    describe 'in the production environment' do
      let(:from_date) {'2015-01-01'}
      let(:to_date) {'2015-01-25'}
      let(:sta_count_dates) {{"BALANCE_ROW_COUNT"=> 2}}
      let(:sta_open_balances) {{"ACCOUNT_NUMBER"=> '020022', "OPEN_BALANCE"=> 10000.00, "TRANS_DATE"=>"09-Jan-2015 12:00 AM"}}
      let(:sta_open_to_adjust_value) {{"ACCCOUNT_NUMBER"=> '022011', "ADJUST_TRANS_COUNT"=> 1, "MIN_DATE"=>"02-Jan-2015 12:00 AM","AMOUNT_TO_ADJUST"=> 0.63}}
      let(:sta_close_balances) {{"ACCOUNT_NUMBER"=> '022011', "BALANCE"=> 9499.99, "TRANS_DATE"=>"21-Jan-2015 12:00 AM"}}
      let(:sta_close_balances2) {{"ACCOUNT_NUMBER"=> '022011', "BALANCE"=> 10000.00, "TRANS_DATE"=>"24-Jan-2015 12:00 AM"}}
      let(:sta_breakdown1) {{"TRANS_DATE" =>"21-Jan-2015 12:00 AM",  "REFNUMBER"=> nil,"DESCR"=> 'Interest Rate / Daily Balance',
                            "DEBIT" => 0, "CREDIT" => 0, "RATE" =>0.12,
                            "BALANCE"=> 9499.99}}
      let(:sta_breakdown2) {{"TRANS_DATE" =>"21-Jan-2015 12:00 AM",  "REFNUMBER"=> "F99999","DESCR"=> 'SECURITIES SAFEKEEPING FEE',
                             "DEBIT" => 500.01, "CREDIT" => 0, "RATE" =>0,
                             "BALANCE"=> 0}}
      let(:sta_breakdown3) {{"TRANS_DATE" =>"01-Jan-2015 12:00 AM",  "REFNUMBER"=> nil, "DESCR"=> 'INTEREST',
                             "DEBIT" => 0, "CREDIT" => 0.63, "RATE" =>0,
                             "BALANCE"=> 0}}
      let(:result_sta_count) {double('Oracle Result Set', fetch_hash: nil)}
      let(:result_open) {double('Oracle Result Set', fetch_hash: nil)}
      let(:result_adjustment) {double('Oracle Result Set', fetch_hash: nil)}
      let(:result_close) {double('Oracle Result Set', fetch_hash: nil)}
      let(:result_activities) {double('Oracle Result Set', fetch_hash: nil)}
      before do
        expect(MAPI::ServiceApp).to receive(:environment).at_least(1).times.and_return(:production)
        expect(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(result_sta_count)
        expect(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(result_open)
        expect(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(result_adjustment)
        expect(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(result_close)
        expect(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(result_activities)
        allow(result_sta_count).to receive(:fetch_hash).and_return(sta_count_dates, nil)
        allow(result_open).to receive(:fetch_hash).and_return(sta_open_balances, nil)
        allow(result_adjustment).to receive(:fetch_hash).and_return(sta_open_to_adjust_value, nil)
        allow(result_close).to receive(:fetch_hash).and_return(sta_close_balances, nil)
        allow(result_activities).to receive(:fetch_hash).and_return(sta_breakdown1, sta_breakdown2, sta_breakdown3, nil)
      end

      it_behaves_like 'a STA activities endpoint'

      it 'should has 3 rows of activities based on the fake data' do
        expect(sta_activities['activities'].count).to eq(3)
      end
      it 'should return expected balance value and date for Opening balance to be adjusted' do
        expect(sta_activities['start_balance']).to eq(10000.00 - 0.63)
        expect(sta_activities['start_date'].to_s).to eq('2015-01-02')
      end
      it 'should return the expected close balance and date which is what returned from database and not the date passed in' do
        expect(sta_activities['end_balance']).to eq(9499.99)
        expect(sta_activities['end_date'].to_s).to eq('2015-01-21')
      end
      it 'should return expected activities values' do
        sta_activities['activities'].each do |activity|
          case  activity['descr']
          when 'Interest Rate / Daily Balance'
            expect(activity['trans_date'].to_s).to eq('2015-01-21')
            expect(activity['refnumber']).to eq(nil)
            expect(activity['debit']).to eq(nil)
            expect(activity['credit']).to eq(nil)
            expect(activity['balance']).to eq(9499.99)
            expect(activity['rate']).to eq(0.12)
          when 'SECURITIES SAFEKEEPING FEE'
            expect(activity['trans_date'].to_s).to eq('2015-01-21')
            expect(activity['refnumber']).to eq('F99999')
            expect(activity['debit']).to eq(500.01)
            expect(activity['credit']).to eq(nil)
            expect(activity['balance']).to eq(nil)
            expect(activity['rate']).to eq(0)
          else
            expect(activity['trans_date'].to_s).to eq('2015-01-01')
            expect(activity['refnumber']).to eq(nil)
            expect(activity['debit']).to eq(nil)
            expect(activity['credit']).to eq(0.63)
            expect(activity['balance']).to eq(nil)
            expect(activity['rate']).to eq(0)
          end
        end

      end

      it 'should return start date and end date that are returned from the open & close balance queries when there is no adjustment' do
        expect(result_sta_count).to receive(:fetch_hash).and_return(sta_count_dates, nil).at_least(1).times
        expect(result_open).to receive(:fetch_hash).and_return(sta_open_balances, nil).at_least(1).times
        expect(result_adjustment).to receive(:fetch_hash).and_return(nil)
        expect(result_close).to receive(:fetch_hash).and_return(sta_close_balances, nil).at_least(1).times
        expect(result_activities).to receive(:fetch_hash).and_return(sta_breakdown1, nil).at_least(1).times
        expect(sta_activities['start_balance']).to eq(10000.00)
        expect(sta_activities['end_balance']).to eq(9499.99,)
        expect(sta_activities['start_date'].to_s).to eq('2015-01-09')
        expect(sta_activities['end_date'].to_s).to eq('2015-01-21')
        expect(sta_activities['activities'].count).to eq(1)
      end

      it 'should return 0 activites row if there are balances that did not changed' do
        expect(result_sta_count).to receive(:fetch_hash).and_return(sta_count_dates, nil).at_least(1).times
        expect(result_open).to receive(:fetch_hash).and_return(sta_open_balances, nil).at_least(1).times
        expect(result_adjustment).to receive(:fetch_hash).and_return(nil)
        expect(result_close).to receive(:fetch_hash).and_return(sta_close_balances2, nil).at_least(1).times
        expect(result_activities).to receive(:fetch_hash).and_return(nil)
        expect(sta_activities['start_balance']).to eq(10000.00)
        expect(sta_activities['end_balance']).to eq(10000.00,)
        expect(sta_activities['start_date'].to_s).to eq('2015-01-09')
        expect(sta_activities['end_date'].to_s).to eq('2015-01-24')
        expect(sta_activities['activities'].count).to eq(0)
      end
    end
    describe 'in the production environment with 0 row count' do
      let(:from_date) {'2015-01-01'}
      let(:to_date) {'2015-01-21'}
      let(:sta_count_0) {{"BALANCE_ROW_COUNT"=> 0}}
      let(:result_sta_count) {double('Oracle Result Set', fetch_hash: nil)}
      before do
        expect(MAPI::ServiceApp).to receive(:environment).at_least(1).times.and_return(:production)
        expect(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(result_sta_count)
        allow(result_sta_count).to receive(:fetch_hash).and_return(sta_count_0, nil)
      end
      it 'invalid param result in 404 if row count is 0' do
        get "/member/#{MEMBER_ID}/sta_activities/#{from_date}/#{to_date}"
        expect(last_response.status).to eq(404)
      end
    end
  end
end
