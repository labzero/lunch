require 'rails_helper'

RSpec.describe DashboardController, :type => :controller do
  login_user
  before do
    session['member_id'] = 750
  end

  describe "GET index", :vcr do
    let(:member_id) {750}
    let(:empty_financing_availability_gauge) {{total: {amount: 0, display_percentage: 100, percentage: 0}}}
    before do
      allow(Time).to receive_message_chain(:zone, :now, :to_date).and_return(Date.new(2015, 6, 24))
      allow(subject).to receive(:current_user_roles)
      allow_any_instance_of(MembersService).to receive(:member_contacts)
      allow(MessageService).to receive(:new).and_return(double('service instance', todays_quick_advance_message: nil))
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
    it 'should assign @quick_advance_status' do
      get :index
      expect(assigns[:quick_advance_status]).to be_present
    end
    it 'should assign @quick_advance_status to `:open` if the desk is enabled and we have terms' do
      get :index
      expect(assigns[:quick_advance_status]).to eq(:open)
    end
    it 'should assign @quick_advance_status to `:no_terms` if the desk is enabled and we have no terms' do
      allow_any_instance_of(EtransactAdvancesService).to receive(:has_terms?).and_return(false)
      get :index
      expect(assigns[:quick_advance_status]).to eq(:no_terms)
    end
    it 'should assign @quick_advance_status to `:open` if the desk is disabled' do
      allow_any_instance_of(EtransactAdvancesService).to receive(:etransact_active?).and_return(false)
      get :index
      expect(assigns[:quick_advance_status]).to eq(:closed)
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
    describe 'the @contacts instance variable' do
      let(:contacts) { double('some contact') }
      let(:cam_username) { 'cam' }
      let(:rm_username) { 'rm' }
      let(:uppercase_username) { 'ALLCAPSNAME' }
      before do
        allow_any_instance_of(MembersService).to receive(:member_contacts).and_return(contacts)
        allow(contacts).to receive(:[]).with(:cam).and_return({username: cam_username})
        allow(contacts).to receive(:[]).with(:rm).and_return({username: rm_username})
        allow(Rails.application.assets).to receive(:find_asset)
      end
      it 'is the result of the `members_service.member_contacts` method' do
        get :index
        expect(assigns[:contacts]).to eq(contacts)
      end
      it 'contains an `image_url` for the cam' do
        allow(Rails.application.assets).to receive(:find_asset).with("#{cam_username}.jpg").and_return(true)
        get :index
        expect(assigns[:contacts][:cam][:image_url]).to eq("#{cam_username}.jpg")
      end
      it 'contains an `image_url` for the rm' do
        allow(Rails.application.assets).to receive(:find_asset).with("#{rm_username}.jpg").and_return(true)
        get :index
        expect(assigns[:contacts][:rm][:image_url]).to eq("#{rm_username}.jpg")
      end
      it 'contains an `image_url` that is the downcased version of the username for the rm' do
        allow(contacts).to receive(:[]).with(:rm).and_return({username: uppercase_username})
        allow(Rails.application.assets).to receive(:find_asset).with("#{uppercase_username.downcase}.jpg").and_return(true)
        get :index
        expect(assigns[:contacts][:rm][:image_url]).to eq("#{uppercase_username.downcase}.jpg")
      end
      it 'contains an `image_url` that is the downcased version of the username for the cam' do
        allow(contacts).to receive(:[]).with(:cam).and_return({username: uppercase_username})
        allow(Rails.application.assets).to receive(:find_asset).with("#{uppercase_username.downcase}.jpg").and_return(true)
        get :index
        expect(assigns[:contacts][:cam][:image_url]).to eq("#{uppercase_username.downcase}.jpg")
      end
      it 'assigns the default image_url if the image asset does not exist for the contact' do
        allow(Rails.application.assets).to receive(:find_asset).and_return(false)
        get :index
        expect(assigns[:contacts][:rm][:image_url]).to eq('placeholder-usericon.svg')
        expect(assigns[:contacts][:cam][:image_url]).to eq('placeholder-usericon.svg')
      end
      it 'returns {} if nil is returned from the service object' do
        allow_any_instance_of(MembersService).to receive(:member_contacts).and_return(nil)
        get :index
        expect(assigns[:contacts]).to eq({})
      end
    end
    describe 'the @quick_advance_message instance variable' do
      let(:message) { double('message') }
      let(:service_instance) { double('service instance') }
      before { allow(MessageService).to receive(:new).and_return(service_instance) }
      it 'is set to the value returned by the `todays_quick_advance_message` MessageService instance method' do
        allow(service_instance).to receive(:todays_quick_advance_message).and_return(message)
        get :index
        expect(assigns[:quick_advance_message]).to eq(message)
      end
      it 'is nil if the `todays_quick_advance_message` MessageService instance method returns nil' do
        allow(service_instance).to receive(:todays_quick_advance_message)
        get :index
        expect(assigns[:quick_advance_message]).to be_nil
      end
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
      it 'should assign @borrowing_capacity_guage to a zeroed out gauge if the balance could not be retrieved' do
        allow_any_instance_of(MemberBalanceService).to receive(:borrowing_capacity_summary).and_return(nil)
        get :index
        expect(assigns[:borrowing_capacity_gauge]).to eq(empty_financing_availability_gauge)
      end
      it 'should assign @financing_availability_gauge to a zeroed out gauge if there is no value for `financing_availability` in the profile' do
        allow_any_instance_of(MemberBalanceService).to receive(:profile).and_return({credit_outstanding: {}})
        get :index
        expect(assigns[:financing_availability_gauge]).to eq(empty_financing_availability_gauge)
      end
      it 'should respond with a 200 even if MemberBalanceService#profile returns nil' do
        allow_any_instance_of(MemberBalanceService).to receive(:profile).and_return(nil)
        get :index
        expect(response).to be_success
      end
    end
    describe "Member Service flags" do
      before do
        allow_any_instance_of(MembersService).to receive(:report_disabled?).with(member_id, anything).and_return(false)
      end
      it 'should set @financing_availability_gauge to be zeroed out if the report is disabled' do
        allow_any_instance_of(MembersService).to receive(:report_disabled?).with(member_id, [MembersService::FINANCING_AVAILABLE_DATA]).and_return(true)
        get :index
        expect(assigns[:financing_availability_gauge]).to eq(empty_financing_availability_gauge)
      end
      it 'should set @account_overview to have zero sta balance if the report is disabled' do
        allow_any_instance_of(MembersService).to receive(:report_disabled?).with(member_id, [MembersService::STA_BALANCE_AND_RATE_DATA, MembersService::STA_DETAIL_DATA]).and_return(true)
        get :index
        expect(assigns[:account_overview][:sta_balance][0]).to eq(["STA Balance:*", nil, "*as of close of business on prior business day"])
      end
      it 'should set @account_overview to have zero credit outstanding balance if the report is disabled' do
        allow_any_instance_of(MembersService).to receive(:report_disabled?).with(member_id, [MembersService::CREDIT_OUTSTANDING_DATA]).and_return(true)
        get :index
        expect(assigns[:account_overview][:credit_outstanding][0]).to eq(["Credit Outstanding:", nil])
      end
      it 'should set @account_overview to have zero capital stock remaining balance if the report is disabled' do
        allow_any_instance_of(MembersService).to receive(:report_disabled?).with(member_id, [MembersService::FHLB_STOCK_DATA]).and_return(true)
        get :index
        expect(assigns[:account_overview][:remaining][3]).to eq(["Stock Leverage", nil])
      end
      it 'should set @account_overview to have zero collateral borrowing capacity if the report is disabled' do
        allow_any_instance_of(MembersService).to receive(:report_disabled?).with(member_id, [MembersService::COLLATERAL_HIGHLIGHTS_DATA]).and_return(true)
        get :index
        expect(assigns[:account_overview][:remaining][2]).to eq(["Collateral Borrowing Capacity", nil])
      end
      it 'should set @borrowing_capacity to be nil if the report is disabled' do
        allow_any_instance_of(MembersService).to receive(:report_disabled?).with(member_id, [MembersService::COLLATERAL_REPORT_DATA]).and_return(true)
        get :index
        expect(assigns[:borrowing_capacity]).to eq(nil)
      end
    end
  end

  describe "GET quick_advance_rates", :vcr do
    allow_policy :advances, :show?
    let(:rate_data) { {some: 'data'} }
    let(:RatesService) {class_double(RatesService)}
    let(:rate_service_instance) {double("rate service instance", quick_advance_rates: nil)}
    let(:advance_request) { double('An AdvanceRequest', rates: rate_data) }
    let(:make_request) { get :quick_advance_rates }

    before do
      allow(subject).to receive(:advance_request).and_return(advance_request)
    end

    it_behaves_like 'a user required action', :get, :quick_advance_rates
    it_behaves_like 'an authorization required method', :get, :quick_advance_rates, :advances, :show?
    it 'gets the rates from the advance request' do
      expect(subject).to receive(:advance_request).and_return(advance_request)
      expect(advance_request).to receive(:rates).and_return(rate_data)
      make_request
    end
    it 'should render its view' do
      make_request
      expect(response.body).to render_template('dashboard/quick_advance_rates')
    end
    it 'should set @rate_data' do
      make_request
      expect(assigns[:rate_data]).to eq(rate_data)
    end
    it 'should set @advance_terms' do
      make_request
      expect(assigns[:advance_terms]).to eq(AdvanceRequest::ADVANCE_TERMS)
    end
    it 'should set @advance_types' do
      make_request
      expect(assigns[:advance_types]).to eq(AdvanceRequest::ADVANCE_TYPES)
    end
    it 'clears the request before fetching rates' do
      expect(subject).to receive(:advance_request_clear!).ordered
      expect(advance_request).to receive(:rates).ordered
      make_request
    end
  end

  describe "POST quick_advance_preview", :vcr do
    allow_policy :advances, :show?
    let(:member_id) {750}
    let(:advance_term) {'1week'}
    let(:advance_type) {'aa'}
    let(:advance_rate) {'0.17'}
    let(:username) {'Test User'}
    let(:advance_description) {double('some description')}
    let(:advance_program) {double('some program')}
    let(:amount) { 100000 }
    let(:interest_day_count) { 'some interest_day_count' }
    let(:payment_on) { 'some payment_on' }
    let(:maturity_date) { 'some maturity_date' }
    let(:check_capstock) { true }
    let(:check_result) {{:status => 'pass', :low => 100000, :high => 1000000000}}
    let(:make_request) { post :quick_advance_preview, interest_day_count: interest_day_count, payment_on: payment_on, maturity_date: maturity_date, member_id: member_id, advance_term: advance_term, advance_type: advance_type, advance_rate: advance_rate, amount: amount, check_capstock: check_capstock}
    let(:advance_request) { double('An AdvanceRequest', :type= => nil, :term= => nil, :amount= => nil, :stock_choice= => nil, validate_advance: true, errors: nil, sta_debit_amount: 0, timestamp!: nil, amount: amount) }
    before do
      allow(subject).to receive(:advance_request).and_return(advance_request)
      allow(subject).to receive(:populate_advance_request_view_parameters)
      allow(subject).to receive(:advance_request_to_session)
    end
    it_behaves_like 'a user required action', :post, :quick_advance_preview
    it_behaves_like 'an authorization required method', :post, :quick_advance_preview, :advances, :show?
    it 'should populate the normal advance view parameters' do
      expect(subject).to receive(:populate_advance_request_view_parameters)
      make_request
    end
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
    it 'should validate the advance' do
      expect(advance_request).to receive(:validate_advance)
      make_request
    end
    describe 'the rate is stale' do
      before do
        allow(advance_request).to receive(:errors).and_return([double('An Error', type: :rate, code: :stale)])
      end
      it 'renders the quick_advance_error' do
        make_request
        expect(response).to render_template(:quick_advance_error)
      end
      it 'renders the quick_advance_error withoiut a layout' do
        expect(subject).to receive(:render_to_string).with(:quick_advance_error, layout: false)
        make_request
      end
      it 'sets preview_success to `false`' do
        data = JSON.parse(make_request.body)
        expect(data['preview_success']).to be false
      end
      it 'sets preview_error to `true`' do
        data = JSON.parse(make_request.body)
        expect(data['preview_error']).to be true
      end
    end

    {
      'GrossUpError': {type: :preview, code: :capital_stock_offline},
      'CreditError': {type: :preview, code: :credit},
      'CollateralError': {type: :preview, code: :collateral},
      'ExceedsTotalDailyLimitError': {type: :preview, code: :total_daily_limit},
      'LowLimit': {type: :limits, code: :low},
      'HighLimit': {type: :limits, code: :high}
    }.each do |name, error|
      describe "POST quick_advance_error of type `#{name}`" do
        before do
          error[:value] = nil unless error.has_key?(:value)
          allow(advance_request).to receive(:errors).and_return([double('An Error', error)])
        end
        it 'should render its view' do
          make_request
          expect(response.body).to render_template('dashboard/quick_advance_error')
        end
      end
    end

    describe "POST quick_advance_capstock" do
      before do
        allow(advance_request).to receive(:errors).and_return([double('An Error', type: :preview, code: :capital_stock, value: nil)])
      end
      it 'should render its view' do
        make_request
        expect(response.body).to render_template('dashboard/quick_advance_capstock')
      end
    end
  end

  describe "POST quick_advance_perform", :vcr do
    allow_policy :advances, :show?
    let(:member_id) {750}
    let(:advance_term) {'someterm'}
    let(:advance_type) {'sometype'}
    let(:advance_description) {double('some description')}
    let(:advance_program) {double('some program')}
    let(:advance_rate) {'0.17'}
    let(:username) {'Test User'}
    let(:amount) { 100000 }
    let(:securid_pin) { '1111' }
    let(:securid_token) { '222222' }
    let(:make_request) { post :quick_advance_perform, member_id: member_id, advance_term: advance_term, advance_type: advance_type, advance_rate: advance_rate, amount: amount, securid_pin: securid_pin, securid_token: securid_token }
    let(:securid_service) { SecurIDService.new('a user', test_mode: true) }
    let(:advance_request) { double('An AdvanceRequest', expired?: false, executed?: true, execute: nil, sta_debit_amount: 0) }

    before do
      allow(subject).to receive(:session_elevated?).and_return(true)
      allow(SecurIDService).to receive(:new).and_return(securid_service)
      allow(subject).to receive(:advance_request).and_return(advance_request)
      allow(subject).to receive(:populate_advance_request_view_parameters)
      allow(subject).to receive(:advance_request_to_session)
    end

    it_behaves_like 'a user required action', :post, :quick_advance_perform
    it_behaves_like 'an authorization required method', :post, :quick_advance_perform, :advances, :show?
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
    it 'should check if the rate has expired' do
      expect(advance_request).to receive(:expired?)
      make_request
    end
    it 'should populate the normal advance view parameters' do
      expect(subject).to receive(:populate_advance_request_view_parameters)
      make_request
    end
    it 'executes the advance' do
      expect(advance_request).to receive(:execute)
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
        expect(advance_request).to_not receive(:execute)
        make_request
      end
    end

    describe 'with an expired rate' do
      before do
        allow(advance_request).to receive(:expired?).and_return(true)
      end
      it 'should render a quick advance error' do
        make_request
        expect(response.body).to render_template('dashboard/quick_advance_error')
      end
      it 'should set the error message to `rate_expired`' do
        make_request
        expect(assigns[:error_message]).to eq(:rate_expired)
      end
      it 'should populate the normal advance view parameters' do
        expect(subject).to receive(:populate_advance_request_view_parameters)
        make_request
      end
      it 'should not execute the advance' do
        expect(advance_request).to_not receive(:execute)
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

  RSpec.shared_examples "an advance_request method" do |method|
    it 'should initialize the advance_request hash if it doesn\'t exist' do
      session['advance_request'] = nil
      subject.send(method)
      expect(session['advance_request']).to be_kind_of(Hash)
    end
    it 'should not initialize the advance_request hash if it exists' do
      hash = {}
      session['advance_request'] = hash
      subject.send(method)
      expect(session['advance_request']).to equal(hash)
    end
  end

  describe '`populate_advance_request_view_parameters` method' do
    let(:call_method) { subject.send(:populate_advance_request_view_parameters) }
    let(:advance_request) { double('An AdvanceRequest').as_null_object }
    before do
      allow(subject).to receive(:advance_request).and_return(advance_request)
    end
    it 'should get the advance request' do
      expect(subject).to receive(:advance_request)
      call_method
    end
    {
      authorized_amount: :authorized_amount,
      cumulative_stock_required: :cumulative_stock_required,
      current_trade_stock_required: :current_trade_stock_required,
      pre_trade_stock_required: :pre_trade_stock_required,
      net_stock_required: :net_stock_required,
      gross_amount: :gross_amount,
      gross_cumulative_stock_required: :gross_cumulative_stock_required,
      gross_current_trade_stock_required: :gross_current_trade_stock_required,
      gross_pre_trade_stock_required: :gross_pre_trade_stock_required,
      gross_net_stock_required: :gross_net_stock_required,
      interest_day_count: :interest_day_count,
      payment_on: :payment_on,
      trade_date: :trade_date,
      funding_date: :funding_date,
      maturity_date: :maturity_date,
      initiated_at: :initiated_at,
      advance_number: :confirmation_number,
      advance_amount: :amount,
      advance_term: :term,
      advance_rate: :rate,
      advance_description: :term_description,
      advance_type: :human_type,
      advance_type_raw: :type,
      advance_program: :program_name,
      collateral_type: :collateral_type,
      old_rate: :old_rate,
      rate_changed: :rate_changed?
    }.each do |param, method|
      it "should populate the view variable `@#{param}` with the value found on the advance request for attribute `#{method}`" do
        value = double("Advance Request Parameter: #{method}")
        allow(advance_request).to receive(method).and_return(value)
        call_method
        expect(assigns[param]).to eq(value)
      end
    end
  end

  describe '`advance_request` protected method' do
    let(:call_method) { subject.send(:advance_request) }
    it 'returns a new AdvanceRequest if the controller is lacking one' do
      member_id = double('A Member ID')
      signer = double('A Signer')
      request = double('A Request')
      advance_request = double('An AdvanceRequest')
      allow(subject).to receive(:current_member_id).and_return(member_id)
      allow(subject).to receive(:signer_full_name).and_return(signer)
      allow(subject).to receive(:request).and_return(request)
      allow(AdvanceRequest).to receive(:new).with(member_id, signer, request).and_return(advance_request)
      expect(call_method).to be(advance_request)
    end
    it 'returns the AdvanceRequest stored in `@advance_request` if present' do
      advance_request = double('An AdvanceRequest')
      subject.instance_variable_set(:@advance_request, advance_request)
      expect(call_method).to be(advance_request)
    end
  end

  describe '`advance_request_from_session` protected method' do
    let(:call_method) { subject.send(:advance_request_from_session) }
    describe 'with a serialized request in the session' do
      let(:serialized_request) { double('A Serialized AdvanceRequest') }
      let(:advance_request) { double('An AdvanceRequest') }
      before do
        session[:advance_request] = serialized_request
        allow(AdvanceRequest).to receive(:from_hash).and_return(advance_request)
      end
      it 'fetches the request hash from the session' do
        allow(session).to receive(:[]).and_call_original
        expect(session).to receive(:[]).with(:advance_request)
        call_method
      end
      it 'builds an AdvanceRequest from the hash' do
        request = double('A Request')
        allow(subject).to receive(:request).and_return(request)
        expect(AdvanceRequest).to receive(:from_hash).with(serialized_request, request)
        call_method
      end
      it 'assigns the AdvanceRequest to @advance_request' do
        call_method
        expect(assigns[:advance_request]).to be(advance_request)
      end
    end
    it 'calls `advance_request` if the session has no serialized request' do
      expect(subject).to receive(:advance_request)
      call_method
    end
  end

  describe '`advance_request_to_session` protected method' do
    let(:call_method) { subject.send(:advance_request_to_session) }
    it 'does nothing if there is no @advance_request' do
      call_method
      expect(session[:advance_request]).to be_nil
    end
    it 'converts the AdvanceRequest to a hash and stores in session' do
      serialized_request = double('A Serialized AdvanceRequest')
      advance_request = double('An AdvanceRequest', serializable_hash: serialized_request)
      subject.instance_variable_set(:@advance_request, advance_request)
      call_method
      expect(session[:advance_request]).to be(serialized_request)
    end
  end

  describe '`advance_request_clear!` protected method' do
    let(:call_method) { subject.send(:advance_request_clear!) }
    it 'deletes tha advance request from the session' do
      expect(session).to receive(:delete).with(:advance_request)
      call_method
    end
    it 'nils out the @advance_request' do
      subject.instance_variable_set(:@advance_request, double('An AdvanceRequest'))
      call_method
      expect(assigns[:advance_request]).to be_nil
    end
  end

  describe '`signer_full_name` protected method' do
    let(:signer) { double('A Signer Name') }
    let(:call_method) { subject.send(:signer_full_name) }
    it 'returns the signer name from the session if present' do
      session['signer_full_name'] = signer
      expect(call_method).to be(signer)
    end
    describe 'with no signer in session' do
      let(:username) { double('A Username') }
      before do
        allow(subject).to receive_message_chain(:current_user, :username).and_return(username)
        allow_any_instance_of(EtransactAdvancesService).to receive(:signer_full_name).with(username).and_return(signer)
      end
      it 'fetches the signer from the eTransact Service' do
        expect_any_instance_of(EtransactAdvancesService).to receive(:signer_full_name).with(username)
        call_method
      end
      it 'sets the signer name in the session' do
        call_method
        expect(session['signer_full_name']).to be(signer)
      end
      it 'returns the signer name' do
        expect(call_method).to be(signer)
      end
    end
  end

end