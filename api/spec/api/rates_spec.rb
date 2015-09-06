require 'spec_helper'
require 'date'

describe MAPI::ServiceApp do
  subject { MAPI::Services::Rates }
  before do
    header 'Authorization', "Token token=\"#{ENV['MAPI_SECRET_TOKEN']}\""
  end
  describe "historic overnight rates" do
    describe "development" do
      let(:rates) { get '/rates/historic/overnight'; JSON.parse(last_response.body) }
      it "should return an array of rates" do
        expect(rates.length).to be >= 1
        rates.each do |rate|
          expect(rate.first).to match(/\A\d\d\d\d-(0\d|1[012])-([0-2]\d|3[01])\Z/)
          expect(rate.last).to be_kind_of(Float)
        end
      end

      it "should return 30 rates by default" do
        expect(rates.length).to eq(30)
      end

      it "should allow the number of rates returned to be overridden" do
        get '/rates/historic/overnight', limit: 5
        expect(JSON.parse(last_response.body).length).to eq(5)
      end

      it "should return the rates in ascending date order" do
        expect( rates ).to be == rates.sort_by{|r| Time.zone.parse(r.first) }
      end
    end
  end

  describe "current rates" do

    MAPI::Services::Rates::LOAN_TYPES.each do |loan|
      MAPI::Services::Rates::LOAN_TERMS.each do |term|
        it "should return a #{loan}:#{term} rate" do
          get "/rates/#{loan}/#{term}"
          rate = JSON.parse(last_response.body)
          expect(rate['rate']).to be_kind_of(Float)
          expect(rate['updated_at']).to match(/\A\d\d\d\d-(0\d|1[012])-([0-2]\d|3[01]) ([01]\d|2[0-3]):[0-5]\d:[0-5]\d [+-](0\d|1[012])[0-5][0-5]\Z/)
          date = Time.zone.parse(rate['updated_at'])
          expect(date).to be <= Time.zone.now
        end
      end
    end
  end

  describe "rate summary" do
    before do
      allow(MAPI::Services::Rates::BlackoutDates).to receive(:blackout_dates).and_return(blackout_dates)
      allow(MAPI::Services::Rates::LoanTerms).to receive(:loan_terms).and_return(loan_terms_result)
    end
    let(:today) { Time.zone.today }
    let(:one_week_away) { today + 1.week }
    let(:three_weeks_away) { today + 3.week }
    let(:blackout_dates) { [one_week_away, three_weeks_away] }
    loan_terms = [:overnight, :open, :'1week', :'2week', :'3week', :'1month', :'2month', :'3month', :'6month', :'1year', :'2year', :'3year']
    loan_types = [:whole, :agency, :aaa, :aa]
    let(:loan_terms) { loan_terms }
    let(:loan_types) { loan_types }
    let(:loan_terms_result) do
      inner_peace = Hash.new(Hash.new(true))
      h = Hash.new(inner_peace)
      h[:'1year'] = { whole:  { trade_status: false, display_status: true  } }
      h[:'3year'] = { agency: { trade_status: true,  display_status: false } }
      h[:'1year'].default= inner_peace
      h[:'3year'].default= inner_peace
      h
    end
    let(:rate_summary) do
      get '/rates/summary'
      JSON.parse(last_response.body).with_indifferent_access
    end
    it "should return rates for default loan_types at default loan_terms" do
      loan_types.each do |loan_type|
        loan_terms.each do |loan_term|
          expect(rate_summary[loan_type][loan_term][:rate]).to be_kind_of(String)
        end
      end
    end
    loan_types.each do |loan_type|
      loan_terms.each do |loan_term|
        it "should return correct data for rate_summary[#{loan_type}][#{loan_term}]" do
          r = rate_summary[loan_type][loan_term]
          blacked_out = blackout_dates.include?(Date.parse(r[:maturity_date]))
          cutoff      = !loan_terms_result[loan_term][loan_type][:trade_status]
          disabled    = !loan_terms_result[loan_term][loan_type][:display_status]
          expect(r[:payment_on]).to be_kind_of(String)
          expect(r[:interest_day_count]).to be_kind_of(String)
          expect(r[:maturity_date]).to be_kind_of(String)
          expect(r[:maturity_date]).to match(/\d{4}-\d{2}-\d{2}/)
          expect(r[:days_to_maturity]).to be_kind_of(String)
          expect(r[:days_to_maturity]).to match(/\d+/)
          expect(r[:rate]).to be_kind_of(String)
          expect(r[:rate]).to match(/\d+\.\d+/)
          expect(r[:disabled]).to be_boolean
          expect(r[:disabled]).to be == (blacked_out || cutoff || disabled)
        end
      end
    end
    it "should return a timestamp" do
      expect(rate_summary[:timestamp]).to be_kind_of(String)
    end

    it "should always call get_maturity_date" do
      expect(MAPI::Services::Rates).to receive(:get_maturity_date).at_least(48).with(kind_of(Date), kind_of(String))
      get '/rates/summary'
    end

    it "should set maturity date to get maturity date" do
      maturity_date = 'foobar'
      allow(MAPI::Services::Rates).to receive(:get_maturity_date).and_return(maturity_date)
      loan_types.each do |loan_type|
        loan_terms.each do |loan_term|
          expect(rate_summary[loan_type][loan_term][:maturity_date]).to eq(maturity_date)
        end
      end
    end

    describe "in the production environment" do
      before do
        allow(MAPI::ServiceApp).to receive(:environment).and_return(:production)
        allow(MAPI::Services::Rates::BlackoutDates).to receive(:blackout_dates).and_return([])
      end
      it "should return rates for default loan_types at default loan_terms", vcr: {cassette_name: 'calendar_mds_service'} do
        loan_terms.each do |loan_type|
          loan_types.each do |loan_term|
            expect(rate_summary[loan_term][loan_type][:rate]).to be_kind_of(String)
          end
        end
      end
      it "should return Internal Service Error, if calendar service is unavailable", vcr: {cassette_name: 'calendar_service_unavailable'} do
        get '/rates/summary'
        expect(last_response.status).to eq(503)
      end
      it "should return Internal Service Error, if mds service is unavailable", vcr: {cassette_name: 'mds_service_unavailable'} do
        get '/rates/summary'
        expect(last_response.status).to eq(503)
      end
      it "should return Internal Service Error, if blackout dates service is unavailable", vcr: {cassette_name: 'calendar_mds_service'} do
        allow(MAPI::Services::Rates::BlackoutDates).to receive(:blackout_dates).and_return(nil)
        get '/rates/summary'
        expect(last_response.status).to eq(503)
      end
    end
  end

  describe "weekend_or_holiday?" do
    let(:saturday) { double('saturday')  }
    let(:sunday)   { double('sunday')    }
    let(:monday)   { double('monday')    }
    let(:holiday)  { double('holiday')   }
    let(:formatted){ double('formatted') }

    before do
      MAPI::Services::Rates.class_variable_set(:@@holidays, [formatted])
      [saturday, sunday, monday].each { |d| allow(d).to receive(:strftime).with('%F').and_return(double('random string')) }
      [sunday,monday,holiday].each { |d| allow(d).to receive(:saturday?).and_return(false) }
      [saturday,monday,holiday].each { |d| allow(d).to receive(:sunday?).and_return(false) }
      allow(saturday).to receive(:saturday?).and_return(true)
      allow(sunday).to receive(:sunday?).and_return(true)
      allow(holiday).to receive(:strftime).with('%F').and_return(formatted)
    end
    it "should return true for saturday" do
      expect(subject.weekend_or_holiday?(saturday)).to be_truthy
    end
    it "should return true for sunday" do
      expect(subject.weekend_or_holiday?(sunday)).to be_truthy
    end
    it "should return true for monday" do
      expect(subject.weekend_or_holiday?(monday)).to be_falsey
    end
    it "should return true for holiday" do
      expect(subject.weekend_or_holiday?(holiday)).to be_truthy
    end
  end

  describe "get_maturity_date" do
    let (:day1_str) { double('day1 str') }
    let (:day2_str) { double('day2 str') }
    let (:day1) { double( 'day 1' ) }
    let (:day2) { double( 'day 2' ) }
    let (:day3) { double( 'day 3' ) }
    let (:day4) { double( 'day 4' ) }
    before do
      [day1,day2,day3].zip([day2,day3,day4]).each do |pred,succ|
        allow(pred).to receive( '+' ).with(1.day).and_return(succ)
        allow(succ).to receive( '-' ).with(1.day).and_return(pred)
      end
      allow(day1_str).to receive(:to_date).and_return(day1)
      allow(day2_str).to receive(:to_date).and_return(day2)
    end
    it "should return the same date if is not a weekend" do
      allow(subject).to receive(:weekend_or_holiday?).with(day1).and_return(false)
      expect(subject.get_maturity_date(day1_str,'W')).to eq(day1)
    end
    it "should return the next non weekend date if is weekend" do
      allow(subject).to receive(:weekend_or_holiday?).with(day1).and_return(true)
      allow(subject).to receive(:weekend_or_holiday?).with(day2).and_return(false)
      expect(subject.get_maturity_date(day1_str,'W')).to eq(day2)
    end
    it "should return the previous non weekend date if is weekend and month/year term and hits next month" do
      allow(subject).to receive(:weekend_or_holiday?).with(day1).and_return(false)
      allow(subject).to receive(:weekend_or_holiday?).with(day2).and_return(true)
      allow(subject).to receive(:weekend_or_holiday?).with(day3).and_return(false)
      allow(day3).to receive('>').with(day2).and_return(true)
      allow(day2).to receive(:end_of_month).and_return(day2)
      expect(subject.get_maturity_date(day2_str, 'Y')).to eq(day1)
    end
  end

  describe 'historic price indications' do
    let(:start_date) {'2014-04-01'}
    let(:end_date) {'2014-04-02'}
    it 'throws a 400 if the start_date is later than the end_date' do
      get "rates/price_indication/historical/#{end_date}/#{start_date}/standard/vrc"
      expect(last_response.status).to eq(400)
    end
    it 'throws a 400 if you enter an invalid collateral_type' do
      get "rates/price_indication/historical/#{start_date}/#{end_date}/foo/vrc"
      expect(last_response.status).to eq(400)
    end
    it 'throws a 400 if you enter an invalid credit_type' do
      get "rates/price_indication/historical/#{start_date}/#{end_date}/standard/bar"
      expect(last_response.status).to eq(400)
    end
    it 'calls the `price_indication_historical` method on the MAPI::Services::Rates::PriceIndicationHistorical module' do
      expect(MAPI::Services::Rates::PriceIndicationHistorical).to receive(:price_indication_historical)
      get "rates/price_indication/historical/#{start_date}/#{end_date}/standard/vrc"
    end
  end

  describe 'price_indications_current_vrc' do
    let(:price_indications_current_vrc) { get '/rates/price_indications/current/vrc/standard'; JSON.parse(last_response.body).with_indifferent_access }
    it 'should return data relevant to each loan_term' do
      expect(price_indications_current_vrc[:advance_maturity]).to be_kind_of(String)
      expect(price_indications_current_vrc[:overnight_fed_funds_benchmark]).to be_kind_of(Float)
      expect(price_indications_current_vrc[:basis_point_spread_to_benchmark]).to be_kind_of(Numeric)
      expect(price_indications_current_vrc[:advance_rate]).to be_kind_of(Float)
    end
    it 'invalid collateral should result in 404 error message' do
      get '/rates/price_indications/current/vrc/foo'
      expect(last_response.status).to eq(404)
    end
    describe 'in the production environment' do
      before do
        expect(MAPI::ServiceApp).to receive(:environment).at_least(1).and_return(:production)
      end
      it 'should return data relevant to each loan_term', vcr: {cassette_name: 'current_price_indications_vrc'} do
        expect(price_indications_current_vrc[:advance_maturity]).to be_kind_of(String)
        expect(price_indications_current_vrc[:overnight_fed_funds_benchmark]).to be_kind_of(Float)
        expect(price_indications_current_vrc[:basis_point_spread_to_benchmark]).to be_kind_of(Numeric)
        expect(price_indications_current_vrc[:advance_rate]).to be_kind_of(Float)
      end
      it 'should return Internal Service Error, if current price indications service is unavaible', vcr: {cassette_name: 'current_price_indications_unavailable'} do
        get '/rates/price_indications/current/vrc/standard'
        expect(last_response.status).to eq(503)
      end
    end
  end

  describe 'price_indications_current_frc' do
    let(:price_indications_current_frc) { get '/rates/price_indications/current/frc/sbc'; JSON.parse(last_response.body) }
    it 'should return data relevant to each loan_term' do
      price_indications_current_frc.each do |frc|
        expect(frc['advance_maturity']).to be_kind_of(String)
        expect(frc['treasury_benchmark_maturity']).to be_kind_of(String)
        expect(frc['nominal_yield_of_benchmark']).to be_kind_of(Float)
        expect(frc['basis_point_spread_to_benchmark']).to be_kind_of(Numeric)
        expect(frc['advance_rate']).to be_kind_of(Float)
      end
    end
    it 'invalid collateral should result in 404 error message' do
      get '/rates/price_indications/current/frc/foo'
      expect(last_response.status).to eq(404)
    end
    describe 'in the production environment' do
      before do
        expect(MAPI::ServiceApp).to receive(:environment).at_least(1).and_return(:production)
      end
      it 'should return data relevant to each loan_term', vcr: {cassette_name: 'current_price_indications_frc'} do
        price_indications_current_frc.each do |frc|
          expect(frc['advance_maturity']).to be_kind_of(String)
          expect(frc['treasury_benchmark_maturity']).to be_kind_of(String)
          expect(frc['nominal_yield_of_benchmark']).to be_kind_of(Float)
          expect(frc['basis_point_spread_to_benchmark']).to be_kind_of(Numeric)
          expect(frc['advance_rate']).to be_kind_of(Float)
        end
      end
      it 'should return Internal Service Error, if current price indications service is unavaible', vcr: {cassette_name: 'current_price_indications_unavailable'} do
        get '/rates/price_indications/current/frc/sbc'
        expect(last_response.status).to eq(503)
      end
    end
  end

  describe 'price_indications_current_arc' do
    let(:price_indications_current_frc) { get '/rates/price_indications/current/arc/standard'; JSON.parse(last_response.body) }
    it 'should return data relevant to each loan_term' do
      price_indications_current_frc.each do |arc|
        expect(arc['advance_maturity']).to be_kind_of(String)
        expect(arc['1_month_libor']).to be_kind_of(Numeric)
        expect(arc['3_month_libor']).to be_kind_of(Numeric)
        expect(arc['6_month_libor']).to be_kind_of(Numeric)
        expect(arc['prime']).to be_kind_of(Numeric)
      end
    end
    it 'invalid collateral should result in 404 error message' do
      get '/rates/price_indications/current/arc/foo'
      expect(last_response.status).to eq(404)
    end
    describe 'in the production environment' do
      before do
        expect(MAPI::ServiceApp).to receive(:environment).at_least(1).and_return(:production)
      end
      it 'should return data relevant to each loan_term', vcr: {cassette_name: 'current_price_indications_arc'} do
        price_indications_current_frc.each do |arc|
          expect(arc['advance_maturity']).to be_kind_of(String)
          expect(arc['1_month_libor']).to be_kind_of(Numeric)
          expect(arc['3_month_libor']).to be_kind_of(Numeric)
          expect(arc['6_month_libor']).to be_kind_of(Numeric)
          expect(arc['prime']).to be_kind_of(Numeric)
        end
      end
      it 'should return Internal Service Error, if current price indications service is unavaible', vcr: {cassette_name: 'current_price_indications_unavailable'} do
        get '/rates/price_indications/current/arc/standard'
        expect(last_response.status).to eq(503)
      end
    end
  end

end