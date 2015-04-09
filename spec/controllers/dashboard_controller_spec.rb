require 'rails_helper'

RSpec.describe DashboardController, :type => :controller do
  login_user
  before do
    session['member_id'] = 750
  end

  describe "GET index", :vcr do
    it_behaves_like 'a user required action', :get, :index
    it "should render the index view" do
      get :index
      expect(response.body).to render_template("index")
    end
    it 'should assign @account_overview' do
      get :index
      expect(assigns[:account_overview]).to be_kind_of(Hash)
      expect(assigns[:account_overview].length).to eq(5)
    end
    it "should assign @market_overview" do
      get :index
      expect(assigns[:market_overview]).to be_present
      expect(assigns[:market_overview][0]).to be_present
      expect(assigns[:market_overview][0][:name]).to be_present
      expect(assigns[:market_overview][0][:data]).to be_present
    end
    it "should assign @pledged_collateral" do
      get :index
      expect(assigns[:pledged_collateral]).to be_present
      expect(assigns[:pledged_collateral][:mortgages]).to be_present
      expect(assigns[:pledged_collateral][:mortgages][:absolute]).to be_present
      expect(assigns[:pledged_collateral][:mortgages][:percentage]).to be_present
      expect(assigns[:pledged_collateral][:agency]).to be_present
      expect(assigns[:pledged_collateral][:agency][:absolute]).to be_present
      expect(assigns[:pledged_collateral][:agency][:percentage]).to be_present
      expect(assigns[:pledged_collateral][:aaa]).to be_present
      expect(assigns[:pledged_collateral][:aaa][:absolute]).to be_present
      expect(assigns[:pledged_collateral][:aaa][:percentage]).to be_present
      expect(assigns[:pledged_collateral][:aa]).to be_present
      expect(assigns[:pledged_collateral][:aa][:absolute]).to be_present
      expect(assigns[:pledged_collateral][:aa][:percentage]).to be_present
    end
    it "should assign @total_securities" do
      get :index
      expect(assigns[:total_securities]).to be_present
      expect(assigns[:total_securities][:pledged_securities]).to be_present
      expect(assigns[:total_securities][:pledged_securities][:absolute]).to be_present
      expect(assigns[:total_securities][:pledged_securities][:percentage]).to be_present
      expect(assigns[:total_securities][:safekept_securities]).to be_present
      expect(assigns[:total_securities][:safekept_securities][:absolute]).to be_present
      expect(assigns[:total_securities][:safekept_securities][:percentage]).to be_present
    end
    it "should assign @effective_borrowing_capacity" do
      get :index
      expect(assigns[:effective_borrowing_capacity]).to be_present
      expect(assigns[:effective_borrowing_capacity][:used_capacity]).to be_present
      expect(assigns[:effective_borrowing_capacity][:used_capacity][:absolute]).to be_present
      expect(assigns[:effective_borrowing_capacity][:used_capacity][:percentage]).to be_present
      expect(assigns[:effective_borrowing_capacity][:unused_capacity]).to be_present
      expect(assigns[:effective_borrowing_capacity][:unused_capacity][:absolute]).to be_present
      expect(assigns[:effective_borrowing_capacity][:unused_capacity][:percentage]).to be_present
      expect(assigns[:effective_borrowing_capacity][:threshold_capacity]).to be_present
    end
    it 'should assign @current_overnight_vrc' do
      get :index
      expect(assigns[:current_overnight_vrc]).to be_kind_of(Float)
    end
    it 'should assign @quick_advances_active' do
      get :index
      expect(assigns[:quick_advances_active]).to be_present
    end
    describe "RateService failures" do
      let(:RatesService) {class_double(RatesService)}
      let(:rate_service_instance) {RatesService.new(double('request', uuid: '12345'))}
      before do
        expect(RatesService).to receive(:new).and_return(rate_service_instance)
      end
      it 'should assign @current_overnight_vrc as nil if the rate could not be retrieved' do
        expect(rate_service_instance).to receive(:current_overnight_vrc).and_return(nil)
        get :index
        expect(assigns[:current_overnight_vrc]).to eq(nil)
      end
      it 'should assign @market_overview rate data as nil if the rates could not be retrieved' do
        expect(rate_service_instance).to receive(:overnight_vrc).and_return(nil)
        get :index
        expect(assigns[:market_overview][0][:data]).to eq(nil)
      end
    end
    describe "MemberBalanceService failures" do
      let(:MemberBalanceService) {class_double(MemberBalanceService)}
      let(:member_balance_instance) {MemberBalanceService.new(750, double('request', uuid: '12345'))}
      before do
        expect(MemberBalanceService).to receive(:new).and_return(member_balance_instance)
      end
      it 'should assign @effective_borrowing_capacity as nil if the balance could not be retrieved' do
        expect(member_balance_instance).to receive(:effective_borrowing_capacity).and_return(nil)
        get :index
        expect(assigns[:effective_borrowing_capacity]).to eq(nil)
      end
      it 'should assign @total_securities as nil if the balance could not be retrieved' do
        expect(member_balance_instance).to receive(:total_securities).and_return(nil)
        get :index
        expect(assigns[:total_securities]).to eq(nil)
      end
      it 'should assign @pledged_collateral as nil if the balance could not be retrieved' do
        expect(member_balance_instance).to receive(:pledged_collateral).and_return(nil)
        get :index
        expect(assigns[:pledged_collateral]).to eq(nil)
      end
    end
  end

  describe "GET quick_advance_rates", :vcr do
    let(:rate_data) { {some: 'data'} }
    let(:RatesService) {class_double(RatesService)}
    let(:rate_service_instance) {double("rate service instance", quick_advance_rates: nil)}
    it_behaves_like 'a user required action', :get, :quick_advance_rates
    it 'should call the RatesService object with quick_advance_rates' do
      expect(RatesService).to receive(:new).and_return(rate_service_instance)
      expect(rate_service_instance).to receive(:quick_advance_rates).and_return(rate_data)
      get :quick_advance_rates
    end
    it 'should render its view' do
      get :quick_advance_rates
      expect(response.body).to render_template('dashboard/quick_advance_rates')
    end
    it 'should set @rate_data' do
      allow(RatesService).to receive(:new).and_return(rate_service_instance)
      allow(rate_service_instance).to receive(:quick_advance_rates).and_return(rate_data)
      get :quick_advance_rates
      expect(assigns[:rate_data]).to eq(rate_data)
    end
    it 'should set @advance_terms' do
      get :quick_advance_rates
      expect(assigns[:advance_terms]).to eq(subject.class::ADVANCE_TERMS)
    end
    it 'should set @advance_types' do
      get :quick_advance_rates
      expect(assigns[:advance_types]).to eq(subject.class::ADVANCE_TYPES)
  end

  describe "POST quick_advance_preview" do
    end
    let(:RatesService) {class_double(RatesService)}
    let(:rate_service_instance) {double("rate service instance", quick_advance_preview: nil)}
    let(:member_id) {double(MEMBER_ID)}
    let(:advance_term) {'some term'}
    let(:advance_type) {'some type'}
    let(:advance_rate) {'0.17'}
    let(:amount) { Random.rand(100000000) }
    let(:make_request) { post :quick_advance_preview, advance_term: advance_term, advance_type: advance_type, advance_rate: advance_rate, amount: amount
 }
    it_behaves_like 'a user required action', :post, :quick_advance_preview
    it 'should render its view' do
      make_request
      expect(response.body).to render_template('dashboard/quick_advance_preview')
    end
    it 'should call the RatesService object\'s `quick_advance_preview` method with the POSTed advance_type, advance_term and rate' do
      stub_const("MEMBER_ID", 750)
      expect(RatesService).to receive(:new).and_return(rate_service_instance)
      expect(rate_service_instance).to receive(:quick_advance_preview).with(MEMBER_ID, amount, advance_type, advance_term, advance_rate.to_f).and_return({})
      make_request
    end
    it 'should set @advance_amount' do
      make_request
      expect(assigns[:advance_amount]).to eq(amount)
    end
    it 'should set @advance_type' do
      make_request
      expect(assigns[:advance_type]).to be_kind_of(String)
    end
    it 'should set @interest_day_count' do
      make_request
      expect(assigns[:interest_day_count]).to be_kind_of(String)
    end
    it 'should set @payment_on' do
      make_request
      expect(assigns[:payment_on]).to be_kind_of(String)
    end
    it 'should set @advance_term' do
      make_request
      expect(assigns[:advance_term]).to be_kind_of(String)
    end
    it 'should set @funding_date' do
      make_request
      expect(assigns[:funding_date]).to be_kind_of(Date)
    end
    it 'should set @maturity_date' do
      make_request
      expect(assigns[:maturity_date]).to be_kind_of(Date)
    end
    it 'should set @advance_rate' do
      make_request
      expect(assigns[:advance_rate]).to be_kind_of(Numeric)
    end
  end

  describe "POST quick_advance_confirmation" do
    let(:RatesService) {class_double(RatesService)}
    let(:rate_service_instance) {double("rate service instance", quick_advance_confirmation: nil)}
    let(:member_id) {double(MEMBER_ID)}
    let(:advance_term) {'some term'}
    let(:advance_type) {'some type'}
    let(:advance_rate) {'0.17'}
    let(:amount) { Random.rand(100000000) }
    let(:make_request) { post :quick_advance_confirmation, advance_term: advance_term, advance_type: advance_type, advance_rate: advance_rate, amount: amount }
    it_behaves_like 'a user required action', :post, :quick_advance_confirmation
    it "should call the RatesService object's `quick_advance_confirmation` method with the POSTed advance_type, advance_term and rate and return a json response" do
      stub_const("MEMBER_ID", 750)
      expect(RatesService).to receive(:new).and_return(rate_service_instance)
      expect(rate_service_instance).to receive(:quick_advance_confirmation).with(MEMBER_ID, amount, advance_type, advance_term, advance_rate.to_f).and_return({})
      make_request
      expect(response.body).to render_template('dashboard/quick_advance_confirmation')
    end
    it 'should set @initiated_at' do
      make_request
      expect(assigns[:initiated_at]).to be_kind_of(DateTime)
    end
    it 'should set @advance_amount' do
      make_request
      expect(assigns[:advance_amount]).to eq(amount)
    end
    it 'should set @advance_type' do
      make_request
      expect(assigns[:advance_type]).to be_kind_of(String)
    end
    it 'should set @interest_day_count' do
      make_request
      expect(assigns[:interest_day_count]).to be_kind_of(String)
    end
    it 'should set @payment_on' do
      make_request
      expect(assigns[:payment_on]).to be_kind_of(String)
    end
    it 'should set @advance_term' do
      make_request
      expect(assigns[:advance_term]).to be_kind_of(String)
    end
    it 'should set @funding_date' do
      make_request
      expect(assigns[:funding_date]).to be_kind_of(Date)
    end
    it 'should set @maturity_date' do
      make_request
      expect(assigns[:maturity_date]).to be_kind_of(Date)
    end
    it 'should set @advance_rate' do
      make_request
      expect(assigns[:advance_rate]).to be_kind_of(Numeric)
    end
    it 'should set @advance_number' do
      make_request
      expect(assigns[:advance_number]).to be_kind_of(String)
    end
  end

  describe "GET current_overnight_vrc", :vcr do
    let(:rate_service_instance) {double('RatesService')}
    let(:etransact_service_instance) {double('EtransactAdvancesService')}
    let(:response_hash) { {} }
    let(:RatesService) {class_double(RatesService)}
    it_behaves_like 'a user required action', :get, :current_overnight_vrc
    it 'calls `current_overnight_vrc` on the rate service and `etransact_active?` on the etransact service' do
      allow(RatesService).to receive(:new).and_return(rate_service_instance)
      allow(EtransactAdvancesService).to receive(:new).and_return(etransact_service_instance)
      expect(etransact_service_instance).to receive(:etransact_active?)
      expect(rate_service_instance).to receive(:current_overnight_vrc).and_return(response_hash)
      get :current_overnight_vrc
    end
    it 'returns a rate' do
      get :current_overnight_vrc
      hash = JSON.parse(response.body)
      expect(hash['rate']).to be_kind_of(Float)
      expect(hash['rate']).to be >= 0
    end
    it 'returns a time stamp for when the rate was last updated' do
      get :current_overnight_vrc
      hash = JSON.parse(response.body)
      date = DateTime.parse(hash['updated_at'])
      expect(date).to be_kind_of(DateTime)
      expect(date).to be <= DateTime.now
    end
  end
end