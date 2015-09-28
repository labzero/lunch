require 'spec_helper'

describe MAPI::ServiceApp do

  before do
    header 'Authorization', "Token token=\"#{ENV['MAPI_SECRET_TOKEN']}\""
  end

  describe 'member dividend_statement' do
    describe 'the `dividend_statement` method' do
      let(:date) {  Date.new(2015,1,11) }
      let(:div_id) { ['2012Q3', '2012Q4', '2013Q1', '2013Q2', '2013Q3', '2013Q4', '2014Q1', '2014Q2', '2014Q3', '2014Q4', '2015Q1', '2015Q2'].sample }
      let(:sta_account_number) { double('an STA account number') }
      let(:dividend_summary_data) { JSON.parse(File.read(File.join(MAPI.root, 'spec', 'fixtures', 'dividend_summary_data.json'))) }
      let(:dividend_details) { JSON.parse(File.read(File.join(MAPI.root, 'spec', 'fixtures', 'dividend_details.json'))) }

      it 'calls the `dividend_statement` method when the endpoint is hit' do
        allow(MAPI::Services::Member::DividendStatement).to receive(:dividend_statement).and_return('a response')
        get "/member/#{MEMBER_ID}/dividend_statement/#{date}/2015Q1"
        expect(last_response.status).to eq(200)
      end

      [:development, :test, :production].each do |env|
        describe "in the #{env} environment" do
          let(:dividend_statement) { MAPI::Services::Member::DividendStatement.dividend_statement(env, MEMBER_ID, date, div_id) }
          if env == :production
            let(:div_id_result_set) {double('Oracle Result Set', fetch_hash: nil)}
            let(:sta_account_number_result_set) {double('Oracle Result Set', fetch: nil)}
            let(:sta_account_number_result) {[sta_account_number]}
            let(:dividend_summary_data_result_set) {double('Oracle Result Set', fetch_hash: nil)}
            let(:dividend_summary_data_result) {dividend_summary_data}
            let(:dividend_details_result_set) {double('Oracle Result Set', fetch_hash: nil)}
            let(:dividend_details_result) {[dividend_details[0],dividend_details[1], dividend_details[2], nil]}

            before do
              allow(MAPI::ServiceApp).to receive(:environment).at_least(1).and_return(:production)
              allow(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(div_id_result_set, sta_account_number_result_set, dividend_summary_data_result_set, dividend_details_result_set)
              allow(div_id_result_set).to receive(:fetch_hash).and_return(*[double('a div id row', :[] => div_id), nil])
              allow(sta_account_number_result_set).to receive(:fetch).and_return(sta_account_number_result)
              allow(dividend_summary_data_result_set).to receive(:fetch_hash).and_return(dividend_summary_data_result)
              allow(dividend_details_result_set).to receive(:fetch_hash).and_return(*dividend_details_result)
            end
          end
          it "returns an object with a `transaction_date` attribute" do
            expect(dividend_statement[:transaction_date]).to be_kind_of(Date)
          end
          it "returns an object with a `shares_dividend` attribute" do
            expect(dividend_statement[:shares_dividend]).to be_kind_of(Integer)
          end
          it "returns an object with a `sta_account_number` attribute" do
            expect(dividend_statement[:sta_account_number]).to be_kind_of(String)
          end
          %w(annualized_rate rate average_shares_outstanding shares_par_value cash_dividend total_dividend).each do |attr|
            it "returns an object with a `#{attr}` attribute" do
              expect(dividend_statement[attr.to_sym]).to be_kind_of(Float)
            end
          end
          it "returns an object with a `details` attribute" do
            expect(dividend_statement[:details]).to be_kind_of(Array)
          end
          describe 'the `details` array' do
            it 'contains objects with a `certificate_sequence`' do
              dividend_statement[:details].each do |dividend|
                expect(dividend[:certificate_sequence]).to be_kind_of(String)
              end
            end
            %w(issue_date start_date end_date).each do |attr|
              it "contains objects with an `#{attr}`" do
                dividend_statement[:details].each do |dividend|
                  expect(dividend[attr.to_sym]).to be_kind_of(Date)
                end
              end
            end
            %w(shares_outstanding days_outstanding).each do |attr|
              it "contains objects with an `#{attr}`" do
                dividend_statement[:details].each do |dividend|
                  expect(dividend[attr.to_sym]).to be_kind_of(Integer)
                end
              end
            end
            %w(average_shares_outstanding dividend).each do |attr|
              it "contains objects with an `#{attr}`" do
                dividend_statement[:details].each do |dividend|
                  expect(dividend[attr.to_sym]).to be_kind_of(Float)
                end
              end
            end
          end
        end
      end
    end
  end

  describe 'private methods' do
    describe '`fake_div_ids`' do
      let(:start_date) { Date.new(2012,1,1) }
      let(:end_date) { Date.new(2015,6,30) }
      let(:div_ids) { %w(2015Q2 2015Q1 2014Q4 2014Q3 2014Q2 2014Q1 2013Q4 2013Q3 2013Q2 2013Q1 2012Q4 2012Q3 2012Q2 2012Q1) }
      let(:fake_div_ids) { MAPI::Services::Member::DividendStatement::Private.fake_div_ids(start_date) }
      before { allow(MAPI::Services::Member::DividendStatement::Private).to receive(:last_quarter_end_date).and_return(end_date) }
      it 'returns an array of div_ids starting from given date' do
        expect(fake_div_ids).to eq(div_ids)
      end
    end

    describe '`last_quarter_end_date`' do
      let(:last_quarter_end_date) { MAPI::Services::Member::DividendStatement::Private.last_quarter_end_date }
      it 'returns the end date of last year\'s fourth quarter when the current quarter is the first quarter' do
        allow(Time.zone).to receive(:today).and_return(Date.new(2015,2,1))
        expect(last_quarter_end_date).to eq(Date.new(2014,12,31))
      end
      it 'returns the end date of this year\'s first quarter when the current quarter is the second quarter' do
        allow(Time.zone).to receive(:today).and_return(Date.new(2015,5,1))
        expect(last_quarter_end_date).to eq(Date.new(2015,3,31))
      end
      it 'returns the end date of this year\'s second quarter when the current quarter is the third quarter' do
        allow(Time.zone).to receive(:today).and_return(Date.new(2015,8,1))
        expect(last_quarter_end_date).to eq(Date.new(2015,6,30))
      end
      it 'returns the end date of this year\'s third quarter when the current quarter is the fourth quarter' do
        allow(Time.zone).to receive(:today).and_return(Date.new(2015,11,1))
        expect(last_quarter_end_date).to eq(Date.new(2015,9,30))
      end
    end

    describe '`fake_div_summary`' do
      let(:div_id) { '2015Q1' }
      let(:r) { Random.new(div_id[0..3].to_i * div_id.last.to_i) }
      let(:end_date) { double('end date') }
      let(:fake_div_summary) { MAPI::Services::Member::DividendStatement::Private.fake_div_summary(div_id, r) }
      it 'returns a `TRAN_DATE` that is the result of the `end_date_from_div_id` method' do
        allow(MAPI::Services::Member::DividendStatement::Private).to receive(:end_date_from_div_id).and_return(end_date)
        expect(fake_div_summary['TRAN_DATE']).to eq(end_date)
      end
      it 'returns a psuedo-random "DIV_RATE" between 1 and 2' do
        expect(fake_div_summary['DIV_RATE']).to be_kind_of(Float)
        expect(fake_div_summary['DIV_RATE']).to be_between(1,2)
      end
      it 'returns a psuedo-random "ANNUAL_DIV_RATE" between 3 and 7' do
        expect(fake_div_summary['ANNUAL_DIV_RATE']).to be_kind_of(Float)
        expect(fake_div_summary['ANNUAL_DIV_RATE']).to be_between(3,7)
      end
      it 'returns a psuedo-random "DIV_PER_SHR" between 1 and 2' do
        expect(fake_div_summary['DIV_PER_SHR']).to be_kind_of(Float)
        expect(fake_div_summary['DIV_PER_SHR']).to be_between(1,2)
      end
      it 'returns a psuedo-random "AVG_SHR_OS" between 11111111 and 99999999' do
        expect(fake_div_summary['AVG_SHR_OS']).to be_kind_of(Integer)
        expect(fake_div_summary['AVG_SHR_OS']).to be_between(11111111,99999999)
      end
      it 'returns a psuedo-random "CASH_DIVIDEND" between 111111 and 99999999' do
        expect(fake_div_summary['CASH_DIVIDEND']).to be_kind_of(Float)
        expect(fake_div_summary['CASH_DIVIDEND']).to be_between(111111,999999)
      end
      it 'returns a psuedo-random "TOTAL_DIV_TRAN" between 111111 and 99999999' do
        expect(fake_div_summary['TOTAL_DIV_TRAN']).to be_kind_of(Float)
        expect(fake_div_summary['TOTAL_DIV_TRAN']).to be_between(111111,999999)
      end
      it 'returns a "CASH_DIVIDEND" that is equal to the "TOTAL_DIV_TRAN"' do
        results = fake_div_summary
        expect(results['CASH_DIVIDEND']).to eq(results['TOTAL_DIV_TRAN'])
      end
      ['NO_SHARE', 'NO_SHARE_PAR_VALUE'].each do |attr|
        it "returns a #{attr} that is zero" do
          expect(fake_div_summary[attr]).to eq(0)
        end
      end
    end
  end
end
