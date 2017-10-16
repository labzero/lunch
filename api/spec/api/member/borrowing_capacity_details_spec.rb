require 'spec_helper'

describe MAPI::ServiceApp do
  describe 'is borrowing capacity data available' do
    let(:logger) { double('logger') }
    let(:app) { instance_double(MAPI::ServiceApp, logger: logger) }
    let(:member_id) { rand(999..99999) }
    let(:as_of_date) { '2017-07-01' }
    let(:borrowing_capacity_data_available) { MAPI::Services::Member::BorrowingCapacity.borrowing_capacity_data_available?(app, member_id, as_of_date) }
    let(:member_hash) { double('member hash') }
    let(:member) { double('member') }
    let(:date) { double('date') }
    let(:as_of_date_obj) { instance_double(Date, strftime: nil) }
    let(:formatted_date) { '201707' }
    before do
      allow(Date).to receive(:parse).and_return(as_of_date_obj)
    end
    describe 'when using fake data' do
      before do
        allow(MAPI::Services::Member::BorrowingCapacity).to receive(:should_fake?).and_return(true)
        allow(MAPI::Services::Member::BorrowingCapacity).to receive(:fake).and_return(member_hash)
        allow(member_hash).to receive(:[]).and_return(member)
        allow(member).to receive(:[]).and_return(date)
        allow(as_of_date_obj).to receive(:strftime).and_return(formatted_date)
        allow(date).to receive(:[])
        allow(member).to receive(:with_indifferent_access)
      end      
      describe 'when fake data is returned properly' do
        it 'gets the date from the member object' do
          expect(member).to receive(:[]).with(formatted_date)
          borrowing_capacity_data_available
        end
        it 'gets the `PERIODVALUE` from the date' do
          allow(member).to receive(:[]).with(formatted_date).and_return(date)
          expect(date).to receive(:[]).with('PERIODVALUE')
          borrowing_capacity_data_available
        end
        describe 'when date has a value' do
          before do
            allow(member).to receive(:[]).with(formatted_date).and_return(date)                  
          end
          it 'returns false if `PERIODVALUE` is nil' do
            allow(date).to receive(:[]).with('PERIODVALUE').and_return(nil)                 
            expect(borrowing_capacity_data_available[:data_available]).to be(false)
          end
          it 'returns true if `PERIODVALUE` is not nil' do
            allow(date).to receive(:[]).with('PERIODVALUE').and_return(double('a value'))                 
            expect(borrowing_capacity_data_available[:data_available]).to be(true)
          end
        end
      end
      describe 'when fake data results in `nil`s' do
        it 'returns `false` if reading the fake returns `nil`' do
          allow(member_hash).to receive(:[]).and_return(nil)
          expect(borrowing_capacity_data_available[:data_available]).to be(false)
        end
        describe 'when the member is not `nil`' do
          before do
            allow(member_hash).to receive(:[]).and_return(member)
          end
          it 'returns `false` if the date object is not found' do
            allow(member).to receive(:[]).and_return(nil)
            expect(borrowing_capacity_data_available[:data_available]).to be(false)
          end
          it 'returns `false` if `PERIODVALUE` is `nil`' do
            allow(date).to receive(:[]).with('PERIODVALUE').and_return(nil)              
            expect(borrowing_capacity_data_available[:data_available]).to be(false)
          end
        end
      end
    end
    describe 'when using real data' do
      let(:results) { double('results') }
      let(:results_hash) { instance_double(Hash, :[] => nil) }
      before do
        allow(MAPI::Services::Member::BorrowingCapacity).to receive(:should_fake?).and_return(false)
        allow(ActiveRecord::Base.connection).to receive(:execute).and_return(results)
        allow(results).to receive(:fetch_hash).and_return(results_hash)
        allow(results_hash).to receive(:[]).and_return(double('data for period'))
      end
      it 'executes SQL' do
          data_available_sql = <<-SQL
          SELECT PERIODVALUE
          FROM FHLBOWN.COLLATERAL_SUMMARY_TYPE_HIST@COLAPROD_LINK.WORLD
          WHERE CUSTOMER_MASTER_ID = #{ActiveRecord::Base.connection.quote(member_id)}
          AND PERIODVALUE = #{ActiveRecord::Base.connection.quote(as_of_date_obj.strftime('%Y%m'))}
          SQL
        expect(ActiveRecord::Base.connection).to receive(:execute).with(data_available_sql)
        borrowing_capacity_data_available
      end
      describe 'when the results get returned' do
        it 'calls fetch_hash' do
          expect(results).to receive(:fetch_hash).and_return(results_hash)
          borrowing_capacity_data_available
        end
        it 'gets a `PERIODVALUE` from results hash' do
          allow(results_hash).to receive(:[]).with('PERIODVALUE').and_return(double('data for period'))
          expect(borrowing_capacity_data_available[:data_available]).to be(true)
        end
        it 'does not get a `PERIODVALUE` from results hash' do
          allow(results_hash).to receive(:[]).with('PERIODVALUE').and_return(nil)
          expect(borrowing_capacity_data_available[:data_available]).to be(false)
        end
      end
    end
  end

  describe 'borrowing capacity details' do
    let(:as_of_date) {'2015-01-14'}
    let(:borrowing_capacity_details) { get "/member/#{member_id}/borrowing_capacity_details/#{as_of_date}"; JSON.parse(last_response.body) }

    describe 'in the dev environment' do
      before do
        allow(MAPI::Services::Member::BorrowingCapacity).to receive(:should_fake?).and_return(true) 
        allow(File).to receive(:join).with(any_args).and_call_original
      end      
      it 'loads the fake for balances' do
        expect(File).to receive(:join).with(MAPI.root, 'fakes', 'borrowing_capacity_balances.json')
        borrowing_capacity_details
      end
      it 'loads the fake for std' do
        expect(File).to receive(:join).with(MAPI.root, 'fakes', 'borrowing_capacity_std_breakdown.json')
        borrowing_capacity_details
      end
    end

    describe 'in the production environment' do
      let(:as_of_date) { Time.zone.today }
      let(:results) { double('results', fetch_hash: nil) }
      before do 
        allow(MAPI::ServiceApp).to receive(:environment).at_least(1).times.and_return(:production)
        allow(ActiveRecord::Base.connection).to receive(:execute).and_return(results)
        allow(results).to receive(:fetch_hash).and_return(nil, nil)
      end

      describe 'when the current month data are requested' do
        before do 
          allow(Date).to receive(:parse).with(anything).and_return(Date.today) 
        end
        it 'executes balances sql for current month' do
          sql = <<-SQL
            SELECT UPDATE_DATE, STD_EXCL_BL_BC, STD_EXCL_BANK_BC, STD_EXCL_REG_BC, STD_SECURITIES_BC, STD_ADVANCES, STD_LETTERS_CDT_USED,
            STD_SWAP_COLL_REQ, STD_COVER_OTHER_PT_DEF, STD_PREPAY_FEES, STD_OTHER_COLL_REQ, STD_MPF_CE_COLL_REQ, STD_COLL_EXCESS_DEF,
            SBC_MV_AA, SBC_BC_AA, SBC_ADVANCES_AA, SBC_COVER_OTHER_AA, SBC_MV_COLL_EXCESS_DEF_AA, SBC_COLL_EXCESS_DEF_AA,
            SBC_MV_AAA, SBC_BC_AAA, SBC_ADVANCES_AAA, SBC_COVER_OTHER_AAA, SBC_MV_COLL_EXCESS_DEF_AAA, SBC_COLL_EXCESS_DEF_AAA,
            SBC_MV_AG, SBC_BC_AG, SBC_ADVANCES_AG, SBC_COVER_OTHER_AG, SBC_MV_COLL_EXCESS_DEF_AG, SBC_COLL_EXCESS_DEF_AG,
            SBC_OTHER_COLL_REQ, SBC_COLL_EXCESS_DEF, STD_TOTAL_BC, SBC_BC, SBC_MV, SBC_ADVANCES, SBC_MV_COLL_EXCESS_DEF
            FROM V_CONFIRM_SUMMARY_INTRADAY@COLAPROD_LINK.WORLD
            WHERE FHLB_ID = #{ActiveRecord::Base.connection.quote(member_id)}
          SQL
          expect(ActiveRecord::Base.connection).to receive(:execute).with(sql).and_return(results)
          borrowing_capacity_details
        end
        it 'executes std breakdown sql for current month' do
          sql = <<-SQL
            SELECT COLLATERAL_TYPE, STD_COUNT, STD_UNPAID_BALANCE, STD_BORROWING_CAPACITY,
            STD_ORIGINAL_AMOUNT, STD_MARKET_VALUE, COLLATERAL_SORT_ID
            FROM V_CONFIRM_DETAIL@COLAPROD_LINK.WORLD
            WHERE FHLB_ID = #{ActiveRecord::Base.connection.quote(member_id)}
            ORDER BY COLLATERAL_SORT_ID
          SQL
          expect(ActiveRecord::Base.connection).to receive(:execute).with(sql).and_return(results)
          borrowing_capacity_details
        end
      end

      describe 'when historical data are requested' do
        let(:past_date) { Date.today - rand(1..6).months }
        before do 
          allow(Date).to receive(:parse).with(anything).and_return(past_date) 
        end
        it 'executes historical balances sql' do
          sql = <<-SQL
            SELECT CUSTOMER_MASTER_ID, STD_EXCL_BL_BC, STD_EXCL_BANK_BC, STD_EXCL_REG_BC, STD_SECURITIES_BC, STD_ADVANCES, STD_LETTERS_CDT_USED,
            STD_SWAP_COLL_REQ, STD_COVER_OTHER_PT_DEF, STD_PREPAY_FEES, STD_OTHER_COLL_REQ, STD_MPF_CE_COLL_REQ, STD_COLL_EXCESS_DEF,
            SBC_MV_AA, SBC_BC_AA, SBC_ADVANCES_AA, SBC_COVER_OTHER_AA, SBC_MV_COLL_EXCESS_DEF_AA, SBC_COLL_EXCESS_DEF_AA,
            SBC_MV_AAA, SBC_BC_AAA, SBC_ADVANCES_AAA, SBC_COVER_OTHER_AAA, SBC_MV_COLL_EXCESS_DEF_AAA, SBC_COLL_EXCESS_DEF_AAA,
            SBC_MV_AG, SBC_BC_AG, SBC_ADVANCES_AG, SBC_COVER_OTHER_AG, SBC_MV_COLL_EXCESS_DEF_AG, SBC_COLL_EXCESS_DEF_AG,
            SBC_OTHER_COLL_REQ, SBC_COLL_EXCESS_DEF, STD_TOTAL_BC, SBC_BC, SBC_MV, SBC_ADVANCES, SBC_MV_COLL_EXCESS_DEF
            FROM FHLBOWN.COLLATERAL_SUMMARY_TYPE_HIST@COLAPROD_LINK.WORLD
            WHERE CUSTOMER_MASTER_ID = #{ActiveRecord::Base.connection.quote(member_id)}
            AND PERIODVALUE = #{ActiveRecord::Base.connection.quote(past_date.strftime('%Y%m'))}
          SQL
          expect(ActiveRecord::Base.connection).to receive(:execute).with(sql).and_return(results)
          borrowing_capacity_details
        end

        it 'executes historical std breakdown sql' do
          sql = <<-SQL
            SELECT COLLATERAL_TYPE, STD_COUNT, STD_UNPAID_BALANCE, STD_BORROWING_CAPACITY, STD_ORIGINAL_AMOUNT, STD_MARKET_VALUE, COLLATERAL_SORT_ID
            FROM FHLBOWN.COLLATERAL_SUMMARY_TYPE_HIST@COLAPROD_LINK.WORLD
            WHERE CUSTOMER_MASTER_ID = #{ActiveRecord::Base.connection.quote(member_id)}
            AND PERIODVALUE = #{ActiveRecord::Base.connection.quote(past_date.strftime('%Y%m'))}
            ORDER BY COLLATERAL_SORT_ID
          SQL
          expect(ActiveRecord::Base.connection).to receive(:execute).with(sql).and_return(results)
          borrowing_capacity_details
        end
      end

      describe 'returning the results' do
        let(:bc_balances) {{"UPDATE_DATE"=> "12-JAN-2015 03:18 PM", "STD_EXCL_BL_BC"=> 20.5, "STD_EXCL_BANK_BC"=> 30.4, "STD_EXCL_REG_BC"=> 40, "STD_SECURITIES_BC"=> 0,
                            "STD_ADVANCES"=> 15000099, "STD_LETTERS_CDT_USED"=> 20, "STD_SWAP_COLL_REQ"=> 10, "STD_COVER_OTHER_PT_DEF"=> 99, "STD_PREPAY_FEES"=> 260,
                            "STD_OTHER_COLL_REQ"=> 70, "STD_MPF_CE_COLL_REQ"=> 155, "STD_COLL_EXCESS_DEF"=> 82911718, "SBC_MV_AA"=> 1, "SBC_BC_AA"=> 2, "SBC_ADVANCES_AA"=> 3,
                            "SBC_COVER_OTHER_AA"=> 4, "SBC_MV_COLL_EXCESS_DEF_AA"=> 5, "SBC_COLL_EXCESS_DEF_AA"=> 6, "SBC_MV_AAA"=> 7, "SBC_BC_AAA"=> 8, "SBC_ADVANCES_AAA"=> 9,
                            "SBC_COVER_OTHER_AAA"=> 10, "SBC_MV_COLL_EXCESS_DEF_AAA"=> 11.4, "SBC_COLL_EXCESS_DEF_AAA"=> 12.5, "SBC_MV_AG"=> 3584326, "SBC_BC_AG"=> 3405110,
                            "SBC_ADVANCES_AG"=> 19, "SBC_COVER_OTHER_AG"=> 1, "SBC_MV_COLL_EXCESS_DEF_AG"=> 3584326, "SBC_COLL_EXCESS_DEF_AG"=> 3584326.6, "SBC_OTHER_COLL_REQ"=>77,
                            "SBC_COLL_EXCESS_DEF"=> 3405110, "STD_TOTAL_BC"=> 97911718, "SBC_BC" => 3405110, "SBC_MV"=> 3584326, "SBC_ADVANCES"=> 0, "SBC_MV_COLL_EXCESS_DEF"=> 3584326}}
        let(:bc_breakdown) {{"COLLATERAL_TYPE" =>"BL SUMMARY - RESIDENTIAL",  "STD_COUNT"=> 1.0,"STD_ORIGINAL_AMOUNT"=> 61335099,
                             "STD_UNPAID_BALANCE" => 58403242, "STD_MARKET_VALUE" => 51394853.5, "STD_BORROWING_CAPACITY" =>40601935.4, "COLLATERAL_SORT_ID"=>"C10"}}
        let(:bc_breakdown2) {{"COLLATERAL_TYPE" =>"BL SUMMARY - MULTIFAMILY",  "STD_COUNT"=> 2.0,"STD_ORIGINAL_AMOUNT"=> 61335099,
                              "STD_UNPAID_BALANCE" => 58403242, "STD_MARKET_VALUE" => 51394853, "STD_BORROWING_CAPACITY" =>40601935, "COLLATERAL_SORT_ID"=>"C12"}}
        let(:result_set1) {double('Oracle Result Set', fetch_hash: nil)}
        let(:result_set2) {double('Oracle Result Set', fetch_hash: nil)}
        before do
          expect(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(result_set1)
          expect(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(result_set2)
          allow(result_set1).to receive(:fetch_hash).and_return(bc_balances, nil)
          allow(result_set2).to receive(:fetch_hash).and_return(bc_breakdown, bc_breakdown2, nil)
        end

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
          expect(result_sbc_collateral).to include('aa', 'aaa', 'agency')
          result_sbc_collateral.each do |collateral_type, row|
            if  collateral_type == 'aa'
              expect(row['total_market_value']).to eq(1)
              expect(row['total_borrowing_capacity']).to eq(2)
              expect(row['advances']).to eq(3)
              expect(row['standard_credit']).to eq(4)
              expect(row['remaining_market_value']).to eq(5)
              expect(row['remaining_borrowing_capacity']).to eq(6)
            elsif collateral_type == 'aaa'
              expect(row['total_market_value']).to eq(7)
              expect(row['total_borrowing_capacity']).to eq(8)
              expect(row['advances']).to eq(9)
              expect(row['standard_credit']).to eq(10)
              expect(row['remaining_market_value']).to eq(11)
              expect(row['remaining_borrowing_capacity']).to eq(13)
            elsif collateral_type == 'agency'
              expect(row['total_market_value']).to eq(3584326)
              expect(row['total_borrowing_capacity']).to eq(3405110)
              expect(row['advances']).to eq(19)
              expect(row['standard_credit']).to eq(1)
              expect(row['remaining_market_value']).to eq(3584326)
              expect(row['remaining_borrowing_capacity']).to eq(3584327)
            else
              raise 'wrong collateral type'
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
          expect(result_sbc_collateral).to include('aa', 'aaa', 'agency')
          result_sbc_collateral.each do |collateral_type, row|
            if  collateral_type == 'aa'
              expect(row['total_market_value']).to eq(0)
              expect(row['total_borrowing_capacity']).to eq(0)
              expect(row['advances']).to eq(0)
              expect(row['standard_credit']).to eq(0)
              expect(row['remaining_market_value']).to eq(0)
              expect(row['remaining_borrowing_capacity']).to eq(0)
            elsif collateral_type == 'aaa'
              expect(row['total_market_value']).to eq(0)
              expect(row['total_borrowing_capacity']).to eq(0)
              expect(row['advances']).to eq(0)
              expect(row['standard_credit']).to eq(0)
              expect(row['remaining_market_value']).to eq(0)
              expect(row['remaining_borrowing_capacity']).to eq(0)
            elsif collateral_type == 'agency'
              expect(row['total_market_value']).to eq(0)
              expect(row['total_borrowing_capacity']).to eq(0)
              expect(row['advances']).to eq(0)
              expect(row['standard_credit']).to eq(0)
              expect(row['remaining_market_value']).to eq(0)
              expect(row['remaining_borrowing_capacity']).to eq(0)
            else
              raise 'wrong collateral type'
            end
          end
        end

        describe 'standard[:securities]' do
          let(:security) { rand(1111111..9999999) + rand() }
          let(:rounded_security) { security.round() }
          let(:new_bc_balances) { bc_balances }

          it 'should return `STD_SECURITIES_BC` as a rounded integer for standard[:securities]' do
            new_bc_balances['STD_SECURITIES_BC'] = security
            allow(result_set1).to receive(:fetch_hash).and_return(new_bc_balances, nil)
            expect(borrowing_capacity_details['standard']['securities']).to eq(rounded_security)
          end
          it 'should return 0 if there is no value for `STD_SECURITIES_BC`' do
            new_bc_balances['STD_SECURITIES_BC'] = nil
            allow(result_set1).to receive(:fetch_hash).and_return(new_bc_balances, nil)
            expect(borrowing_capacity_details['standard']['securities']).to eq(0)
          end
        end

        describe 'standard[:collateral][:count]' do
          let(:count) { rand(1..99) + rand() }
          let(:rounded_count) { count.round() }
          let(:new_bc_breakdown) { bc_breakdown }
          it 'should return `STD_COUNT` as a rounded integer for standard[:collateral][:count]' do
            new_bc_breakdown['STD_COUNT'] = count
            allow(result_set2).to receive(:fetch_hash).and_return(new_bc_breakdown, nil)
            expect(borrowing_capacity_details['standard']['collateral'][0]['count']).to eq(rounded_count)
          end
          it 'should return 0 if there is no value for `STD_COUNT`' do
            new_bc_breakdown['STD_COUNT'] = nil
            allow(result_set2).to receive(:fetch_hash).and_return(new_bc_breakdown, nil)
            expect(borrowing_capacity_details['standard']['collateral'][0]['count']).to eq(0)
          end
        end
      end
    end
  end
end