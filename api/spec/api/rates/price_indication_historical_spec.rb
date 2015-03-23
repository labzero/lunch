require 'spec_helper'
require 'date'

describe MAPI::ServiceApp do
  before do
    header 'Authorization', "Token token=\"#{ENV['MAPI_SECRET_TOKEN']}\""
  end
  describe "price indication historical" do
    let!(:collateral_type) {'sbc'}
    let!(:credit_type) {'frc'}
    let!(:start_date) {'2014-01-01'}
    let!(:end_date) {'2014-02-01'}
    let(:rates) { get "rates/price_indication/historical/#{start_date}/#{end_date}/#{collateral_type}/#{credit_type}"; JSON.parse(last_response.body) }
    it "should returns the start and end date that as passed in " do
      expect(rates['start_date']).to match(MAPI::Shared::Constants::REPORT_PARAM_DATE_FORMAT)
      expect(rates['end_date']).to match(MAPI::Shared::Constants::REPORT_PARAM_DATE_FORMAT)
    end
    it "should returns collateral and credit as per passed in" do
      expect(rates['collateral_type'].to_s).to eq(collateral_type)
      expect(rates['credit_type'].to_s).to eq(credit_type)
    end
    it 'should return dates that is within the passed in dates range, and each has valid rates data' do
      rates['rates_by_date'].each do |ratedate|
        expect(ratedate['date'].to_s).to match(MAPI::Shared::Constants::REPORT_PARAM_DATE_FORMAT)
        expect(ratedate['date'].to_date).to be_between(start_date.to_date, end_date.to_date).inclusive
        ratedate['rates_by_term'].each do |term|
          expect(term['term']).to be_kind_of(String)
          expect(term['day_count_basis']).to be_kind_of(String)
          expect(term['pay_freq']).to be_kind_of(String)
          expect(term['rate']).to be_kind_of(Numeric)
        end
      end
    end
    it 'should return 400 if invalid_collateral type' do
      get "rates/price_indication/historical/#{start_date}/#{end_date}/wholeloan/#{credit_type}"
      expect(last_response.status).to eq(400)
      get "rates/price_indication/historical/#{start_date}/#{end_date}/sbc/daily_prime"
      expect(last_response.status).to eq(400)
      get "rates/price_indication/historical/12-12-2014/#{end_date}/standard/daily_prime"
      expect(last_response.status).to eq(400)
      get "rates/price_indication/historical/#{start_date}/03-03-2014/standard/1m_libor"
      expect(last_response.status).to eq(400)
      get "rates/price_indication/historical/2013-12-31/2013-01-02/standard/1m_libor"
      expect(last_response.status).to eq(400)
    end
    describe "test min date" do
      let(:rates) { get "rates/price_indication/historical/1993-02-02/#{end_date}/#{collateral_type}/#{credit_type}"; JSON.parse(last_response.body) }
      it 'should return min_date if pass in start_date is earlier than min date' do
         expect(rates['start_date']).to eq(MAPI::Services::Rates::PriceIndicationHistorical::IRDB_CODE_TERM_MAPPING[collateral_type][credit_type]['min_date'])
      end
    end

    describe "check manual changes to "
  end
end