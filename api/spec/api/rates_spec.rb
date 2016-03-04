require 'spec_helper'
require 'date'


def n_level_hash_with_default(default, n)
  n == 0 ? default : n_level_hash_with_default(Hash.new(default), n-1)
end

def types_and_terms_hash
  Hash[loan_types.map { |type| [type, Hash[loan_terms.map{ |term| [term, yield(type, term)] }]] }]
end

def mk_term(frequency, unit, term)
  {
      xml: double("#{term}/xml"),
      rate: double("#{term}/rate"),
      maturity_date: double("#{term}/maturity_date"),
      maturity_string: double("#{term}/maturity_string"),
      maturity_time: double("#{term}/maturity_time"),
      frequency: frequency,
      unit: unit,
      term: term.to_sym
  }
end

def mk_type(type)
  {
      xml: double("#{type}/xml"),
      type_long: subject::LOAN_MAPPING[type],
      type: type.to_sym,
      day_count_basis: double("#{type}/day_count_basis")
  }
end

describe MAPI::ServiceApp do
  subject { MAPI::Services::Rates }
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
        ['Live', 'StartOfDay', nil].each do |type|
          it "should return a #{loan}:#{term}:#{type} rate" do
            get (type.nil? ? "/rates/#{loan}/#{term}" : "/rates/#{loan}/#{term}/#{type}")
            rate = JSON.parse(last_response.body)
            expect(rate['rate']).to be_kind_of(Float)
            expect(rate['updated_at']).to match(/\A\d\d\d\d-(0\d|1[012])-([0-2]\d|3[01]) ([01]\d|2[0-3]):[0-5]\d:[0-5]\d [+-](0\d|1[012])[0-5][0-5]\Z/)
            date = Time.zone.parse(rate['updated_at'])
            expect(date).to be <= Time.zone.now
          end
        end
      end
    end
  end

  describe "extract_market_data_from_soap_response" do
    let (:types)     { %w(whole agency aa aaa).map{ |type| mk_type(type) } }
    let (:types_xml) { types.map{ |type| type[:xml] } }

    let (:overnight) { mk_term('1', 'D', 'overnight') }
    let (:open_day)  { overnight.clone }
    let (:w1)        { mk_term('1', 'W', '1week') }
    let (:w2)        { mk_term('2', 'W', '2week') }
    let (:w3)        { mk_term('3', 'W', '3week') }
    let (:m1)        { mk_term('1', 'M', '1month') }
    let (:m2)        { mk_term('2', 'M', '2month') }
    let (:m3)        { mk_term('3', 'M', '3month') }
    let (:m4)        { mk_term('4', 'M', '4month') }
    let (:m5)        { mk_term('5', 'M', '5month') }
    let (:m6)        { mk_term('6', 'M', '6month') }
    let (:y1)        { mk_term('1', 'Y', '1year') }
    let (:y2)        { mk_term('2', 'Y', '2year') }
    let (:y3)        { mk_term('3', 'Y', '3year') }
    let (:terms) { [overnight,open_day,w1,w2,w3,m1,m2,m3,m4,m5,m6,y1,y2,y3] }
    let (:invalid_terms) { [m4,m5] }
    let (:valid_terms) { terms - invalid_terms }
    let (:terms_xml) { terms.map{ |term| term[:xml] } }

    let (:response) { double('response') }
    let (:result)   { subject.extract_market_data_from_soap_response(response) }
    before do
      allow(response).to receive_message_chain(:doc,:remove_namespaces!)
      allow(response).to receive_message_chain(:doc,:xpath).with(subject::PATHS[:type_data]).and_return(types_xml)

      types.each do |type|
        allow(type[:xml]).to  receive(:css).with(subject::PATHS[:term_data]).and_return(terms_xml)
        allow(subject).to receive(:extract_text).with(type[:xml], :type_long).and_return(type[:type_long])
        allow(subject).to receive(:extract_text).with(type[:xml], :day_count_basis).and_return(type[:day_count_basis])
      end

      terms.each do |term|
        [:frequency, :unit, :rate, :maturity_string].each do |field|
          allow(subject).to receive(:extract_text).with(term[:xml], field).and_return(term[field])
        end
        allow(Time).to receive_message_chain(:zone,:parse).with(term[:maturity_string]).and_return(term[:maturity_time])
        allow(term[:maturity_time]).to receive(:to_date).and_return(term[:maturity_date])
      end
    end

    it 'should return correct rate, maturity_data and interest_day_count for valid terms' do
      types.each do |type|
        valid_terms.each do |term|
          expect(result[type[:type]][term[:term]][:rate]).to eq(term[:rate])
          expect(result[type[:type]][term[:term]][:maturity_date]).to eq(term[:maturity_date])
          expect(result[type[:type]][term[:term]][:interest_day_count]).to eq(type[:day_count_basis])
        end
      end
    end

    it 'should not return anything for invalid terms' do
      types.each do |type|
        invalid_terms.each do |term|
          expect(result[type[:type]][term[:term]]).to be_nil
        end
      end
    end
  end

  describe "rate summary" do
    before do
      allow(MAPI::Services::Rates::Holidays).to receive(:holidays).and_return([])
      allow(MAPI::Services::Rates::BlackoutDates).to receive(:blackout_dates).and_return(blackout_dates)
      allow(MAPI::Services::Rates::LoanTerms).to receive(:loan_terms).and_return(loan_terms_hash)
      allow(MAPI::Services::Rates::RateBands).to receive(:rate_bands).and_return(rate_bands_hash)
      allow(MAPI::Services::Rates).to receive(:init_mds_connection).and_return(false)
      allow(MAPI::Services::Rates).to receive(:fake).with('market_data_live_rates').and_return(live_hash)
      allow(MAPI::Services::Rates).to receive(:fake).with('market_data_start_of_day_rates').and_return(start_of_day_hash)
    end
    let(:today) { Time.zone.today }
    let(:one_week_away) { today + 1.week }
    let(:three_weeks_away) { today + 3.week }
    let(:blackout_dates) { [one_week_away, three_weeks_away] }
    loan_terms = [:overnight, :open, :'1week', :'2week', :'3week', :'1month', :'2month', :'3month', :'6month', :'1year', :'2year', :'3year']
    loan_types = [:whole, :agency, :aaa, :aa]
    let(:loan_terms) { loan_terms }
    let(:loan_types) { loan_types }
    let(:loan_terms_hash) do
      default = n_level_hash_with_default(true, 2)
      h = Hash.new(default)
      h[:'1year'] = { whole:  { trade_status: false, display_status: true  } }
      h[:'3year'] = { agency: { trade_status: true,  display_status: false } }
      h[:'1year'].default = default
      h[:'3year'].default = default
      h
    end
    let(:live_hash) do
      JSON.parse(File.read(File.join(MAPI.root, 'fakes', "market_data_live_rates.json"))).with_indifferent_access
    end
    let (:threshold) { 0.1 }
    let (:threshold_as_BPS) { (threshold*100).to_i.to_s }

    let(:start_of_day_hash) do
      h = JSON.parse(File.read(File.join(MAPI.root, 'fakes', "market_data_live_rates.json"))).with_indifferent_access
      h[:aa][:'1week'][:rate]  = (h[:aa][:'1week'][:rate].to_f + (2*threshold)).to_s
      h[:aaa][:'1week'][:rate] = (h[:aa][:'1week'][:rate].to_f - (2*threshold)).to_s
      h
    end
    let(:rate_bands_hash) { n_level_hash_with_default(threshold_as_BPS, 2) }
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

          live_rate         = live_hash[loan_type][loan_term][:rate].to_f
          start_of_day_rate = start_of_day_hash[loan_type][loan_term][:rate].to_f
          rate_band_lo      = rate_bands_hash[loan_term]['LOW_BAND_OFF_BP'].to_f/100.0
          rate_band_hi      = rate_bands_hash[loan_term]['HIGH_BAND_OFF_BP'].to_f/100.0
          below_threshold   = live_rate < start_of_day_rate - rate_band_lo
          above_threshold   = live_rate > start_of_day_rate + rate_band_hi

          blacked_out = blackout_dates.include?(Date.parse(r[:maturity_date]))
          cutoff      = !loan_terms_hash[loan_term][loan_type][:trade_status]
          disabled    = !loan_terms_hash[loan_term][loan_type][:display_status]
          expect(r[:payment_on]).to be_kind_of(String)
          expect(r[:interest_day_count]).to be_kind_of(String)
          expect(r[:maturity_date]).to be_kind_of(String)
          expect(r[:maturity_date]).to match(/\d{4}-\d{2}-\d{2}/)
          expect(r[:days_to_maturity]).to be_kind_of(String)
          expect(r[:days_to_maturity]).to match(/\d+/)
          expect(r[:rate]).to be_kind_of(String)
          expect(r[:rate]).to match(/\d+\.\d+/)
          expect(r[:disabled]).to be_boolean
          expect(r[:disabled]).to be == (blacked_out || cutoff || disabled || below_threshold || above_threshold)
          expect(r[:end_of_day]).to be(cutoff)
          expect(r[:start_of_day_rate]).to eq(start_of_day_rate)
          expect(r[:rate_band_info]).to eq(MAPI::Services::Rates.rate_band_info(live_hash[loan_type][loan_term], rate_bands_hash[loan_term]))
        end
      end
    end
    it "should return a timestamp" do
      expect(rate_summary[:timestamp]).to be_kind_of(String)
    end

    it "should always call get_maturity_date" do
      expect(MAPI::Services::Rates).to receive(:get_maturity_date).at_least(48).with(kind_of(Date), kind_of(String), kind_of(Array))
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
      let(:logger){ double('logger') }
      let(:maturity_date_before){ double('maturity_date_before') }
      let(:maturity_date_after){ double('maturity_date_after') }
      let(:interest_day_count){ double( 'interest_day_count' ) }
      let(:live_data_xml){ double('live_data_xml') }
      let(:live_data_value_with_string_keys) do
        {
            'payment_on' => 'Maturity',
            'interest_day_count' => interest_day_count,
            'rate' => "5.0",
            'maturity_date' => maturity_date_before,
        }
      end
      let(:live_data_value_with_symbol_keys) { live_data_value_with_string_keys.with_indifferent_access }
      let(:live_data_hash_with_string_keys) do
        types_and_terms_hash { |_type, _term| live_data_value_with_string_keys.clone }
      end
      let(:live_data_hash_with_symbol_keys) do
        types_and_terms_hash { |_type, _term| live_data_value_with_symbol_keys.clone }
      end
      let(:start_of_day_xml){ double('start_of_day_xml') }
      let(:start_of_day){ n_level_hash_with_default("5.0", 3) }
      let(:mds_connection){ double('mds_connection') }
      let(:rate_bands_hash) { n_level_hash_with_default("10", 2) }
      let(:trade_status){ double('trade_status') }
      let(:display_status){ double('display_status') }
      let(:loan_terms_hash){ n_level_hash_with_default({ trade_status: trade_status, display_status: display_status }, 2) }
      before do
        allow(MAPI::ServiceApp).to receive(:environment).and_return(:production)
        allow_any_instance_of(MAPI::ServiceApp).to receive(:logger).and_return(logger)
        allow(MAPI::Services::Rates::Holidays).to receive(:holidays).and_return([])
        allow(MAPI::Services::Rates::BlackoutDates).to receive(:blackout_dates).and_return([])
        allow(MAPI::Services::Rates::LoanTerms).to receive(:loan_terms).and_return(loan_terms_hash)
        allow(MAPI::Services::Rates::RateBands).to receive(:rate_bands).and_return(rate_bands_hash)
        allow(MAPI::Services::Rates).to receive(:init_mds_connection).and_return(mds_connection)
        allow(MAPI::Services::Rates).to receive(:get_market_data_from_soap).with(logger, 'Live').and_return(live_data_xml)
        allow(MAPI::Services::Rates).to receive(:get_market_data_from_soap).with(logger, 'StartOfDay').and_return(start_of_day_xml)
        allow(MAPI::Services::Rates).to receive(:extract_market_data_from_soap_response).with(live_data_xml).and_return(live_data_hash_with_symbol_keys)
        allow(MAPI::Services::Rates).to receive(:extract_market_data_from_soap_response).with(start_of_day_xml).and_return(start_of_day)
        allow(MAPI::Services::Rates).to receive(:get_maturity_date).with(maturity_date_before, kind_of(String), []).and_return(maturity_date_after)
      end

      it "should return Internal Service Error, if calendar service is unavailable" do
        allow(MAPI::Services::Rates::Holidays).to receive(:holidays).and_return(nil)
        get '/rates/summary'
        expect(last_response.status).to eq(503)
      end

      it "should return Internal Service Error, if blackout dates service is unavailable" do
        allow(MAPI::Services::Rates::BlackoutDates).to receive(:blackout_dates).and_return(nil)
        get '/rates/summary'
        expect(last_response.status).to eq(503)
      end

      it "should return Internal Service Error, if loan terms service is unavailable" do
        allow(MAPI::Services::Rates::LoanTerms).to receive(:loan_terms).and_return(nil)
        get '/rates/summary'
        expect(last_response.status).to eq(503)
      end

      it "should return Internal Service Error, if get_market_data soap endpoint is unavailable" do
        allow(MAPI::Services::Rates).to receive(:get_market_data_from_soap).with(logger, 'Live').and_return(nil)
        get '/rates/summary'
        expect(last_response.status).to eq(503)
      end

      it "should return Internal Service Error, if the hash returned from get_market_data soap endpoint uses string keys instead of symbol keys" do
        allow(MAPI::Services::Rates).to receive(:extract_market_data_from_soap_response).with(live_data_xml).and_return(live_data_hash_with_string_keys)
        expect(logger).to receive(:error).at_least(1).times
        get '/rates/summary'
      end

      it "should return 200 if all the endpoints return valid data" do
        get '/rates/summary'
        expect(last_response.status).to eq(200)
      end
    end
  end
  
  describe '`disabled?` class method' do
    let(:date) { (Date.new(2000,1,1)..Date.new(2015,1,1)).to_a.sample }
    let(:rate_band_info) { double('rate band info', :[] => nil) }
    let(:rate_info) { double('a rate object', :[] => nil) }
    let(:loan_term) { double('a loan term object', :[] => nil) }
    let(:blackout_dates) { [date] }
    let(:call_method) { subject.disabled?(rate_info, loan_term, blackout_dates) }
    before do
      allow(rate_info).to receive(:[]).with(:rate_band_info).and_return(rate_band_info)
    end
    
    it 'returns true if the maturity date of the rate is included in the blackout dates array' do
      allow(rate_info).to receive(:[]).with('maturity_date').and_return(date)
      expect(call_method).to eq(true)
    end
    it 'returns true if the loan status `trade_status` is false' do
      allow(loan_term).to receive(:[]).with('trade_status').and_return(false)
      expect(call_method).to eq(true)
    end
    it 'returns true if the loan status `display_status` is false' do
      allow(loan_term).to receive(:[]).with('display_status').and_return(false)
      expect(call_method).to eq(true)
    end
    it 'returns true if the `min_threshold_exceeded` value in rate band info is true' do
      allow(rate_band_info).to receive(:[]).with(:min_threshold_exceeded).and_return(true)
      expect(call_method).to eq(true)
    end
    it 'returns true if the `max_threshold_exceeded` value in rate band info is true' do
      allow(rate_band_info).to receive(:[]).with(:max_threshold_exceeded).and_return(true)
      expect(call_method).to eq(true)
    end
    it 'returns false if no thresholds have been exceeded, trade_status and display_status are not false, and the maturity date is not blacked out' do
      allow(loan_term).to receive(:[]).and_return(true)
      allow(rate_band_info).to receive(:[]).and_return(false)
      expect(call_method).to eq(false)
    end
  end
  
  describe '`rate_band_info` class method' do
    let(:rate_info) { double('a rate object', :[] => nil) }
    let(:band_info) { double('a rate band object', :[] => nil) }
    let(:delta) { rand(1..50) }
    let(:rate) { rand() }
    let(:call_method) { subject.rate_band_info(rate_info, band_info) }
    
    [
      ['low_band_off', 'LOW_BAND_OFF_BP', 'subtracting'],
      ['low_band_warn', 'LOW_BAND_WARN_BP', 'subtracting'],
      ['high_band_off', 'HIGH_BAND_OFF_BP', 'adding'],
      ['high_band_warn', 'HIGH_BAND_WARN_BP', 'adding'],
    ].each do |threshold|
      before do 
        allow(band_info).to receive(:[]).with(threshold[1]).and_return(delta) 
        allow(rate_info).to receive(:[]).with(:start_of_day_rate).and_return(rate)
      end
      it "returns a hash with a `#{threshold[0]}_delta` key that expresses the provided #{threshold[1]} rate band basis point as a float" do
        expect(call_method["#{threshold[0]}_delta".to_sym]).to eq(delta.to_f/100.0)
      end
      it "calculates the `#{threshold[0]}_rate` by #{threshold[2]} the `#{threshold[0]}_delta` from the start_rate" do
        expected_value = threshold[2] == 'subtracting' ? rate_info[:start_of_day_rate] - delta.to_f/100.0 : rate_info[:start_of_day_rate] + delta.to_f/100.0
        expect(call_method["#{threshold[0]}_rate".to_sym]).to eq(expected_value)
      end
    end
    describe 'min_threshold_exceeded' do
      before do
        allow(band_info).to receive(:[]).with('LOW_BAND_OFF_BP').and_return(delta)
        allow(rate_info).to receive(:[]).with(:start_of_day_rate).and_return(rate)
      end
      it 'is true if the live rate is less than the low_band_off_rate' do
        allow(rate_info).to receive(:[]).with(:rate).and_return(rate - delta)
        expect(call_method[:min_threshold_exceeded]).to eq(true)
      end
      it 'is false if the live rate is not less than the low_band_off_rate' do
        allow(rate_info).to receive(:[]).with(:rate).and_return(rate + delta)
        expect(call_method[:min_threshold_exceeded]).to eq(false)
      end
    end
    describe 'max_threshold_exceeded' do
      before do
        allow(band_info).to receive(:[]).with('HIGH_BAND_OFF_BP').and_return(delta)
        allow(rate_info).to receive(:[]).with(:start_of_day_rate).and_return(rate)
      end
      it 'is true if the live rate is more than the high_band_off_rate' do
        allow(rate_info).to receive(:[]).with(:rate).and_return(rate + delta)
        expect(call_method[:max_threshold_exceeded]).to eq(true)
      end
      it 'is false if the live rate is not more than the high_band_off_rate' do
        allow(rate_info).to receive(:[]).with(:rate).and_return(rate - delta)
        expect(call_method[:max_threshold_exceeded]).to eq(false)
      end
    end
  end

  describe "weekend_or_holiday?" do
    let(:saturday) { double('saturday', saturday?: true,  sunday?: false, strftime: nonholiday) }
    let(:sunday)   { double('sunday',   saturday?: false, sunday?: true,  strftime: nonholiday) }
    let(:monday)   { double('monday',   saturday?: false, sunday?: false, strftime: nonholiday) }
    let(:holiday)  { double('holiday',  saturday?: false, sunday?: false, strftime: formatted)  }
    let(:formatted){ double('formatted') }
    let(:nonholiday) { double('nonholiday') }
    let(:holidays) { [formatted] }

    it "should return true for saturday" do
      expect(subject.weekend_or_holiday?(saturday, holidays)).to be_truthy
    end
    it "should return true for sunday" do
      expect(subject.weekend_or_holiday?(sunday, holidays)).to be_truthy
    end
    it "should return true for monday" do
      expect(subject.weekend_or_holiday?(monday, holidays)).to be_falsey
    end
    it "should return true for holiday" do
      expect(subject.weekend_or_holiday?(holiday, holidays)).to be_truthy
    end
  end

  describe "get_maturity_date" do
    let (:day1_str) { double('day1 str', to_date: day1) }
    let (:day2_str) { double('day2 str', to_date: day2) }
    let (:day1) { double( 'day 1' ) }
    let (:day2) { double( 'day 2' ) }
    let (:day3) { double( 'day 3' ) }
    let (:day4) { double( 'day 4' ) }
    let (:start_date)  { '2015-09-30'.to_date }
    let (:end_date_3m) { '2015-12-30'.to_date }
    let (:end_date_1y) { '2016-09-30'.to_date }
    let(:holidays) { double( 'holidays' ) }
    before do
      [day1,day2,day3].zip([day2,day3,day4]).each do |pred,succ|
        allow(pred).to receive( '+' ).with(1.day).and_return(succ)
        allow(succ).to receive( '+' ).with(-1.day).and_return(pred)
      end
    end
    it "should return the same date if is not a weekend" do
      allow(subject).to receive(:weekend_or_holiday?).with(day1, holidays).and_return(false)
      expect(subject.get_maturity_date(day1_str, 'W', holidays)).to eq(day1)
    end
    it "should return the next non weekend date if is weekend" do
      allow(subject).to receive(:weekend_or_holiday?).with(day1, holidays).and_return(true)
      allow(subject).to receive(:weekend_or_holiday?).with(day2, holidays).and_return(false)
      expect(subject.get_maturity_date(day1_str, 'W', holidays)).to eq(day2)
    end
    it "should return the previous non weekend date if is weekend and month/year term and hits next month" do
      allow(subject).to receive(:weekend_or_holiday?).with(day1, holidays).and_return(false)
      allow(subject).to receive(:weekend_or_holiday?).with(day2, holidays).and_return(true)
      allow(subject).to receive(:weekend_or_holiday?).with(day3, holidays).and_return(false)
      allow(day3).to receive('>').with(day2).and_return(true)
      allow(day2).to receive(:end_of_month).and_return(day2)
      expect(subject.get_maturity_date(day2_str, 'Y', holidays)).to eq(day1)
    end

    it 'test particular data points' do
      expect(subject.get_maturity_date(start_date + MAPI::Services::Rates::TERM_MAPPING[:'3month'][:time], 'M', [])).to eq(end_date_3m)
      expect(subject.get_maturity_date(start_date + MAPI::Services::Rates::TERM_MAPPING[:'1year'][:time], 'Y', [])).to eq(end_date_1y)
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

  describe 'historic sta indications' do
    let(:start_date) {'2014-04-01'}
    let(:end_date) {'2014-04-02'}
    let(:historic_sta_rates) { get "rates/price_indication/historical/#{start_date}/#{end_date}/sta/sta"; JSON.parse(last_response.body).with_indifferent_access }
    it 'throws a 400 if the start_date is later than the end_date' do
      get "rates/price_indication/historical/#{end_date}/#{start_date}/sta/sta"
      expect(last_response.status).to eq(400)
    end
    it 'calls the `historical sta` method on the MAPI::Services::Rates::PriceIndicationHistorical module' do
      expect(MAPI::Services::Rates::HistoricalSTA).to receive(:historical_sta)
      get "rates/price_indication/historical/#{start_date}/#{end_date}/sta/sta"
    end
    it 'should return historical sta data' do
      historic_sta_rates['rates_by_date'].each do |row|
        expect(row['date']).to be_kind_of(String)
        expect(row['rate']).to be_kind_of(Float)
      end
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
