require 'spec_helper'
require 'date'
include MAPI::Shared::Constants

describe MAPI::ServiceApp do
  before do
    header 'Authorization', "Token token=\"#{ENV['MAPI_SECRET_TOKEN']}\""
  end
  describe 'price indication historical' do
    let(:collateral_type) {'standard'}
    let(:credit_type) {'frc'}
    let(:start_date) {'2014-01-01'}
    let(:end_date) {'2014-02-01'}
    let(:price_indications) { get "rates/price_indication/historical/#{start_date}/#{end_date}/#{collateral_type}/#{credit_type}"; JSON.parse(last_response.body) }

    before do
      allow(MAPI::Services::Rates::PriceIndicationHistorical).to receive(:calendar_holiday_london_only).at_least(1).and_return([])
      allow(MAPI::Services::Rates::PriceIndicationHistorical::Private).to receive(:fake_historical_price_indications).and_return([])
    end

    it 'should return the start_date that was given if it occurred after the bank began storing that data' do
      expect(price_indications['start_date']).to eq(start_date)
    end
    it 'should return the date at which the bank starting storing data for that credit type if the given start_date occurs before that date' do
      start_date = '1992-01-01'
      expect((get "rates/price_indication/historical/#{start_date}/#{end_date}/#{collateral_type}/#{credit_type}"; JSON.parse(last_response.body))['start_date']).to eq(IRDB_CODE_TERM_MAPPING[:standard][:frc][:min_date])
    end
    it 'should return the collateral_type that was passed in' do
      expect(price_indications['collateral_type'].to_s).to eq(collateral_type)
    end
    it 'should return the credit_type that was passed in' do
      expect(price_indications['credit_type'].to_s).to eq(credit_type)
    end
    it 'should return a rates_by_date array' do
      expect(price_indications['rates_by_date']).to be_kind_of(Array)
    end
    describe 'adding London holidays' do
      it 'should not add London holidays if there are none to add' do
        expect(MAPI::Services::Rates::PriceIndicationHistorical::Private).to_not receive(:add_london_holiday_rows)
      end
      describe 'when there are holidays to add' do
        before do
          allow(MAPI::Services::Rates::PriceIndicationHistorical).to receive(:calendar_holiday_london_only).at_least(1).and_return(['1776-07-04'])
        end
        CREDIT_TYPES.each do |credit_type|
          next if credit_type == :embedded_cap # TODO add test once embedded cap is rigged up
          if credit_type == :vrc
            it 'should not add London holidays if the credit_type is `vrc`' do
              expect(MAPI::Services::Rates::PriceIndicationHistorical::Private).to_not receive(:add_london_holiday_rows)
              get "rates/price_indication/historical/#{start_date}/#{end_date}/#{collateral_type}/vrc"
            end
          else
            it "should add London holidays if the credit_type is '#{credit_type}'" do
              expect(MAPI::Services::Rates::PriceIndicationHistorical::Private).to receive(:add_london_holiday_rows)
              get "rates/price_indication/historical/#{start_date}/#{end_date}/#{collateral_type}/#{credit_type}"
            end
          end
        end
      end
    end

    describe 'the rates_by_date array' do
      before do
        allow(MAPI::Services::Rates::PriceIndicationHistorical::Private).to receive(:fake_historical_price_indications).and_call_original
      end
      it 'should contain rates_by_date objects' do
        expect(price_indications['rates_by_date'].first).to be_kind_of(Hash)
      end
      describe 'a rates_by_date object' do
        it 'should contain a date' do
          expect(price_indications['rates_by_date'].first['date']).to match(MAPI::Shared::Constants::REPORT_PARAM_DATE_FORMAT)
        end
        it 'should contain a rates_by_term array of rate_objects' do
          expect(price_indications['rates_by_date'].first['rates_by_term']).to be_kind_of(Array)
          expect(price_indications['rates_by_date'].first['rates_by_term'].first).to be_kind_of(Hash)
        end
        describe 'a rate_object' do
          ['term', 'type', 'day_count_basis', 'pay_freq'].each do |property|
            it "should contain a #{property}" do
              expect(price_indications['rates_by_date'].first['rates_by_term'].first[property]).to be_kind_of(String)
            end
          end
          it 'should contain a value' do
            expect(price_indications['rates_by_date'].first['rates_by_term'].first['value']).to be_kind_of(Float)
          end
        end
      end
    end

    describe 'in the production environment' do
      let(:irdb_query) {double('SQL query for irdb')}
      let(:benchmark_query) {double('SQL query for irdb and benchmark')}
      let(:irdb_cursor) {double('irdb cursor')}
      let(:benchmark_cursor) {double('benchmark cursor')}
      let(:rows) {{
                       'TRX_IR_CODE' => 'PRIME',
                       'TRX_EFFECTIVE_DATE' => '2014-01-01',
                       'TRX_TERM_VALUE' => '1',
                       'TRX_TERM_UOM' => 'D',
                       'TRX_VALUE' => 0.436,
                       'MS_DAY_CNT_BAS' => 'Actual/360',
                       'MS_DATA_FREQ' => 'Daily'
                   }}
      before do
        allow(MAPI::ServiceApp).to receive(:environment).at_least(1).and_return(:production)
      end
      it 'executes the SQL query for the irdb_connection if the credit type is anything other than :daily_prime' do
        expect(MAPI::Services::Rates::PriceIndicationHistorical::Private).to receive(:irdb_connection_string).and_return(irdb_query)
        expect(ActiveRecord::Base.connection).to receive(:execute).with(irdb_query).and_return(irdb_cursor)
        expect(irdb_cursor).to receive(:fetch_hash).and_return(rows, nil)
        price_indications
      end
      it 'executes the SQL query for the irdb_with_benchmark_connection if the credit type is :daily_prime' do
        expect(MAPI::Services::Rates::PriceIndicationHistorical::Private).to receive(:irdb_with_benchmark_connection_string).and_return(benchmark_query)
        expect(ActiveRecord::Base.connection).to receive(:execute).with(benchmark_query).and_return(benchmark_cursor)
        expect(benchmark_cursor).to receive(:fetch_hash).and_return(rows, nil)
        get "rates/price_indication/historical/#{start_date}/#{end_date}/#{collateral_type}/daily_prime"; JSON.parse(last_response.body)
      end
    end

    describe 'calendar_holiday_london_only' do
      let(:start_date) {'2014-04-01'}
      let(:end_date) {'2014-06-01'}
      let(:london_only_holidays) {MAPI::Services::Rates::PriceIndicationHistorical.calendar_holiday_london_only(:test, start_date, end_date)}
      before do
        allow(MAPI::Services::Rates::PriceIndicationHistorical).to receive(:calendar_holiday_london_only).at_least(1).and_call_original
      end

      it 'returns an array of dates if there are London-only holidays contained in the given range' do
        expect(london_only_holidays).to be_kind_of(Array)
        expect(london_only_holidays.first).to eq(Time.zone.parse('2014-04-18'))
        expect(london_only_holidays.last).to eq(Time.zone.parse('2014-05-06'))
      end
      describe 'in production', vcr: {cassette_name: 'london_only_calendar_mds_service'} do
        let(:london_only_holidays) {MAPI::Services::Rates::PriceIndicationHistorical.calendar_holiday_london_only(:production, start_date, end_date)}
        it 'should raise and log an error if the calendar service is unavailable', vcr: {cassette_name: 'calendar_service_unavailable'} do
          expect{london_only_holidays}.to raise_error('Internal Service Error: the holiday calendar service could not be reached')
        end
        it 'does not include holidays that are US only' do
          expect(london_only_holidays).to_not include(Time.zone.parse('2014-05-25'))
        end
        it 'does not include holidays that are both US and London holidays' do
          expect(london_only_holidays).to_not include(Time.zone.parse('2014-04-06'))
        end
        it 'does not include London-only holidays that fall on a weekend' do
          expect(london_only_holidays).to_not include(Time.zone.parse('2014-05-25'))
        end
        it 'includes holidays that are only celebrated in London' do
          expect(london_only_holidays).to include(Time.zone.parse('2014-04-03'), Time.zone.parse('2014-05-05'))
        end
      end

    end

    describe 'private methods' do
      let(:subject) {MAPI::Services::Rates::PriceIndicationHistorical::Private}

      describe '`fake_historical_price_indications` method' do
        let(:start_date) {'2014-04-01'.to_date}
        let(:end_date) {'2014-04-02'.to_date}
        let(:london_holidays) {[]}
        before do
          allow(MAPI::Services::Rates::PriceIndicationHistorical::Private).to receive(:fake_historical_price_indications).and_call_original
        end
        it 'returns an array of historic_price objects' do
          expect(subject.fake_historical_price_indications(start_date, end_date, :standard, :vrc, 'FRADVN', ['1D'], london_holidays)).to be_kind_of(Array)
          expect(subject.fake_historical_price_indications(start_date, end_date, :standard, :vrc, 'FRADVN', ['1D'], london_holidays).first).to be_kind_of(Hash)
        end
        describe 'historic_price object' do
          ['TRX_IR_CODE', 'TRX_TERM_VALUE', 'TRX_TERM_UOM', 'MS_DAY_CNT_BAS', 'MS_DATA_FREQ'].each do |property|
            it "returns a '#{property}' value" do
              expect(subject.fake_historical_price_indications(start_date, end_date, :standard, :vrc, 'FRADVN', ['1D'], london_holidays).first[property]).to be_kind_of(String)
            end
          end
          it 'returns a `TRX_EFFECTIVE_DATE` value' do
            expect(subject.fake_historical_price_indications(start_date, end_date, :standard, :vrc, 'FRADVN', ['1D'], london_holidays).first['TRX_EFFECTIVE_DATE']).to match(MAPI::Shared::Constants::REPORT_PARAM_DATE_FORMAT)
          end
          COLLATERAL_TYPES.each do |collateral_type|
            CREDIT_TYPES.each do |credit_type|
              irdb_lookup = IRDB_CODE_TERM_MAPPING[collateral_type][credit_type]
              next if credit_type == :embedded_cap # TODO add test once embedded cap is rigged up
              if credit_type == :frc || credit_type == :vrc
                it "returns a rate if the collateral_type is '#{collateral_type}' and the credit_type is '#{credit_type}'" do
                  expect(subject.fake_historical_price_indications(start_date, end_date, collateral_type, credit_type, irdb_lookup[:code], irdb_lookup[:terms], london_holidays).first['TRX_VALUE']).to be_between(0,1)
                  expect(subject.fake_historical_price_indications(start_date, end_date, collateral_type, credit_type, irdb_lookup[:code], irdb_lookup[:terms], london_holidays).first['TRX_VALUE']).to be_kind_of(Float)
                end
              elsif credit_type == :daily_prime && collateral_type == :standard
                it "returns a rate for a given date if the credit_type is '#{credit_type}'" do
                  expect(subject.fake_historical_price_indications(start_date, end_date, collateral_type, credit_type, irdb_lookup[:code], irdb_lookup[:terms], london_holidays).first['TRX_VALUE']).to be_between(0,1)
                  expect(subject.fake_historical_price_indications(start_date, end_date, collateral_type, credit_type, irdb_lookup[:code], irdb_lookup[:terms], london_holidays).first['TRX_VALUE']).to be_kind_of(Float)
                end
                it "returns a basis_point for a given date if the credit_type is '#{credit_type}'" do
                  expect(subject.fake_historical_price_indications(start_date, end_date, collateral_type, credit_type, irdb_lookup[:code], irdb_lookup[:terms], london_holidays)[1]['TRX_VALUE']).to be_between(-200,200)
                  expect(subject.fake_historical_price_indications(start_date, end_date, collateral_type, credit_type, irdb_lookup[:code], irdb_lookup[:terms], london_holidays)[1]['TRX_VALUE']).to be_kind_of(Fixnum)
                end
              elsif credit_type != :daily_prime
                it "returns a basis_point if the collateral_type is '#{collateral_type}' and the credit_type is '#{credit_type}'" do
                  expect(subject.fake_historical_price_indications(start_date, end_date, collateral_type, credit_type, irdb_lookup[:code], irdb_lookup[:terms], london_holidays).first['TRX_VALUE']).to be_between(-200,200)
                  expect(subject.fake_historical_price_indications(start_date, end_date, collateral_type, credit_type, irdb_lookup[:code], irdb_lookup[:terms], london_holidays).first['TRX_VALUE']).to be_kind_of(Fixnum)
                end
              end
            end
          end
        end
      end

      describe '`add_london_holiday_rows` method' do
        let(:rates_array) {[{date: '2014-06-13'.to_date, rates_by_term: ['some array of terms']}]}
        let(:holiday_array) {['2014-04-01'.to_date, '2014-04-02'.to_date]}
        let(:terms) {['1D']}
        it 'iterates through an array of dates and adds a new rate_by_date object to the given rates_by_date array' do
          expect(subject.add_london_holiday_rows(holiday_array, rates_array, terms).length).to eq(3)
        end
        it 'adds an empty historic_price object for every date and term it is given' do
          [1,2].each do |i|
            expect(subject.add_london_holiday_rows(holiday_array, rates_array, terms)[i][:rates_by_term].first[:term]).to eq(terms.first)
            expect(subject.add_london_holiday_rows(holiday_array, rates_array, terms)[i][:rates_by_term].first[:type]).to eq('index')
            [:value, :day_count_basis, :pay_freq].each do |property|
              expect(subject.add_london_holiday_rows(holiday_array, rates_array, terms)[i][:rates_by_term].first[property]).to be_nil
            end
          end
        end
      end

      describe '`rate_object_data_type` method' do
        [:frc, :vrc].each do |credit_type|
          it "returns 'rate' if credit_type is '#{credit_type}'" do
            expect(subject.rate_object_data_type(credit_type, nil)).to eq('index')
          end
        end
        [:'1m_libor', :'3m_libor', :'6m_libor'].each do |credit_type|
          it "returns 'basis_point' if credit_type is '#{credit_type}'" do
            expect(subject.rate_object_data_type(credit_type, nil)).to eq('basis_point')
          end
        end
      end
      it 'returns `rate` if credit_type is `:daily_prime` and trx_ir_code is `PRIME`' do
        expect(subject.rate_object_data_type(:daily_prime, 'PRIME')).to eq('index')
      end
      it 'returns `basis_point` if credit_type is `:daily_prime` and trx_ir_code is `APRIMEAT`' do
        expect(subject.rate_object_data_type(:daily_prime, 'APRIMEAT')).to eq('basis_point')
      end
    end
  end
end