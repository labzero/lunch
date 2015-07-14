require 'rails_helper'

RSpec.describe DashboardController, :type => :controller do
  login_user
  before do
    session['member_id'] = 750
  end

  describe "GET index", :vcr do
    before do
      allow(Time).to receive_message_chain(:zone, :now, :to_date).and_return(Date.new(2015, 6, 24))
      allow(subject).to receive(:current_user_roles)
    end
    
    it_behaves_like 'a user required action', :get, :index
    it "should render the index view" do
      get :index
      expect(response.body).to render_template("index")
    end
    it 'should call `current_member_roles`' do
      expect(subject).to receive(:current_user_roles)
      get :index
    end
    it 'should assign @account_overview' do
      get :index
      expect(assigns[:account_overview]).to be_kind_of(Hash)
      expect(assigns[:account_overview].length).to eq(3)
    end
    it "should assign @market_overview" do
      get :index
      expect(assigns[:market_overview]).to be_present
      expect(assigns[:market_overview][0]).to be_present
      expect(assigns[:market_overview][0][:name]).to be_present
      expect(assigns[:market_overview][0][:data]).to be_present
    end
    it "should assign @borrowing_capacity_gauge" do
      gauge_hash = double('A Gauge Hash')
      allow(subject).to receive(:calculate_gauge_percentages).and_return(gauge_hash)
      get :index
      expect(assigns[:borrowing_capacity_gauge]).to eq(gauge_hash)
    end
    it 'should have the expected keys in @borrowing_capacity_gauge' do
      get :index
      expect(assigns[:borrowing_capacity_gauge]).to include(:total, :mortgages, :aa, :aaa, :agency)
    end
    it 'should call MemberBalanceService.borrowing_capacity_summary with the current date' do
      expect_any_instance_of(MemberBalanceService).to receive(:borrowing_capacity_summary).with(Time.zone.now.to_date).and_call_original
      get :index
    end
    it 'should call `calculate_gauge_percentages` for @borrowing_capacity_gauge and @financing_availability_gauge'  do
      expect(subject).to receive(:calculate_gauge_percentages).twice
      get :index
    end
    it 'should assign @current_overnight_vrc' do
      get :index
      expect(assigns[:current_overnight_vrc]).to be_kind_of(Float)
    end
    it 'should assign @quick_advances_active' do
      get :index
      expect(assigns[:quick_advances_active]).to be_present
    end
    it 'should assign @financing_availability_gauge' do
      get :index
      expect(assigns[:financing_availability_gauge]).to be_kind_of(Hash)
      expect(assigns[:financing_availability_gauge][:used]).to be_kind_of(Hash)
      expect(assigns[:financing_availability_gauge][:used][:amount]).to be_kind_of(Numeric)
      expect(assigns[:financing_availability_gauge][:used][:percentage]).to be_kind_of(Numeric)
      expect(assigns[:financing_availability_gauge][:used][:display_percentage]).to be_kind_of(Numeric)
      expect(assigns[:financing_availability_gauge][:unused][:amount]).to be_kind_of(Numeric)
      expect(assigns[:financing_availability_gauge][:unused][:percentage]).to be_kind_of(Numeric)
      expect(assigns[:financing_availability_gauge][:unused][:display_percentage]).to be_kind_of(Numeric)
      expect(assigns[:financing_availability_gauge][:uncollateralized][:amount]).to be_kind_of(Numeric)
      expect(assigns[:financing_availability_gauge][:uncollateralized][:percentage]).to be_kind_of(Numeric)
      expect(assigns[:financing_availability_gauge][:uncollateralized][:display_percentage]).to be_kind_of(Numeric)
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
      it 'should assign @borrowing_capacity_guage as nil if the balance could not be retrieved' do
        allow_any_instance_of(MemberBalanceService).to receive(:borrowing_capacity_summary).and_return(nil)
        get :index
        expect(assigns[:borrowing_capacity_guage]).to eq(nil)
      end
      it 'should assign @financing_availability_gauge to nil if there is no value for `financing_availability` in the profile' do
        allow_any_instance_of(MemberBalanceService).to receive(:profile).and_return({credit_outstanding: {}})
        get :index
        expect(assigns[:financing_availability_gauge]).to be_nil
      end
    end
  end

  describe "GET quick_advance_rates", :vcr do
    allow_policy :advances, :show?
    let(:rate_data) { {some: 'data'} }
    let(:RatesService) {class_double(RatesService)}
    let(:rate_service_instance) {double("rate service instance", quick_advance_rates: nil)}
    it_behaves_like 'a user required action', :get, :quick_advance_rates
    it_behaves_like 'an authorization required method', :get, :quick_advance_rates, :advances, :show?
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
  end

  describe "POST quick_advance_preview", :vcr do
    allow_policy :advances, :show?
    let(:etransact_service_instance) {double('EtransactAdvancesService', quick_advance_validate: {}, signer_full_name: username)}
    let(:member_id) {750}
    let(:advance_term) {'someterm'}
    let(:advance_type) {'sometype'}
    let(:advance_rate) {'0.17'}
    let(:username) {'Test User'}
    let(:amount) { 100 }
    let(:make_request) { post :quick_advance_preview, member_id: member_id, advance_term: advance_term, advance_type: advance_type, advance_rate: advance_rate, amount: amount}

    it_behaves_like 'a user required action', :post, :quick_advance_preview
    it_behaves_like 'an authorization required method', :post, :quick_advance_preview, :advances, :show?
    it 'should render its view' do
      make_request
      expect(response.body).to render_template('dashboard/quick_advance_preview')
    end
    it 'should set @session_elevated to the result of calling `session_elevated?`' do
      result = double('needs securid')
      expect(subject).to receive(:session_elevated?).and_return(result)
      make_request
      expect(assigns[:session_elevated]).to be(result)
    end
    it 'should set @advance_amount' do
      make_request
      expect(assigns[:advance_amount]).to be_kind_of(Numeric)
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
      expect(assigns[:funding_date]).to be_kind_of(String)
    end
    it 'should set @maturity_date' do
      make_request
      expect(assigns[:maturity_date]).to be_kind_of(String)
    end
    it 'should set @advance_rate' do
      make_request
      expect(assigns[:advance_rate]).to be_kind_of(Numeric)
    end
    describe 'stubbed service' do
      before do
        allow(EtransactAdvancesService).to receive(:new).and_return(etransact_service_instance)
      end
      it 'should call the EtransactAdvancesService object\'s `quick_advance_validate` method with the POSTed advance_type, advance_term and rate' do
        expect(etransact_service_instance).to receive(:quick_advance_validate).with(member_id, amount, advance_type, advance_term, advance_rate.to_f, username).and_return({})
        make_request
      end
      it 'should request the signer full name' do
        expect(etransact_service_instance).to receive(:signer_full_name).with(subject.current_user.username).and_return(username)
        make_request
      end
      it 'should not request the signer full name if one is stored in the session' do
        session['signer_full_name'] = 'foo'
        expect(etransact_service_instance).to_not receive(:signer_full_name).with(subject.current_user.username)
        make_request
      end
    end
  end

  describe "POST quick_advance_perform", :vcr do
    allow_policy :advances, :show?
    let(:etransact_service_instance) {EtransactAdvancesService.new(ActionDispatch::TestRequest.new)}
    let(:member_id) {750}
    let(:advance_term) {'someterm'}
    let(:advance_type) {'sometype'}
    let(:advance_rate) {'0.17'}
    let(:username) {'Test User'}
    let(:amount) { 100 }
    let(:securid_pin) { '1111' }
    let(:securid_token) { '222222' }
    let(:make_request) { post :quick_advance_perform, member_id: member_id, advance_term: advance_term, advance_type: advance_type, advance_rate: advance_rate, amount: amount, securid_pin: securid_pin, securid_token: securid_token }
    let(:securid_service) { SecurIDService.new('a user', test_mode: true) }

    before do
      allow(subject).to receive(:session_elevated?).and_return(true)
      allow(SecurIDService).to receive(:new).and_return(securid_service)
      allow(EtransactAdvancesService).to receive(:new).and_return(etransact_service_instance)
    end

    it_behaves_like 'a user required action', :post, :quick_advance_perform
    it_behaves_like 'an authorization required method', :post, :quick_advance_perform, :advances, :show?
    it 'should call the EtransactAdvancesService object\'s `quick_advance_execute` method with the POSTed advance_type, advance_term and rate' do
      expect(etransact_service_instance).to receive(:quick_advance_execute).with(member_id, amount, advance_type, advance_term, advance_rate.to_f, username).and_return({})
      make_request
    end
    it 'should render the confirmation view on success' do
      make_request
      expect(response.body).to render_template('dashboard/quick_advance_perform')
    end
    it 'should return a JSON response containing the view, the advance status and the securid status' do
      html = SecureRandom.hex
      allow(subject).to receive(:render_to_string).and_return(html)
      make_request
      json = JSON.parse(response.body)
      expect(json['html']).to eq(html)
      expect(json['securid']).to eq(RSA::SecurID::Session::AUTHENTICATED.to_s)
      expect(json['advance_success']).to be(true)
    end
    it 'should check if the session has been elevated' do
      expect(subject).to receive(:session_elevated?).at_least(:once)
      make_request
    end
    it 'should set @initiated_at' do
      make_request
      expect(assigns[:initiated_at]).to be_kind_of(DateTime)
    end
    it 'should set @advance_amount' do
      make_request
      expect(assigns[:advance_amount]).to be_kind_of(Numeric)
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
      expect(assigns[:funding_date]).to be_kind_of(String)
    end
    it 'should set @maturity_date' do
      make_request
      expect(assigns[:maturity_date]).to be_kind_of(String)
    end
    it 'should set @advance_rate' do
      make_request
      expect(assigns[:advance_rate]).to be_kind_of(Numeric)
    end
    it 'should set @advance_number' do
      make_request
      expect(assigns[:advance_number]).to be_kind_of(String)
    end
    it 'should request the signer full name' do
      expect(etransact_service_instance).to receive(:signer_full_name).with(subject.current_user.username).and_return(username)
      make_request
    end
    it 'should not request the signer full name if one is stored in the session' do
      session['signer_full_name'] = 'foo'
      expect(etransact_service_instance).to_not receive(:signer_full_name).with(subject.current_user.username)
      make_request
    end
    describe 'with unelevated session' do
      before do
        allow(subject).to receive(:session_elevated?).and_return(false)
      end
      it 'should return a securid status of `invalid_pin` if the pin is malformed' do
        post :quick_advance_perform, securid_pin: 'foo', securid_token: securid_token
        json = JSON.parse(response.body)
        expect(json['securid']).to eq('invalid_pin')
      end
      it 'should return a securid status of `invalid_token` if the token is malformed' do
        post :quick_advance_perform, securid_token: 'foo', securid_pin: securid_pin
        json = JSON.parse(response.body)
        expect(json['securid']).to eq('invalid_token')
      end
      it 'should authenticate the user via RSA SecurID if the session is not elevated' do
        expect(securid_service).to receive(:authenticate).with(securid_pin, securid_token)
        make_request
      end
      it 'should elevate the session if RSA SecurID authentication succedes' do
        expect(securid_service).to receive(:authenticate).with(securid_pin, securid_token).ordered
        expect(securid_service).to receive(:authenticated?).ordered.and_return(true)
        expect(subject).to receive(:session_elevate!).ordered
        make_request
      end
      it 'should not elevate the session if RSA SecurID authentication fails' do
        expect(securid_service).to receive(:authenticate).with(securid_pin, securid_token).ordered
        expect(securid_service).to receive(:authenticated?).ordered.and_return(false)
        expect(subject).to_not receive(:session_elevate!).ordered
        make_request
      end
      it 'should not perform the advance if the session is not elevated' do
        expect(etransact_service_instance).to_not receive(:quick_advance_execute)
        make_request
      end
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

  describe 'calculate_gauge_percentages private method' do
    let(:foo_capacity) { rand(1000..2000) }
    let(:bar_capacity) { rand(1000..2000) }
    let(:total_borrowing_capacity) { foo_capacity + bar_capacity }
    let(:capacity_hash) do
      {
        total: total_borrowing_capacity,
        foo: foo_capacity,
        bar: bar_capacity
      }
    end
    let(:call_method) { subject.send(:calculate_gauge_percentages, capacity_hash, total_borrowing_capacity, :total) }
    it 'should not raise an exception if total_borrowing_capacity is zero' do
      expect {subject.send(:calculate_gauge_percentages, capacity_hash, 0, :total)}.to_not raise_error
    end
    it 'should convert the capacties into gauge hashes' do
      gauge_hash = call_method
      expect(gauge_hash[:foo]).to include(:amount, :percentage, :display_percentage)
      expect(gauge_hash[:bar]).to include(:amount, :percentage, :display_percentage)
      expect(gauge_hash[:total]).to include(:amount, :percentage, :display_percentage)
    end
    it 'should not include the excluded keys values in calculating display_percentage' do
      expect(call_method[:total][:display_percentage]).to eq(100)
    end
  end

end