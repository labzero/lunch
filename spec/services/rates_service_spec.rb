require 'rails_helper'

describe RatesService do
  let(:member_id) {double('MemberID')}
  let(:advance_type) {double('advance_type')}
  let(:advance_term) {double('advance_term')}
  let(:advance_rate) {double('advance_rate')}
  let(:amount) { double('An Amount') }
  let(:start_date) {Date.new(2014,12,01)}
  let(:end_date) {Date.new(2014,12,31)}

  subject { RatesService.new(double('request', uuid: '12345')) }
  it { expect(subject).to respond_to(:overnight_vrc) }
  it { expect(subject).to respond_to(:current_overnight_vrc) }
  it { expect(subject).to respond_to(:quick_advance_rates) }
  it { expect(subject).to respond_to(:historical_price_indications) }
  it { expect(subject).to respond_to(:current_price_indications) }

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
    let(:advance_request) { double('advance request instance') }
    let(:rates) { double('rates hash') }
    it "should return a hash of hashes containing pledged collateral values" do
      expect(quick_advance_rates.length).to be >= 1
      expect(quick_advance_rates[:overnight][:whole_loan]).to be_kind_of(Float)
      expect(quick_advance_rates[:open][:agency]).to be_kind_of(Float)
      expect(quick_advance_rates["1week"][:aaa]).to be_kind_of(Float)
      expect(quick_advance_rates["2week"][:aa]).to be_kind_of(Float)
    end
  end

  describe 'the `rate` method', :vcr do
    let(:mapi_response) {
      {
        rate: double('rate', to_f: nil),
        updated_at: double('updated at')
      }
    }
    let(:rate) { subject.rate('agency','1month') }
    before do
      allow(JSON).to receive(:parse).and_return(mapi_response)
      allow(DateTime).to receive(:parse)
    end
    it_should_behave_like 'a MAPI backed service object method', :rate, [:agency, :'1month']
    it 'returns a float for it\'s `rate` attribute' do
      allow(mapi_response[:rate]).to receive(:to_f).and_return(mapi_response[:rate])
      expect(rate[:rate]).to eq(mapi_response[:rate])
    end
    it 'returns nil for for it\'s `rate` attribute if there is no rate in the MAPI response' do
      allow(JSON).to receive(:parse).and_return({})
      expect(rate[:rate]).to be_nil
    end
    it 'returns a datetime for it\'s `updated_at` attribute' do
      allow(DateTime).to receive(:parse).with(mapi_response[:updated_at]).and_return(mapi_response[:updated_at])
      expect(rate[:updated_at]).to eq(mapi_response[:updated_at])
    end
    it 'returns nil for for it\'s `updated_at` attribute if there is no updated_at in the MAPI response' do
      allow(JSON).to receive(:parse).and_return({})
      expect(rate[:updated_at]).to be_nil
    end
    it 'returns a HashWithIndifferentAccess' do
      expect(rate['updated_at']).to be(rate[:updated_at])
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

  describe '`historical_price_indications` method', :vcr do
    let(:historical_prices) {subject.historical_price_indications(start_date, end_date, RatesService::COLLATERAL_TYPES.first, RatesService::CREDIT_TYPES.first)}
    it 'should return nil if the argument passed for collateral_type is not valid' do
      expect(Rails.logger).to receive(:warn)
      expect(subject.historical_price_indications(start_date, end_date, 'invalid collateral type', RatesService::CREDIT_TYPES.first)).to be_nil
    end
    it 'should return nil if the argument passed for credit_type is not valid' do
      expect(Rails.logger).to receive(:warn)
      expect(subject.historical_price_indications(start_date, end_date, RatesService::COLLATERAL_TYPES.first, 'invalid credit type')).to be_nil
    end
    it 'should return nil if `embedded_cap` is passed for credit_type' do
      expect(Rails.logger).to receive(:warn)
      expect(subject.historical_price_indications(start_date, end_date, RatesService::COLLATERAL_TYPES.first, 'embedded_cap')).to be_nil
    end
    it 'should return nil if there was an API error' do
      allow_any_instance_of(RestClient::Resource).to receive(:get).and_raise(RestClient::InternalServerError)
      expect(subject.historical_price_indications(start_date, end_date, RatesService::COLLATERAL_TYPES.first, RatesService::CREDIT_TYPES.first)).to eq(nil)
    end
    it 'should return nil if there was a connection error' do
      allow_any_instance_of(RestClient::Resource).to receive(:get).and_raise(Errno::ECONNREFUSED)
      expect(subject.historical_price_indications(start_date, end_date, RatesService::COLLATERAL_TYPES.first, RatesService::CREDIT_TYPES.first)).to eq(nil)
    end
    it 'should return a data object from the MAPI endpoint' do
      expect(subject.historical_price_indications(start_date, end_date, RatesService::COLLATERAL_TYPES.first, RatesService::CREDIT_TYPES.first)).to be_kind_of(Hash)
    end
  end

  describe '`current_price_indications` method', :vcr do
    let(:current_prices) {subject.current_price_indications(RatesService::COLLATERAL_TYPES.first, RatesService::CREDIT_TYPES.first)}
    it 'should return nil if the argument passed for collateral_type is not valid' do
      expect(Rails.logger).to receive(:warn)
      expect(subject.current_price_indications('invalid collateral type', RatesService::CREDIT_TYPES.first)).to be_nil
    end
    it 'should return nil if the argument passed for credit_type is not valid' do
      expect(Rails.logger).to receive(:warn)
      expect(subject.current_price_indications(RatesService::COLLATERAL_TYPES.first, 'invalid credit type')).to be_nil
    end
    it 'should return a data object from the MAPI endpoint' do
      expect(subject.current_price_indications(RatesService::COLLATERAL_TYPES.first, RatesService::CREDIT_TYPES.first)).to be_kind_of(Array)
    end
  end

end