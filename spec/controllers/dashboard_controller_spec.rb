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
        expect(assigns[:account_overview][:remaining][3]).to eq(["Stock Leverage", nil, nil, 2])
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
    let(:etransact_service_instance) {double('EtransactAdvancesService', check_limits: {}, quick_advance_validate: {}, signer_full_name: username, include?: nil)}
    let(:member_id) {750}
    let(:advance_term) {'1week'}
    let(:advance_type) {'sometype'}
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
    let(:checked_rate_hash) { {rate: double('rate'), old_rate: double('old_rate'), rate_changed: double('rate_changed')} }
    before do
      allow(subject).to receive(:get_description_from_advance_term).and_return(advance_description)
      allow(subject).to receive(:get_type_from_advance_type).and_return(advance_type)
      allow(subject).to receive(:get_program_from_advance_type).and_return(advance_program)
      allow(subject).to receive(:check_advance_rate).and_return({})
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
    it 'should set @advance_amount' do
      make_request
      expect(assigns[:advance_amount]).to be_kind_of(Numeric)
    end
    it 'should set @advance_type' do
      make_request
      expect(assigns[:advance_type]).to be_kind_of(String)
    end
    it 'should set @advance_description' do
      make_request
      expect(assigns[:advance_description]).to eq(advance_description)
    end
    it 'should set @advance_program' do
      make_request
      expect(assigns[:advance_program]).to eq(advance_program)
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
    describe 'after checking the advance rate' do
      before { allow(subject).to receive(:check_advance_rate).and_return(checked_rate_hash) }
      %i(advance_rate old_rate rate_changed).each do |var|
        it "should set @#{var.to_s}" do
          make_request
          expect(assigns[var]).to eq(checked_rate_hash[var])
        end
      end
    end
    describe 'stubbed service' do
      before do
        allow(EtransactAdvancesService).to receive(:new).and_return(etransact_service_instance)
      end
      it 'should call the EtransactAdvancesService object\'s `check_limits` method with the POSTed amount and advance_term' do
        expect(etransact_service_instance).to receive(:check_limits).with(member_id, amount, advance_term).and_return({})
        make_request
      end
      it 'should call the EtransactAdvancesService object\'s `quick_advance_validate` method with the POSTed advance_type, advance_term and rate' do
        allow(etransact_service_instance).to receive(:check_limits).with(member_id, amount, advance_term).and_return(check_result)
        expect(etransact_service_instance).to receive(:quick_advance_validate).with(member_id, amount, advance_type, advance_term, advance_rate.to_f, check_capstock, username).and_return({})
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

    describe "POST quick_advance_capstock" do
      let(:amount) { 1000000 }
      it 'should render its view' do
        make_request
        expect(response.body).to render_template('dashboard/quick_advance_capstock')
      end
      it 'should set @authorized_amount' do
        make_request
        expect(assigns[:authorized_amount]).to be_kind_of(Numeric)
      end
      it 'should set @exception_message' do
        make_request
        expect(assigns[:exception_message]).to be_kind_of(String)
      end
      it 'should set @cumulative_stock_required' do
        make_request
        expect(assigns[:cumulative_stock_required]).to be_kind_of(Numeric)
      end
      it 'should set @current_trade_stock_required' do
        make_request
        expect(assigns[:current_trade_stock_required]).to be_kind_of(Numeric)
      end
      it 'should set @pre_trade_stock_required' do
        make_request
        expect(assigns[:pre_trade_stock_required]).to be_kind_of(Numeric)
      end
      it 'should set @net_stock_required' do
        make_request
        expect(assigns[:net_stock_required]).to be_kind_of(Numeric)
      end
      it 'should set @gross_amount' do
        make_request
        expect(assigns[:gross_amount]).to be_kind_of(Numeric)
      end
      it 'should set @gross_cumulative_stock_required' do
        make_request
        expect(assigns[:gross_cumulative_stock_required]).to be_kind_of(Numeric)
      end
      it 'should set @gross_current_trade_stock_required' do
        make_request
        expect(assigns[:gross_current_trade_stock_required]).to be_kind_of(Numeric)
      end
      it 'should set @gross_pre_trade_stock_required' do
        make_request
        expect(assigns[:gross_pre_trade_stock_required]).to be_kind_of(Numeric)
      end
      it 'should set @gross_net_stock_required' do
        make_request
        expect(assigns[:gross_net_stock_required]).to be_kind_of(Numeric)
      end
    end

    describe "POST quick_advance_error" do
      let(:amount) { 2000000 }
      it 'should render its view' do
        make_request
        expect(response.body).to render_template('dashboard/quick_advance_error')
      end
      it 'should set @advance_amount' do
        make_request
        expect(assigns[:advance_amount]).to be_kind_of(Numeric)
      end
      it 'should set @advance_type' do
        make_request
        expect(assigns[:advance_type]).to be_kind_of(String)
      end
      it 'should set @advance_term' do
        make_request
        expect(assigns[:advance_term]).to be_kind_of(String)
      end
      it 'should set @advance_rate' do
        make_request
        expect(assigns[:advance_rate]).to be_kind_of(Numeric)
      end
      it 'should set @error_message' do
        make_request
        expect(assigns[:error_message]).to eq(:pass)
      end
      it 'should set @advance_description' do
        make_request
        expect(assigns[:advance_description]).to eq(advance_description)
      end
      it 'should set @advance_program' do
        make_request
        expect(assigns[:advance_program]).to eq(advance_program)
      end
      it 'should set @payment_on' do
        make_request
        expect(assigns[:payment_on]).to be_kind_of(String)
      end
      it 'should set @interest_day_count' do
        make_request
        expect(assigns[:interest_day_count]).to be_kind_of(String)
      end
      it 'should set @maturity_date' do
        make_request
        expect(assigns[:maturity_date]).to be_kind_of(String)
      end
      it 'should set @funding_date to today' do
        date = Date.new(2015,8,17)
        make_request
        expect(assigns[:funding_date]).to eq(date.iso8601)
      end
    end

    describe "POST quick_advance_error of type `CreditError`" do
      let(:amount) { 100001 }
      it 'should render its view' do
        make_request
        expect(response.body).to render_template('dashboard/quick_advance_error')
      end
      it 'should set @advance_amount' do
        make_request
        expect(assigns[:advance_amount]).to be_kind_of(Numeric)
      end
      it 'should set @advance_type' do
        advance_type = double('advance_type')
        allow(subject).to receive(:get_type_from_advance_type).and_return(advance_type)
        make_request
        expect(assigns[:advance_type]).to eq(advance_type)
      end
      it 'should set @error_message' do
        make_request
        expect(assigns[:error_message]).to eq(:credit)
      end
      it 'should set @advance_description' do
        make_request
        expect(assigns[:advance_description]).to eq(advance_description)
      end
      it 'should set @advance_program' do
        make_request
        expect(assigns[:advance_program]).to eq(advance_program)
      end
      it 'should set @advance_term' do
        make_request
        expect(assigns[:advance_term]).to eq(advance_term)
      end
      it 'should set @advance_rate' do
        make_request
        expect(assigns[:advance_rate]).to eq(advance_rate.to_f)
      end
      it 'should set @payment_on' do
        make_request
        expect(assigns[:payment_on]).to be_kind_of(String)
      end
      it 'should set @interest_day_count' do
        make_request
        expect(assigns[:interest_day_count]).to be_kind_of(String)
      end
      it 'should set @maturity_date' do
        make_request
        expect(assigns[:maturity_date]).to be_kind_of(String)
      end
      it 'should set @funding_date to today' do
        date = Date.new(2015,8,17)
        make_request
        expect(assigns[:funding_date]).to eq(date.iso8601)
      end
    end

    describe "POST quick_advance_error of type `ExceedsTotalDailyLimitError`" do
      let(:amount) { 100003 }
      it 'should render its view' do
        make_request
        expect(response.body).to render_template('dashboard/quick_advance_error')
      end
      it 'should set @advance_amount' do
        make_request
        expect(assigns[:advance_amount]).to be_kind_of(Numeric)
      end
      it 'should set @advance_type' do
        advance_type = double('advance_type')
        allow(subject).to receive(:get_type_from_advance_type).and_return(advance_type)
        make_request
        expect(assigns[:advance_type]).to eq(advance_type)
      end
      it 'should set @error_message' do
        make_request
        expect(assigns[:error_message]).to eq(:total_daily_limit)
      end
      it 'should set @advance_description' do
        make_request
        expect(assigns[:advance_description]).to eq(advance_description)
      end
      it 'should set @advance_program' do
        make_request
        expect(assigns[:advance_program]).to eq(advance_program)
      end
      it 'should set @advance_term' do
        make_request
        expect(assigns[:advance_term]).to eq(advance_term)
      end
      it 'should set @advance_rate' do
        make_request
        expect(assigns[:advance_rate]).to eq(advance_rate.to_f)
      end
      it 'should set @payment_on' do
        make_request
        expect(assigns[:payment_on]).to be_kind_of(String)
      end
      it 'should set @interest_day_count' do
        make_request
        expect(assigns[:interest_day_count]).to be_kind_of(String)
      end
      it 'should set @maturity_date' do
        make_request
        expect(assigns[:maturity_date]).to be_kind_of(String)
      end
      it 'should set @funding_date to today' do
        date = Date.new(2015,8,17)
        make_request
        expect(assigns[:funding_date]).to eq(date.iso8601)
      end
    end

    describe "POST quick_advance_error of type `CollateralError`" do
      let(:amount) { 100002 }
      it 'should render its view' do
        make_request
        expect(response.body).to render_template('dashboard/quick_advance_error')
      end
      it 'should set @advance_amount' do
        make_request
        expect(assigns[:advance_amount]).to be_kind_of(Numeric)
      end
      it 'should set @error_message' do
        make_request
        expect(assigns[:error_message]).to eq(:collateral)
      end
      it 'should set @advance_type' do
        advance_type = double('advance_type')
        allow(subject).to receive(:get_type_from_advance_type).and_return(advance_type)
        make_request
        expect(assigns[:advance_type]).to eq(advance_type)
      end
      it 'should set @collateral_type' do
        collateral_type = double('collateral_type')
        stub_const('DashboardController::COLLATERAL_TYPE_MAPPING', {"#{advance_type}": collateral_type})
        make_request
        expect(assigns[:collateral_type]).to eq(collateral_type)
      end
      it 'should set @advance_description' do
        make_request
        expect(assigns[:advance_description]).to eq(advance_description)
      end
      it 'should set @advance_program' do
        make_request
        expect(assigns[:advance_program]).to eq(advance_program)
      end
      it 'should set @advance_term' do
        make_request
        expect(assigns[:advance_term]).to eq(advance_term)
      end
      it 'should set @advance_rate' do
        make_request
        expect(assigns[:advance_rate]).to eq(advance_rate.to_f)
      end
      it 'should set @payment_on' do
        make_request
        expect(assigns[:payment_on]).to be_kind_of(String)
      end
      it 'should set @interest_day_count' do
        make_request
        expect(assigns[:interest_day_count]).to be_kind_of(String)
      end
      it 'should set @maturity_date' do
        make_request
        expect(assigns[:maturity_date]).to be_kind_of(String)
      end
      it 'should set @funding_date to today' do
        date = Date.new(2015,8,17)
        make_request
        expect(assigns[:funding_date]).to eq(date.iso8601)
      end
    end

    describe "POST quick_advance_low_limit_error" do
      let(:amount) { 2000 }
      it 'should render its view' do
        make_request
        expect(response.body).to render_template('dashboard/quick_advance_error')
      end
      it 'should set @advance_amount' do
        make_request
        expect(assigns[:advance_amount]).to be_kind_of(Numeric)
      end
      it 'should set @advance_type' do
        make_request
        expect(assigns[:advance_type]).to be_kind_of(String)
      end
      it 'should set @advance_term' do
        make_request
        expect(assigns[:advance_term]).to be_kind_of(String)
      end
      it 'should set @advance_rate' do
        make_request
        expect(assigns[:advance_rate]).to be_kind_of(Numeric)
      end
      it 'should set @error_message' do
        make_request
        expect(assigns[:error_message]).to eq(:low)
      end
      it 'should set @advance_description' do
        make_request
        expect(assigns[:advance_description]).to eq(advance_description)
      end
      it 'should set @advance_program' do
        make_request
        expect(assigns[:advance_program]).to eq(advance_program)
      end
    end

    describe "POST quick_advance_high_limit_error" do
      let(:amount) { 20000000000 }
      it 'should render its view' do
        make_request
        expect(response.body).to render_template('dashboard/quick_advance_error')
      end
      it 'should set @advance_amount' do
        make_request
        expect(assigns[:advance_amount]).to be_kind_of(Numeric)
      end
      it 'should set @advance_type' do
        make_request
        expect(assigns[:advance_type]).to be_kind_of(String)
      end
      it 'should set @advance_term' do
        make_request
        expect(assigns[:advance_term]).to be_kind_of(String)
      end
      it 'should set @advance_rate' do
        make_request
        expect(assigns[:advance_rate]).to be_kind_of(Numeric)
      end
      it 'should set @error_message' do
        make_request
        expect(assigns[:error_message]).to eq(:high)
      end
      it 'should set @advance_description' do
        make_request
        expect(assigns[:advance_description]).to eq(advance_description)
      end
      it 'should set @advance_program' do
        make_request
        expect(assigns[:advance_program]).to eq(advance_program)
      end
    end
  end

  describe "POST quick_advance_perform", :vcr do
    allow_policy :advances, :show?
    let(:etransact_service_instance) {EtransactAdvancesService.new(ActionDispatch::TestRequest.new)}
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

    before do
      allow(subject).to receive(:session_elevated?).and_return(true)
      allow(SecurIDService).to receive(:new).and_return(securid_service)
      allow(EtransactAdvancesService).to receive(:new).and_return(etransact_service_instance)
      allow(subject).to receive(:get_description_from_advance_term).and_return(advance_description)
      allow(subject).to receive(:get_type_from_advance_type).and_return(advance_type)
      allow(subject).to receive(:get_program_from_advance_type).and_return(advance_program)
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
    it 'should check if the rate has expired' do
      expect(subject).to receive(:advance_request_expired?)
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
    it 'should set @advance_description' do
      make_request
      expect(assigns[:advance_description]).to eq(advance_description)
    end
    it 'should set @advance_program' do
      make_request
      expect(assigns[:advance_program]).to eq(advance_program)
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
    it 'should populate the normal advance view parameters' do
      expect(subject).to receive(:populate_advance_request_view_parameters)
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

    describe 'with an expired rate' do
      before do
        allow(subject).to receive(:advance_request_expired?).and_return(true)
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
      it 'should not exeucte the advance' do
        expect_any_instance_of(EtransactAdvancesService).to_not receive(:quick_advance_execute)
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

  describe 'get_description_from_advance_term method' do
    %w(OVERNIGHT overnight OPEN open).each do |term|
      it "returns `#{I18n.t('dashboard.quick_advance.vrc_title')}` if it is passed `#{term}` as a term" do
        expect(subject.send(:get_description_from_advance_term, term)).to eq(I18n.t('dashboard.quick_advance.vrc_title'))
      end
    end
    it "returns `#{I18n.t('dashboard.quick_advance.frc_title')}` if it is passed anything other than `open` or `overnight` as a term" do
      expect(subject.send(:get_description_from_advance_term, 'foo')).to eq(I18n.t('dashboard.quick_advance.frc_title'))
    end
    it 'should return nil if its passed nil' do
       expect(subject.send(:get_description_from_advance_term, nil)).to be_nil
     end
  end

  describe 'get_program_from_advance_type method' do
    ['whole loan', 'WHOLE LOAN', 'wholeloan', 'WHOLELOAN', 'whole', 'WHOLE'].each do |type|
      it "returns `#{I18n.t('dashboard.quick_advance.table.axes_labels.standard')}` if it is passed `#{type}` as a type" do
        expect(subject.send(:get_program_from_advance_type, type)).to eq(I18n.t('dashboard.quick_advance.table.axes_labels.standard'))
      end
    end
     ['SBC-AGENCY', 'SBC-AAA', 'SBC-AA', 'sbc-agency', 'sbc-aaa', 'sbc-aa', 'AGENCY', 'agency', 'AAA', 'aaa', 'AA', 'aa'].each do |type|
       it "returns `#{I18n.t('dashboard.quick_advance.table.axes_labels.securities_backed')}` if it is passed `#{type}` as a type" do
         expect(subject.send(:get_program_from_advance_type, type)).to eq(I18n.t('dashboard.quick_advance.table.axes_labels.securities_backed'))
       end
     end
     it 'should return nil if its passed nil' do
       expect(subject.send(:get_program_from_advance_type, nil)).to be_nil
     end
  end

  describe 'get_type_from_advance_type method' do
    ['whole loan', 'WHOLE LOAN', 'wholeloan', 'WHOLELOAN', 'whole', 'WHOLE'].each do |type|
      it "returns `#{I18n.t('dashboard.quick_advance.table.whole_loan')}` if it is passed `#{type}` as a type" do
        expect(subject.send(:get_type_from_advance_type, type)).to eq(I18n.t('dashboard.quick_advance.table.whole_loan'))
      end
    end
    ['SBC-AGENCY', 'sbc-agency', 'AGENCY', 'agency'].each do |type|
      it "returns `#{I18n.t('dashboard.quick_advance.table.agency')}` if it is passed `#{type}` as a type" do
        expect(subject.send(:get_type_from_advance_type, type)).to eq(I18n.t('dashboard.quick_advance.table.agency'))
      end
    end
    ['SBC-AAA', 'sbc-aaa', 'aaa', 'AAA'].each do |type|
      it "returns `#{I18n.t('dashboard.quick_advance.table.aaa')}` if it is passed `#{type}` as a type" do
        expect(subject.send(:get_type_from_advance_type, type)).to eq(I18n.t('dashboard.quick_advance.table.aaa'))
      end
    end
    ['SBC-AA', 'sbc-aa', 'aa', 'AA'].each do |type|
      it "returns `#{I18n.t('dashboard.quick_advance.table.aa')}` if it is passed `#{type}` as a type" do
        expect(subject.send(:get_type_from_advance_type, type)).to eq(I18n.t('dashboard.quick_advance.table.aa'))
      end
    end
    it 'should return nil if its passed nil' do
      expect(subject.send(:get_type_from_advance_type, nil)).to be_nil
    end
  end

  describe '`get_type_from_advance_type` method' do
    before do
      stub_const('DashboardController::COLLATERAL_TYPE_MAPPING', :[] => double('A Value'))
    end
    it 'should call `to_sym` on the advance_type' do
      advance_type = double('An Advance Type')
      expect(advance_type).to receive(:to_sym)
      subject.send(:get_collateral_type_from_advance_type, advance_type)
    end
    it 'should look the symbol up in the COLLATERAL_TYPE_MAPPING and return the found value' do
      advance_type = double('An Advance Type', to_sym: double('An Advance Type Symbol'))
      mapped_value = double('A Mapped Value')
      allow(subject.class::COLLATERAL_TYPE_MAPPING).to receive(:[]).with(advance_type.to_sym).and_return(mapped_value)
      expect(subject.send(:get_collateral_type_from_advance_type, advance_type)).to eq(mapped_value)
    end
    it 'should return nil if its passed nil' do
      expect(subject.send(:get_collateral_type_from_advance_type, nil)).to be_nil
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
    before do
      allow(subject).to receive(:get_description_from_advance_term).and_return(nil)
      allow(subject).to receive(:get_program_from_advance_type).and_return(nil)
      allow(subject).to receive(:get_type_from_advance_type).and_return(nil)
    end
    it 'should get the advance_request_parameters' do
      expect(subject).to receive(:advance_request_parameters).with(no_args)
      call_method
    end
    {
      authorized_amount: :authorized_amount,
      exception_message: :exception_message,
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
      funding_date: :funding_date,
      maturity_date: :maturity_date,
      initiated_at: :initiated_at,
      advance_number: :confirmation_number,
      advance_amount: {key: :advance_amount, chain: [:to_f]},
      advance_term: :advance_term,
      advance_rate: {key: :advance_rate, chain: [:to_f]},
      advance_description: {key: :advance_term, method: :get_description_from_advance_term},
      advance_type: {key: :advance_type, method: :get_type_from_advance_type},
      advance_type_raw: :advance_type,
      advance_program: {key: :advance_type, method: :get_program_from_advance_type},
      collateral_type: {key: :advance_type, method: :get_collateral_type_from_advance_type}
    }.each do |param, key|
      if key.is_a?(Hash)
        chain = key[:chain]
        method = key[:method]
        key = key[:key]
      end
      it "should populate the view variable `@#{param}` with the value found in the advance_request_parameters under key `#{key}`" do
        value = double("Advance Request Parameter: #{key}")
        if chain || method
          intermediary_value = value
          value = double('Processed Value')
          allow(intermediary_value).to receive_message_chain(*chain).and_return(value) if chain
          allow(subject).to receive(method).with(intermediary_value).and_return(value) if method
          allow(subject).to receive(:advance_request_parameters).and_return({key => intermediary_value})
        else
          allow(subject).to receive(:advance_request_parameters).and_return({key => value})
        end
        call_method
        expect(assigns[param]).to eq(value)
      end
      it "should populate the view variable `@#{param}` with nil if no value was found in the advance_request_parameters under key `#{key}`" do
        call_method
        expect(assigns).to include(param)
        expect(assigns[param]).to eq(nil)
      end
    end
  end
  describe '`advance_request_expired?` method' do
    let(:rate_timeout) { rand(3..60) }
    let(:call_method) { subject.send(:advance_request_expired?) }
    let(:now) { Time.zone.now }
    before do
      allow_any_instance_of(EtransactAdvancesService).to receive(:settings).and_return({rate_timeout: rate_timeout})
      allow(Time.zone).to receive(:now).and_return(now)
    end
    it_should_behave_like 'an advance_request method', :advance_request_expired?
    it 'should get the rate timeout from the etransact service' do
      expect_any_instance_of(EtransactAdvancesService).to receive(:settings).and_return({})
      call_method
    end
    it 'returns true if the advance_request timestamp + the rate timeout < now' do
      session[:advance_request] = {'timestamp' => now - (rate_timeout + 0.1).seconds}
      expect(call_method).to be(true)
    end
    it 'returns true if the advance_request timestamp + the rate timeout == now' do
      session[:advance_request] = {'timestamp' => now - rate_timeout.seconds}
      expect(call_method).to be(true)
    end
    it 'returns false if the advance_request timestamp + the rate timeout > now' do
      session[:advance_request] = {'timestamp' => now - (rate_timeout - 0.1).seconds}
      expect(call_method).to be(false)
    end
    it 'returns false if the advance_request timestamp is missing' do
      expect(call_method).to be(false)
    end
    it 'raises an error if the etransact settings can\'t be retrieved' do
      allow_any_instance_of(EtransactAdvancesService).to receive(:settings).and_return(nil)
      expect{call_method}.to raise_error
    end
  end
  describe '`advance_request_parameters` method' do
    let(:request_params) { double('Request Params') }
    before do
      allow(request_params).to receive(:with_indifferent_access).and_return(request_params)
    end
    it_should_behave_like 'an advance_request method', :advance_request_parameters
    it 'stores the supplied parameters' do
      session[:advance_request] = {}
      expect(session[:advance_request]).to receive(:[]=).with('parameters', request_params)
      subject.send(:advance_request_parameters, request_params)
    end
    it 'returns the stored parameters when called without any arguments' do
      session[:advance_request] = {'parameters' => request_params}
      expect(subject.send(:advance_request_parameters)).to eq(request_params)
    end
    it 'returns the stored parameters when called with parameters' do
      expect(subject.send(:advance_request_parameters, request_params)).to eq(request_params)
    end
    it 'returns the result of calling `with_indifferent_access` on the paramters' do
      indifferent_request_params = double('Indifferent Request Params')
      allow(request_params).to receive(:with_indifferent_access).and_return(indifferent_request_params)
      expect(subject.send(:advance_request_parameters, request_params)).to eq(indifferent_request_params)
    end
  end
  describe '`advance_request_timestamp!` method' do
    it 'should set the advance request timestamp field to now' do
      now = double('A DateTime')
      allow(Time.zone).to receive(:now).and_return(now)
      subject.send(:advance_request_timestamp!)
      expect(session['advance_request']['timestamp']).to eq(now)
    end
    it_should_behave_like 'an advance_request method', :advance_request_timestamp!
  end

  describe 'the `check_advance_rate` method' do
    let(:old_rate) { rand() }
    let(:new_rate) { rand() }
    let(:response_hash) { {rate: old_rate} }
    let(:service_object) { double('a service object', rate: response_hash)}
    let(:check_advance_rate) { subject.send(:check_advance_rate, 'some request', 'some type', 'some term', old_rate)}
    before do
      allow(RatesService).to receive(:new).and_return(service_object)
    end
    it 'sets `old_rate` to the rate it was passed' do
      expect(check_advance_rate[:old_rate]).to eq(old_rate)
    end
    describe 'when the rate has changed' do
      it 'sets `advance_rate` to the new rate' do
        new_response_hash = {rate: new_rate}
        allow(service_object).to receive(:rate).and_return(new_response_hash)
        expect(check_advance_rate[:advance_rate]).to eq(new_rate)
      end
      it 'sets `rate_changed` to true' do
        new_response_hash = {rate: new_rate}
        allow(service_object).to receive(:rate).and_return(new_response_hash)
        expect(check_advance_rate[:rate_changed]).to eq(true)
      end
    end
    describe 'when the rate has not changed' do
      it 'sets `advance_rate` to the old rate' do
        expect(check_advance_rate[:advance_rate]).to eq(old_rate)
      end
      it 'sets `rate_changed` to false' do
        expect(check_advance_rate[:rate_changed]).to eq(false)
      end
    end
  end

end