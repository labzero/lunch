require 'spec_helper'
require 'date'

describe MAPI::ServiceApp do
  describe 'historical sta' do
    let(:start_date) {'2014-01-01'}
    let(:end_date) {'2014-02-01'}
    let(:historical_sta_price_indications) { get "rates/price_indication/historical/#{start_date}/#{end_date}/sta/sta"; JSON.parse(last_response.body) }

    it 'should return an hash' do
      expect(historical_sta_price_indications).to be_kind_of(Hash)
    end
    it 'should contain a date' do
      historical_sta_price_indications['rates_by_date'].each do |row|
        expect(row['date']).to match(MAPI::Shared::Constants::REPORT_PARAM_DATE_FORMAT)
      end
    end
    it 'should contain a rate' do
      historical_sta_price_indications['rates_by_date'].each do |row|
        expect(row['rate']).to be_kind_of(Float)
      end
    end

    describe 'in the production environment' do
      let(:irdb_query) {double('SQL query for irdb')}
      let(:irdb_cursor) {double('irdb cursor')}
      let(:sta_rates) {''}
      before do
        allow(MAPI::ServiceApp).to receive(:environment).and_return(:production)
      end
      it 'executes the SQL query for the irdb_connection' do
        allow(MAPI::Services::Rates::HistoricalSTA::Private).to receive(:irdb_sql_query).and_return(irdb_query)
        expect(ActiveRecord::Base.connection).to receive(:execute).with(irdb_query).and_return(irdb_cursor)
        allow(irdb_cursor).to receive(:fetch_hash)
        historical_sta_price_indications
      end
    end
  end
  describe 'private methods' do
    let(:subject) {MAPI::Services::Rates::HistoricalSTA::Private}

    describe '`irdb_sql_query` method' do
      let(:start_date) {'2014-04-01'.to_date}
      let(:end_date) {'2014-04-02'.to_date}
      let(:final_sql) {"              SELECT TRX_EFFECTIVE_DATE, TRX_VALUE\n              FROM IRDB.IRDB_TRANS\n              WHERE TRX_IR_CODE ='STARATE'\n              AND (TRX_TERM_VALUE || TRX_TERM_UOM  = '1D' )\n              AND TRX_EFFECTIVE_DATE BETWEEN to_date('2014-04-01', 'yyyy-mm-dd') AND\n              to_date('2014-04-02', 'yyyy-mm-dd')\n              ORDER BY TRX_EFFECTIVE_DATE\n" }
      it 'returns sql with correct start and end date parameters' do
        expect(subject.irdb_sql_query(start_date, end_date)).to eq(final_sql)
      end
    end

    describe '`fake_sta_indications` method' do
      let(:start_date) {'2014-04-01'.to_date}
      let(:end_date) {'2014-04-02'.to_date}
      it 'returns an array of historic sta objects' do
        expect(subject.fake_sta_indications(start_date, end_date)).to be_kind_of(Array)
        subject.fake_sta_indications(start_date, end_date).each do |historic_sta_object|
          expect(historic_sta_object).to be_kind_of(Hash)
        end
      end
      describe 'historic_sta_object object' do
        it 'returns a `TRX_EFFECTIVE_DATE` value' do
          subject.fake_sta_indications(start_date, end_date).each do |historic_sta_object|
            expect(historic_sta_object['TRX_EFFECTIVE_DATE']).to match(MAPI::Shared::Constants::REPORT_PARAM_DATE_FORMAT)
          end
        end
        it 'returns a `TRX_VALUE` value' do
          subject.fake_sta_indications(start_date, end_date).each do |historic_sta_object|
            expect(historic_sta_object['TRX_VALUE']).to be_between(0,1)
            expect(historic_sta_object['TRX_VALUE']).to be_kind_of(Float)
          end
        end
      end
    end
  end
end