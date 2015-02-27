require 'spec_helper'

describe MAPI::ServiceApp do
  before do
    header 'Authorization', "Token token=\"#{ENV['MAPI_SECRET_TOKEN']}\""
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
          else
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
end