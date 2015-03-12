require 'spec_helper'

describe MAPI::ServiceApp do

  let(:as_of_date)  {Time.now.in_time_zone(MAPI::Shared::Constants::ETRANSACT_TIME_ZONE).to_date-1}

  let(:advances_historical){{"ADVDET_ADVANCE_NUMBER"=> "330006", "ADVDET_CURRENT_PAR"=> 3000000, "ADV_DAY_COUNT"=> "ACT/365",
                             "ADV_PAYMENT_FREQ"=> "13W", "ADX_INTEREST_RECEIVABLE"=>  6305.75, "ADX_NEXT_INT_PAYMENT_DATE"=> "28-FEB-2014 12:00 AM",
                             "ADVDET_INTEREST_RATE"=> 2.74, "ADVDET_ISSUE_DATE"=> "23-SEP-2013 12:00 AM", "ADVDET_MATURITY_DATE"=>  "31-DEC-2018 12:00 AM",
                             "ADVDET_MNEMONIC"=>  "FRC",  "ADVDET_DATEUPDATE"=>  "27-JAN-2014 12:00 AM",  "ADVDET_SUBSIDY_PROGRAM"=> nil,
                             "TRADE_DATE"=> "23-SEP-2014 12:00 AM", "FUTURE_INTEREST"=> 6981.37, "ADV_INDEX"=> "USD-VRC-FHLBSF 1D",
                             "TOTAL_PREPAY_FEES"=>  nil, "SA_TOTAL_PREPAY_FEES"=>  nil ,  "SA_INDICATION_VALUATION_DATE"=> nil}}

  before do
    header 'Authorization', "Token token=\"#{ENV['MAPI_SECRET_TOKEN']}\""
  end
  describe 'Advances Details' do
    let(:advances) { get "/member/#{MEMBER_ID}/advances_details/#{as_of_date}"; JSON.parse(last_response.body) }
    valid_payment_frequencies = ['Monthly','Annually','Every 13 weeks', 'Every 9 weeks','Every 4 weeks','Semiannually','Every 26 weeks','Daily']
    valid_day_count_basis = ['Actual/Actual','Actual/365','30/360','Actual/360']
    RSpec.shared_examples 'Advances Details endpoint' do
      it 'should return a date for as_of_date' do
        expect(advances['as_of_date']).to match(MAPI::Shared::Constants::REPORT_PARAM_DATE_FORMAT)
      end
      it 'should return expected advances detail hash where value could not be nil' do
        advances['advances_details'].each do |row|
          expect(row['trade_date'].to_s).to match(MAPI::Shared::Constants::REPORT_PARAM_DATE_FORMAT)
          expect(row['funding_date'].to_s).to match(MAPI::Shared::Constants::REPORT_PARAM_DATE_FORMAT)
          expect(row['interest_payment_frequency'].to_s).to be_kind_of(String)
          expect(row['day_count_basis'].to_s).to be_kind_of(String)
          expect(row['advance_type'].to_s).to be_kind_of(String)
          expect(row['advance_number'].to_s).to be_kind_of(String)
          expect(row['current_par']).to be_kind_of(Numeric)
          expect(row['interest_rate']).to be_kind_of(Numeric)
          expect(row['open_vrc_indicator']).to be_boolean
          if (row['open_vrc_indicator'])
            expect(row['maturity_date']).to be_nil
          else
            expect(row['maturity_date'].to_s).to match(MAPI::Shared::Constants::REPORT_PARAM_DATE_FORMAT)
          end
        end
      end
    end

    describe 'in the development environment' do
      it 'should return 4 or 6 rows when reading from current fake data ' do
        expect(advances['structured_product_indication_date'].to_s).to match(MAPI::Shared::Constants::REPORT_PARAM_DATE_FORMAT)
        advances['advances_details'].each do |row|
          expect(row['estimated_next_interest_payment']).to be_kind_of(Numeric)
          expect(row['next_interest_pay_date']).to match(MAPI::Shared::Constants::REPORT_PARAM_DATE_FORMAT)
          expect(row['discount_program']).to be_kind_of(String).or be_nil
          expect(row['prepayment_fee_indication']).to be_kind_of(Numeric).or be_nil
          expect(row['estimated_next_interest_payment']).to be_kind_of(Numeric)
          expect(row['next_interest_pay_date']).to match(MAPI::Shared::Constants::REPORT_PARAM_DATE_FORMAT)

          if row['prepayment_fee_indication'] ==  nil
            expect(row['structure_product_prepay_valuation_date']).to be_nil
            expect(row['notes'].to_s).to be_kind_of(String)
          else
            expect(row['prepayment_fee_indication']).to be_kind_of(Numeric)
            expect(row['structure_product_prepay_valuation_date']).to be_nil.or match(MAPI::Shared::Constants::REPORT_PARAM_DATE_FORMAT)
          end
        end
      end

      it_behaves_like 'Advances Details endpoint'
    end

    describe 'in development environment, if date is before yesterday, it should get historical data' do
      let(:advances) { get "/member/#{MEMBER_ID}/advances_details/2013-01-02"; JSON.parse(last_response.body) }
      it 'should show nil for prepayment related ' do
        advances['advances_details'].each do |row|
          expect(row['prepayment_fee_indication']).to be_nil()
          expect(row['structure_product_prepay_valuation_date']).to be_nil()
        end
      end

      it_behaves_like 'Advances Details endpoint'
    end

    it 'invalid param or future date result in 400 error message' do
      future_date = Time.now.in_time_zone(MAPI::Shared::Constants::ETRANSACT_TIME_ZONE).to_date+1
      get "/member/#{MEMBER_ID}/advances_details/12-12-2014"
      expect(last_response.status).to eq(400)
      get "/member/#{MEMBER_ID}/advances_details/#{future_date}"
      expect(last_response.status).to eq(400)
    end

    describe 'in the production environment with the date that is yesterday to get latest EOD image' do
      let(:advances_current1a) {{"ADVDET_ADVANCE_NUMBER"=> "330111", "ADVDET_CURRENT_PAR"=> 7000000, "ADV_DAY_COUNT"=>"ACT/ACT", "ADV_PAYMENT_FREQ"=> "ME",
                                 "ADX_INTEREST_RECEIVABLE"=> 10095.34, "ADX_NEXT_INT_PAYMENT_DATE"=> "02-FEB-2015 12:00 AM", "ADVDET_INTEREST_RATE"=> 1.88,
                                 "ADVDET_ISSUE_DATE"=> "23-SEP-2013 12:00 AM", "ADVDET_MATURITY_DATE"=> "24-SEP-2018 12:00 AM", "ADVDET_MNEMONIC"=> "FRC",
                                 "ADVDET_DATEUPDATE"=> "27-JAN-2015 12:00 AM", "ADVDET_SUBSIDY_PROGRAM"=> nil, "TRADE_DATE"=> "23-SEP-2013 12:00 AM",
                                 "FUTURE_INTEREST"=> 11176.99, "ADV_INDEX"=> nil, "TOTAL_PREPAY_FEES"=> nil, "SA_TOTAL_PREPAY_FEES"=> 187049.23,
                                 "SA_INDICATION_VALUATION_DATE"=> "31-DEC-2014 12:00 AM"}}
      let(:advances_current2a){{"ADVDET_ADVANCE_NUMBER"=> "330112", "ADVDET_CURRENT_PAR"=> 3000000, "ADV_DAY_COUNT"=> "ACT/360",
                                "ADV_PAYMENT_FREQ"=> "IAM", "ADX_INTEREST_RECEIVABLE"=>  6305.75, "ADX_NEXT_INT_PAYMENT_DATE"=> "28-FEB-2015 12:00 AM",
                                "ADVDET_INTEREST_RATE"=> 2.74, "ADVDET_ISSUE_DATE"=> "23-SEP-2013 12:00 AM", "ADVDET_MATURITY_DATE"=>  "31-DEC-2038 12:00 AM",
                                "ADVDET_MNEMONIC"=>  "VRC-OPEN",  "ADVDET_DATEUPDATE"=>  "27-JAN-2015 12:00 AM",  "ADVDET_SUBSIDY_PROGRAM"=> nil,
                                "TRADE_DATE"=> "23-SEP-2013 12:00 AM", "FUTURE_INTEREST"=> 6981.37, "ADV_INDEX"=> "USD-VRC-FHLBSF 1D",
                                "TOTAL_PREPAY_FEES"=>  nil, "SA_TOTAL_PREPAY_FEES"=>  nil ,  "SA_INDICATION_VALUATION_DATE"=> nil}}
      let(:result_set1) {double('Oracle Result Set', fetch_hash: nil)}

      before do
        expect(MAPI::ServiceApp).to receive(:environment).at_least(1).times.and_return(:production)
        expect(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(result_set1)
        allow(result_set1).to receive(:fetch_hash).and_return(advances_current1a, nil)
      end

      it_behaves_like 'Advances Details endpoint'

      it 'should translated the payment frequency and day count basis, structured product indication, notes correctly for the latest advances details' do
        advances['advances_details'].each do |row|
          expect(row['interest_payment_frequency']).to eq('Monthend')
          expect(row['day_count_basis']).to eq('Actual/Actual')
          expect(row['prepayment_fee_indication']).to eq(187049.23)
          expect(row['structure_product_prepay_valuation_date'].to_date).to eq('2014-12-31'.to_date)
        end
      end

      it 'should show maturity date as nil when it is open VRC and maturity date is 2038-12-31' do
        expect(result_set1).to receive(:fetch_hash).and_return(advances_current2a, nil)
        advances['advances_details'].each do |row|
          expect(row['interest_payment_frequency']).to eq('At Maturity')
          expect(row['day_count_basis']).to eq('Actual/360')
          expect(row['maturity_date']).to eq(nil)
        end
      end


    end
    describe 'in the production environment with the date that yesterday to get current image' do
      let(:advances_current1) {{"ADVDET_ADVANCE_NUMBER"=> "330113", "ADVDET_CURRENT_PAR"=> 7000000, "ADV_DAY_COUNT"=>"A360", "ADV_PAYMENT_FREQ"=> "M",
                                "ADX_INTEREST_RECEIVABLE"=> 10095.34, "ADX_NEXT_INT_PAYMENT_DATE"=> "02-FEB-2015 12:00 AM", "ADVDET_INTEREST_RATE"=> 1.88,
                                "ADVDET_ISSUE_DATE"=> "23-SEP-2013 12:00 AM", "ADVDET_MATURITY_DATE"=> "24-SEP-2018 12:00 AM", "ADVDET_MNEMONIC"=> "FRC",
                                "ADVDET_DATEUPDATE"=> "27-JAN-2015 12:00 AM", "ADVDET_SUBSIDY_PROGRAM"=> nil, "TRADE_DATE"=> "23-SEP-2013 12:00 AM",
                                "FUTURE_INTEREST"=> 11176.99, "ADV_INDEX"=> nil, "TOTAL_PREPAY_FEES"=> nil, "SA_TOTAL_PREPAY_FEES"=> nil,
                                "SA_INDICATION_VALUATION_DATE"=> nil}}
      let(:advances_current2){{"ADVDET_ADVANCE_NUMBER"=> "330114", "ADVDET_CURRENT_PAR"=> 3000000, "ADV_DAY_COUNT"=> "ACT365",
                               "ADV_PAYMENT_FREQ"=> "A", "ADX_INTEREST_RECEIVABLE"=>  6305.75, "ADX_NEXT_INT_PAYMENT_DATE"=> "28-FEB-2015 12:00 AM",
                               "ADVDET_INTEREST_RATE"=> 2.74, "ADVDET_ISSUE_DATE"=> "23-SEP-2013 12:00 AM", "ADVDET_MATURITY_DATE"=>  "31-DEC-2038 12:00 AM",
                               "ADVDET_MNEMONIC"=>  "VRC-OPEN",  "ADVDET_DATEUPDATE"=>  "27-JAN-2015 12:00 AM",  "ADVDET_SUBSIDY_PROGRAM"=> nil,
                               "TRADE_DATE"=> "23-SEP-2013 12:00 AM", "FUTURE_INTEREST"=> 6981.37, "ADV_INDEX"=> "USD-VRC-FHLBSF 1D",
                               "TOTAL_PREPAY_FEES"=>  nil, "SA_TOTAL_PREPAY_FEES"=>  nil ,  "SA_INDICATION_VALUATION_DATE"=> nil}}
      let(:advances_current3){{"ADVDET_ADVANCE_NUMBER"=> "330117", "ADVDET_CURRENT_PAR"=> 3000000, "ADV_DAY_COUNT"=> "ACT/ACT",
                               "ADV_PAYMENT_FREQ"=> "9W", "ADX_INTEREST_RECEIVABLE"=>  6305.75, "ADX_NEXT_INT_PAYMENT_DATE"=> "28-FEB-2015 12:00 AM",
                               "ADVDET_INTEREST_RATE"=> 1.23456, "ADVDET_ISSUE_DATE"=> "23-SEP-2013 12:00 AM", "ADVDET_MATURITY_DATE"=>  "31-DEC-2038 12:00 AM",
                               "ADVDET_MNEMONIC"=>  "ARC-LIBOR",  "ADVDET_DATEUPDATE"=>  "27-JAN-2015 12:00 AM",  "ADVDET_SUBSIDY_PROGRAM"=> nil,
                               "TRADE_DATE"=> "23-SEP-2013 12:00 AM", "FUTURE_INTEREST"=> 6981.37, "ADV_INDEX"=> "USD-LIBOR-BBA 1M",
                               "TOTAL_PREPAY_FEES"=>  nil, "SA_TOTAL_PREPAY_FEES"=>  nil ,  "SA_INDICATION_VALUATION_DATE"=> nil}}
      let(:advances_current4){{"ADVDET_ADVANCE_NUMBER"=> "330116", "ADVDET_CURRENT_PAR"=> 8111111, "ADV_DAY_COUNT"=> "A365",
                               "ADV_PAYMENT_FREQ"=> "4W", "ADX_INTEREST_RECEIVABLE"=>  6000.75, "ADX_NEXT_INT_PAYMENT_DATE"=> "28-FEB-2015 12:00 AM",
                               "ADVDET_INTEREST_RATE"=> 2.74, "ADVDET_ISSUE_DATE"=> "23-SEP-2013 12:00 AM", "ADVDET_MATURITY_DATE"=>  "31-DEC-2038 12:00 AM",
                               "ADVDET_MNEMONIC"=>  "VRC-OPEN",  "ADVDET_DATEUPDATE"=>  "27-JAN-2015 12:00 AM",  "ADVDET_SUBSIDY_PROGRAM"=> nil,
                               "TRADE_DATE"=> "23-SEP-2013 12:00 AM", "FUTURE_INTEREST"=> 6981.37, "ADV_INDEX"=> "USD-VRC-FHLBSF 1D",
                               "TOTAL_PREPAY_FEES"=>  nil, "SA_TOTAL_PREPAY_FEES"=>  nil ,  "SA_INDICATION_VALUATION_DATE"=> nil}}
      let(:advances_current5){{"ADVDET_ADVANCE_NUMBER"=> "330115", "ADVDET_CURRENT_PAR"=> 3000000, "ADV_DAY_COUNT"=> "ACT/ACT",
                               "ADV_PAYMENT_FREQ"=> "Q", "ADX_INTEREST_RECEIVABLE"=>  6305.75, "ADX_NEXT_INT_PAYMENT_DATE"=> "28-FEB-2015 12:00 AM",
                               "ADVDET_INTEREST_RATE"=> 2.74, "ADVDET_ISSUE_DATE"=> "23-SEP-2013 12:00 AM", "ADVDET_MATURITY_DATE"=>  "31-DEC-2038 12:00 AM",
                               "ADVDET_MNEMONIC"=>  "VRC-OPEN",  "ADVDET_DATEUPDATE"=>  "27-JAN-2015 12:00 AM",  "ADVDET_SUBSIDY_PROGRAM"=> nil,
                               "TRADE_DATE"=> "23-SEP-2013 12:00 AM", "FUTURE_INTEREST"=> 6981.37, "ADV_INDEX"=> "USD-VRC-FHLBSF 1D",
                               "TOTAL_PREPAY_FEES"=>  nil, "SA_TOTAL_PREPAY_FEES"=>  nil ,  "SA_INDICATION_VALUATION_DATE"=> nil}}


      let(:result_set1) {double('Oracle Result Set', fetch_hash: nil)}

      before do
        expect(MAPI::ServiceApp).to receive(:environment).at_least(1).times.and_return(:production)
        expect(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(result_set1)
        allow(result_set1).to receive(:fetch_hash).and_return(advances_current1, advances_current2, advances_current3, advances_current4,  nil)
      end

      it_behaves_like 'Advances Details endpoint'

      it 'should return the multiple advances_details rows' do
        expect(advances['advances_details'].count()).to eq(4)
      end

      it 'should translated the payment frequency and day count basis' do
        advances['advances_details'].each do |row|

          expect(valid_payment_frequencies).to include(row['interest_payment_frequency'])
          expect(valid_day_count_basis).to include(row['day_count_basis'])
          expect(row['prepayment_fee_indication']).to be_nil
          expect(row['structure_product_prepay_valuation_date']).to be_nil

          if row['open_vrc_indicator']
            expect(row['maturity_date']).to be_nil
          else
            expect(row['maturity_date'].to_s).to match(MAPI::Shared::Constants::REPORT_PARAM_DATE_FORMAT)
          end
        end
      end

      it 'should show maturity date as nil when it is open VRC and maturity date is 2038-12-31' do
        expect(result_set1).to receive(:fetch_hash).and_return(advances_current5, nil)
        advances['advances_details'].each do |row|
          expect(row['interest_payment_frequency']).to eq('Quarterly')
          expect(row['day_count_basis']).to eq('Actual/Actual')
          expect(row['maturity_date']).to eq(nil)
          expect(row['open_vrc_indicator']).to eq(true)
        end
      end


    end

    describe 'in the production environment with the date that is yesterday but no current image and should get historical image' do
      let(:advances_historical2){{"ADVDET_ADVANCE_NUMBER"=> "330005", "ADVDET_CURRENT_PAR"=> 3000001, "ADV_DAY_COUNT"=> "BOND",
                                  "ADV_PAYMENT_FREQ"=> "26W", "ADX_INTEREST_RECEIVABLE"=>  6305.75, "ADX_NEXT_INT_PAYMENT_DATE"=> "28-FEB-2014 12:00 AM",
                                  "ADVDET_INTEREST_RATE"=> 2.74, "ADVDET_ISSUE_DATE"=> "23-SEP-2013 12:00 AM", "ADVDET_MATURITY_DATE"=>  "01-DEC-2016 12:00 AM",
                                  "ADVDET_MNEMONIC"=>  "FRC",  "ADVDET_DATEUPDATE"=>  "27-JAN-2014 12:00 AM",  "ADVDET_SUBSIDY_PROGRAM"=> nil,
                                  "TRADE_DATE"=> "23-SEP-2014 12:00 AM", "FUTURE_INTEREST"=> 6981.37, "ADV_INDEX"=> "USD-VRC-FHLBSF 1D",
                                  "TOTAL_PREPAY_FEES"=>  nil, "SA_TOTAL_PREPAY_FEES"=>  nil ,  "SA_INDICATION_VALUATION_DATE"=> nil}}
      let(:advances_historical3){{"ADVDET_ADVANCE_NUMBER"=> "330001", "ADVDET_CURRENT_PAR"=> 3000000, "ADV_DAY_COUNT"=> "30/360",
                                  "ADV_PAYMENT_FREQ"=> "D", "ADX_INTEREST_RECEIVABLE"=>  6305.75, "ADX_NEXT_INT_PAYMENT_DATE"=> "28-FEB-2015 12:00 AM",
                                  "ADVDET_INTEREST_RATE"=> 2.74, "ADVDET_ISSUE_DATE"=> "23-SEP-2013 12:00 AM", "ADVDET_MATURITY_DATE"=>  "31-DEC-2038 12:00 AM",
                                  "ADVDET_MNEMONIC"=>  "VRC-OPEN",  "ADVDET_DATEUPDATE"=>  "27-JAN-2015 12:00 AM",  "ADVDET_SUBSIDY_PROGRAM"=> nil,
                                  "TRADE_DATE"=> "23-SEP-2013 12:00 AM", "FUTURE_INTEREST"=> 6981.37, "ADV_INDEX"=> "USD-VRC-FHLBSF 1D",
                                  "TOTAL_PREPAY_FEES"=>  nil, "SA_TOTAL_PREPAY_FEES"=>  nil ,  "SA_INDICATION_VALUATION_DATE"=> nil}}

      let(:result_set1) {double('Oracle Result Set', fetch_hash: nil)}
      let(:result_set2) {double('Oracle Result Set', fetch_hash: nil)}
      before do
        expect(MAPI::ServiceApp).to receive(:environment).at_least(1).times.and_return(:production)
        expect(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(result_set1)
        expect(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(result_set2)
        allow(result_set1).to receive(:fetch_hash).and_return(nil)
        allow(result_set2).to receive(:fetch_hash).and_return(advances_historical, advances_historical2, advances_historical3,  nil)
      end

      it_behaves_like 'Advances Details endpoint'

      it 'should return the same number of advances_details rows retrieved' do
        expect(advances['advances_details'].count()).to eq(3)
      end

      it 'should return historical row if date is yesterday but not current image found' do
        advances['advances_details'].each do |row|
          expect(valid_payment_frequencies).to include(row['interest_payment_frequency'])
          expect(valid_day_count_basis).to include(row['day_count_basis'])
          expect(row['prepayment_fee_indication']).to eq(nil)
          expect(row['structure_product_prepay_valuation_date']).to eq(nil)

          if row['open_vrc_indicator']
            expect(row['maturity_date']).to be_nil
          else
            expect(row['maturity_date'].to_s).to match(MAPI::Shared::Constants::REPORT_PARAM_DATE_FORMAT)
          end
        end
      end
    end
    describe 'in the production environment with the date that is older than yesterday should only retrieve once from database' do

      let(:result_set1) {double('Oracle Result Set', fetch_hash: nil)}

      before do
        expect(MAPI::ServiceApp).to receive(:environment).at_least(1).times.and_return(:production)
        expect(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(result_set1)
        allow(result_set1).to receive(:fetch_hash).and_return(advances_historical,  nil)
      end

      it_behaves_like 'Advances Details endpoint'


      it 'should return historical row if date is yesterday but not current image found' do
        advances['advances_details'].each do |row|
          expect(row['interest_payment_frequency']).to eq('Every 13 weeks')
          expect(row['day_count_basis']).to eq('Actual/365')
          expect(row['maturity_date'].to_s).to eq('2018-12-31')
          expect(row['prepayment_fee_indication']).to eq(nil)
          expect(row['structure_product_prepay_valuation_date']).to eq(nil)
          expect(row['open_vrc_indicator']).to eq(false)
        end
      end
    end
  end
end