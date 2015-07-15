require 'spec_helper'

describe MAPI::ServiceApp do

  before do
    header 'Authorization', "Token token=\"#{ENV['MAPI_SECRET_TOKEN']}\""
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
          expect(activity['refnumber']).to be_kind_of(String).or be_nil
          expect(activity['descr']).to be_kind_of(String)
          expect(activity['debit']).to be_kind_of(Numeric).or be_nil
          expect(activity['credit']).to be_kind_of(Numeric).or be_nil
          expect(activity['debit'] || activity['credit'] || activity['balance']).to_not be_nil
          expect(activity['balance']).to be_kind_of(Numeric).or be_nil
          expect(activity['rate']).to be_kind_of(Numeric).or be_nil
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

      it 'should have activities for the given date range' do
        sta_activities['activities'].each do |activity|
          expect(activity['trans_date'] >= from_date && activity['trans_date'] <= to_date)
        end
        min_number_of_days = 0
        (from_date.to_date..to_date.to_date).each do |date|
          day_of_week = date.wday
          min_number_of_days += 1 if day_of_week != 0 && day_of_week != 6
        end
        expect(sta_activities['activities'].count).to be > min_number_of_days
      end
      describe 'small date range' do
        let(:from_date) {'2014-01-01'}
        let(:to_date) {'2014-01-03'}
        it 'should have activities for the given date range' do
          sta_activities['activities'].each do |activity|
            expect(activity['trans_date'] >= from_date && activity['trans_date'] <= to_date)
          end
          min_number_of_days = 0
          (from_date.to_date..to_date.to_date).each do |date|
            day_of_week = date.wday
            min_number_of_days += 1 if day_of_week != 0 && day_of_week != 6
          end
          expect(sta_activities['activities'].count).to be > min_number_of_days
        end
      end
    end
    describe 'in the production environment' do
      let(:from_date) {'2015-01-01'}
      let(:to_date) {'2015-01-25'}
      let(:sta_count_dates) {{"BALANCE_ROW_COUNT"=> 2}}
      let(:sta_open_balances) {{"ACCOUNT_NUMBER"=> '020022', "OPEN_BALANCE"=> "10000.00", "TRANS_DATE"=>"09-Jan-2015 12:00 AM"}}
      let(:sta_open_to_adjust_value) {{"ACCCOUNT_NUMBER"=> '022011', "ADJUST_TRANS_COUNT"=> 1, "MIN_DATE"=>"02-Jan-2015 12:00 AM","AMOUNT_TO_ADJUST"=> 0.63}}
      let(:sta_close_balances) {{"ACCOUNT_NUMBER"=> '022011', "BALANCE"=> "9499.99", "TRANS_DATE"=>"21-Jan-2015 12:00 AM"}}
      let(:sta_close_balances2) {{"ACCOUNT_NUMBER"=> '022011', "BALANCE"=> "10000.00", "TRANS_DATE"=>"24-Jan-2015 12:00 AM"}}
      let(:sta_breakdown1) {{"TRANS_DATE" =>"21-Jan-2015 12:00 AM",  "REFNUMBER"=> nil,"DESCR"=> 'Interest Rate / Daily Balance',
                             "DEBIT" => "0", "CREDIT" => "0", "RATE" => "0.12",
                             "BALANCE"=> "9499.99"}}
      let(:sta_breakdown2) {{"TRANS_DATE" =>"21-Jan-2015 12:00 AM",  "REFNUMBER"=> "F99999","DESCR"=> 'SECURITIES SAFEKEEPING FEE',
                             "DEBIT" => "500.01", "CREDIT" => "0", "RATE" =>"0",
                             "BALANCE"=> "0"}}
      let(:sta_breakdown3) {{"TRANS_DATE" =>"01-Jan-2015 12:00 AM",  "REFNUMBER"=> nil, "DESCR"=> 'INTEREST',
                             "DEBIT" => "0", "CREDIT" => "0.63", "RATE" => "0",
                             "BALANCE"=> "0"}}
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

  describe 'current_sta_rate' do
    let(:sta_rate_data) { JSON.parse(File.read(File.join(MAPI.root, 'spec', 'fixtures', 'current_sta_rate.json')))
    }
    let(:current_sta_rate) { MAPI::Services::Member::SettlementTransactionAccount.current_sta_rate(subject, MEMBER_ID) }

    it 'calls the `current_sta_rate` method when the endpoint is hit' do
      allow(MAPI::Services::Member::SettlementTransactionAccount).to receive(:current_sta_rate).and_return('a response')
      get "/member/#{MEMBER_ID}/current_sta_rate"
      expect(last_response.status).to eq(200)
    end

    [:test, :production].each do |env|
      describe "`current_sta_rate` method in the #{env} environment" do
        let(:sta_rate_result_set) {double('Oracle Result Set', fetch_hash: nil)} if env == :production
        let(:sta_rate_result) {[sta_rate_data[0], nil]} if env == :production

        before do
          if env == :production
            allow(MAPI::ServiceApp).to receive(:environment).at_least(1).and_return(:production)
            allow(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(sta_rate_result_set)
            allow(sta_rate_result_set).to receive(:fetch_hash).and_return(*sta_rate_result)
          end
        end
        it "returns an object with a `date` attribute" do
          expect(current_sta_rate[:date]).to be_kind_of(Date)
        end
        it "returns an object with a `rate` attribute" do
          expect(current_sta_rate[:rate]).to be_kind_of(Float)
        end
        it "returns an object with an `account_number` attribute" do
          expect(current_sta_rate[:account_number]).to be_kind_of(String)
        end
        describe 'with no data' do
          before do
            if env == :production
              allow(sta_rate_result_set).to receive(:fetch_hash).and_return(nil)
            else
              allow(JSON).to receive(:parse).and_return(JSON.parse(File.read(File.join(MAPI.root, 'spec', 'fixtures', 'current_sta_rate_null_values.json'))))
              allow(MAPI::Services::Member::CashProjections::Private).to receive(:fake_as_of_date).and_return(nil)
            end
          end
          %w(date rate account_number).each do |attr|
            it "returns nil for the #{attr} attribute" do
              expect(current_sta_rate[attr.to_sym]).to be_nil
            end
          end
        end

      end
    end

  end
end