require 'spec_helper'

describe RatesService do
  let(:member_id) {double(MEMBER_ID)}
  let(:advance_type) {double('advance_type')}
  let(:advance_term) {double('advance_term')}
  let(:advance_rate) {double('advance_rate')}
  let(:start_date) {Date.new(2014,12,01)}
  let(:end_date) {Date.new(2014,12,31)}

  subject { RatesService.new(double('request', uuid: '12345')) }
  it { expect(subject).to respond_to(:overnight_vrc) }
  it { expect(subject).to respond_to(:current_overnight_vrc) }
  it { expect(subject).to respond_to(:quick_advance_rates) }
  it { expect(subject).to respond_to(:quick_advance_preview) }
  it { expect(subject).to respond_to(:quick_advance_confirmation) }
  it { expect(subject).to respond_to(:historical_price_indications) }

  describe "`overnight_vrc` method", :vcr do
    let(:rates) {subject.overnight_vrc}
    it "should return an array of rates" do
      expect(rates.length).to be >= 1
      rates.each do |rate|
        expect(rate.first).to be_kind_of(Date)
        expect(rate.last).to be_kind_of(Float)
      end
    end
    it "should return 30 rates by default" do
      expect(rates.length).to eq(30)
    end
    it "should allow the number of rates returned to be overridden" do
      expect(subject.overnight_vrc(5).length).to eq(5)
    end
    it "should return nil if there was an API error" do
      expect_any_instance_of(RestClient::Resource).to receive(:get).and_raise(RestClient::InternalServerError)
      expect(rates).to eq(nil)
    end
    it "should return nil if there was a connection error" do
      expect_any_instance_of(RestClient::Resource).to receive(:get).and_raise(Errno::ECONNREFUSED)
      expect(rates).to eq(nil)
    end
  end

  describe "`quick_advance_rates` method", :vcr do
    let(:quick_advance_rates) {subject.quick_advance_rates(member_id)}
    it "should return a hash of hashes containing pledged collateral values" do
      expect(quick_advance_rates.length).to be >= 1
      expect(quick_advance_rates[:overnight][:whole_loan]).to be_kind_of(Float)
      expect(quick_advance_rates[:open][:agency]).to be_kind_of(Float)
      expect(quick_advance_rates["1week"][:aaa]).to be_kind_of(Float)
      expect(quick_advance_rates["2week"][:aa]).to be_kind_of(Float)
    end
  end

  describe "`quick_advance_preview` method" do
    let(:quick_advance_preview) {subject.quick_advance_preview(member_id, advance_type, advance_term, advance_rate)}
    it "should return a hash of hashes containing info relevant to the requested preview" do
      expect(quick_advance_preview.length).to be >= 1
      expect(quick_advance_preview[:status]).to be_kind_of(String)
      expect(quick_advance_preview[:advance_amount]).to be_kind_of(Integer)
      expect(quick_advance_preview["advance_term"]).to be_kind_of(String)
      expect(quick_advance_preview["advance_type"]).to be_kind_of(String)
      expect(quick_advance_preview["interest_day_count"]).to be_kind_of(String)
      expect(quick_advance_preview["payment_on"]).to be_kind_of(String)
      expect(quick_advance_preview["funding_date"]).to be_kind_of(String)
      expect(quick_advance_preview["maturity_date"]).to be_kind_of(String)
    end
  end

  describe "`quick_advance_confirmation` method" do
    let(:quick_advance_confirmation) {subject.quick_advance_confirmation(member_id, advance_type, advance_term, advance_rate)}
    it "should return a hash of hashes containing info relevant to the requested preview" do
      expect(quick_advance_confirmation.length).to be >= 1
      expect(quick_advance_confirmation[:status]).to be_kind_of(String)
      expect(quick_advance_confirmation[:confirmation_number]).to be_kind_of(Integer)
      expect(quick_advance_confirmation[:advance_amount]).to be_kind_of(Integer)
      expect(quick_advance_confirmation["advance_term"]).to be_kind_of(String)
      expect(quick_advance_confirmation["advance_type"]).to be_kind_of(String)
      expect(quick_advance_confirmation["interest_day_count"]).to be_kind_of(String)
      expect(quick_advance_confirmation["payment_on"]).to be_kind_of(String)
      expect(quick_advance_confirmation["funding_date"]).to be_kind_of(String)
      expect(quick_advance_confirmation["maturity_date"]).to be_kind_of(String)
    end
  end

  describe "`current_overnight_vrc` method", :vcr do
    let(:rate) {subject.current_overnight_vrc}
    it "should return a hash with a rate and a timestamp" do
      expect(rate[:rate]).to be_kind_of(Float)
      expect(rate[:rate]).to be >= 0
      expect(rate[:updated_at]).to be_kind_of(DateTime)
      expect(rate[:updated_at]).to be <= DateTime.now
    end
    it "should return nil if there was an error" do
      expect_any_instance_of(RestClient::Resource).to receive(:get).and_raise(RestClient::InternalServerError)
      expect(rate).to eq(nil)
    end
    it "should return nil if there was a connection error" do
      expect_any_instance_of(RestClient::Resource).to receive(:get).and_raise(Errno::ECONNREFUSED)
      expect(rate).to eq(nil)
    end
  end

  describe "`historical_price_indications` method" do
    let(:historical_prices) {subject.historical_price_indications(start_date, end_date, RatesService::COLLATERAL_TYPES.first, RatesService::CREDIT_TYPES.first)}
    it 'should return nil if the argument passed for collateral_type is not valid' do
      expect(Rails.logger).to receive(:warn)
      expect(subject.historical_price_indications(start_date, end_date, 'invalid collateral type', RatesService::CREDIT_TYPES.first)).to be_nil
    end
    it 'should return nil if the argument passed for credit_type is not valid' do
      expect(Rails.logger).to receive(:warn)
      expect(subject.historical_price_indications(start_date, end_date, RatesService::COLLATERAL_TYPES.first, 'invalid credit type')).to be_nil
    end
    it 'should return the start date that it was supplied' do
      expect(historical_prices[:start_date]).to eq(start_date)
    end
    it 'should return the end date that it was supplied' do
      expect(historical_prices[:end_date]).to eq(end_date)
    end
    it 'should return the collateral type that it was supplied' do
      expect(historical_prices[:collateral_type]).to eq(RatesService::COLLATERAL_TYPES.first)
    end
    it 'should return the credit type that it was supplied' do
      expect(historical_prices[:credit_type]).to eq(RatesService::CREDIT_TYPES.first)
    end
    it 'should return an array of rate data objects with an associated date and rate array for each one' do
      expect(historical_prices[:rates_by_date]).to be_kind_of(Array)
      historical_prices[:rates_by_date].each do |row|
        expect(row[:date]).to be_kind_of(Date)
        expect(row[:rates_by_term]).to be_kind_of(Array)
      end
    end

    # TODO remove this code once you are hitting MAPI and not generating fake data in your method
    # START of code to remove once MAPI endpoint is built
    describe 'credit_type mappings for creation of fake data' do
      it 'should use HISTORICAL_FRC_TERM_MAPPINGS keys to set the terms if `frc` is passed as the credit_type arg' do
        expect(RatesService::HISTORICAL_FRC_TERM_MAPPINGS).to receive(:keys).at_least(1).and_call_original
        subject.historical_price_indications(start_date, end_date, 'standard', 'frc')
      end
      [:'1m_libor', :'3m_libor', :'6m_libor', :daily_prime].each do |credit_type|
        it "should use HISTORICAL_ARC_TERM_MAPPINGS keys to set the terms if `#{credit_type}` is passed as the credit_type arg" do
          expect(RatesService::HISTORICAL_ARC_TERM_MAPPINGS).to receive(:keys).at_least(1).and_call_original
          subject.historical_price_indications(start_date, end_date, 'standard', credit_type)
        end
      end
    end
    # END of code to remove once MAPI endpoint is built

    describe 'rate data objects' do
      it 'should have an associated term' do
        historical_prices[:rates_by_date].each do |row|
          row[:rates_by_term].each do |rate_object|
            expect(RatesService::HISTORICAL_FRC_TERM_MAPPINGS.keys).to include(rate_object[:term])
          end
        end
      end
      it 'should return a rate as a float' do # TODO maybe change this to account for null values coming back from MAPI once the endpoint is built
        historical_prices[:rates_by_date].each do |row|
          row[:rates_by_term].each do |rate_object|
            expect(rate_object[:rate]).to be_kind_of(Float)
          end
        end
      end
      it 'should return a day_count_basis as a string' do
        historical_prices[:rates_by_date].each do |row|
          row[:rates_by_term].each do |rate_object|
            expect(rate_object[:day_count_basis]).to be_kind_of(String)
          end
        end
      end
      it 'should return a pay_freq as a string' do
        historical_prices[:rates_by_date].each do |row|
          row[:rates_by_term].each do |rate_object|
            expect(rate_object[:pay_freq]).to be_kind_of(String)
          end
        end
      end
    end
    # TODO remove code below once you have rigged up the reports for all supported collateral_types and credit_types
    # START of code that should be removed once this method supports all valid collateral_types and credit_types
    it 'returns nil if `sbc` is passed as the collateral_type arg' do
      expect(Rails.logger).to receive(:warn)
      expect(subject.historical_price_indications(start_date, end_date, 'sbc', RatesService::CREDIT_TYPES.first)).to be_nil
    end
    it 'returns nil if `vrc` is passed as the credit_type arg' do
      expect(Rails.logger).to receive(:warn)
      expect(subject.historical_price_indications(start_date, end_date, RatesService::COLLATERAL_TYPES.first, 'vrc')).to be_nil
    end
    it 'returns nil if `embedded_cap` is passed as the credit_type arg' do
      expect(Rails.logger).to receive(:warn)
      expect(subject.historical_price_indications(start_date, end_date, RatesService::COLLATERAL_TYPES.first, 'embedded_cap')).to be_nil
    end
    # END of code that should be removed once this method supports all valid collateral_types and credit_types
  end
end