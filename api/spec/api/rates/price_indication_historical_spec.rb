require 'spec_helper'
require 'date'

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
      allow(MAPI::Services::Rates::PriceIndicationHistorical).to receive(:calendar_holiday_london_only).and_return([])
      allow(MAPI::Services::Rates::PriceIndicationHistorical::Private).to receive(:fake_historical_price_indications).and_return([])
    end

    it 'should return the start_date that was given if it occurred after the bank began storing that data' do
      expect(price_indications['start_date']).to eq(start_date)
    end
    it 'should return the date at which the bank starting storing data for that credit type if the given start_date occurs before that date' do
      start_date = '1992-01-01'
      expect((get "rates/price_indication/historical/#{start_date}/#{end_date}/#{collateral_type}/#{credit_type}"; JSON.parse(last_response.body))['start_date'].to_date).to eq(MAPI::Shared::Constants::IRDB_CODE_TERM_MAPPING[:standard][:frc][:min_date])
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
    it 'should add rate objects for all terms for a given rate_by_date object' do
      expect(MAPI::Services::Rates::PriceIndicationHistorical::Private).to receive(:add_rate_objects_for_all_terms)
      price_indications
    end
    describe 'adding London holidays' do
      it 'should not add London holidays if there are none to add' do
        expect(MAPI::Services::Rates::PriceIndicationHistorical::Private).to_not receive(:add_london_holiday_rows)
      end
      describe 'when there are holidays to add' do
        before do
          allow(MAPI::Services::Rates::PriceIndicationHistorical::Private).to receive(:add_rate_objects_for_all_terms)
          allow(MAPI::Services::Rates::PriceIndicationHistorical).to receive(:calendar_holiday_london_only).and_return(['1776-07-04'])
        end
        MAPI::Shared::Constants::CREDIT_TYPES.each do |credit_type|
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
        price_indications['rates_by_date'].each do |rate_by_date_object|
          expect(rate_by_date_object).to be_kind_of(Hash)
        end
      end
      describe 'a rates_by_date object' do
        it 'should contain a date' do
          price_indications['rates_by_date'].each do |rate_by_date_object|
            expect(rate_by_date_object['date']).to match(MAPI::Shared::Constants::REPORT_PARAM_DATE_FORMAT)
          end
        end
        it 'should contain a rates_by_term array of rate_objects' do
          price_indications['rates_by_date'].each do |rate_by_date_object|
            expect(rate_by_date_object['rates_by_term']).to be_kind_of(Array)
            rate_by_date_object['rates_by_term'].each do |rate_by_term_object|
              expect(rate_by_term_object).to be_kind_of(Hash)
            end
          end
        end
        describe 'a rate_object' do
          ['term', 'type', 'day_count_basis', 'pay_freq'].each do |property|
            it "should contain a #{property}" do
              price_indications['rates_by_date'].each do |rate_by_date_object|
                rate_by_date_object['rates_by_term'].each do |rate_by_term_object|
                  expect(rate_by_term_object[property]).to be_kind_of(String)
                end
              end
            end
          end
          it 'should contain a value' do
            price_indications['rates_by_date'].each do |rate_by_date_object|
              rate_by_date_object['rates_by_term'].each do |rate_by_term_object|
                expect(rate_by_term_object['value']).to be_kind_of(Float)
              end
            end
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
        allow(MAPI::ServiceApp).to receive(:environment).and_return(:production)
      end
      it 'executes the SQL query for the irdb_connection if the credit type is anything other than :daily_prime' do
        allow(MAPI::Services::Rates::PriceIndicationHistorical::Private).to receive(:irdb_sql_query).and_return(irdb_query)
        expect(ActiveRecord::Base.connection).to receive(:execute).with(irdb_query).and_return(irdb_cursor)
        allow(irdb_cursor).to receive(:fetch_hash)
        price_indications
      end
      it 'executes the SQL query for the irdb_with_benchmark_connection if the credit type is :daily_prime' do
        allow(MAPI::Services::Rates::PriceIndicationHistorical::Private).to receive(:irdb_with_benchmark_sql_query).and_return(benchmark_query)
        expect(ActiveRecord::Base.connection).to receive(:execute).with(benchmark_query).and_return(benchmark_cursor)
        allow(benchmark_cursor).to receive(:fetch_hash)
        get "rates/price_indication/historical/#{start_date}/#{end_date}/#{collateral_type}/daily_prime"; JSON.parse(last_response.body)
      end
    end

    describe 'calendar_holiday_london_only' do
      let(:start_date) {'2014-04-01'}
      let(:end_date) {'2014-06-01'}
      let(:london_only_holidays) {MAPI::Services::Rates::PriceIndicationHistorical.calendar_holiday_london_only(:test, start_date, end_date)}
      before do
        allow(MAPI::Services::Rates::PriceIndicationHistorical).to receive(:calendar_holiday_london_only).and_call_original
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
          subject.fake_historical_price_indications(start_date, end_date, :standard, :vrc, 'FRADVN', ['1D'], london_holidays).each do |historic_price_object|
            expect(historic_price_object).to be_kind_of(Hash)
          end
        end
        describe 'historic_price object' do
          ['TRX_IR_CODE', 'TRX_TERM_VALUE', 'TRX_TERM_UOM', 'MS_DAY_CNT_BAS', 'MS_DATA_FREQ'].each do |property|
            it "returns a '#{property}' value" do
              subject.fake_historical_price_indications(start_date, end_date, :standard, :vrc, 'FRADVN', ['1D'], london_holidays).each do |historic_price_object|
                expect(historic_price_object[property]).to be_kind_of(String)
              end
            end
          end
          it 'returns a `TRX_EFFECTIVE_DATE` value' do
            subject.fake_historical_price_indications(start_date, end_date, :standard, :vrc, 'FRADVN', ['1D'], london_holidays).each do |historic_price_object|
              expect(historic_price_object['TRX_EFFECTIVE_DATE']).to match(MAPI::Shared::Constants::REPORT_PARAM_DATE_FORMAT)
            end
          end
          MAPI::Shared::Constants::COLLATERAL_TYPES.each do |collateral_type|
            MAPI::Shared::Constants::CREDIT_TYPES.each do |credit_type|
              irdb_lookup = MAPI::Shared::Constants::IRDB_CODE_TERM_MAPPING[collateral_type][credit_type]
              next if credit_type == :embedded_cap # TODO add test once embedded cap is rigged up
              if credit_type == :frc || credit_type == :vrc
                it "returns a rate if the collateral_type is '#{collateral_type}' and the credit_type is '#{credit_type}'" do
                  subject.fake_historical_price_indications(start_date, end_date, collateral_type, credit_type, irdb_lookup[:code], irdb_lookup[:terms], london_holidays).each do |historic_price_object|
                    expect(historic_price_object['TRX_VALUE']).to be_between(0,1)
                    expect(historic_price_object['TRX_VALUE']).to be_kind_of(Float)
                  end
                end
              elsif credit_type == :daily_prime && collateral_type == :standard
                it "returns a rate as the first value for a given date if the credit_type is '#{credit_type}'" do
                  expect(subject.fake_historical_price_indications(start_date, end_date, collateral_type, credit_type, irdb_lookup[:code], irdb_lookup[:terms], london_holidays).first['TRX_VALUE']).to be_between(0,1)
                  expect(subject.fake_historical_price_indications(start_date, end_date, collateral_type, credit_type, irdb_lookup[:code], irdb_lookup[:terms], london_holidays).first['TRX_VALUE']).to be_kind_of(Float)
                end
                it "returns a basis_point for all other values than the first for a given date if the credit_type is '#{credit_type}'" do
                  subject.fake_historical_price_indications(start_date, start_date, collateral_type, credit_type, irdb_lookup[:code], irdb_lookup[:terms], london_holidays).each_with_index do |historic_price_object, i|
                    next if i == 0
                    expect(historic_price_object['TRX_VALUE']).to be_between(-200,200)
                    expect(historic_price_object['TRX_VALUE']).to be_kind_of(Fixnum)
                  end
                end
              elsif credit_type != :daily_prime
                it "returns a basis_point if the collateral_type is '#{collateral_type}' and the credit_type is '#{credit_type}'" do
                  subject.fake_historical_price_indications(start_date, end_date, collateral_type, credit_type, irdb_lookup[:code], irdb_lookup[:terms], london_holidays).each do |historic_price_object|
                    expect(historic_price_object['TRX_VALUE']).to be_between(-200,200)
                    expect(historic_price_object['TRX_VALUE']).to be_kind_of(Fixnum)
                  end
                end
              end
            end
          end
        end
      end

      describe '`add_london_holiday_rows` method' do
        let(:rates_array) {[{date: '2014-04-01'.to_date, rates_by_term: ['some array of terms']}, {date: '2014-06-13'.to_date, rates_by_term: ['some array of terms']}]}
        let(:holiday_array) {['2014-04-01'.to_date, '2014-07-02'.to_date]}
        let(:terms) {MAPI::Shared::Constants::LIBOR_TERMS}
        it 'iterates through an array of dates and adds an empty rate_by_date object to the given rates_by_date array' do
          expect(subject.add_london_holiday_rows(holiday_array, rates_array, terms).length).to eq(3)
          [:value, :day_count_basis, :pay_freq].each do |property|
            (subject.add_london_holiday_rows(holiday_array, rates_array, terms).select {|rate_object| rate_object[:date] == '2014-07-02'.to_date}).each do |rate_by_date_object|
              rate_by_date_object[:rates_by_term].each do |rate_by_term_object|
                expect(rate_by_term_object[property]).to be_nil
              end
            end
          end
          (subject.add_london_holiday_rows(holiday_array, rates_array, terms).select {|rate_object| rate_object[:date] == '2014-07-02'.to_date}).each do |rate_by_date_object|
            rate_by_date_object[:rates_by_term].each do |rate_by_term_object|
              expect(terms).to include(rate_by_term_object[:term])
              expect(rate_by_term_object[:type]).to eq('index')
            end
          end
          expect(terms).to include((subject.add_london_holiday_rows(holiday_array, rates_array, terms).select {|rate_object| rate_object[:date] == '2014-07-02'.to_date}).first[:rates_by_term].first[:term])
          expect((subject.add_london_holiday_rows(holiday_array, rates_array, terms).select {|rate_object| rate_object[:date] == '2014-07-02'.to_date}).first[:rates_by_term].first[:type]).to eq('index')
        end
        it 'ignores dates in the holiday_array if they are already present in the rates_array' do
          expect(subject.add_london_holiday_rows(holiday_array, rates_array, terms).length).to eq(3)
          expect((subject.add_london_holiday_rows(holiday_array, rates_array, terms).select {|rate_object| rate_object[:date] == '2014-04-01'.to_date}).length).to eq(1)
          expect((subject.add_london_holiday_rows(holiday_array, rates_array, terms).select {|rate_object| rate_object[:date] == '2014-04-01'.to_date}).first[:rates_by_term]).to eq(['some array of terms'])
        end
        it 'adds the correct number of historic_rate_objects based on the terms given' do
          expect(subject.add_london_holiday_rows(holiday_array, rates_array, terms).last[:rates_by_term].length).to eq(terms.length)
        end
        it 'adds an extra historic_rate_object in the rate_array if the credit_type is daily_prime' do
          expect(subject.add_london_holiday_rows(holiday_array, rates_array, terms, :daily_prime).last[:rates_by_term].length).to eq(terms.length + 1)
        end
      end

      describe '`add_rate_objects_for_all_terms` method' do
        let(:terms) {MAPI::Shared::Constants::LIBOR_TERMS}
        let(:rates_array) {[{date: '2014-04-01'.to_date, rates_by_term: [
                            {term: terms[0]},
                            {term: terms[2]},
                            {term: terms[3]}
                          ]}]}
        it 'iterates through all rates_by_terms arrays for the rate_array and creates empty historic_rate_objects for any terms that are missing' do
          expect(subject.add_rate_objects_for_all_terms(rates_array, terms).first[:rates_by_term].length).to eq(MAPI::Shared::Constants::LIBOR_TERMS.length)
          [:value, :day_count_basis, :pay_freq].each do |property|
            expect(subject.add_rate_objects_for_all_terms(rates_array, terms).first[:rates_by_term].select {|rate_object| rate_object[:term] == MAPI::Shared::Constants::LIBOR_TERMS[1]}.first[property]).to be_nil
          end
          expect(subject.add_rate_objects_for_all_terms(rates_array, terms).first[:rates_by_term].select {|rate_object| rate_object[:term] == MAPI::Shared::Constants::LIBOR_TERMS[1]}.first[:type]).to eq('index')
        end
      end

      describe '`rate_object_data_type` method' do
        MAPI::Shared::Constants::INDEX_CREDIT_TYPES.each do |credit_type|
          it "returns 'rate' if credit_type is '#{credit_type}'" do
            expect(subject.rate_object_data_type(credit_type, nil)).to eq('index')
          end
        end
        MAPI::Shared::Constants::BASIS_POINT_CREDIT_TYPES.each do |credit_type|
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