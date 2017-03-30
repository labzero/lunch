require 'spec_helper'
require 'date'


def n_level_hash_with_default(default, n)
  n == 0 ? default : n_level_hash_with_default(Hash.new(default), n-1)
end

def types_and_terms_hash
  Hash[loan_types.map { |type| [type, Hash[loan_terms.map{ |term| [term, yield(type, term)] }]] }]
end

def types_and_terms_custom_hash
  Hash[loan_types.map { |type| [type, Hash[loan_terms_custom.map{ |term| [term, yield(type, term)] }]] }]
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

  RSpec.shared_examples 'a rates summary' do |funding_date=nil, maturity_date=nil|
    before do
      allow(MAPI::Services::Rates).to receive(:get_market_data_from_soap).with(logger, 'Live', funding_date, maturity_date).and_return(live_data_xml)
      allow(MAPI::Services::Rates).to receive(:get_market_data_from_soap).with(logger, 'StartOfDay', funding_date, maturity_date).and_return(start_of_day_xml)
    end
    it "returns Internal Service Error, if calendar service is unavailable" do
      allow(MAPI::Services::Rates::Holidays).to receive(:holidays).and_return(nil)
      if funding_date
        get '/rates/summary', funding_date: funding_date
      elsif maturity_date
        get '/rates/summary', maturity_date: maturity_date
      else
        get '/rates/summary'
      end
      expect(last_response.status).to eq(503)
    end

    it "returns Internal Service Error, if blackout dates service is unavailable" do
      allow(MAPI::Services::Rates::BlackoutDates).to receive(:blackout_dates).and_return(nil)
      if funding_date
        get '/rates/summary', funding_date: funding_date
      elsif maturity_date
        get '/rates/summary', maturity_date: maturity_date
      else
        get '/rates/summary'
      end
      expect(last_response.status).to eq(503)
    end

    it "returns Internal Service Error, if loan terms service is unavailable" do
      allow(MAPI::Services::Rates::LoanTerms).to receive(:loan_terms).and_return(nil)
      if funding_date
        get '/rates/summary', funding_date: funding_date
      elsif maturity_date
        get '/rates/summary', maturity_date: maturity_date
      else
        get '/rates/summary'
      end
      expect(last_response.status).to eq(503)
    end

    it "returns Internal Service Error, if get_market_data soap endpoint is unavailable" do
      allow(MAPI::Services::Rates).to receive(:get_market_data_from_soap).with(logger, 'Live', funding_date, maturity_date).and_return(nil)
      if funding_date
        get '/rates/summary', funding_date: funding_date
      elsif maturity_date
        get '/rates/summary', maturity_date: maturity_date
      else
        get '/rates/summary'
      end
      expect(last_response.status).to eq(503)
    end

    it "returns Internal Service Error, if the hash returned from get_market_data soap endpoint uses string keys instead of symbol keys" do
      allow(MAPI::Services::Rates).to receive(:extract_market_data_from_soap_response).with(live_data_xml).and_return(live_data_hash_with_string_keys)
      expect(logger).to receive(:error).at_least(1).times
      if funding_date
        get '/rates/summary', funding_date: funding_date
      elsif maturity_date
        get '/rates/summary', maturity_date: maturity_date
      else
        get '/rates/summary'
      end
    end

    it "returns 200 if all the endpoints return valid data" do
      if funding_date
        get '/rates/summary', funding_date: funding_date
      elsif maturity_date
        get '/rates/summary', maturity_date: maturity_date
      else
        get '/rates/summary'
      end
      expect(last_response.status).to eq(200)
    end
  end

  describe "historic overnight rates" do
    let(:make_request) { get '/rates/historic/overnight' }
    let(:rates) { make_request; JSON.parse(last_response.body) }
    describe "development" do
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
    describe 'in production' do
      before do
        allow(described_class).to receive(:environment).and_return(:production)
        allow(subject).to receive(:fetch_rows).and_return([])
      end
      describe 'queries the DB for historic rates' do
        it 'calls `fetch_rows` with the logger' do
          logger = instance_double(Logger, error: nil)
          allow_any_instance_of(described_class).to receive(:logger).and_return(logger)
          expect(subject).to receive(:fetch_rows).with(logger, anything)
          make_request
        end
        it 'calls `fetch_rows` with the query' do
          expect(subject).to receive(:fetch_rows).with(anything, match(/SELECT\s+TRX_EFFECTIVE_DATE,\s+TRX_VALUE\s+FROM IRDB.IRDB_TRANS\s+T\s+WHERE\s+TRX_IR_CODE\s+=\s+'FRADVN'\s+AND\s+\(TRX_TERM_VALUE\s+\|\|\s+TRX_TERM_UOM\s+=\s+'1D'\s+\)\s+ORDER/i))
          make_request
        end
        it 'orders the query by `TRX_EFFECTIVE_DATE` descending' do
          expect(subject).to receive(:fetch_rows).with(anything, match(/\s+ORDER\s+BY\s+TRX_EFFECTIVE_DATE\s+DESC/i))
          make_request
        end
        it 'includes the limit in the query' do
          limit = rand(1..10)
          quoted_limit = SecureRandom.hex
          allow(ActiveRecord::Base.connection).to receive(:quote).with(limit).and_return(quoted_limit)
          expect(subject).to receive(:fetch_rows).with(anything, match(/\A\s*SELECT\s+\*\s+FROM\s+\(.*\)\s+WHERE\s+ROWNUM\s+<=\s+#{quoted_limit}\s*\z/im))
          get '/rates/historic/overnight', limit: limit
        end
      end
      it 'returns an empty JSON array if no data was found' do
        expect(rates).to eq([])
      end
      it 'returns a 503 if an error occured' do
        allow(subject).to receive(:fetch_rows).and_return(nil)
        make_request
        expect(last_response.status).to be(503)
      end
    end
  end

  describe "current rates" do
    let(:today) { Time.zone.today }
    let(:maturity_date) { today + rand(3..1095).days }
    MAPI::Services::Rates::LOAN_TYPES.each do |loan|
      [*MAPI::Services::Rates::LOAN_TERMS, "#{rand(3..1095)}day"].each do |term|
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
    describe "in the production environment" do
      let(:mds_connection) { MAPI::Services::Rates.init_mds_connection(:production) }
      let(:call_method) { get 'rates/whole/2month' }
      let(:call_method_custom) { get 'rates/whole/10day' }
      before do
        allow(MAPI::ServiceApp).to receive(:environment).and_return(:production)
      end
      it 'calls `init_mds_connection`' do
        expect(MAPI::Services::Rates).to receive(:init_mds_connection).with(:production)
        call_method
      end
      describe 'building the MDS message', vcr: {cassette_name: 'market_data_rate_2months'} do
        it 'includes the caller ID' do
          expect(mds_connection).to receive(:call).with(:get_market_data, include(message: include('v11:caller' => [{'v11:id' => ENV['MAPI_COF_ACCOUNT']}])) ).and_call_original
          call_method
        end
        it 'includes paymentFrequency with frequency = 2 and frequencyUnit = M' do
          requests = include('v1:marketData' => [include('v12:data' => [{'v12:FhlbsfDataPoint' => ['v12:tenor' => ['v12:interval' => [{'v13:frequency' => '2','v13:frequencyUnit' => 'M'}]]]}])])
          expect(mds_connection).to receive(:call).with(:get_market_data, include(message: include('v1:requests' => [{'v1:fhlbsfMarketDataRequest' => [requests]}])) ).and_call_original
          call_method
        end
      end
      describe 'building the custom MDS message', vcr: {cassette_name: 'market_data_rate_custom'} do
        it 'includes paymentFrequency with frequency = 10 and frequencyUnit = D' do
          requests = include('v1:marketData' => [include('v12:data' => [{'v12:FhlbsfDataPoint' => ['v12:tenor' => ['v12:interval' => [{'v13:frequency' => '10','v13:frequencyUnit' => 'D'}]]]}])])
          expect(mds_connection).to receive(:call).with(:get_market_data, include(message: include('v1:requests' => [{'v1:fhlbsfMarketDataRequest' => [requests]}])) ).and_call_original
          call_method_custom
        end
      end
      it 'returns a 503 if the MDS connection was not successful', vcr: {cassette_name: 'market_data_rate_2months'} do
        allow(mds_connection).to receive(:call).and_return(instance_double(Savon::Response, success?: false))
        call_method
        expect(last_response.status).to be(503)
      end
      it 'returns a 503 if the MDS connection returned an error', vcr: {cassette_name: 'market_data_rate_error'} do
        call_method
        expect(last_response.status).to be(503)
      end
    end
  end

  describe '`extract_text` class method' do
    let(:node) { instance_double(Nokogiri::XML::Node, content: nil) }
    let(:document) { instance_double(Nokogiri::XML::Document, at_css: node) }
    let(:path_key) { instance_double(Symbol, 'A Path Key') }
    let(:path) { instance_double(String, 'A Path') }
    let(:call_method) { MAPI::Services::Rates.extract_text(document, path_key) }
    before do
      stub_const('MAPI::Services::Rates::PATHS', {path_key => path})
    end
    it 'looks up the `path_key` in the `PATHS`' do
      expect(MAPI::Services::Rates::PATHS).to receive(:[]).with(path_key).and_return(path)
      call_method
    end
    it 'calls `at_css` on the `document` with the `path`' do
      expect(document).to receive(:at_css).with(path)
      call_method
    end
    it 'returns the content from the found node' do
      content = instance_double(String, 'Some Content')
      allow(node).to receive(:content).and_return(content)
      expect(call_method).to be(content)
    end
    it 'returns nil if the node is not found' do
      allow(document).to receive(:at_css).and_return(nil)
      expect(call_method).to be(nil)
    end
  end

  describe "extract_market_data_from_soap_response" do
    let(:xml_type_data) { instance_double(Nokogiri::XML::Node, css: []) }
    let(:xml_term_data) { instance_double(Nokogiri::XML::Node) }
    let(:xml_document) { instance_double(Nokogiri::XML::Document, remove_namespaces!: true, xpath: []) }
    let(:rate) { SecureRandom.hex }
    let(:maturity_string) { (Time.zone.today+ rand(3..1095).days).to_s }
    let(:type) { SecureRandom.hex }
    let(:type_long) { SecureRandom.hex }
    let(:day_count_basis) { SecureRandom.hex }
    let(:term) { SecureRandom.hex }
    let(:get_term_data_response) { { rate: rate, maturity_string: maturity_string, term: term } }
    let(:get_term_data_overnight_response) { { rate: rate, maturity_string: maturity_string, term: 'overnight' } }
    let(:response) { instance_double(Savon::Response, doc: xml_document) }
    let(:call_method) { subject.extract_market_data_from_soap_response(response) }

    before do
      allow(xml_document).to receive(:xpath).with(MAPI::Services::Rates::PATHS[:type_data]).and_return([xml_type_data])
      allow(xml_type_data).to receive(:css).with(MAPI::Services::Rates::PATHS[:term_data]).and_return([xml_term_data])
      allow(MAPI::Services::Rates).to receive(:get_term_data).and_return(get_term_data_response)
      allow(MAPI::Services::Rates).to receive(:extract_text)
      allow(MAPI::Services::Rates).to receive(:extract_text).with(xml_type_data, :type_long).and_return(type_long)
      loan_mapping_inverted = { type_long => type }
      stub_const 'MAPI::Shared::Constants::LOAN_MAPPING_INVERTED', loan_mapping_inverted
      allow(NewRelic::Agent).to receive(:notice_error)
    end

    describe 'when there are no custom terms' do
      it 'extracts the day count basis from the term data' do
        expect(MAPI::Services::Rates).to receive(:extract_text).with(xml_type_data, :day_count_basis)
        call_method
      end
      it 'extracts the `type_long` from the term data' do
        expect(MAPI::Services::Rates).to receive(:extract_text).with(xml_type_data, :type_long)
        call_method
      end
      it 'converts the `type_long` to a type' do
        expect(call_method[type].length).to be > 0
      end
      it 'calls `get_term_data` with the `term_data` and `type_data`' do
        expect(MAPI::Services::Rates).to receive(:get_term_data).with(xml_type_data, xml_term_data, false)
        call_method
      end
      it 'returns no results if `get_term_data` returns nothing' do
        allow(MAPI::Services::Rates).to receive(:get_term_data).with(xml_type_data, xml_term_data, anything).and_return(nil)
        expect(call_method).to be_empty
      end
      describe 'when `get_term_data` successfully parses the data' do
        it 'returns the correct rate' do
          expect(call_method[type][term][:rate]).to eq(rate)
        end
        it 'returns the correct maturity_date' do
          expect(call_method[type][term][:maturity_date]).to eq(Time.zone.parse(maturity_string).to_date)
        end
        it 'returns the correct interest_day_count' do
          allow(MAPI::Services::Rates).to receive(:extract_text).with(xml_type_data, :day_count_basis).and_return(day_count_basis)
          expect(call_method[type][term][:interest_day_count]).to eq(day_count_basis)
        end
        it 'returns the correct payment_on' do
          expect(call_method[type][term][:payment_on]).to eq('Maturity')
        end
        it 'clones overnight term into open term' do
          allow(MAPI::Services::Rates).to receive(:get_term_data).and_return(get_term_data_overnight_response)
          expect(call_method[type][:open]).to eq(call_method[type][:overnight])
        end
        it 'logs a NewRelic error if a blank rate is returned' do
          get_term_data_response[:rate] = ''
          expect(NewRelic::Agent).to receive(:notice_error).with('Blank rate returned', trace_only: true, custom_params: {term: term, type: type, data: xml_term_data})
          call_method
        end
      end
    end
    describe 'when there are custom terms' do
      before do
        allow(xml_document).to receive(:xpath).with(MAPI::Services::Rates::PATHS[:type_data]).and_return([xml_type_data, xml_type_data])
      end
      it 'calls `get_term_data` with the `term_data`, `type_data` and is_custom' do
        expect(MAPI::Services::Rates).to receive(:get_term_data).with(xml_type_data, xml_term_data, true)
        call_method
      end
    end
  end

  describe 'get_term_data' do
    let(:type_data) { double('Type Data') }
    let(:term_data) { double('Term Data') }
    let(:funding_date) { SecureRandom.hex }
    let(:maturity_string) { SecureRandom.hex }
    let(:rate) { SecureRandom.hex }
    let(:term) { SecureRandom.hex }
    let(:frequency) { SecureRandom.hex }
    let(:unit) { SecureRandom.hex }
    let(:days) { rand(3..1095) }
    let(:custom_term) { days.to_s + 'day' }
    let(:days_to_maturity_return) { {days: days, term: custom_term} }
    let(:call_method) { subject.get_term_data(type_data, term_data, false) }
    let(:call_method_custom) { subject.get_term_data(type_data, term_data, true) }

    before do
      allow(MAPI::Services::Rates).to receive(:extract_text)
    end

    it 'extracts rate from the term data' do
      expect(MAPI::Services::Rates).to receive(:extract_text).with(term_data, :rate)
      call_method
    end
    it 'extracts maturity_string from the term data' do
      expect(MAPI::Services::Rates).to receive(:extract_text).with(term_data, :maturity_string)
      call_method
    end
    describe 'when not custom' do
      it 'extracts frequency from the term data' do
        expect(MAPI::Services::Rates).to receive(:extract_text).with(term_data, :frequency)
        call_method
      end
      it 'extracts unit from the term data' do
        expect(MAPI::Services::Rates).to receive(:extract_text).with(term_data, :unit)
        call_method
      end
      it 'returns nil if the term could not be identified' do
        stub_const('MAPI::Services::Rates::PERIOD_TO_TERM', {})
        expect(call_method).to be_nil
      end
    end
    describe 'when custom' do
      before do
        allow(MAPI::Services::Rates).to receive(:extract_text).with(term_data, :maturity_string).and_return(maturity_string)
        allow(MAPI::Services::Rates).to receive(:extract_text).with(type_data, :spot_date).and_return(funding_date)
        allow(MAPI::Services::Rates).to receive(:days_to_maturity).and_return(days_to_maturity_return)
      end
      it 'extracts unit from the term data' do
        expect(MAPI::Services::Rates).to receive(:extract_text).with(type_data, :spot_date)
        call_method_custom
      end
      it 'calls days_to_maturity with maturity_string and funding_date' do
        expect(MAPI::Services::Rates).to receive(:days_to_maturity).with(maturity_string, funding_date)
        call_method_custom
      end
      it 'returns nil if the term could not be identified' do
        allow(MAPI::Services::Rates).to receive(:days_to_maturity).with(maturity_string, funding_date).and_return({})
        expect(call_method_custom).to be_nil
      end
    end
    describe 'return hash' do
      before do
        allow(MAPI::Services::Rates).to receive(:extract_text).with(term_data, :rate).and_return(rate)
        allow(MAPI::Services::Rates).to receive(:extract_text).with(term_data, :maturity_string).and_return(maturity_string)
      end
      describe 'when not custom' do
        before do
          allow(MAPI::Services::Rates).to receive(:extract_text).with(term_data, :frequency).and_return(frequency)
          allow(MAPI::Services::Rates).to receive(:extract_text).with(term_data, :unit).and_return(unit)
          period_to_term = { "#{frequency}#{unit}" => term }
          stub_const 'MAPI::Services::Rates::PERIOD_TO_TERM', period_to_term
        end
        it 'sets the correct rate' do
          expect(call_method[:term]).to eq(term)
        end
        it 'sets the correct maturity_string' do
          expect(call_method[:maturity_string]).to eq(maturity_string)
        end
      end
      describe 'when custom' do
        before do
          allow(MAPI::Services::Rates).to receive(:days_to_maturity).and_return(days_to_maturity_return)
        end
        it 'sets the correct rate' do
          expect(call_method_custom[:term]).to eq(custom_term)
        end
        it 'sets the correct maturity_string' do
          expect(call_method_custom[:maturity_string]).to eq(maturity_string)
        end
      end
    end
  end

  describe "rate summary" do
    before do
      allow_any_instance_of(MAPI::ServiceApp).to receive(:logger).and_return(logger)
      allow(MAPI::Services::Rates::Holidays).to receive(:holidays).and_return([])
      allow(MAPI::Services::Rates::BlackoutDates).to receive(:blackout_dates).and_return(blackout_dates)
      allow(MAPI::Services::Rates::LoanTerms).to receive(:loan_terms).and_return(loan_terms_hash)
      allow(MAPI::Services::Rates::RateBands).to receive(:rate_bands).and_return(rate_bands_hash)
      allow(MAPI::Services::Rates).to receive(:init_mds_connection).and_return(false)
      allow(MAPI::Services::Rates).to receive(:fake).with('market_data_live_rates').and_return(live_hash)
      allow(MAPI::Services::Rates).to receive(:fake).with('market_data_start_of_day_rates').and_return(start_of_day_hash)
      allow(MAPI::Mailers::InternalMailer).to receive(:send_rate_band_alert)
    end
    let(:logger) { instance_double(Logger, error: nil)}
    let(:today) { Time.zone.today }
    let(:one_week_away) { today + 1.week }
    let(:three_weeks_away) { today + 3.week }
    let(:blackout_dates) { [one_week_away, three_weeks_away] }
    loan_terms = [:overnight, :open, :'1week', :'2week', :'3week', :'1month', :'2month', :'3month', :'6month', :'1year', :'2year', :'3year']
    loan_terms_custom = [:overnight, :open, :'1week', :'2week', :'3week', :'1month', :'2month', :'3month', :'6month', :'1year', :'2year', :'3year', :'10day']
    loan_types = [:whole, :agency, :aaa, :aa]
    let(:loan_terms) { loan_terms }
    let(:loan_terms_custom) { loan_terms_custom }
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
      JSON.parse(File.read(File.join(MAPI.root, 'fakes', "market_data_live_rates.json"))).with_indifferent_access
    end
    let(:rate_bands_hash) { n_level_hash_with_default(threshold_as_BPS, 2) }
    let(:rate_summary) do
      get '/rates/summary'
      JSON.parse(last_response.body).with_indifferent_access
    end
    let(:custom_maturity_date) { Time.zone.today+ rand(3..1095).days }
    let(:days_to_maturity_term) { (custom_maturity_date.to_date - Time.zone.today).to_i.to_s + 'day' }
    let(:rate_summary_with_maturity_date) do
      get '/rates/summary', maturity_date: custom_maturity_date
      JSON.parse(last_response.body).with_indifferent_access
    end
    let(:rate_summary_with_member_id) do
      get '/rates/summary', member_id: 3
      JSON.parse(last_response.body).with_indifferent_access
    end
    it "returns rates for default loan_types at default loan_terms" do
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
        describe 'when a rate band violation occurs' do
          let(:rate_band_hash) {MAPI::Services::Rates.rate_band_info(live_hash[loan_type][loan_term], rate_bands_hash[loan_term])}
          before do
            rate_band_hash[:max_threshold_exceeded] = false
            rate_band_hash[:min_threshold_exceeded] = false
            loan_terms_hash[loan_term][loan_type][:trade_status] = true
            loan_terms_hash[loan_term][loan_type][:display_status] = true
            allow(MAPI::Services::Rates).to receive(:rate_band_info).and_call_original
            allow(MAPI::Services::Rates).to receive(:rate_band_info).with(live_hash[loan_type][loan_term], rate_bands_hash[loan_term]).and_return(rate_band_hash)
            allow(logger).to receive(:error)
            allow(NewRelic::Agent).to receive(:notice_error)
          end
          shared_examples 'rate band violations' do |term, type|
            it 'logs the violation' do
              expect(logger).to receive(:error).with(match(/type=#{type}, term=#{term}, details=#{Regexp.quote(rate_summary[type][term].to_json)}/))
              get '/rates/summary'
            end
            it 'logs the violation in NewRelic' do
              details = rate_summary[type][term]
              details[:maturity_date] = details[:maturity_date].to_date
              expect(NewRelic::Agent).to receive(:notice_error).with('Rate band threshold exceeded', trace_only: true, custom_params: {term: term, type: type, details: details})
              get '/rates/summary'
            end
            it 'sends a rate band alert' do
              request_id = instance_double(String, 'A Request UUID')
              user_id = instance_double(String, 'A User ID')
              allow_any_instance_of(MAPI::ServiceApp).to receive(:request_id).and_return(request_id)
              allow_any_instance_of(MAPI::ServiceApp).to receive(:request_user_id).and_return(user_id)
              expect(MAPI::Mailers::InternalMailer).to receive(:send_rate_band_alert).with(type, term, live_hash[type][term][:rate].to_f, start_of_day_hash[type][term][:rate].to_f, rate_band_hash, request_id, user_id)
              rate_summary
            end
            shared_examples 'ignored violation' do
              it 'does not log the violation in NewRelic' do
                expect(NewRelic::Agent).to_not receive(:notice_error)
                rate_summary
              end
              it 'does not log the violation' do
                expect(logger).to_not receive(:error)
                rate_summary
              end
              it 'does not send a rate band alert' do
                expect(MAPI::Mailers::InternalMailer).to_not receive(:send_rate_band_alert)
                rate_summary
              end
            end
            describe 'if its passed the end-of-day' do
              before do
                loan_terms_hash[loan_term][loan_type][:trade_status] = false
              end

              include_examples 'ignored violation'
            end

            describe 'if the rate is already disabled' do
              before do
                loan_terms_hash[loan_term][loan_type][:display_status] = false
              end

              include_examples 'ignored violation'
            end
          end
          describe 'when the rate high threshold is exceeded' do
            before do
              rate_band_hash[:max_threshold_exceeded] = true
            end

            include_examples 'rate band violations', loan_term, loan_type
          end
          describe 'when the rate low threshold is exceeded' do
            before do
              rate_band_hash[:min_threshold_exceeded] = true
            end

            include_examples 'rate band violations', loan_term, loan_type
          end
        end
      end
    end
    it "returns a timestamp" do
      expect(rate_summary[:timestamp]).to be_kind_of(String)
    end

    it "always call get_maturity_date" do
      expect(MAPI::Services::Rates).to receive(:get_maturity_date).at_least(48).with(kind_of(Date), kind_of(String), kind_of(Array))
      get '/rates/summary'
    end

    it "sets maturity date to get maturity date" do
      maturity_date = 'foobar'
      allow(MAPI::Services::Rates).to receive(:get_maturity_date).and_return(maturity_date)
      loan_types.each do |loan_type|
        loan_terms.each do |loan_term|
          expect(rate_summary[loan_type][loan_term][:maturity_date]).to eq(maturity_date)
        end
      end
    end

    describe "sets custom term data if maturity_date is not nil" do
      loan_types.each do |loan_type|
        it "should set #{loan_type} payment_on" do
          expect(rate_summary_with_maturity_date[loan_type][days_to_maturity_term][:payment_on]).to eq('Maturity')
        end
        it "should set #{loan_type} interest_day_count" do
          expect(rate_summary_with_maturity_date[loan_type][days_to_maturity_term][:interest_day_count]).to eq('ACT/ACT')
        end
        it "should set #{loan_type} days_to_maturity" do
          expect(rate_summary_with_maturity_date[loan_type][days_to_maturity_term][:days_to_maturity]).to eq((custom_maturity_date.to_date - Time.zone.today.to_date).to_i)
        end
        it "should set #{loan_type} rate" do
          expect(rate_summary_with_maturity_date[loan_type][days_to_maturity_term][:rate]).to be_kind_of(Float)
        end
        it "should set #{loan_type} maturity_date" do
          expect(rate_summary_with_maturity_date[loan_type][days_to_maturity_term][:maturity_date]).to eq(custom_maturity_date.iso8601)
        end
      end
    end

    describe 'sets fake rates a for member, if member_id = 3' do
      before do
        allow(subject).to receive(:disabled?)
        allow(subject).to receive(:get_maturity_date)
        allow(subject).to receive(:rate_band_info).and_call_original
      end
      loan_types.each do |loan_type|
        loan_terms.each do |loan_term|
          it 'sets blackout_dates to []' do
            expect(subject).to receive(:disabled?).with(anything, loan_terms_hash[loan_term][loan_type], [])
            rate_summary_with_member_id
          end
          it 'sets holidays to []' do
            expect(subject).to receive(:get_maturity_date).with(anything, anything, [])
            rate_summary_with_member_id
          end
          it "sets end_of_day for #{loan_type} #{loan_term} to false" do
            expect(rate_summary_with_member_id[loan_type][loan_term][:end_of_day]).to eq(false)
          end
          it "sets trade_status for #{loan_type} #{loan_term} to true" do
            expect(subject).to receive(:disabled?).with(anything,  {trade_status: true, display_status: anything, end_time: anything, end_time_reached: anything}, anything)
            rate_summary_with_member_id
          end
          it "sets display_status for #{loan_type} #{loan_term} to true" do
            expect(subject).to receive(:disabled?).with(anything,  {trade_status: anything, display_status: true, end_time: anything, end_time_reached: anything}, anything)
            rate_summary_with_member_id
          end
          it "sets end_time for #{loan_type} #{loan_term} to end_of_day" do
            expect(subject).to receive(:disabled?).with(anything,  {trade_status: anything, display_status: anything, end_time: Time.zone.now.end_of_day, end_time_reached: anything}, anything)
            rate_summary_with_member_id
          end
          it "sets end_time_reached for #{loan_type} #{loan_term} to false" do
            expect(subject).to receive(:disabled?).with(anything,  {trade_status: anything, display_status: anything, end_time: anything, end_time_reached: false}, anything)
            rate_summary_with_member_id
          end
          it "sets LOW_BAND_OFF_BP for #{loan_term} to 1000" do
            expect(subject).to receive(:rate_band_info).with(anything,  {'LOW_BAND_OFF_BP'=> 1000, 'HIGH_BAND_OFF_BP'=> anything})
            rate_summary_with_member_id
          end
          it "sets HIGH_BAND_OFF_BP for #{loan_term} to 1000" do
            expect(subject).to receive(:rate_band_info).with(anything,  {'LOW_BAND_OFF_BP'=> anything, 'HIGH_BAND_OFF_BP'=> 1000})
            rate_summary_with_member_id
          end
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
      let(:live_data_custom_hash_with_string_keys) do
        types_and_terms_custom_hash { |_type, _term| live_data_value_with_string_keys.clone }
      end
      let(:live_data_custom_hash_with_symbol_keys) do
        types_and_terms_custom_hash { |_type, _term| live_data_value_with_symbol_keys.clone }
      end
      let(:start_of_day_xml){ double('start_of_day_xml') }
      let(:start_of_day){ n_level_hash_with_default("5.0", 3) }
      let(:mds_connection){ double('mds_connection') }
      let(:rate_bands_hash) { n_level_hash_with_default("10", 2) }
      let(:trade_status){ double('trade_status') }
      let(:display_status){ double('display_status') }
      today = Time.zone.today
      funding_date =  today + rand(1..2).days
      maturity_date =  today + 10.days
      let(:loan_terms_hash){ n_level_hash_with_default({ trade_status: trade_status, display_status: display_status }, 2) }
      before do
        allow(MAPI::ServiceApp).to receive(:environment).and_return(:production)
        allow_any_instance_of(MAPI::ServiceApp).to receive(:logger).and_return(logger)
        allow(MAPI::Services::Rates::Holidays).to receive(:holidays).and_return([])
        allow(MAPI::Services::Rates::BlackoutDates).to receive(:blackout_dates).and_return([])
        allow(MAPI::Services::Rates::LoanTerms).to receive(:loan_terms).and_return(loan_terms_hash)
        allow(MAPI::Services::Rates::RateBands).to receive(:rate_bands).and_return(rate_bands_hash)
        allow(MAPI::Services::Rates).to receive(:init_mds_connection).and_return(mds_connection)
        allow(MAPI::Services::Rates).to receive(:extract_market_data_from_soap_response).with(live_data_xml).and_return(live_data_hash_with_symbol_keys)
        allow(MAPI::Services::Rates).to receive(:extract_market_data_from_soap_response).with(start_of_day_xml).and_return(start_of_day)
        allow(MAPI::Services::Rates).to receive(:get_maturity_date).with(maturity_date_before, kind_of(String), []).and_return(maturity_date_after)
      end
      describe "funding date is nil and maturity date is nil" do
        it_behaves_like 'a rates summary'
      end
      describe "funding date is not nil" do
        before do
          allow(MAPI::Services::Rates).to receive(:get_market_data_from_soap).with(logger, 'Live', funding_date, nil).and_return(live_data_xml)
          allow(MAPI::Services::Rates).to receive(:get_market_data_from_soap).with(logger, 'StartOfDay', funding_date, nil).and_return(start_of_day_xml)
        end
        it_behaves_like 'a rates summary', funding_date

        it "passes funding date to get_market_data_from_soap method, if the date is supplied" do
          expect(subject).to receive(:get_market_data_from_soap).with(logger, 'Live', funding_date, nil)
          expect(subject).to receive(:get_market_data_from_soap).with(logger, 'StartOfDay', funding_date, nil)
          get '/rates/summary', funding_date: funding_date
        end
      end
      describe "maturity date is not nil" do
        before do
          allow(MAPI::Services::Rates).to receive(:get_market_data_from_soap).with(logger, 'Live', nil, maturity_date).and_return(live_data_xml)
          allow(MAPI::Services::Rates).to receive(:get_market_data_from_soap).with(logger, 'StartOfDay', nil, maturity_date).and_return(start_of_day_xml)
          allow(MAPI::Services::Rates).to receive(:extract_market_data_from_soap_response).with(live_data_xml).and_return(live_data_custom_hash_with_symbol_keys)
        end
        it_behaves_like 'a rates summary', nil, maturity_date

        it "passes maturity date to get_market_data_from_soap method, if the date is supplied with `live` value" do
          expect(subject).to receive(:get_market_data_from_soap).with(logger, 'Live', nil, maturity_date)
          get '/rates/summary', maturity_date: maturity_date
        end
        it "passes maturity date to get_market_data_from_soap method, if the date is supplied with `StartOfDay` value" do
          expect(subject).to receive(:get_market_data_from_soap).with(logger, 'StartOfDay', nil, maturity_date)
          get '/rates/summary', maturity_date: maturity_date
        end
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

  fakeable_method 'is_limited_pricing_day? class method' do
    let(:request) { double(Sinatra::Request) }
    let(:date) { Time.zone.today }
    let(:call_method) { subject.is_limited_pricing_day?(app, date) }

    before do
      allow(app).to receive(:request).and_return(request)
      allow(subject).to receive(:request_cache).and_yield
    end

    it 'caches the response in the request keyed by date' do
      expect(subject).to receive(:request_cache).with(request, ['is_limited_pricing_day', date.to_s]).and_return([])
      call_method
    end
    it 'returns true if today is a limited pricing day' do
      allow(subject).to receive(:request_cache).and_return([date])
      expect(call_method).to be(true)
    end
    it 'returns false if today is not a limited pricing day' do
      allow(subject).to receive(:request_cache).and_return([date + 1.day])
      expect(call_method).to be(false)
    end

    production_only vcr: {cassette_name: 'calendar_mds_service'} do
      let(:calendar_service) { subject.init_cal_connection(environment) }

      it 'initializes the calendar service connection' do
        expect(subject).to receive(:init_cal_connection).with(environment)
        call_method
      end
      it 'calls the calendar service to get the limited pricing holiday information' do
        expect(calendar_service).to receive(:call).with(:get_holiday, include(message_tag: 'holidayRequest', soap_header: MAPI::Services::Rates::SOAP_HEADER )).and_call_original
        call_method
      end
      it 'only checks for holidays on today' do
        today_str = date.strftime('%F')
        expect(calendar_service).to receive(:call).with(:get_holiday, include(message: {'v1:endDate' => today_str, 'v1:startDate' => today_str})).and_call_original
        call_method
      end
      it 'raises an error if the calendar service could not be reached' do
        allow(calendar_service).to receive(:call).and_raise(Savon::Error)
        expect{call_method}.to raise_error(RuntimeError)
      end
      it 'the request_cache block returns the dates from the service' do
        expected = ['2015-04-03', '2016-03-25', '2017-04-14', '2018-03-30'].collect(&:to_date)
        result = []
        allow(subject).to receive(:request_cache) do |*args, &block|
          result = block.call
        end
        call_method
        expect(result).to match(expected)
      end
    end

    excluding_production do
      it 'fetches data from the fakes' do
        expect(subject).to receive(:fake).with('limited_pricing_days').and_return([])
        call_method
      end
      it 'the request_cache block returns the dates from the fakes' do
        expected = ['2016-04-04', '2016-04-05', '2015-04-03', '2016-03-25', '2017-04-14', '2018-03-30'].collect(&:to_date)
        result = []
        allow(subject).to receive(:request_cache) do |*args, &block|
          result = block.call
        end
        call_method
        expect(result).to match(expected)
      end
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
      expect(price_indications_current_vrc[:advance_rate]).to be_kind_of(Float)
      expect(price_indications_current_vrc[:effective_date]).to be_kind_of(String)
      expect(price_indications_current_vrc[:effective_date]).to match(/\d{4}-\d{2}-\d{2}/)
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
        expect(price_indications_current_vrc[:advance_rate]).to be_kind_of(Float)
        expect(price_indications_current_vrc[:effective_date]).to be_kind_of(String)
        expect(price_indications_current_vrc[:effective_date]).to match(/\d{4}-\d{2}-\d{2}/)
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
        expect(frc['advance_rate']).to be_kind_of(Float)
        expect(frc['effective_date']).to match(/\d{4}-\d{2}-\d{2}/)
      end
    end
    it 'invalid collateral should result in 404 error message' do
      get '/rates/price_indications/current/frc/foo'
      expect(last_response.status).to eq(404)
    end
    it 'checks if the effective_date is a limited pricing day' do
      today = Time.zone.today
      expect(subject).to receive(:is_limited_pricing_day?).with(anything, today).exactly(10)
      price_indications_current_frc
    end
    it 'does not return rates for products whose effective_date is a limited pricing day' do
      allow(subject).to receive(:is_limited_pricing_day?).and_return(true, false, true, false, true, true, true, true, false, false)
      expect(price_indications_current_frc.length).to be(4)
    end
    describe 'in the production environment' do
      before do
        expect(MAPI::ServiceApp).to receive(:environment).at_least(1).and_return(:production)
      end
      it 'should return data relevant to each loan_term', vcr: {cassette_name: 'current_price_indications_frc'} do
        price_indications_current_frc.each do |frc|
          expect(frc['advance_maturity']).to be_kind_of(String)
          expect(frc['advance_rate']).to be_kind_of(Float)
          expect(frc['effective_date']).to match(/\d{4}-\d{2}-\d{2}/)
        end
      end
      it 'should return Internal Service Error, if current price indications service is unavaible', vcr: {cassette_name: 'current_price_indications_unavailable'} do
        get '/rates/price_indications/current/frc/sbc'
        expect(last_response.status).to eq(503)
      end
    end
    describe 'when using fake data' do
      before do
        allow(MAPI::Services::Rates).to receive(:init_pi_connection).and_return(false)
        allow(MAPI::Services::Rates).to receive(:is_limited_pricing_day?).and_return(false)
      end
      it 'uses `rates_current_price_indications_standard_frc` as the fake data when the collateral type is `:standard`' do
        expect(MAPI::Services::Rates).to receive(:fake).with('rates_current_price_indications_standard_frc').and_return([{}])
        get '/rates/price_indications/current/frc/standard'
      end
      it 'uses `rates_current_price_indications_sbc_frc` as the fake data when the collateral type is `:sbc`' do
        expect(MAPI::Services::Rates).to receive(:fake).with('rates_current_price_indications_sbc_frc').and_return([{}])
        get '/rates/price_indications/current/frc/sbc'
      end
    end
  end

  describe 'price_indications_current_arc' do
    let(:price_indications_current_arc) { get '/rates/price_indications/current/arc/standard'; JSON.parse(last_response.body) }
    let(:rates) {[
      {
        'advance_maturity' => instance_double(String, to_s: nil),
        '1_month_libor' => instance_double(Integer, to_i: nil),
        '3_month_libor' => instance_double(Integer, to_i: nil),
        '6_month_libor' => instance_double(Integer, to_i: nil),
        'prime' => instance_double(Integer, to_i: nil)
      }
    ]}
    let(:sentinel) { SecureRandom.hex }
    before do
      allow(MAPI::Services::Rates).to receive(:fake).and_return(rates)
      allow(subject).to receive(:is_limited_pricing_day?)
    end

    it 'returns a 404 if passed an invalid collateral type' do
      get '/rates/price_indications/current/arc/foo'
      expect(last_response.status).to eq(404)
    end
    it 'returns rates with an `advance_maturity`' do
      allow(rates.first['advance_maturity']).to receive(:to_s).and_return(sentinel)
      expect(price_indications_current_arc.length).to be > 0
      price_indications_current_arc.each do |rate|
        expect(rate['advance_maturity']).to eq(sentinel)
      end
    end
    %w(1_month_libor 3_month_libor 6_month_libor prime).each do |key|
      it "returns rates with an `#{key}`" do
        allow(rates.first[key]).to receive(:to_i).and_return(sentinel)
        expect(price_indications_current_arc.length).to be > 0
        price_indications_current_arc.each do |rate|
          expect(rate[key]).to eq(sentinel)
        end
      end
    end
    it 'sets the `effective_date` of all rates to today in the non-production environment' do
      today_string = Time.zone.today.iso8601
      expect(price_indications_current_arc.length).to be > 0
      price_indications_current_arc.each do |rate|
        expect(rate['effective_date']).to eq(today_string)
      end
    end
    it 'checks if the effective_date is a limited pricing day' do
      today = instance_double(Date)
      allow(today).to receive(:to_date).and_return(today)
      allow(Time.zone).to receive(:today).and_return(today)
      expect(subject).to receive(:is_limited_pricing_day?).with(anything, today)
      price_indications_current_arc
    end
    it 'does not return rates for products whose effective_date is a limited pricing day' do
      allow(subject).to receive(:is_limited_pricing_day?).and_return(true)
      expect(price_indications_current_arc.length).to eq(0)
    end
    describe 'in the production environment' do
      before do
        allow(MAPI::ServiceApp).to receive(:environment).and_return(:production)
      end
      it 'should return data relevant to each loan_term', vcr: {cassette_name: 'current_price_indications_arc'} do
        price_indications_current_arc.each do |arc|
          expect(arc['advance_maturity']).to be_kind_of(String)
          expect(arc['1_month_libor']).to be_kind_of(Numeric)
          expect(arc['3_month_libor']).to be_kind_of(Numeric)
          expect(arc['6_month_libor']).to be_kind_of(Numeric)
          expect(arc['prime']).to be_kind_of(Numeric)
          expect(arc['effective_date']).to match(/\d{4}-\d{2}-\d{2}/)
        end
      end
      it 'should return Internal Service Error, if current price indications service is unavaible', vcr: {cassette_name: 'current_price_indications_unavailable'} do
        get '/rates/price_indications/current/arc/standard'
        expect(last_response.status).to eq(503)
      end
    end
  end

  describe '`get_market_data_from_soap` method' do
    let(:logger){ instance_double(Logger, error: nil) }
    today = Time.zone.today
    let(:funding_date) { today + rand(1..2).days }
    let(:maturity_date) { today + rand(3..1095).days }
    let(:live_or_start_of_day){ double('live_or_start_of_day') }
    let(:mds_connection) { instance_double(Savon::Client, call: nil) }
    let(:call_method) { subject.get_market_data_from_soap(logger, live_or_start_of_day, funding_date, maturity_date) }

    before do
      allow_any_instance_of(MAPI::ServiceApp).to receive(:logger).and_return(logger)
      MAPI::Services::Rates.class_variable_set(:@@mds_connection, mds_connection)
    end

    MAPI::Services::Rates::LOAN_TYPES.each do |loan|
      it "calls market_data_message_for_loan_type with #{loan}" do
        allow(subject).to receive(:market_data_message_for_loan_type)
        expect(subject).to receive(:market_data_message_for_loan_type).with(loan, live_or_start_of_day, funding_date)
        call_method
      end
      it "calls market_data_message_for_loan_type with #{loan} with maturity_date" do
        allow(subject).to receive(:market_data_message_for_loan_type)
        expect(subject).to receive(:market_data_message_for_loan_type).with(loan, live_or_start_of_day, funding_date, maturity_date)
        call_method
      end
    end

    describe 'requesting rates from MDS' do
      it 'calls the `get_market_data` endpoint' do
        expect(mds_connection).to receive(:call).with(:get_market_data, anything)
        call_method
      end
      it 'includes `marketDataRequest` as the `message_tag`' do
        expect(mds_connection).to receive(:call).with(:get_market_data, include(message_tag: 'marketDataRequest'))
        call_method
      end
      it 'includes the caller ID in the message' do
        account = instance_double(String, 'MAPI_COF_ACCOUNT')
        stub_const('ENV', {'MAPI_COF_ACCOUNT' => account})
        expect(mds_connection).to receive(:call).with(:get_market_data, include(message: include('v11:caller' => [include('v11:id' => account)])))
        call_method
      end
      it 'includes the built regular term requests in the message' do
        allow(subject).to receive(:market_data_message_for_loan_type)
        type_requests = MAPI::Services::Rates::LOAN_TYPES.collect do |type|
          type_message = double('A Type Message')
          allow(subject).to receive(:market_data_message_for_loan_type).with(type, live_or_start_of_day, funding_date).and_return(type_message)
          type_message
        end
        expect(mds_connection).to receive(:call).with(:get_market_data, include(message: include('v1:requests' => [include('v1:fhlbsfMarketDataRequest' => include(*type_requests))])))
        call_method
      end
      it 'includes the built custom term requests in the message' do
        allow(subject).to receive(:market_data_message_for_loan_type)
        type_requests = MAPI::Services::Rates::LOAN_TYPES.collect do |type|
          type_message = double('A Type Message')
          allow(subject).to receive(:market_data_message_for_loan_type).with(type, live_or_start_of_day, funding_date, maturity_date).and_return(type_message)
          type_message
        end
        expect(mds_connection).to receive(:call).with(:get_market_data, include(message: include('v1:requests' => [include('v1:fhlbsfMarketDataRequest' => include(*type_requests))])))
        call_method
      end
      it 'includes SOAP authentication headers' do
        expect(mds_connection).to receive(:call).with(:get_market_data, include(soap_header: subject::SOAP_HEADER))
        call_method
      end
      describe 'when a Savon::Error is raised' do
        let(:err) { Savon::Error.new }
        before do
          allow(mds_connection).to receive(:call).and_raise(err)
        end
        it 'returns nil on error' do
          expect(call_method).to be_nil
        end
        it 'logs the error' do
          expect(logger).to receive(:error).with(err)
          call_method
        end
      end
    end

    it 'returns the results of the MDS call' do
      market_data = double('Some Market Data')
      allow(mds_connection).to receive(:call).and_return(market_data)
      expect(call_method).to be(market_data)
    end

    it 'returns nil if there is no MDS connection' do
      MAPI::Services::Rates.class_variable_set(:@@mds_connection, nil)
      expect(call_method).to be_nil
    end
  end

  describe '`market_data_message_for_loan_type` method' do
    let(:loan_type){ [:whole, :agency, :aaa, :aa].sample }
    let(:loan_type_result){ MAPI::Shared::Constants::LOAN_MAPPING[loan_type.to_s] }
    let(:live_or_start_of_day){ double('live_or_start_of_day') }
    today = Time.zone.today
    let(:funding_date) { today + rand(1..2).days }
    let(:call_method) { subject.market_data_message_for_loan_type(loan_type, live_or_start_of_day, funding_date) }
    let(:call_method_no_funding_date) { subject.market_data_message_for_loan_type(loan_type, live_or_start_of_day, nil) }
    let(:caller) { double('caller') }
    let(:maturity_date) { today + rand(3..1095).days }
    let(:call_method_maturity_date) { subject.market_data_message_for_loan_type(loan_type, live_or_start_of_day, funding_date, maturity_date) }
    let(:frequency) {(maturity_date.to_date - (funding_date || Time.zone.today).to_date).to_i.to_s}

    it 'returns a hash with a `v11:id` inside `v1:caller' do
      allow(ENV).to receive(:[]).with('MAPI_FHLBSF_ACCOUNT').and_return(caller)
      expect(call_method['v1:caller']).to include('v11:id'=>caller)
    end
    it 'returns hash with `v12:spotDate` inside `v1:marketData`, if the funding date is not nil' do
      expect(call_method['v1:marketData'].first).to include('v12:spotDate'=>funding_date.iso8601)
    end
    it 'returns hash without `v12:spotDate` inside `v1:marketData`, if the funding date is nil' do
      expect(call_method_no_funding_date['v1:marketData'].first).to_not include('v12:spotDate')
    end
    it 'returns a hash with a `v12:name` inside `v1:marketData`' do
      expect(call_method['v1:marketData'].first).to include('v12:name'=>loan_type_result)
    end
    it 'returns a hash with a `v12:data` inside `v1:marketData`' do
      expect(call_method['v1:marketData'].first).to include('v12:data'=>'')
    end
    it 'returns a hash with a `v12:id` inside `v12:pricingGroup`' do
      expect(call_method['v1:marketData'].first['v12:pricingGroup'].first).to include('v12:id'=>live_or_start_of_day)
    end
    describe 'custom date' do
      it 'returns a hash with a `v12:FhlbsfDataPoint` inside `v1:data`' do
        expect(call_method_maturity_date['v1:marketData'].first['v12:data'].first).to include('v12:FhlbsfDataPoint' => ['v12:tenor' => ['v12:interval' => [{'v13:frequency'=>frequency, 'v13:frequencyUnit'=>'D'}]]])
      end
    end
  end

  describe '`init_mds_connection` class method' do
    before do
      MAPI::Services::Rates.class_variable_set(:@@mds_connection, nil)
    end
    describe 'in the production environment' do
      let(:call_method) { MAPI::Services::Rates.init_mds_connection(:production) }
      let(:client) { instance_double(Savon::Client) }
      it 'calls `soap_client`' do
        expect(MAPI::Services::Rates).to receive(:soap_client)
        call_method
      end
      it 'returns the SOAP client' do
        allow(MAPI::Services::Rates).to receive(:soap_client).and_return(client)
        expect(call_method).to be(client)
      end
      it 'caches the generated SOAP client' do
        client = call_method
        expect(call_method).to be(client)
      end
      describe 'when called with `cache` = `false`' do
        let(:call_method) { MAPI::Services::Rates.init_mds_connection(:production, false) }
        it 'returns a fresh SOAP client' do
          allow(MAPI::Services::Rates).to receive(:soap_client).and_return(client)
          expect(call_method).to be(client)
        end
        it 'does not cache the client' do
          client = MAPI::Services::Rates.init_mds_connection(:production, false)
          expect(MAPI::Services::Rates.init_mds_connection(:production, false)).to_not be(client)
        end
      end
    end
    describe 'when the environment is not production' do
      let(:call_method) { MAPI::Services::Rates.init_mds_connection(:foo) }
      it 'returns nil' do
        expect(call_method).to be_nil
      end
      it 'does not call `soap_client`' do
        expect(MAPI::Services::Rates).to_not receive(:soap_client)
        call_method
      end
    end
  end

  describe '`init_cal_connection` class method' do
    before do
      MAPI::Services::Rates.class_variable_set(:@@cal_connection, nil)
    end
    describe 'in the production environment' do
      let(:call_method) { MAPI::Services::Rates.init_cal_connection(:production) }
      let(:client) { instance_double(Savon::Client) }
      it 'calls `soap_client`' do
        expect(MAPI::Services::Rates).to receive(:soap_client)
        call_method
      end
      it 'returns the SOAP client' do
        allow(MAPI::Services::Rates).to receive(:soap_client).and_return(client)
        expect(call_method).to be(client)
      end
      it 'caches the generated SOAP client' do
        client = call_method
        expect(call_method).to be(client)
      end
      describe 'when called with `cache` = `false`' do
        let(:call_method) { MAPI::Services::Rates.init_cal_connection(:production, false) }
        it 'returns a fresh SOAP client' do
          allow(MAPI::Services::Rates).to receive(:soap_client).and_return(client)
          expect(call_method).to be(client)
        end
        it 'does not cache the client' do
          client = MAPI::Services::Rates.init_cal_connection(:production, false)
          expect(MAPI::Services::Rates.init_cal_connection(:production, false)).to_not be(client)
        end
      end
    end
    describe 'when the environment is not production' do
      let(:call_method) { MAPI::Services::Rates.init_cal_connection(:foo) }
      it 'returns nil' do
        expect(call_method).to be_nil
      end
      it 'does not call `soap_client`' do
        expect(MAPI::Services::Rates).to_not receive(:soap_client)
        call_method
      end
    end
  end

  describe '`init_pi_connection` class method' do
    before do
      MAPI::Services::Rates.class_variable_set(:@@pi_connection, nil)
    end
    describe 'in the production environment' do
      let(:call_method) { MAPI::Services::Rates.init_pi_connection(:production) }
      let(:client) { instance_double(Savon::Client) }
      it 'calls `soap_client`' do
        expect(MAPI::Services::Rates).to receive(:soap_client)
        call_method
      end
      it 'returns the SOAP client' do
        allow(MAPI::Services::Rates).to receive(:soap_client).and_return(client)
        expect(call_method).to be(client)
      end
      it 'caches the generated SOAP client' do
        client = call_method
        expect(call_method).to be(client)
      end
      describe 'when called with `cache` = `false`' do
        let(:call_method) { MAPI::Services::Rates.init_pi_connection(:production, false) }
        it 'returns a fresh SOAP client' do
          allow(MAPI::Services::Rates).to receive(:soap_client).and_return(client)
          expect(call_method).to be(client)
        end
        it 'does not cache the client' do
          client = MAPI::Services::Rates.init_pi_connection(:production, false)
          expect(MAPI::Services::Rates.init_pi_connection(:production, false)).to_not be(client)
        end
      end
    end
    describe 'when the environment is not production' do
      let(:call_method) { MAPI::Services::Rates.init_pi_connection(:foo) }
      it 'returns nil' do
        expect(call_method).to be_nil
      end
      it 'does not call `soap_client`' do
        expect(MAPI::Services::Rates).to_not receive(:soap_client)
        call_method
      end
    end
  end

  describe '`soap_client` class method' do
    let(:endpoint_env_name) { double('An ENV name for an endpoint') }
    let(:endpoint) { SecureRandom.hex }
    let(:namespaces) { double('A Hash of namespaces') }
    let(:call_method) { MAPI::Services::Rates.soap_client(endpoint_env_name, namespaces) }
    let(:connection) { Savon::Client.new(endpoint: endpoint, namespace: SecureRandom.hex) }
    before do
      allow(ENV).to receive(:[]).with(endpoint_env_name).and_return(endpoint)
      allow(Savon).to receive(:client).and_return(connection)
    end
    it 'builds a Savon client with an endpoint from the ENV' do
      expect(Savon).to receive(:client).with(include(wsdl: endpoint)).and_return(connection)
      call_method
    end
    it 'builds a Savon client with the passed namespaces' do
      expect(Savon).to receive(:client).with(include(namespaces: namespaces)).and_return(connection)
      call_method
    end
    it 'builds a Savon client with the COMMON options' do
      expect(Savon).to receive(:client).with(include(MAPI::Services::Rates::COMMON)).and_return(connection)
      call_method
    end
    it 'adds `SOAP_OPEN_TIMEOUT to the clieny' do
      call_method
      expect(connection.globals[:open_timeout]).to be(MAPI::Services::Rates::SOAP_OPEN_TIMEOUT)
    end
    it 'adds `SOAP_READ_TIMEOUT to the client' do
      call_method
      expect(connection.globals[:read_timeout]).to be(MAPI::Services::Rates::SOAP_READ_TIMEOUT)
    end
    it 'returns the Savon client' do
      expect(call_method).to be(connection)
    end
  end

end
