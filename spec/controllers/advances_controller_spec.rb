require 'rails_helper'

RSpec.describe AdvancesController, :type => :controller do
  login_user
  before do
    session[described_class::SessionKeys::MEMBER_ID] = 750
  end

  {AASM::InvalidTransition => [AdvanceRequest.new(7, 'foo'), 'executed', :default], AASM::UnknownStateMachineError => ['message'], AASM::UndefinedState => ['foo'], AASM::NoDirectAssignmentError => ['message']}.each do |exception, args|
    describe "`rescue_from` #{exception}" do
      allow_policy :advances, :show?
      let(:make_request) { get :select_rate }
      before do
        allow(subject).to receive(:fetch_advance_request)
        allow(subject).to receive(:select_rate).and_raise(exception.new(*args))
        allow(controller).to receive(:populate_advance_error_view_parameters)
      end

      it 'logs at the `info` log level' do
        allow(subject.logger).to receive(:info).and_call_original
        expect(subject.logger).to receive(:info).with(no_args) do |*args, &block|
          expect(block.call).to match(/Exception: /i)
        end.exactly(:twice)
        make_request
      end
      it 'puts the advance_request as JSON in the log' do
        expect(subject.send(:advance_request)).to receive(:to_json).and_call_original
        make_request
      end
      it 'renders the error view' do
        make_request
        expect(response).to render_template('error')
      end
    end
  end

  describe 'GET manage_advances' do
    let(:job_id) { SecureRandom.hex }
    let(:job_status) { double('JobStatus', update_attributes!: nil, id: job_id, destroy: nil, result_as_string: nil ) }
    let(:member_balance_service_job_instance) { double('member_balance_service_job_instance', job_status: job_status) }
    let(:response_hash) { double('MemberBalanceServiceHash') }
    let(:trade_date) { (Time.zone.today + (rand(1..10))).to_s }
    let(:funding_date) { (Time.zone.today + (rand(1..10))).to_s }
    let(:maturity_date) { (Time.zone.today - (rand(1..10))).to_s }
    let(:advance_number) { SecureRandom.hex }
    let(:advance_type) { SecureRandom.hex }
    let(:status) { SecureRandom.hex }
    let(:interest_rate) { rand(1..100) / 100.0 }
    let(:current_par) { rand(10000..99999) }
    let(:user) { controller.current_user }
    let(:user_id) { user.id }
    let(:member_id) { controller.current_member_id }
    let(:active_advances_response) {[{'trade_date' => trade_date, 'funding_date' => funding_date, 'maturity_date' => maturity_date, 'advance_number' => advance_number, 'advance_type' => advance_type, 'status' => status, 'interest_rate' => interest_rate, 'current_par' => current_par}]}
    let(:call_action) { get :manage }

    before do
      allow(job_status).to receive(:result_as_string).and_return(active_advances_response.to_json)
      allow(response_hash).to receive(:collect)
    end
    it_behaves_like 'a user required action', :get, :manage
    it_behaves_like 'a controller action with an active nav setting', :manage, :advances
    it { should use_before_filter(:set_html_class) }
    it 'renders the manage_advances view' do
      call_action
      expect(response.body).to render_template(:manage)
    end
    describe 'when a job_id is not present' do
      it_behaves_like 'a MemberBalanceServiceJob backed report', 'active_advances', :perform_later

      before { allow(MemberBalanceServiceJob).to receive(:perform_later).and_return(member_balance_service_job_instance) }

      it 'sets the @load_url with the appropriate params' do
        call_action
        expect(assigns[:load_url]).to eq(advances_manage_url(job_id: job_status.id))
      end
      it 'sets @advances_detail[:deferred] to true' do
        call_action
        expect(assigns[:advances_data_table][:deferred]).to eq(true)
      end
    end
    describe 'job_id present' do
      let(:call_action_with_job_id) { get :manage, job_id: job_id }
      it_behaves_like 'a JobStatus backed report'
      before do
        allow(JobStatus).to receive(:find_by).and_return(job_status)
      end
      it 'sets @advances_detail to the hash returned from the job status' do
        call_action_with_job_id
        expect(assigns[:advances_data_table][:rows][0][:columns]).to eq([{:type=>:date, :value=>trade_date}, {:type=>:date, :value=>funding_date}, {:type=>:date, :value=>maturity_date}, {:value=>advance_number}, {:value=>advance_type}, {:value=>status}, {:type=>:index, :value=>interest_rate}, {:type=>:number, :value=>current_par}])
      end
    end
  end

  describe 'GET select_rate' do
    allow_policy :advances, :show?
    let(:advance_id) { SecureRandom.uuid }
    let(:advance_amount) { double('amount') }
    let(:advance_type) { double('type') }
    let(:advance_term) { double('term') }
    let(:advance_term_type) { double('advance_term_type') }
    let(:message_service_instance) { double('service instance', todays_quick_advance_message: nil) }
    let(:etransact_service_instance) { double('service instance', etransact_status: nil, etransact_active?: nil) }
    let(:make_request) { get :select_rate }
    let(:advance_request) { double(AdvanceRequest, amount: advance_amount, type: advance_type, term: advance_term, term_type: advance_term_type, id: advance_id, :allow_grace_period= => nil, :type= => nil, :term= => nil, :amount= => nil) }
    let(:profile) { double('profile') }
    let(:member_balance_service_instance) { double('member balance service instance', profile: profile) }

    before do
      allow(MessageService).to receive(:new).and_return(message_service_instance)
      allow(EtransactAdvancesService).to receive(:new).and_return(etransact_service_instance)
      allow(subject).to receive(:advance_request).and_return(advance_request)
      allow(controller).to receive(:fetch_advance_request)
    end

    it_behaves_like 'a user required action', :get, :select_rate
    it_behaves_like 'a controller action with an active nav setting', :select_rate, :advances
    it { should use_before_filter(:fetch_advance_request) }
    it { should use_before_filter(:set_html_class) }
    it { should use_after_filter(:save_advance_request) }

    it 'renders its view' do
      make_request
      expect(response.body).to render_template('select_rate')
    end
    it 'sets @quick_advance_message from the MessageService' do
      message = double('message')
      allow(message_service_instance).to receive(:todays_quick_advance_message).and_return( message)
      make_request
      expect(assigns[:limited_pricing_message]).to eq(message)
    end
    it 'sets @etransact_status to the value returned by the EtransactAdvancesService' do
      status = double('status')
      allow(etransact_service_instance).to receive(:etransact_status).and_return(status)
      make_request
      expect(assigns[:etransact_status]).to eq(status)
    end
    it 'sets @advance_request_id' do
      make_request
      expect(assigns[:advance_request_id]).to eq(advance_id)
    end
    it 'sets @selected_amount' do
      make_request
      expect(assigns[:selected_amount]).to eq(advance_amount)
    end
    it 'sets @selected_type' do
      make_request
      expect(assigns[:selected_type]).to eq(advance_type)
    end
    it 'sets @selected_term' do
      make_request
      expect(assigns[:selected_term]).to eq(advance_term)
    end
    it 'sets @active_term_type from the advance request' do
      make_request
      expect(assigns[:active_term_type]).to eq(advance_term_type)
    end
    it 'sets @active_term_type to `:vrc` if the term_type of the advance request is nil' do
      allow(advance_request).to receive(:term_type)
      make_request
      expect(assigns[:active_term_type]).to eq(:vrc)
    end
    it 'enables the grace period if called before the desk closes' do
      allow(etransact_service_instance).to receive(:etransact_active?).and_return(true)
      expect(advance_request).to receive(:allow_grace_period=).with(true)
      make_request
    end
    it 'does not enable the grace period if called after the desk closes' do
      allow(etransact_service_instance).to receive(:etransact_active?).and_return(false)
      expect(advance_request).not_to receive(:allow_grace_period=)
      make_request
    end
    describe 'when there are advance_request parameters passed' do
      it 'assigns the advance_request `type` when present' do
        expect(advance_request).to receive(:type=).with(advance_type.to_s)
        get :select_rate, advance_request: {type: advance_type}
      end
      it 'assigns the advance_request `term` when present' do
        expect(advance_request).to receive(:term=).with(advance_term.to_s)
        get :select_rate, advance_request: {term: advance_term}
      end
      it 'assigns the advance_request `amount` when present' do
        expect(advance_request).to receive(:amount=).with(advance_amount.to_s)
        get :select_rate, advance_request: {amount: advance_amount}
      end
    end
    it 'sets `@profile`' do
      allow(MemberBalanceService).to receive(:new).and_return(member_balance_service_instance)
      allow(subject).to receive(:sanitize_profile_if_endpoints_disabled).with(profile).and_return(profile)
      make_request
      expect(assigns[:profile]).to eq(profile)
    end
  end

  describe 'GET fetch_rates' do
    allow_policy :advances, :show?
    let(:advance_id) { SecureRandom.uuid }
    let(:amount) {  }
    let(:rate_data) { {some: 'data'} }
    let(:RatesService) {class_double(RatesService)}
    let(:rate_service_instance) {double("rate service instance", quick_advance_rates: nil)}
    let(:advance_type) { double('advance type') }
    let(:advance_term) { double('advance term') }
    let(:advance_request) { double(AdvanceRequest, rates: rate_data, type: advance_type, term: advance_term, errors: [], id: SecureRandom.uuid, :allow_grace_period= => nil) }
    let(:make_request) { get :fetch_rates }

    before do
      allow(controller).to receive(:fetch_advance_request)
      allow(subject).to receive(:advance_request).and_return(advance_request)
    end

    it_behaves_like 'a user required action', :get, :fetch_rates
    it_behaves_like 'an authorization required method', :get, :fetch_rates, :advances, :show?
    it { should use_before_filter(:fetch_advance_request) }
    it { should use_before_filter(:set_html_class) }
    it { should use_after_filter(:save_advance_request) }

    it 'gets the rates from the advance request' do
      expect(subject).to receive(:advance_request).and_return(advance_request)
      expect(advance_request).to receive(:rates).and_return(rate_data)
      make_request
    end
    it 'render its view' do
      make_request
      expect(response.body).to render_template('fetch_rates')
    end
    it 'includes the html in its response' do
      make_request
      data = JSON.parse(response.body)
      expect(data['html']).to be_kind_of(String)
    end
    it 'includes the advance request ID in its response' do
      make_request
      data = JSON.parse(response.body)
      expect(data['id']).to eq(advance_request.id)
    end
    it 'sets @add_advances_active to the result of the `etransact_active` method on the EtransactAdvancesService' do
      add_advances_active = double('etransact active')
      allow(EtransactAdvancesService).to receive(:new).and_return(double('service instance', etransact_active?: add_advances_active))
      make_request
      expect(assigns[:add_advances_active]).to eq(add_advances_active)
    end
    it 'sets @rate_data' do
      make_request
      expect(assigns[:rate_data]).to eq(rate_data)
    end
    it 'sets @advance_terms' do
      make_request
      expect(assigns[:advance_terms]).to eq(AdvanceRequest::ADVANCE_TERMS)
    end
    it 'sets @advance_types' do
      make_request
      expect(assigns[:advance_types]).to eq(AdvanceRequest::ADVANCE_TYPES)
    end
    it 'sets @selected_type' do
      make_request
      expect(assigns[:selected_type]).to eq(advance_type)
    end
    it 'sets @selected_term' do
      make_request
      expect(assigns[:selected_term]).to eq(advance_term)
    end
  end

  describe 'POST preview' do
    allow_policy :advances, :show?
    let(:member_id) {750}
    let(:advance_id) { SecureRandom.uuid }
    let(:advance_term) {'1week'}
    let(:advance_type) {'aa'}
    let(:advance_rate) {'0.17'}
    let(:username) {'Test User'}
    let(:advance_description) {double('some description')}
    let(:advance_program) {double('some program')}
    let(:amount) { rand(100010..999999) }
    let(:interest_day_count) { 'some interest_day_count' }
    let(:payment_on) { 'some payment_on' }
    let(:maturity_date) { 'some maturity_date' }
    let(:check_capstock) { true }
    let(:check_result) {{:status => 'pass', :low => 100000, :high => 1000000000}}
    let(:error_code) { double('error code') }
    let(:error_value) { double('error value') }
    let(:make_request) { post :preview, advance_request: {term: advance_term, type: advance_type, rate: advance_rate, amount: amount, id: advance_id} }
    let(:advance_request) { double(AdvanceRequest, :type= => nil, :term= => nil, :amount= => nil, :stock_choice= => nil, validate_advance: true, errors: [], sta_debit_amount: 0, timestamp!: nil, amount: amount, id: SecureRandom.uuid) }
    before do
      allow(subject).to receive(:advance_request).and_return(advance_request)
      allow(subject).to receive(:populate_advance_summary_view_parameters)
      allow(subject).to receive(:save_advance_request)
      allow(controller).to receive(:fetch_advance_request).and_return(advance_request)
    end
    it_behaves_like 'a user required action', :post, :preview
    it_behaves_like 'an authorization required method', :post, :preview, :advances, :show?
    it { should use_before_filter(:fetch_advance_request) }
    it { should use_before_filter(:set_html_class) }
    it { should use_after_filter(:save_advance_request) }

    it 'populates the advance preview view parameters' do
      expect(subject).to receive(:populate_advance_preview_view_parameters)
      make_request
    end
    it 'renders its view' do
      make_request
      expect(response.body).to render_template('preview')
    end
    it 'sets @session_elevated to the result of calling `session_elevated?`' do
      result = double('needs securid')
      expect(subject).to receive(:session_elevated?).and_return(result)
      make_request
      expect(assigns[:session_elevated]).to be(result)
    end
    it 'validates the advance' do
      expect(advance_request).to receive(:validate_advance)
      make_request
    end
    it 'sets the advance amount if passed an amount' do
      expect(advance_request).to receive(:amount=).with(amount.to_s)
      make_request
    end
    it 'clears the capital stock choice if passed an amount' do
      expect(advance_request).to receive(:stock_choice=).with(nil)
      make_request
    end
    context 'various error states' do
      shared_examples 'an advance preview error' do
        it 'renders the error view' do
          make_request
          expect(response).to render_template(:error)
        end
      end
      describe 'limit errors' do
        let(:limit_error) { double('limit error', type: :limits, code: error_code, value: error_value) }
        before do
          allow(advance_request).to receive(:errors).and_return([limit_error])
        end
        it_behaves_like 'an advance preview error'
        it 'populates the advance error view parameters with the proper error message and error value' do
          expect(subject).to receive(:populate_advance_error_view_parameters).with({error_message: error_code, error_value: error_value})
          make_request
        end
      end
      describe 'rate errors' do
        let(:rate_error) { double('rate error', type: :rate, code: error_code) }
        before do
          allow(advance_request).to receive(:errors).and_return([rate_error])
        end
        it_behaves_like 'an advance preview error'
        it 'populates the advance error view parameters with the proper error message' do
          expect(subject).to receive(:populate_advance_error_view_parameters).with({error_message: error_code, error_value: nil})
          make_request
        end
      end
      describe 'collateral preview errors' do
        let(:collateral_error) { double('collateral error', type: :preview, code: :collateral, value: error_value) }
        before do
          allow(advance_request).to receive(:errors).and_return([collateral_error])
        end
        it_behaves_like 'an advance preview error'
        it 'populates the advance error view parameters with the proper error message and error value' do
          expect(subject).to receive(:populate_advance_error_view_parameters).with({error_message: :collateral, error_value: error_value})
          make_request
        end
      end
      describe 'other preview errors' do
        let(:preview_error) { double('preview error', type: :preview, code: :foo, value: error_value) }
        before do
          allow(advance_request).to receive(:errors).and_return([preview_error])
        end
        it_behaves_like 'an advance preview error'
        it 'populates the advance error view parameters with the proper error message and error value' do
          expect(subject).to receive(:populate_advance_error_view_parameters).with({error_message: :foo, error_value: error_value})
          make_request
        end
      end
      describe 'unknown errors' do
        let(:unknown_error) { double('unknown error', type: :foo) }
        before do
          allow(advance_request).to receive(:errors).and_return([unknown_error])
        end
        it_behaves_like 'an advance preview error'
        it 'populates the advance error view parameters with the proper error message' do
          expect(subject).to receive(:populate_advance_error_view_parameters).with({error_message: nil, error_value: nil})
          make_request
        end
      end
      describe 'error priority' do
        {
          rate: [:stale, :unknown, :settings],
          limits: [:unknown, :high, :low],
          preview: [
            :unknown, :capital_stock_offline, :credit,
            :collateral, :total_daily_limit, :disabled_product
          ],
          foo: [:unknown]
        }.each do |type, errors|
          errors.each do |error|
            it "prioritizes #{type}:#{error} over preview:capital_stock" do
              allow(advance_request).to receive(:errors).and_return([
                AdvanceRequest::Error.new(type, error),
                AdvanceRequest::Error.new(:preview, :capital_stock)
              ])
              make_request
              expect(assigns[:error_message]).to be(error)
            end
          end
        end
        it 'shows capital stock gross up if there are no other errors' do
          allow(advance_request).to receive(:errors).and_return([
            AdvanceRequest::Error.new(:preview, :capital_stock)
          ])
          make_request
          expect(response).to render_template(:capstock_purchase)
        end
      end
    end

    describe 'capital stock purchase required' do
      before do
        allow(advance_request).to receive(:errors).and_return([double('An Error', type: :preview, code: :capital_stock, value: nil)])
      end
      it 'render its view' do
        make_request
        expect(response.body).to render_template(:capstock_purchase)
      end
      it 'populates the capstock view parameters' do
        expect(controller).to receive(:populate_advance_capstock_view_parameters)
        make_request
      end
    end
  end

  describe 'POST execute' do
    allow_policy :advances, :show?
    let(:member_id) {750}
    let(:advance_id) { SecureRandom.uuid }
    let(:advance_term) { double('someterm') }
    let(:advance_type) { double('sometype') }
    let(:advance_description) {double('some description')}
    let(:advance_program) {double('some program')}
    let(:advance_rate) {'0.17'}
    let(:username) {'Test User'}
    let(:amount) { 100000 }
    let(:securid_pin) { '1111' }
    let(:securid_token) { '222222' }
    let(:make_request) { post :perform, member_id: member_id, advance_request: {term: advance_term, type: advance_type, id: advance_id}, advance_rate: advance_rate, amount: amount, securid_pin: securid_pin, securid_token: securid_token }
    let(:securid_service) { SecurIDService.new('a user', test_mode: true) }
    let(:advance_request) { double(AdvanceRequest, expired?: false, executed?: true, execute: nil, sta_debit_amount: 0, errors: [], id: SecureRandom.uuid) }

    before do
      allow(subject).to receive(:session_elevated?).and_return(true)
      allow(SecurIDService).to receive(:new).and_return(securid_service)
      allow(subject).to receive(:populate_advance_summary_view_parameters)
      allow(subject).to receive(:save_advance_request)
      allow(subject).to receive(:advance_request).and_return(advance_request)
      allow(controller).to receive(:fetch_advance_request).and_return(advance_request)
    end

    it_behaves_like 'a user required action', :post, :perform
    it_behaves_like 'an authorization required method', :post, :perform, :advances, :show?
    it { should use_before_filter(:fetch_advance_request) }
    it { should use_before_filter(:set_html_class) }
    it { should use_after_filter(:save_advance_request) }

    it 'renders the confirmation view on success' do
      make_request
      expect(response.body).to render_template(:perform)
    end
    it 'checks if the session has been elevated' do
      expect(subject).to receive(:session_elevated?).at_least(:once)
      make_request
    end
    it 'checks if the rate has expired' do
      expect(advance_request).to receive(:expired?)
      make_request
    end
    it 'populates the advance summary view parameters' do
      expect(subject).to receive(:populate_advance_summary_view_parameters)
      make_request
    end
    it 'executes the advance' do
      expect(advance_request).to receive(:execute)
      make_request
    end
    describe 'when the advance cannot be executed' do
      before { expect(advance_request).to receive(:executed?).and_return(false) }
      it 'populates the advance error view parameters' do
        expect(subject).to receive(:populate_advance_error_view_parameters)
        make_request
      end
      it 'renders the error view' do
        make_request
        expect(response.body).to render_template(:error)
      end
    end
    describe 'with unelevated session' do
      before do
        allow(subject).to receive(:session_elevated?).and_return(false)
      end
      it 'populates the preview view parameters with the securid_status, preview set to false and without calculating stock' do
        expect(subject).to receive(:populate_advance_preview_view_parameters).with({securid_status: 'invalid_pin'})
        post :perform, securid_pin: 'foo', securid_token: securid_token
      end
      it 'renders the preview view if the securid status is not :authenticated' do
        post :perform, securid_pin: 'foo', securid_token: securid_token
        expect(response.body).to render_template('preview')
      end
      it 'sets securid_status to `invalid_pin` if the pin is malformed' do
        expect(subject).to receive(:populate_advance_preview_view_parameters).with(hash_including(securid_status: 'invalid_pin'))
        post :perform, securid_pin: 'foo', securid_token: securid_token
      end
      it 'sets securid_status to `invalid_token` if the token is malformed' do
        expect(subject).to receive(:populate_advance_preview_view_parameters).with(hash_including(securid_status: 'invalid_token'))
        post :perform, securid_token: 'foo', securid_pin: securid_pin
      end
      it 'authenticates the user via RSA SecurID if the session is not elevated' do
        expect(securid_service).to receive(:authenticate).with(securid_pin, securid_token)
        make_request
      end
      it 'elevates the session if RSA SecurID authentication succeeds' do
        expect(securid_service).to receive(:authenticate).with(securid_pin, securid_token).ordered
        expect(securid_service).to receive(:authenticated?).ordered.and_return(true)
        expect(subject).to receive(:session_elevate!).ordered
        make_request
      end
      it 'does not elevate the session if RSA SecurID authentication fails' do
        expect(securid_service).to receive(:authenticate).with(securid_pin, securid_token).ordered
        expect(securid_service).to receive(:authenticated?).ordered.and_return(false)
        expect(subject).to_not receive(:session_elevate!).ordered
        make_request
      end
      it 'does not perform the advance if the session is not elevated' do
        expect(advance_request).to_not receive(:execute)
        make_request
      end
    end
    describe 'with an expired rate' do
      before do
        allow(advance_request).to receive(:expired?).and_return(true)
      end
      it 'renders the error view' do
        make_request
        expect(response.body).to render_template(:error)
      end
      it 'populates the error view parameters with an the error message of `rate_expired`' do
        expect(subject).to receive(:populate_advance_error_view_parameters).with({error_message: :rate_expired})
        make_request
      end
      it 'does not execute the advance' do
        expect(advance_request).to_not receive(:execute)
        make_request
      end
    end
  end

  describe 'private methods' do
    describe '`populate_advance_summary_view_parameters`' do
      let(:call_method) { subject.send(:populate_advance_summary_view_parameters) }
      let(:advance_request) { double('An AdvanceRequest').as_null_object }
      before do
        allow(subject).to receive(:advance_request).and_return(advance_request)
      end
      it 'gets the advance request' do
        expect(subject).to receive(:advance_request)
        call_method
      end
      {
        advance_request_id: :id,
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
        human_interest_day_count: :human_interest_day_count,
        human_payment_on: :human_payment_on,
        trade_date: :trade_date,
        funding_date: :funding_date,
        maturity_date: :maturity_date,
        initiated_at: :initiated_at,
        advance_number: :confirmation_number,
        advance_amount: :amount,
        advance_term: :human_term,
        advance_raw_term: :term,
        advance_rate: :rate,
        advance_description: :term_description,
        advance_type: :human_type,
        advance_type_raw: :type,
        advance_program: :program_name,
        collateral_type: :collateral_type,
        old_rate: :old_rate,
        rate_changed: :rate_changed?,
        total_amount: :total_amount,
        stock: :sta_debit_amount
      }.each do |param, method|
        it "populates the view variable `@#{param}` with the value found on the advance request for attribute `#{method}`" do
          value = double("Advance Request Parameter: #{method}")
          allow(advance_request).to receive(method).and_return(value)
          call_method
          expect(assigns[param]).to eq(value)
        end
      end
    end

    describe '`populate_advance_error_view_parameters`' do
      let(:argument_double) { double('some arg') }
      before { allow(controller).to receive(:populate_advance_summary_view_parameters) }
      describe 'with default arguments' do
        let(:call_method) { controller.send(:populate_advance_error_view_parameters) }
        it 'calls `populate_advance_summary_view_parameters`' do
          expect(controller).to receive(:populate_advance_summary_view_parameters)
          call_method
        end
        ['catchall_error', 'error_message', 'error_value'].each do |optional_arg|
          it "sets @#{optional_arg} to nil" do
            call_method
            expect(assigns[optional_arg.to_sym]).to be_nil
          end
        end
      end
      it 'sets @error_message to the value it was passed for `error_message`' do
        controller.send(:populate_advance_error_view_parameters, error_message: argument_double)
        expect(assigns[:error_message]).to eq(argument_double)
      end
      it 'sets @error_value to the value it was passed for `error_value`' do
        controller.send(:populate_advance_error_view_parameters, error_value: argument_double)
        expect(assigns[:error_value]).to eq(argument_double)
      end
    end

    describe '`populate_advance_capstock_view_parameters`' do
      let(:call_method) { subject.send(:populate_advance_capstock_view_parameters) }
      let(:net_stock_required) { rand(1000..1000000) }
      let(:advance_amount) { net_stock_required + rand(1000..1000000) }
      let(:summary_params) { {advance_amount: rand(1000..1000000), net_stock_required: rand(1000..1000000)} }
      before { allow(controller).to receive(:populate_advance_summary_view_parameters) }
      it 'calls `populate_advance_summary_view_parameters`' do
        expect(controller).to receive(:populate_advance_summary_view_parameters)
        call_method
      end
      it 'calculates @net_amount by subtracting net_stock_required from advance_amount' do
        controller.instance_variable_set(:@net_stock_required, net_stock_required)
        controller.instance_variable_set(:@advance_amount, advance_amount)
        call_method
        expect(assigns[:net_amount]).to eq(advance_amount.to_f - net_stock_required.to_f)
      end
    end

    describe '`populate_advance_preview_view_parameters`' do
      let(:argument_double) { double('some arg') }
      let(:call_method) { controller.send(:populate_advance_preview_view_parameters) }
      before do
        allow(controller).to receive(:session_elevated?)
        allow(controller).to receive(:populate_advance_summary_view_parameters)
        allow(controller).to receive(:current_member_name)
      end
      it 'calls `populate_advance_summary_view_parameters`' do
        expect(controller).to receive(:populate_advance_summary_view_parameters)
        call_method
      end
      it 'sets @session_elevated to the result of `session_elevated?`' do
        session_elevated = double('session elevated')
        allow(controller).to receive(:session_elevated?).and_return(session_elevated)
        call_method
        expect(assigns[:session_elevated]).to eq(session_elevated)
      end
      it 'sets @current_member_name to the result of calling `current_member_name`' do
        member_name = double('member name')
        allow(controller).to receive(:current_member_name).and_return(member_name)
        call_method
        expect(assigns[:current_member_name]).to eq(member_name)
      end
      describe 'with default arguments' do
        it 'sets @securid_status to nil' do
          call_method
          expect(assigns[:securid_status]).to be_nil
        end
      end
      it 'sets @securid_status to the securid_status it was passed' do
        securid_status = double('status')
        controller.send(:populate_advance_preview_view_parameters, securid_status: securid_status)
        expect(assigns[:securid_status]).to eq(securid_status)
      end
    end

    describe '`advance_request`' do
      let(:call_method) { subject.send(:advance_request) }
      let(:advance_request) { double(AdvanceRequest, owners: double(Set, add: nil)) }
      it 'returns a new AdvanceRequest if the controller is lacking one' do
        member_id = double('A Member ID')
        signer = double('A Signer')
        allow(subject).to receive(:current_member_id).and_return(member_id)
        allow(subject).to receive(:signer_full_name).and_return(signer)
        allow(AdvanceRequest).to receive(:new).with(member_id, signer, subject.request).and_return(advance_request)
        expect(call_method).to be(advance_request)
      end
      it 'returns the AdvanceRequest stored in `@advance_request` if present' do
        subject.instance_variable_set(:@advance_request, advance_request)
        expect(call_method).to be(advance_request)
      end
      it 'adds the current user to the owners list' do
        allow(AdvanceRequest).to receive(:new).and_return(advance_request)
        expect(advance_request.owners).to receive(:add).with(subject.current_user.id)
        call_method
      end
    end

    describe '`find_or_create_advance_request`' do
      let(:id) { double('An ID') }
      let(:call_method) { subject.send(:fetch_advance_request) }
      let(:advance_request) { double(AdvanceRequest, owners: double(Set, member?: true), class: AdvanceRequest) }

      shared_examples 'modify authorization' do
        it 'checks if the current user is allowed to modify the advance' do
          expect(subject).to receive(:authorize).with(advance_request, :modify?)
          call_method
        end
        it 'raises a Pundit::NotAuthorizedError if the user cant modify the advance' do
          allow(advance_request.owners).to receive(:member?).and_return(false)
          expect{ call_method }.to raise_error(Pundit::NotAuthorizedError)
        end
      end

      describe 'without a passed ID' do
        let(:id) { nil }
        before do
          allow(subject).to receive(:advance_request).and_return(advance_request)
        end
        it 'calls `advance_request` if the session has no ID' do
          expect(subject).to receive(:advance_request)
          subject.send(:fetch_advance_request)
        end
        include_examples 'modify authorization'
      end
      describe 'with a passed request ID' do
        before do
          allow(AdvanceRequest).to receive(:find).and_return(advance_request)
          subject.request.params[:advance_request] = {id: id}
        end
        it 'finds the AdvanceRequest by ID' do
          expect(AdvanceRequest).to receive(:find).with(id, subject.request)
          call_method
        end
        it 'assigns the AdvanceRequest to @advance_request' do
          call_method
          expect(assigns[:advance_request]).to be(advance_request)
        end
        include_examples 'modify authorization'
      end
    end

    describe '`save_advance_request`' do
      let(:id) { double('An ID') }
      let(:advance_request) { double(AdvanceRequest, id: id, save: false) }
      let(:call_method) { subject.send(:save_advance_request) }
      it 'does nothing if there is no @advance_request' do
        call_method
        expect(session[:advance_request]).to be_nil
      end
      describe 'with an AdvanceRequest' do
        before do
          subject.instance_variable_set(:@advance_request, advance_request)
        end
        it 'saves the AdvanceRequest' do
          expect(advance_request).to receive(:save)
          call_method
        end
      end
    end

    describe '`signer_full_name`' do
      let(:signer) { double('A Signer Name') }
      let(:call_method) { subject.send(:signer_full_name) }
      it 'returns the signer name from the session if present' do
        session[described_class::SessionKeys::SIGNER_FULL_NAME] = signer
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
          expect(session[described_class::SessionKeys::SIGNER_FULL_NAME]).to be(signer)
        end
        it 'returns the signer name' do
          expect(call_method).to be(signer)
        end
      end
    end

    describe '`set_html_class`' do
      it 'sets @html_class to `white-background`' do
        subject.send(:set_html_class)
        expect(assigns[:html_class]).to eq('white-background')
      end
    end
  end

end