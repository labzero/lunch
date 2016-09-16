require 'rails_helper'
include CustomFormattingHelper
include ContactInformationHelper
include ActionView::Helpers::TextHelper

RSpec.describe SecuritiesController, type: :controller do
  login_user
  let(:member_id) { rand(1000..99999) }
  before { allow(controller).to receive(:current_member_id).and_return(member_id) }

  describe 'requests hitting MemberBalanceService' do
    let(:member_balance_service_instance) { double('MemberBalanceServiceInstance') }

    before do
      allow(MemberBalanceService).to receive(:new).and_return(member_balance_service_instance)
    end

    describe 'GET manage' do
      let(:security) do
        security = {}
        [:cusip, :description, :custody_account_type, :eligibility, :maturity_date, :authorized_by, :current_par, :borrowing_capacity].each do |attr|
          security[attr] = double(attr.to_s, upcase: nil)
        end
        security
      end
      let(:call_action) { get :manage }
      let(:securities) { [security] }
      let(:status) { double('status') }
      before do
        allow(member_balance_service_instance).to receive(:managed_securities).and_return(securities)
        allow(security[:cusip]).to receive(:upcase).and_return(security[:cusip])
      end
      it_behaves_like 'a user required action', :get, :manage
      it_behaves_like 'a controller action with an active nav setting', :manage, :securities
      it 'renders the `manage` view' do
        call_action
        expect(response.body).to render_template('manage')
      end
      it 'raises an error if the managed_securities endpoint returns nil' do
        allow(member_balance_service_instance).to receive(:managed_securities).and_return(nil)
        expect{call_action}.to raise_error(StandardError)
      end
      it 'sets `@title`' do
        call_action
        expect(assigns[:title]).to eq(I18n.t('securities.manage.title'))
      end
      it 'assigns @securities_table_data the correct column_headings' do
        call_action
        expect(assigns[:securities_table_data][:column_headings]).to eq([{value: 'check_all', type: :checkbox, name: 'check_all'}, I18n.t('common_table_headings.cusip'), I18n.t('common_table_headings.description'), I18n.t('common_table_headings.status'), I18n.t('securities.manage.eligibility'), I18n.t('common_table_headings.maturity_date'), I18n.t('common_table_headings.authorized_by'), fhlb_add_unit_to_table_header(I18n.t('common_table_headings.current_par'), '$'), fhlb_add_unit_to_table_header(I18n.t('global.borrowing_capacity'), '$')])
      end
      describe 'the `columns` array in each row of @securities_table_data[:rows]' do
        describe 'the checkbox object at the first index' do
          it 'has a `type` of `checkbox`' do
            call_action
            assigns[:securities_table_data][:rows].each do |row|
              expect(row[:columns][0][:type]).to eq(:checkbox)
            end
          end
          it 'has a `name` of `securities[]`' do
            call_action
            assigns[:securities_table_data][:rows].each do |row|
              expect(row[:columns][0][:name]).to eq('securities[]')
            end
          end
          it 'has a `value` that is a JSON\'d string of the security' do
            call_action
            assigns[:securities_table_data][:rows].each do |row|
              expect(JSON.parse(row[:columns][0][:value])).to eq(JSON.parse(security.to_json))
            end
          end
          it 'has `disabled` set to `false` if there is a cusip value' do
            call_action
            assigns[:securities_table_data][:rows].each do |row|
              expect(row[:columns][0][:disabled]).to eq(false)
            end
          end
          it 'has `disabled` set to `true` if there is no cusip value' do
            security[:cusip] = nil
            allow(member_balance_service_instance).to receive(:managed_securities).and_return([security])
            call_action
            assigns[:securities_table_data][:rows].each do |row|
              expect(row[:columns][0][:disabled]).to eq(true)
            end
          end
          it 'has a `data` field that includes its status' do
            allow(Security).to receive(:human_custody_account_type_to_status).with(security[:custody_account_type]).and_return(status)
            call_action
            assigns[:securities_table_data][:rows].each do |row|
              expect(row[:columns][0][:data]).to eq({status: status})
            end
          end
        end
        [[:cusip, 1], [:description, 2], [:eligibility, 4], [:authorized_by, 6]].each do |attr_with_index|
          it "contains an object at the #{attr_with_index.last} index with the correct value for #{attr_with_index.first}" do
            call_action
            assigns[:securities_table_data][:rows].each do |row|
              expect(row[:columns][attr_with_index.last][:value]).to eq(security[attr_with_index.first])
            end
          end
          it "contains an object at the #{attr_with_index.last} index with a value of '#{I18n.t('global.missing_value')}' when the given security has no value for #{attr_with_index.first}" do
            security[attr_with_index.first] = nil
            allow(member_balance_service_instance).to receive(:managed_securities).and_return([security])
            call_action
            assigns[:securities_table_data][:rows].each do |row|
              expect(row[:columns][attr_with_index.last][:value]).to eq(I18n.t('global.missing_value'))
            end
          end
        end
        it 'contains an object at the 3 index with a value of the response from the `Security#human_custody_account_type_to_status` class method' do
          allow(Security).to receive(:human_custody_account_type_to_status).with(security[:custody_account_type]).and_return(status)
          call_action
          assigns[:securities_table_data][:rows].each do |row|
            expect(row[:columns][3][:value]).to eq(status)
          end
        end
        it 'contains an object at the 5 index with the correct value for :maturity_date and a type of `:date`' do
          call_action
          assigns[:securities_table_data][:rows].each do |row|
            expect(row[:columns][5][:value]).to eq(security[:maturity_date])
            expect(row[:columns][5][:type]).to eq(:date)
          end
        end
        [[:current_par, 7], [:borrowing_capacity, 8]].each do |attr_with_index|
          it "contains an object at the #{attr_with_index.last} index with the correct value for #{attr_with_index.first} and a type of `:number`" do
            call_action
            assigns[:securities_table_data][:rows].each do |row|
              expect(row[:columns][attr_with_index.last][:value]).to eq(security[attr_with_index.first])
              expect(row[:columns][attr_with_index.last][:type]).to eq(:number)
            end
          end
        end
      end
      it 'sets @securities_table_data[:filter]' do
        filter = {
          name: 'securities-status-filter',
          data: [
            {
              text: I18n.t('securities.manage.safekept'),
              value: 'Safekept'
            },
            {
              text: I18n.t('securities.manage.pledged'),
              value: 'Pledged'
            },
            {
              text: I18n.t('securities.manage.all'),
              value: 'all',
              active: true
            }
          ]
        }
        call_action
        expect(assigns[:securities_table_data][:filter]).to eq(filter)
      end
    end
  end

  describe 'GET `requests`' do
    let(:authorized_requests) { [] }
    let(:awaiting_authorization_requests) { [] }
    let(:securities_requests_service) { double(SecuritiesRequestService, authorized: authorized_requests, awaiting_authorization: awaiting_authorization_requests) }
    let(:call_action) { get :requests }
    before do
      allow(SecuritiesRequestService).to receive(:new).and_return(securities_requests_service)
    end

    it_behaves_like 'a user required action', :get, :requests
    it_behaves_like 'a controller action with an active nav setting', :requests, :securities

    it 'renders the `requests` view' do
      call_action
      expect(response.body).to render_template('requests')
    end
    it 'sets `@title`' do
      call_action
      expect(assigns[:title]).to eq(I18n.t('securities.requests.title'))
    end
    it 'raises an error if the `authorized` securities request endpoint returns nil' do
      allow(securities_requests_service).to receive(:authorized).and_return(nil)
      expect{call_action}.to raise_error(/SecuritiesController#requests has encountered nil/i)
    end
    it 'raises an error if the `awaiting_authorization` securities request endpoint returns nil' do
      allow(securities_requests_service).to receive(:awaiting_authorization).and_return(nil)
      expect{call_action}.to raise_error(/SecuritiesController#requests has encountered nil/i)
    end
    it 'fetches the list of authorized securities requests from the service' do
      expect(securities_requests_service).to receive(:authorized)
      call_action
    end
    it 'fetches the list of securities requests awaiting authorization from the service' do
      expect(securities_requests_service).to receive(:awaiting_authorization)
      call_action
    end
    describe '`@authorized_requests_table`' do
      it 'builds the column headers' do
        call_action
        expect(assigns[:authorized_requests_table][:column_headings]).to eq([
          I18n.t('securities.requests.columns.request_id'),
          I18n.t('common_table_headings.description'),
          I18n.t('common_table_headings.authorized_by'),
          I18n.t('securities.requests.columns.authorization_date'),
          I18n.t('common_table_headings.settlement_date'),
          I18n.t('global.actions')
        ])
      end
      it 'builds a row for each entry in the `authorized` requests' do
        3.times do
          authorized_requests << {
            request_id: double('Request ID'),
            authorized_by: double('Authorized By'),
            authorized_date: double('Authorized Date'),
            settle_date: double('Settlement Date'),
            kind: double('Kind')
          }
        end
        rows = authorized_requests.collect do |request|
          description = double('A Description')
          allow(subject).to receive(:kind_to_description).with(request[:kind]).and_return(description)
          {
            columns: [
              {value: request[:request_id]},
              {value: description},
              {value: request[:authorized_by]},
              {value: request[:authorized_date], type: :date},
              {value: request[:settle_date], type: :date},
              {value: [[I18n.t('global.view'), '#']], type: :actions}
            ]
          }
        end
        call_action
        expect(assigns[:authorized_requests_table][:rows]).to eq(rows)
      end
    end
    describe '`@awaiting_authorization_requests_table`' do
      it 'builds the column headers' do
        call_action
        expect(assigns[:awaiting_authorization_requests_table][:column_headings]).to eq([
          I18n.t('securities.requests.columns.request_id'),
          I18n.t('common_table_headings.description'),
          I18n.t('securities.requests.columns.submitted_by'),
          I18n.t('securities.requests.columns.submitted_date'),
          I18n.t('common_table_headings.settlement_date'),
          I18n.t('global.actions')
        ])
      end
      it 'builds a row for each entry in the `awaiting_authorization` requests' do
        3.times do
          awaiting_authorization_requests << {
            request_id: double('Request ID'),
            submitted_by: double('Submitted By'),
            submitted_date: double('Submitted Date'),
            settle_date: double('Settlement Date'),
            kind: double('Kind')
          }
        end
        rows = awaiting_authorization_requests.collect do |request|
          description = double('A Description')
          allow(subject).to receive(:kind_to_description).with(request[:kind]).and_return(description)
          {
            columns: [
              {value: request[:request_id]},
              {value: description},
              {value: request[:submitted_by]},
              {value: request[:submitted_date], type: :date},
              {value: request[:settle_date], type: :date},
              {value: [I18n.t('securities.requests.actions.authorize')], type: :actions}
            ]
          }
        end
        call_action
        expect(assigns[:awaiting_authorization_requests_table][:rows]).to eq(rows)
      end
      describe 'when the `current_user` can authorize securities' do
        let(:request_id) { SecureRandom.hex }
        allow_policy :security, :authorize?
        before do
          allow(subject).to receive(:kind_to_description)
        end
        it "builds rows with a link to view the submitted request for the `:action` cell" do
          awaiting_authorization_requests << {
            request_id: request_id,
            kind: 'pledge_release'
          }
          call_action
          expect(assigns[:awaiting_authorization_requests_table][:rows].length).to be > 0
          assigns[:awaiting_authorization_requests_table][:rows].each do |row|
            expect(row[:columns].last).to eq({value: [[I18n.t('securities.requests.actions.authorize'), securities_release_view_path(request_id) ]], type: :actions})
          end
        end
        {
          'pledge_release' => :securities_release_view_path,
          'safekept_release' => :securities_release_view_path,
          'pledge_intake' => :securities_pledge_view_path,
          'safekept_intake' => :securities_safekeep_view_path,
          'safekept_transfer' => :securities_transfer_view_path,
          'pledge_transfer' => :securities_transfer_view_path
        }.each do |kind, path_helper|
          it "sets the authorize action URL to `#{path_helper}` when the `kind` is `#{kind}`" do
            awaiting_authorization_requests << {
              request_id: request_id,
              kind: kind
            }
            call_action
            expect(assigns[:awaiting_authorization_requests_table][:rows].length).to be > 0
            assigns[:awaiting_authorization_requests_table][:rows].each do |row|
              expect(row[:columns].last).to eq({value: [[I18n.t('securities.requests.actions.authorize'), send(path_helper, request_id) ]], type: :actions})
            end
          end
        end
        it "sets the authorize action URL to nil when the `kind` is unknown" do
          awaiting_authorization_requests << {
            request_id: request_id,
            kind: SecureRandom.hex
          }
          call_action
          expect(assigns[:awaiting_authorization_requests_table][:rows].length).to be > 0
          assigns[:awaiting_authorization_requests_table][:rows].each do |row|
            expect(row[:columns].last).to eq({value: [[I18n.t('securities.requests.actions.authorize'), nil ]], type: :actions})
          end
        end
      end
    end
  end

  describe 'GET view_request' do
    let(:type) { SecureRandom.hex }
    let(:request_id) { SecureRandom.hex }
    let(:securities_request) { instance_double(SecuritiesRequest, kind: nil) }
    let(:service) { instance_double(SecuritiesRequestService, submitted_request: securities_request) }
    let(:call_action) { get :view_request, request_id: request_id, type: type }
    allow_policy :security, :authorize?

    before do
      allow(SecuritiesRequestService).to receive(:new).and_return(service)
      allow(controller).to receive(:populate_view_variables)
      allow(controller).to receive(:type_matches_kind).and_return(true)
    end

    it_behaves_like 'a user required action', :get, :view_request, request_id: SecureRandom.hex, type: :release
    it_behaves_like 'a controller action with an active nav setting', :view_request, :securities, request_id: SecureRandom.hex, type: :release
    it_behaves_like 'an authorization required method', :get, :view_request, :security, :authorize?, request_id: SecureRandom.hex, type: :release

    it 'raises an exception if passed an unknown type' do
      expect{call_action}.to raise_error(ArgumentError, "Unknown request type: #{type}")
    end

    {
      release: :edit_release,
      pledge: :edit_pledge,
      safekeep: :edit_safekeep,
      transfer: :edit_transfer
    }.each do |type, view|
      describe "when the `type` is `#{type}`" do
        let(:call_action) { get :view_request, request_id: request_id, type: type }
        it 'raises an ActionController::RoutingError if the service object returns nil' do
          allow(service).to receive(:submitted_request)
          expect{call_action}.to raise_error(ActionController::RoutingError, 'There has been an error and SecuritiesController#view_request has encountered nil. Check error logs.')
        end
        it 'raises an ActionController::RoutingError if the securities request kind does not match the request type param' do
          allow(controller).to receive(:type_matches_kind).and_return(false)
          expect{call_action}.to raise_error(ActionController::RoutingError, "The type specified by the `/securities/view` route does not match the @securities_request.kind. \nType: `#{type}`\nKind: `#{securities_request.kind}`")
        end
        it 'creates a new `SecuritiesRequestService` with the `current_member_id`' do
          expect(SecuritiesRequestService).to receive(:new).with(member_id, any_args).and_return(service)
          call_action
        end
        it 'creates a new `SecuritiesRequestService` with the `request`' do
          expect(SecuritiesRequestService).to receive(:new).with(anything, request).and_return(service)
          call_action
        end
        it 'calls `submitted_request` on the `SecuritiesRequestService` instance with the `request_id`' do
          expect(service).to receive(:submitted_request).with(request_id)
          call_action
        end
        it 'sets `@securities_request` to the result of `SecuritiesRequestService#request_id`' do
          call_action
          expect(assigns[:securities_request]).to eq(securities_request)
        end
        it 'calls `populate_view_variables`' do
          expect(controller).to receive(:populate_view_variables)
          call_action
        end
        it "renders the `#{view}` view" do
          call_action
          expect(response.body).to render_template(view)
        end
        it 'calls `populate_view_variables`' do
          expect(controller).to receive(:populate_view_variables).with(type)
          call_action
        end
      end
    end
    it 'sets `@title` appropriately when the `type` is `:transfer` and the `kind` is `:pledge_transfer`' do
      allow(securities_request).to receive(:kind).and_return(:pledge_transfer)
      get :view_request, request_id: request_id, type: :transfer
      expect(assigns[:title]).to eq(I18n.t('securities.transfer.pledge.title'))
    end
    it 'sets `@title` appropriately when the `type` is `:transfer` and the `kind` is `:safekept_transfer`' do
      allow(securities_request).to receive(:kind).and_return(:safekept_transfer)
      get :view_request, request_id: request_id, type: :transfer
      expect(assigns[:title]).to eq(I18n.t('securities.transfer.safekeep.title'))
    end
  end

  context 'edit securities requests (pledged, safekept, release, transfer)' do
    let(:securities_request) { double(SecuritiesRequest,
                                              :settlement_date => Time.zone.now,
                                              :trade_date => Time.zone.now,
                                              :transaction_code => SecuritiesRequest::TRANSACTION_CODES.values[rand(0..1)],
                                              :settlement_type => SecuritiesRequest::SETTLEMENT_TYPES.values[rand(0..1)],
                                              :delivery_type => SecuritiesRequest::DELIVERY_TYPES.values[rand(0..3)],
                                              :securities => {},
                                              :pledged_account= => nil,
                                              :safekept_account= => nil,
                                              :kind= => nil) }
    let(:member_service_instance) { double('MembersService') }
    let(:member_details) {{
      'pledged_account_number' => rand(999..9999),
      'unpledged_account_number' => rand(999..9999)
    }}
    before do
      allow(MembersService).to receive(:new).with(request).and_return(member_service_instance)
      allow(SecuritiesRequest).to receive(:new).and_return(securities_request)
      allow(member_service_instance).to receive(:member).with(anything).and_return(member_details)
      allow(controller).to receive(:populate_view_variables) do
        controller.instance_variable_set(:@securities_request, securities_request)
      end
    end

    describe 'GET edit_pledge' do
      let(:call_action) { get :edit_pledge }

      it_behaves_like 'a user required action', :get, :edit_pledge
      it_behaves_like 'a controller action with an active nav setting', :edit_pledge, :securities

      it 'calls `populate_view_variables`' do
        expect(subject).to receive(:populate_view_variables).with(:pledge)
        call_action
      end
      it 'gets the `pledged_account_number` from the `MembersService` and assigns to `@securities_request.pledged_account`' do
        expect(securities_request).to receive(:pledged_account=).with(member_details['pledged_account_number'])
        call_action
      end
      it 'assigns `@securities_request.kind` a value of `:pledge_intake`' do
        expect(securities_request).to receive(:kind=).with(:pledge_intake)
        call_action
      end
      it 'renders its view' do
        call_action
        expect(response.body).to render_template('edit_pledge')
      end
    end

    describe 'GET edit_safekeep' do
      let(:call_action) { get :edit_safekeep }

      it_behaves_like 'a user required action', :get, :edit_safekeep
      it_behaves_like 'a controller action with an active nav setting', :edit_safekeep, :securities

      it 'calls `populate_view_variables`' do
        expect(subject).to receive(:populate_view_variables).with(:safekeep)
        call_action
      end
      it 'gets the `unpledged_account_number` from the `MembersService` and assigns to `@securities_request.safekept_account`' do
        expect(securities_request).to receive(:safekept_account=).with(member_details['unpledged_account_number'])
        call_action
      end
      it 'assigns `@securities_request.kind` a value of `:safekept_intake`' do
        expect(securities_request).to receive(:kind=).with(:safekept_intake)
        call_action
      end
      it 'renders its view' do
        call_action
        expect(response.body).to render_template('edit_safekeep')
      end
    end

    describe 'POST edit_release' do
      let(:security) { instance_double(Security, custody_account_type: ['U', 'P'].sample) }
      let(:call_action) { post :edit_release }
      before { allow(securities_request).to receive(:securities).and_return([security]) }

      it_behaves_like 'a user required action', :post, :edit_release
      it_behaves_like 'a controller action with an active nav setting', :edit_release, :securities
      it 'renders its view' do
        call_action
        expect(response.body).to render_template('edit_release')
      end
      it 'calls `populate_view_variables`' do
        expect(controller).to receive(:populate_view_variables)
        call_action
      end
      it 'raises an exception if there are no `securities` for the @security_request' do
        allow(securities_request).to receive(:securities).and_return(nil)
        expect{post :edit_release}.to raise_exception(ArgumentError, 'Securities cannot be nil')
      end
      describe 'when the `securities` have a `custody_account_type` of `U`' do
        before { allow(security).to receive(:custody_account_type).and_return('U') }
        it 'assigns the `@securities_request.kind` a value of `:safekept_release`' do
          expect(securities_request).to receive(:kind=).with(:safekept_release)
          call_action
        end
      end
      describe 'when the `securities` have a `custody_account_type` of `P`' do
        before { allow(security).to receive(:custody_account_type).and_return('P') }
        it 'assigns the `@securities_request.kind` a value of `:pledge_release`' do
          expect(securities_request).to receive(:kind=).with(:pledge_release)
          call_action
        end
      end
      describe 'when the `securities` have a `custody_account_type` that is neither `P` nor `U`' do
        before { allow(security).to receive(:custody_account_type).and_return(SecureRandom.hex) }
        it 'raises an exception' do
          expect{call_action}.to raise_error(ArgumentError, 'Unrecognized `custody_account_type` for passed security.')
        end
      end
    end

    describe 'POST edit_transfer' do
      let(:security) { instance_double(Security, custody_account_type: ['U', 'P'].sample) }
      let(:call_action) { post :edit_transfer }
      before { allow(securities_request).to receive(:securities).and_return([security]) }

      it_behaves_like 'a user required action', :post, :edit_transfer
      it_behaves_like 'a controller action with an active nav setting', :edit_transfer, :securities
      it 'renders its view' do
        call_action
        expect(response.body).to render_template('edit_transfer')
      end
      it 'calls `populate_view_variables`' do
        expect(controller).to receive(:populate_view_variables)
        call_action
      end
      it 'gets the `pledged_account_number` from the `MembersService` and assigns to `@securities_request.pledged_account`' do
        expect(securities_request).to receive(:pledged_account=).with(member_details['pledged_account_number'])
        call_action
      end
      it 'gets the `unpledged_account_number` from the `MembersService` and assigns to `@securities_request.safekept_account`' do
        expect(securities_request).to receive(:safekept_account=).with(member_details['unpledged_account_number'])
        call_action
      end
      it 'raises an exception if there are no `securities` for the @security_request' do
        allow(securities_request).to receive(:securities).and_return(nil)
        expect{post :edit_transfer}.to raise_error(NoMethodError)
      end
      describe 'when the `securities` have a `custody_account_type` of `U`' do
        before { allow(security).to receive(:custody_account_type).and_return('U') }
        it 'assigns the `@securities_request.kind` a value of `:pledge_transfer`' do
          expect(securities_request).to receive(:kind=).with(:pledge_transfer)
          call_action
        end
        it 'sets the @title appropriately' do
          call_action
          expect(assigns[:title]).to eq(I18n.t('securities.transfer.pledge.title'))
        end
      end
      describe 'when the `securities` have a `custody_account_type` of `P`' do
        before { allow(security).to receive(:custody_account_type).and_return('P') }
        it 'assigns the `@securities_request.kind` a value of `:safekept_transfer`' do
          expect(securities_request).to receive(:kind=).with(:safekept_transfer)
          call_action
        end
        it 'sets the @title appropriately' do
          call_action
          expect(assigns[:title]).to eq(I18n.t('securities.transfer.safekeep.title'))
        end
      end
      describe 'when the `securities` have a `custody_account_type` that is neither `P` nor `U`' do
        before { allow(security).to receive(:custody_account_type).and_return(SecureRandom.hex) }
        it 'raises an exception' do
          expect{call_action}.to raise_error(ArgumentError, 'Unrecognized `custody_account_type` for passed security.')
        end
      end
    end
  end

  [:release, :transfer].each do |type|
    action = :"download_#{type}"
    describe "POST download_#{action}" do
      let(:security) { instance_double(Security) }
      let(:security_1) {{
        "cusip" => SecureRandom.hex,
        "description" => SecureRandom.hex
      }}
      let(:security_2) {{
        "cusip" => SecureRandom.hex,
        "description" => SecureRandom.hex
      }}
      let(:securities) { [security_1, security_2] }
      let(:call_action) { post action, securities: securities.to_json }

      before do
        allow(controller).to receive(:populate_securities_table_data_view_variable)
      end

      it_behaves_like 'a user required action', :post, action
      it 'builds `Security` instances from the POSTed array of json objects' do
        expect(Security).to receive(:from_hash).with(securities[0]).ordered
        expect(Security).to receive(:from_hash).with(securities[1]).ordered
        call_action
      end
      it "calls `populate_securities_table_data_view_variable` with `#{type}` and the securities array" do
        allow(Security).to receive(:from_hash).and_return(security)
        expect(controller).to receive(:populate_securities_table_data_view_variable).with(type, [security, security])
        call_action
      end
      it 'responds with an xlsx file' do
        call_action
        expect(response.headers['Content-Disposition']).to eq('attachment; filename="securities.xlsx"')
      end
    end
  end

  describe 'GET download_safekeep' do
    let(:call_action) { post :download_safekeep }

    it 'calls `populate_securities_table_data_view_variable` without securities' do
      expect(controller).to receive(:populate_securities_table_data_view_variable).with(:safekeep)
      call_action
    end

    it 'responds with an xlsx file' do
      call_action
      expect(response.headers['Content-Disposition']).to eq('attachment; filename="securities.xlsx"')
    end
  end

  describe 'GET download_pledge' do
    let(:call_action) { post :download_pledge }

    it 'calls `populate_securities_table_data_view_variable` without securities' do
      expect(controller).to receive(:populate_securities_table_data_view_variable).with(:pledge)
      call_action
    end

    it 'responds with an xlsx file' do
      call_action
      expect(response.headers['Content-Disposition']).to eq('attachment; filename="securities.xlsx"')
    end
  end

  describe 'POST upload_securities' do
    shared_examples 'an upload_securities action with a type' do |type|
      uploaded_file = excel_fixture_file_upload('sample-securities-upload.xlsx')
      headerless_file = excel_fixture_file_upload('sample-securities-upload-headerless.xlsx')
      let(:security) { instance_double(Security, :valid? => true) }
      let(:invalid_security) { instance_double(Security, :valid? => false, errors: {}) }
      let(:sample_securities_upload_array) { [security,security,security,security,security] }
      let(:html_response_string) { SecureRandom.hex }
      let(:form_fields_html_response_string) { SecureRandom.hex }
      let(:parsed_response_body) { call_action; JSON.parse(response.body).with_indifferent_access }
      let(:cusip) { SecureRandom.hex }
      let(:description) { SecureRandom.hex }
      let(:original_par) { rand(1000..1000000) }
      let(:payment_amount) { rand(1000..1000000) }
      let(:custodian_name) { SecureRandom.hex }
      let(:error) { instance_double(MAPIService::Error) }
      let(:error_message) { SecureRandom.hex }
      let(:call_action) { post :upload_securities, file: uploaded_file, type: type }

      before do
        allow(controller).to receive(:populate_securities_table_data_view_variable)
        allow(controller).to receive(:render_to_string)
        allow(Security).to receive(:from_hash).and_return(security)
        allow(controller).to receive(:prioritized_security_error)
      end

      it_behaves_like 'a user required action', :post, :upload_securities, type: type
      it 'succeeds' do
        call_action
        expect(response.status).to eq(200)
      end
      it 'renders the view to a string with `layout` set to false' do
        expect(controller).to receive(:render_to_string).with(:upload_table, layout: false, locals: { type: type})
        call_action
      end
      it 'calls `populate_securities_table_data_view_variable` with the securities' do
        expect(controller).to receive(:populate_securities_table_data_view_variable).with(type, sample_securities_upload_array)
        call_action
      end
      it 'begins parsing data in the row and cell underneath the `cusip` header cell' do
        allow(Roo::Spreadsheet).to receive(:open).and_return(securities_rows_padding)
        expect(Security).to receive(:from_hash).with(security_hash).and_return(security)
        call_action
      end
      it 'returns a json object with `html`' do
        allow(controller).to receive(:render_to_string).with(:upload_table, layout: false, locals: { type: type}).and_return(html_response_string)
        call_action
        expect(parsed_response_body[:html]).to eq(html_response_string)
      end
      it 'returns a json object with `form_data` equal to the JSONed securities' do
        call_action
        expect(parsed_response_body[:form_data]).to eq(sample_securities_upload_array.to_json)
      end
      it 'returns a json object with a nil value for `error`' do
        call_action
        expect(parsed_response_body[:error]).to be_nil
      end
      it 'does not add invalid securities to its `form_data` response' do
        allow(Security).to receive(:from_hash).and_return(security, invalid_security)
        expect(parsed_response_body[:form_data]).to eq([security].to_json)
      end
      describe 'security validations' do
        describe 'when a security is invalid' do
          before do
            allow(Security).to receive(:from_hash).and_return(security, invalid_security, invalid_security, security, security)
          end
          describe 'when there is not an invalid CUSIP present' do
            before { allow(invalid_security).to receive(:errors).and_return({foo: ['some message']}) }
            it 'calls `prioritized_security_error` with the first invalid security it encounters' do
              expect(controller).to receive(:prioritized_security_error).with(invalid_security).exactly(:once)
              call_action
            end
            it 'returns a json object with an error message that is the result of calling `prioritized_security_error`' do
              allow(controller).to receive(:prioritized_security_error).and_return(error_message)
              call_action
              expect(parsed_response_body[:error]).to eq(simple_format(error_message))
            end
          end
          describe 'when there is an invalid CUSIP present' do
            let(:invalid_cusip_1) { SecureRandom.hex }
            let(:invalid_cusip_2) { SecureRandom.hex }

            before do
              allow(invalid_security).to receive(:errors).and_return({cusip: ['some message']})
              allow(invalid_security).to receive(:cusip).and_return(invalid_cusip_1, invalid_cusip_2)
            end

            it 'returns a json object with an error message that enumerates the invalid cusips if they are present' do
              call_action
              expect(parsed_response_body[:error]).to eq(simple_format(I18n.t('securities.upload_errors.invalid_cusips', cusips: [invalid_cusip_1, invalid_cusip_2].join(', '))))
            end
            it 'prioritizes blank CUSIP errors over invalid CUSIP errors' do
              allow(invalid_security).to receive(:cusip).and_return('', invalid_cusip_2)
              call_action
              expect(parsed_response_body[:error]).to eq(simple_format(I18n.t('activemodel.errors.models.security.blank')))
            end
          end
        end
      end
      describe 'when the uploaded file does not contain a header row with `CUSIP` as a value' do
        let(:call_action) { post :upload_securities, file: headerless_file, type: type }
        it 'renders a json object with a nil value for `html`' do
          call_action
          expect(parsed_response_body[:html]).to be_nil
        end
        it 'renders a json object with a generic error messages' do
          call_action
          expect(parsed_response_body[:error]).to eq(simple_format(I18n.t('securities.upload_errors.generic')))
        end
      end
      describe 'when the MIME type of the uploaded file is not in the list of accepted types' do
        let(:incorrect_mime_type) { fixture_file_upload('sample-securities-upload.xlsx', 'text/html') }
        let(:call_action) { post :upload_securities, file: incorrect_mime_type, type: type }
        let(:parsed_response_body) { call_action; JSON.parse(response.body).with_indifferent_access }
        it 'renders a json object with a specific error messages' do
          call_action
          expect(parsed_response_body[:error]).to eq(simple_format(I18n.t('securities.upload_errors.unsupported_mime_type')))
        end
        it 'renders a json object with a nil value for `html`' do
          call_action
          expect(parsed_response_body[:html]).to be_nil
        end
        it 'renders a json object with a nil value for `form_data`' do
          call_action
          expect(parsed_response_body[:form_data]).to be_nil
        end
      end
      describe 'when the XLS file does not contain any rows of securities' do
        no_securities = excel_fixture_file_upload('sample-empty-securities-upload.xlsx')
        let(:call_action) { post :upload_securities, file: no_securities, type: type }
        let(:parsed_response_body) { call_action; JSON.parse(response.body).with_indifferent_access }
        it 'renders a json object with a specific error messages' do
          call_action
          expect(parsed_response_body[:error]).to eq(simple_format(I18n.t('securities.upload_errors.no_rows')))
        end
        it 'renders a json object with a nil value for `html`' do
          call_action
          expect(parsed_response_body[:html]).to be_nil
        end
        it 'renders a json object with a nil value for `form_data`' do
          call_action
          expect(parsed_response_body[:form_data]).to be_nil
        end
      end
      [ArgumentError, IOError, Zip::ZipError].each do |error_klass|
        describe "when opening the file raises a `#{error_klass}`" do
          before { allow(Roo::Spreadsheet).to receive(:open).and_raise(error_klass) }

          it 'renders a json object with a specific error messages' do
            call_action
            expect(parsed_response_body[:error]).to eq(simple_format(I18n.t('securities.upload_errors.cannot_open')))
          end
          it 'renders a json object with a nil value for `html`' do
            call_action
            expect(parsed_response_body[:html]).to be_nil
          end
          it 'renders a json object with a nil value for `form_data`' do
            call_action
            expect(parsed_response_body[:form_data]).to be_nil
          end
        end
      end
    end

    describe 'when the type param is `release`' do
      let(:securities_rows) {[
        ['cusip', 'description', 'original par', 'settlement amount'],
        [cusip, description, original_par, payment_amount]
      ]}
      let(:securities_rows_padding) {[
        [],
        [],
        [nil, nil, 'cusip', 'description', 'original par', 'settlement amount'],
        [nil, nil, cusip, description, original_par, payment_amount]
      ]}
      let(:security_hash) {{
        cusip: cusip,
        description: description,
        original_par: original_par,
        payment_amount: payment_amount
      }}
      it_behaves_like 'an upload_securities action with a type', :release
    end

    describe 'when the type param is `transfer`' do
      let(:securities_rows) {[
        ['cusip', 'description', 'original par'],
        [cusip, description, original_par]
      ]}
      let(:securities_rows_padding) {[
        [],
        [],
        [nil, nil, 'cusip', 'description', 'original par'],
        [nil, nil, cusip, description, original_par]
      ]}
      let(:security_hash) {{
        cusip: cusip,
        description: description,
        original_par: original_par
      }}
      it_behaves_like 'an upload_securities action with a type', :transfer
    end

    [:pledge, :safekeep].each do |type|
      describe "when the type param is `#{type}`" do
        let(:securities_rows) {[
          ['cusip', 'original par', 'payment_amount', 'custodian name'],
          [cusip, original_par, payment_amount, custodian_name]
        ]}
        let(:securities_rows_padding) {[
          [],
          [],
          [nil, nil, 'cusip', 'original par', 'payment_amount', 'custodian name'],
          [nil, nil, cusip, original_par, payment_amount, custodian_name]
        ]}
        let(:security_hash) {{
          cusip: cusip,
          original_par: original_par,
          payment_amount: payment_amount,
          custodian_name: custodian_name
        }}
        it_behaves_like 'an upload_securities action with a type', type
      end
    end
  end

  describe "POST submit_request for unknown types" do
    let(:securities_request_param) { {'transaction_code' => "#{instance_double(String)}"} }
    let(:type) { SecureRandom.hex }
    let(:call_action) { post :submit_request, securities_request: securities_request_param, type: type }

    it 'raises an exception' do
      expect{call_action}.to raise_error(ArgumentError, "Unknown request type: #{type}")
    end
  end
  {
    pledge_release: [:edit_release, I18n.t('securities.authorize.release.title'), :securities_release_pledge_success_url, :release],
    safekept_release: [:edit_release, I18n.t('securities.authorize.release.title'), :securities_release_safekeep_success_url, :release],
    pledge_intake: [:edit_pledge, I18n.t('securities.authorize.pledge.title'), :securities_pledge_success_url, :pledge],
    safekept_intake: [:edit_safekeep, I18n.t('securities.authorize.safekeep.title'), :securities_safekeep_success_url, :safekeep],
    pledge_transfer: [:edit_transfer, I18n.t('securities.authorize.transfer.title'), :securities_transfer_pledge_success_url, :transfer],
    safekept_transfer: [:edit_transfer, I18n.t('securities.authorize.transfer.title'), :securities_transfer_safekeep_success_url, :transfer]
  }.each do |kind, details|
    template, title, success_path, type = details
    describe "POST submit_request for type `#{type}` and kind `#{kind}`" do
      let(:securities_request_param) { {'transaction_code' => "#{instance_double(String)}"} }
      let(:securities_request_service) { instance_double(SecuritiesRequestService, submit_request_for_authorization: true, authorize_request: true) }
      let(:active_model_errors) { instance_double(ActiveModel::Errors, add: nil) }
      let(:securities_request) { instance_double(SecuritiesRequest, :valid? => true, errors: active_model_errors, kind: kind) }
      let(:error_message) { instance_double(String) }
      let(:call_action) { post :submit_request, securities_request: securities_request_param, type: type }

      before do
        allow(controller).to receive(:current_member_id).and_return(member_id)
        allow(controller).to receive(:populate_view_variables)
        allow(controller).to receive(:prioritized_securities_request_error)
        allow(SecuritiesRequestService).to receive(:new).and_return(securities_request_service)
        allow(SecuritiesRequest).to receive(:from_hash).and_return(securities_request)
        allow(controller).to receive(:type_matches_kind).and_return(true)
        allow(controller).to receive(:populate_authorize_request_view_variables)
      end
      it 'raises an ActionController::RoutingError if the securities request kind does not match the request type param' do
        allow(controller).to receive(:type_matches_kind).and_return(false)
        expect{call_action}.to raise_error(ActionController::RoutingError, "The type specified by the `/securities/submit` route does not match the @securities_request.kind. \nType: `#{type}`\nKind: `#{securities_request.kind}`")
      end
      it 'builds a SecuritiesRequest instance with the `securities_request` params' do
        expect(SecuritiesRequest).to receive(:from_hash).with(securities_request_param)
        call_action
      end
      it 'sets @securities_request' do
        call_action
        expect(assigns[:securities_request]).to eq(securities_request)
      end
      describe 'when the securities_request is valid' do
        it 'creates a new instance of SecuritiesRequestService with the `current_member_id`' do
          expect(SecuritiesRequestService).to receive(:new).with(member_id, anything).and_return(securities_request_service)
          call_action
        end
        it 'creates a new instance of SecuritiesRequestService with the current request' do
          expect(SecuritiesRequestService).to receive(:new).with(anything, request).and_return(securities_request_service)
          call_action
        end
        it 'calls `submit_request_for_authorization` on the SecuritiesRequestService instance with the `securities_request`' do
          expect(securities_request_service).to receive(:submit_request_for_authorization).with(securities_request, anything, type).and_return(true)
          call_action
        end
        describe 'when the service object returns true' do
          it 'redirects to the `securities_release_success_url` if there are no errors' do
            allow(active_model_errors).to receive(:present?).and_return(false)
            expect(call_action).to redirect_to(send(success_path))
          end
        end
        describe 'when the service object returns nil' do
          let(:error_body) {{
            'error' => {
              'code' => SecureRandom.hex,
              'type' => SecureRandom.hex
            }
          }}
          let(:error) { instance_double(RestClient::Exception, http_body: error_body.to_json) }

          before do
            allow(securities_request_service).to receive(:submit_request_for_authorization).and_return(nil)
            allow(JSON).to receive(:parse).and_return(error_body)
          end
          describe 'when the error handler is invoked' do
            before { allow(securities_request_service).to receive(:submit_request_for_authorization).and_yield(error) }

            it 'adds an error to the securities_request instance with the given code and type' do
              expect(active_model_errors).to receive(:add).with(error_body['error']['code'].to_sym, error_body['error']['type'].to_sym)
              call_action
            end
            it 'adds an error to the securities_request instance with an attribute of `:base` when the given code is `unkown`' do
              error_body['error']['code'] = 'unknown'
              expect(active_model_errors).to receive(:add).with(:base, error_body['error']['type'].to_sym)
              call_action
            end
            it 'does not add a `:base`, `:submission` error' do
              expect(active_model_errors).not_to receive(:add).with(:base, :submission)
              call_action
            end
          end
          it 'adds a `:base`, `:submission` error if there are not yet any errors' do
            allow(active_model_errors).to receive(:present?).and_return(false)
            expect(active_model_errors).to receive(:add).with(:base, :submission)
            call_action
          end
          it "calls `populate_view_variables` with `#{type}`" do
            expect(controller).to receive(:populate_view_variables).with(type)
            call_action
          end
          it 'calls `prioritized_securities_request_error` with the securities_request instance' do
            expect(controller).to receive(:prioritized_securities_request_error).with(securities_request)
            call_action
          end
          it 'sets `@error_message` to the result of `prioritized_securities_request_error`' do
            allow(controller).to receive(:prioritized_securities_request_error).and_return(error_message)
            call_action
            expect(assigns[:error_message]).to eq(error_message)
          end
          it "renders the `#{template}` view" do
            call_action
            expect(response.body).to render_template(template)
          end

          describe 'when the user is an authorizer' do
            allow_policy :security, :authorize?
            it 'does not check the SecurID details' do
              expect(subject).to_not receive(:securid_perform_check)
              call_action
            end
          end
        end
      end
      describe 'when the securities_request is invalid' do
        before { allow(securities_request).to receive(:valid?).and_return(false) }

        it 'calls `prioritized_securities_request_error` with the securities_request instance' do
          expect(controller).to receive(:prioritized_securities_request_error).with(securities_request)
          call_action
        end
        it 'sets `@error_message` to the result of `prioritized_securities_request_error`' do
          allow(controller).to receive(:prioritized_securities_request_error).and_return(error_message)
          call_action
          expect(assigns[:error_message]).to eq(error_message)
        end
        it "renders the `#{template}` view" do
          call_action
          expect(response.body).to render_template(template)
        end
        describe 'when the user is an authorizer' do
          allow_policy :security, :authorize?
          it 'does not check the SecurID details' do
            expect(subject).to_not receive(:securid_perform_check)
            call_action
          end
        end
      end

      describe 'when the user is an authorizer' do
        let(:request_id) { double('A Request ID') }
        allow_policy :security, :authorize?
        it 'checks the SecurID details if no errors are found in the data' do
          allow(active_model_errors).to receive(:present?).and_return(false)
          expect(subject).to receive(:securid_perform_check).and_return(:authenticated)
          call_action
        end
        describe 'when SecurID passes and there are not yet any errors' do
          before do
            allow(securities_request).to receive(:request_id).and_return(request_id)
          end
          it 'checks the SecurID details if no errors are found in the data' do
            allow(active_model_errors).to receive(:present?).and_return(false)
            expect(subject).to receive(:securid_perform_check).and_return(:authenticated)
            call_action
          end
          describe 'when SecurID passes and there are not yet any errors' do
            before do
              allow(subject).to receive(:session_elevated?).and_return(true)
              allow(active_model_errors).to receive(:blank?).and_return(true)
            end
            it 'authorizes the request' do
              expect(securities_request_service).to receive(:authorize_request).with(request_id, controller.current_user)
              call_action
            end
            it 'emails the internal distro' do
              expect(InternalMailer).to receive(:securities_request_authorized).with(securities_request)
              call_action
            end
            it 'renders the `authorize_request` view' do
              call_action
              expect(response.body).to render_template(:authorize_request)
            end
            it 'calls `populate_authorize_request_view_variables` with the securities request `kind`' do
              expect(controller).to receive(:populate_authorize_request_view_variables).with(kind)
              call_action
            end
            describe 'when the authorization fails' do
              before do
                allow(securities_request_service).to receive(:authorize_request).and_return(false)
                allow(active_model_errors).to receive(:present?).and_return(false, false, true)
              end

              it 'adds an `:base`, `:authorization` error to the securities_request instance' do
                expect(active_model_errors).to receive(:add).with(:base, :authorization)
                call_action
              end
              it 'calls `prioritized_securities_request_error` with the securities_request instance' do
                expect(controller).to receive(:prioritized_securities_request_error).with(securities_request)
                call_action
              end
              it 'sets `@error_message` to the result of `prioritized_securities_request_error`' do
                allow(controller).to receive(:prioritized_securities_request_error).and_return(error_message)
                call_action
                expect(assigns[:error_message]).to eq(error_message)
              end
              it "renders the `#{template}` view" do
                call_action
                expect(response.body).to render_template(template)
              end
            end
          end
          describe 'when SecurID fails' do
            let(:securid_error) { double('A SecurID error') }
            before do
              allow(subject).to receive(:securid_perform_check).and_return(securid_error)
            end
            it 'does not authorize the request' do
              expect(securities_request_service).to_not receive(:authorize_request)
              call_action
            end
            it "renders the `#{template}` view" do
              call_action
              expect(response.body).to render_template(template)
            end
            it "calls `populate_view_variables` with `#{type}`" do
              expect(controller).to receive(:populate_view_variables).with(type)
              call_action
            end
            it 'calls `prioritized_securities_request_error` with the securities_request instance' do
              expect(controller).to receive(:prioritized_securities_request_error).with(securities_request)
              call_action
            end
            it 'sets `@error_message` to the result of `prioritized_securities_request_error`' do
              allow(controller).to receive(:prioritized_securities_request_error).and_return(error_message)
              call_action
              expect(assigns[:error_message]).to eq(error_message)
            end
          end
        end
      end
    end
  end

  describe 'GET `submit_request_success`' do
    request_kind_translations = {
      pledge_release: [I18n.t('securities.success.titles.pledge_release'), I18n.t('securities.success.email.subjects.pledge_release')],
      safekept_release: [I18n.t('securities.success.titles.safekept_release'), I18n.t('securities.success.email.subjects.safekept_release')],
      pledge_intake: [I18n.t('securities.success.titles.pledge_intake'), I18n.t('securities.success.email.subjects.pledge_intake')],
      safekept_intake: [I18n.t('securities.success.titles.safekept_intake'), I18n.t('securities.success.email.subjects.safekept_intake')],
      pledge_transfer: [I18n.t('securities.success.titles.transfer'), I18n.t('securities.success.email.subjects.transfer')],
      safekept_transfer: [I18n.t('securities.success.titles.transfer'), I18n.t('securities.success.email.subjects.transfer')]
    }
    let(:member_service_instance) {double('MembersService')}
    let(:user_no_roles) {{display_name: 'User With No Roles', roles: [], surname: 'With No Roles', given_name: 'User'}}
    let(:user_etransact) {{display_name: 'Etransact User', roles: [User::Roles::ETRANSACT_SIGNER], surname: 'User', given_name: 'Etransact'}}
    let(:user_a) { {display_name: 'R&A User', roles: [User::Roles::SIGNER_MANAGER], given_name: 'R&A', surname: 'User'} }
    let(:user_b) { {display_name: 'Collateral User', roles: [User::Roles::COLLATERAL_SIGNER], given_name: 'Collateral', surname: 'User'} }
    let(:user_c) { {display_name: 'Securities User', roles: [User::Roles::SECURITIES_SIGNER], given_name: 'Securities', surname: 'User'} }
    let(:user_d) { {display_name: 'No Surname', roles: [User::Roles::WIRE_SIGNER], given_name: 'No', surname: nil} }
    let(:user_e) { {display_name: 'No Given Name', roles: [User::Roles::WIRE_SIGNER], given_name: nil, surname: 'Given'} }
    let(:user_f) { {display_name: 'Entire Authority User', roles: [User::Roles::SIGNER_ENTIRE_AUTHORITY], given_name: 'Entire Authority', surname: 'User'} }
    let(:signers_and_users) {[user_no_roles, user_etransact, user_a, user_b, user_c, user_d, user_e, user_f]}
    before do
      allow(MembersService).to receive(:new).and_return(member_service_instance)
      allow(member_service_instance).to receive(:signers_and_users).and_return(signers_and_users)
    end

    it_behaves_like 'a user required action', :get, :submit_request_success

    request_kind_translations.each do |kind, translations|
      title, email_subject = translations
      let(:call_action) { get :submit_request_success, kind: kind }
      it_behaves_like 'a controller action with an active nav setting', :submit_request_success, :securities, kind: kind
      it 'renders the `submit_request_success` view' do
        call_action
        expect(response.body).to render_template('submit_request_success')
      end
      it "sets `@title` to `#{title}` when the `kind` param is `#{kind}`" do
        get :submit_request_success, kind: kind
        expect(assigns[:title]).to eq(title)
      end
      it "sets `@email_subject` to `#{email_subject}` when the `kind` param is `#{kind}`" do
        get :submit_request_success, kind: kind
        expect(assigns[:email_subject]).to eq(email_subject)
      end
      it 'renders the `submit_request_success` view' do
        call_action
        expect(response.body).to render_template('submit_request_success')
      end
      it "sets `@title` to `#{title}` when the `type` param is `#{kind}`" do
        get :submit_request_success, kind: kind
        expect(assigns[:title]).to eq(title)
      end
      it 'sets `@authorized_user_data` to a list of users with securities authority' do
        call_action
        expect(assigns[:authorized_user_data]).to eq([user_c])
      end
      it 'sets `@authorized_user_data` to [] if no users are found' do
        allow(member_service_instance).to receive(:signers_and_users).and_return([])
        call_action
        expect(assigns[:authorized_user_data]).to eq([])
      end
    end
  end

  describe 'DELETE delete_request' do
    allow_policy :security, :delete?
    let(:request_id) { SecureRandom.hex }
    let(:securities_request_service) { instance_double(SecuritiesRequestService, delete_request: true) }
    let(:call_action) { delete :delete_request, request_id: request_id }
    before { allow(SecuritiesRequestService).to receive(:new).and_return(securities_request_service) }

    it_behaves_like 'a user required action', :delete, :delete_request, request_id: SecureRandom.hex
    it_behaves_like 'an authorization required method', :delete, :delete_request, :security, :delete?, request_id: SecureRandom.hex
    it 'creates a new `SecuritiesRequestService` with the `current_member_id`' do
      expect(SecuritiesRequestService).to receive(:new).with(member_id, any_args).and_return(securities_request_service)
      call_action
    end
    it 'creates a new `SecuritiesRequestService` with the `request`' do
      expect(SecuritiesRequestService).to receive(:new).with(anything, request).and_return(securities_request_service)
      call_action
    end
    it 'calls `delete_request` on the `SecuritiesRequestService` instance with the `request_id`' do
      expect(securities_request_service).to receive(:delete_request).with(request_id)
      call_action
    end
    it 'renders JSON hash with a `url` body value `securities_requests_url`' do
      call_action
      expect(JSON.parse(response.body)['url']).to eq(securities_requests_url)
    end
    it "renders JSON hash with an `error_message` body value `#{I18n.t('securities.release.delete_request.error_message')}`" do
      call_action
      expect(JSON.parse(response.body)['error_message']).to eq(I18n.t('securities.release.delete_request.error_message'))
    end
    it 'returns a 200 if the SecuritiesRequestService returns true' do
      call_action
      expect(response.status).to eq(200)
    end
    it 'returns a 404 if the SecuritiesRequestService returns false' do
      allow(securities_request_service).to receive(:delete_request).and_return(false)
      call_action
      expect(response.status).to eq(404)
    end
    it 'returns a 404 if the SecuritiesRequestService returns nil' do
      allow(securities_request_service).to receive(:delete_request).and_return(nil)
      call_action
      expect(response.status).to eq(404)
    end
  end

  describe 'private methods' do
    describe '`kind_to_description`' do
      {
        'pledge_release' => 'securities.requests.form_descriptions.release',
        'safekept_release' => 'securities.requests.form_descriptions.release',
        'pledge_intake' => 'securities.requests.form_descriptions.pledge',
        'safekept_intake' => 'securities.requests.form_descriptions.safekept'
      }.each do |form_type, description_key|
        it "returns the localization value for `#{description_key}` when passed `#{form_type}`" do
          expect(controller.send(:kind_to_description, form_type)).to eq(I18n.t(description_key))
        end
      end
      it 'returns the localization value for `global.missing_value` when passed an unknown form type' do
        expect(controller.send(:kind_to_description, double(String))).to eq(I18n.t('global.missing_value'))
      end
    end

    describe '`populate_transaction_code_dropdown_variables`' do
      transaction_code_dropdown = [
        [I18n.t('securities.release.transaction_code.standard'), SecuritiesRequest::TRANSACTION_CODES[:standard]],
        [I18n.t('securities.release.transaction_code.repo'), SecuritiesRequest::TRANSACTION_CODES[:repo]]
      ]
      let(:securities_request) { instance_double(SecuritiesRequest, transaction_code: nil) }
      let(:call_method) { controller.send(:populate_transaction_code_dropdown_variables, securities_request) }
      it 'sets `@transaction_code_dropdown`' do
        call_method
        expect(assigns[:transaction_code_dropdown]).to eq(transaction_code_dropdown)
      end
      describe 'setting `@transaction_code_defaults`' do
        describe 'when the `transaction_code` is `:standard`' do
          before { allow(securities_request).to receive(:transaction_code).and_return(:standard) }
          it "has a `text` string of `#{transaction_code_dropdown.first.first}`" do
            call_method
            expect(assigns[:transaction_code_defaults][:text]).to eq(transaction_code_dropdown.first.first)
          end
          it "has a `value` of `#{transaction_code_dropdown.first.last}`" do
            call_method
            expect(assigns[:transaction_code_defaults][:value]).to eq(transaction_code_dropdown.first.last)
          end
        end
        describe 'when the `transaction_code` is `:repo`' do
          before { allow(securities_request).to receive(:transaction_code).and_return(:repo) }
          it "has a `text` string of `#{transaction_code_dropdown.last.first}`" do
            call_method
            expect(assigns[:transaction_code_defaults][:text]).to eq(transaction_code_dropdown.last.first)
          end
          it "has a `value` of `#{transaction_code_dropdown.last.last}`" do
            call_method
            expect(assigns[:transaction_code_defaults][:value]).to eq(transaction_code_dropdown.last.last)
          end
        end
        describe 'when the `transaction_code` is neither `:standard` nor `:repo`' do
          it "has a `text` string of `#{transaction_code_dropdown.first.first}`" do
            call_method
            expect(assigns[:transaction_code_defaults][:text]).to eq(transaction_code_dropdown.first.first)
          end
          it "has a `value` of `#{transaction_code_dropdown.first.last}`" do
            call_method
            expect(assigns[:transaction_code_defaults][:value]).to eq(transaction_code_dropdown.first.last)
          end
        end
      end
    end

    describe '`populate_settlement_type_dropdown_variables`' do
      settlement_type_dropdown = [
        [I18n.t('securities.release.settlement_type.free'), SecuritiesRequest::SETTLEMENT_TYPES[:free]],
        [I18n.t('securities.release.settlement_type.vs_payment'), SecuritiesRequest::SETTLEMENT_TYPES[:vs_payment]]
      ]
      let(:securities_request) { instance_double(SecuritiesRequest, settlement_type: nil) }
      let(:call_method) { controller.send(:populate_settlement_type_dropdown_variables, securities_request) }
      it 'sets `@settlement_type_dropdown`' do
        call_method
        expect(assigns[:settlement_type_dropdown]).to eq(settlement_type_dropdown)
      end
      describe 'setting `@settlement_type_defaults`' do
        describe 'when the `settlement_type` is `:free`' do
          before { allow(securities_request).to receive(:settlement_type).and_return(:free) }
          it "has a `text` string of `#{settlement_type_dropdown.first.first}`" do
            call_method
            expect(assigns[:settlement_type_defaults][:text]).to eq(settlement_type_dropdown.first.first)
          end
          it "has a `value` of `#{settlement_type_dropdown.first.last}`" do
            call_method
            expect(assigns[:settlement_type_defaults][:value]).to eq(settlement_type_dropdown.first.last)
          end
        end
        describe 'when the `settlement_type` is `:vs_payment`' do
          before { allow(securities_request).to receive(:settlement_type).and_return(:vs_payment) }
          it "has a `text` string of `#{settlement_type_dropdown.last.first}`" do
            call_method
            expect(assigns[:settlement_type_defaults][:text]).to eq(settlement_type_dropdown.last.first)
          end
          it "has a `value` of `#{settlement_type_dropdown.last.last}`" do
            call_method
            expect(assigns[:settlement_type_defaults][:value]).to eq(settlement_type_dropdown.last.last)
          end
        end
        describe 'when the `settlement_type` is neither `:free` nor `:vs_payment`' do
          before { allow(securities_request).to receive(:settlement_type).and_return(:free) }
          it "has a `text` string of `#{settlement_type_dropdown.first.first}`" do
            call_method
            expect(assigns[:settlement_type_defaults][:text]).to eq(settlement_type_dropdown.first.first)
          end
          it "has a `value` of `#{settlement_type_dropdown.first.last}`" do
            call_method
            expect(assigns[:settlement_type_defaults][:value]).to eq(settlement_type_dropdown.first.last)
          end
        end
      end
    end

    describe '`populate_delivery_instructions_dropdown_variables`' do
      delivery_instructions_dropdown = [
        [I18n.t('securities.release.delivery_instructions.dtc'), SecuritiesRequest::DELIVERY_TYPES[:dtc]],
        [I18n.t('securities.release.delivery_instructions.fed'), SecuritiesRequest::DELIVERY_TYPES[:fed]],
        [I18n.t('securities.release.delivery_instructions.mutual_fund'), SecuritiesRequest::DELIVERY_TYPES[:mutual_fund]],
        [I18n.t('securities.release.delivery_instructions.physical_securities'), SecuritiesRequest::DELIVERY_TYPES[:physical_securities]]
      ]
      let(:securities_request) { instance_double(SecuritiesRequest, delivery_type: nil) }
      let(:call_method) { controller.send(:populate_delivery_instructions_dropdown_variables, securities_request) }
      it 'sets `@delivery_instructions_dropdown`' do
        call_method
        expect(assigns[:delivery_instructions_dropdown]).to eq(delivery_instructions_dropdown)
      end
      describe 'setting `@delivery_instructions_defaults`' do
        [:dtc, :fed, :mutual_fund, :physical_securities].each_with_index do |delivery_type, i|
          describe "when the `delivery_type` is `#{delivery_type}`" do
            before { allow(securities_request).to receive(:delivery_type).and_return(delivery_type) }
            it "has a `text` string of `#{delivery_instructions_dropdown[i].first}`" do
              call_method
              expect(assigns[:delivery_instructions_defaults][:text]).to eq(delivery_instructions_dropdown[i].first)
            end
            it "has a `value` of `#{delivery_instructions_dropdown[i].last}`" do
              call_method
              expect(assigns[:delivery_instructions_defaults][:value]).to eq(delivery_instructions_dropdown[i].last)
            end
          end
        end
        describe "when the `delivery_type` is not one of: `#{SecuritiesRequest::DELIVERY_TYPES.keys}`" do
          it "has a `text` string of `#{delivery_instructions_dropdown.first.first}`" do
            call_method
            expect(assigns[:delivery_instructions_defaults][:text]).to eq(delivery_instructions_dropdown.first.first)
          end
          it "has a `value` of `#{delivery_instructions_dropdown.first.last}`" do
            call_method
            expect(assigns[:delivery_instructions_defaults][:value]).to eq(delivery_instructions_dropdown.first.last)
          end
        end
      end
    end

    describe '`populate_view_variables`' do
      let(:member_id) { rand(1000..99999) }
      let(:security) { {
        cusip: SecureRandom.hex,
        description: SecureRandom.hex,
        original_par: SecureRandom.hex
      } }
      let(:securities) { [instance_double(Security)] }
      let(:securities_request) { instance_double(SecuritiesRequest, securities: securities, :securities= => nil, trade_date: nil, :trade_date= => nil, settlement_date: nil, :settlement_date= => nil) }
      let(:call_action) { controller.send(:populate_view_variables, :release) }
      let(:date_restrictions) { instance_double(Hash) }

      before do
        allow(SecuritiesRequest).to receive(:new).and_return(securities_request)
        allow(controller).to receive(:populate_transaction_code_dropdown_variables)
        allow(controller).to receive(:populate_settlement_type_dropdown_variables)
        allow(controller).to receive(:populate_delivery_instructions_dropdown_variables)
        allow(controller).to receive(:populate_securities_table_data_view_variable)
        allow(controller).to receive(:date_restrictions)
      end

      it 'sets `@pledge_type_dropdown`' do
        pledge_type_dropdown = [
          [I18n.t('securities.release.pledge_type.sbc'), SecuritiesRequest::PLEDGE_TO_VALUES[:sbc]],
          [I18n.t('securities.release.pledge_type.standard'), SecuritiesRequest::PLEDGE_TO_VALUES[:standard]]
        ]
        call_action
        expect(assigns[:pledge_type_dropdown]).to eq(pledge_type_dropdown)
      end
      {
        release: I18n.t('securities.release.title'),
        pledge: I18n.t('securities.pledge.title'),
        safekeep: I18n.t('securities.safekeep.title')
      }.each do |type, title|
        it "sets `@title` to `#{title}` when the `type` is `#{type}`" do
          controller.send(:populate_view_variables, type)
          expect(assigns[:title]).to eq(title)
        end
      end
      [:release, :pledge, :safekeep, :transfer].each do |type|
        it 'sets `@confirm_delete_text` appropriately' do
          controller.send(:populate_view_variables, type)
          expect(assigns[:confirm_delete_text]).to eq(I18n.t("securities.delete_request.titles.#{type}"))
        end
      end
      it 'calls `populate_transaction_code_dropdown_variables` with the @securities_request' do
        expect(controller).to receive(:populate_transaction_code_dropdown_variables).with(securities_request)
        call_action
      end
      it 'calls `populate_settlement_type_dropdown_variables` with the @securities_request' do
        expect(controller).to receive(:populate_settlement_type_dropdown_variables).with(securities_request)
        call_action
      end
      it 'calls `populate_delivery_instructions_dropdown_variables` with the @securities_request' do
        expect(controller).to receive(:populate_delivery_instructions_dropdown_variables).with(securities_request)
        call_action
      end
      it 'sets `@securities_request`' do
        call_action
        expect(assigns[:securities_request]).to eq(securities_request)
      end
      it 'creates a new instance of SecuritiesRequest if `@securities_request` not already set' do
        expect(SecuritiesRequest).to receive(:new).and_return(securities_request)
        call_action
      end
      it 'does not create a new instance of SecuritiesRequest if `securities_request` is already set' do
        controller.instance_variable_set(:@securities_request, securities_request)
        expect(SecuritiesRequest).not_to receive(:new)
        call_action
      end
      it 'sets `securities_request.securities` to the `securities` param if it is present' do
        controller.params = ActionController::Parameters.new({securities: securities})
        expect(securities_request).to receive(:securities=).with(securities)
        call_action
      end
      it 'does not set `securities_request.securities` if the `securities` param is not present' do
        expect(securities_request).not_to receive(:securities=)
        call_action
      end
      it 'sets `securities_request.trade_date` to today if there is not already a trade date' do
        expect(securities_request).to receive(:trade_date=).with(Time.zone.today)
        call_action
      end
      it 'does not set `securities_request.trade_date` if there is already a trade date' do
        allow(securities_request).to receive(:trade_date).and_return(instance_double(Date))
        expect(securities_request).not_to receive(:trade_date=)
        call_action
      end
      it 'sets `securities_request.settlement_date` to today if there is not already a settlement date' do
        expect(securities_request).to receive(:settlement_date=).with(Time.zone.today)
        call_action
      end
      it 'does not set `securities_request.settlement_date` if there is already a settlment date' do
        allow(securities_request).to receive(:settlement_date).and_return(instance_double(Date))
        expect(securities_request).not_to receive(:settlement_date=)
        call_action
      end
      it 'calls `populate_securities_table_data_view_variable` with the securities' do
        expect(controller).to receive(:populate_securities_table_data_view_variable).with(:release, securities)
        call_action
      end
      it 'sets the proper @form_data for a user to submit a request for authorization' do
        form_data = {
          url: securities_release_submit_path,
          submit_text: I18n.t('securities.release.submit_authorization')
        }
      end
      it 'sets `@date_restrictions` to the result of calling the `date_restrictions` method' do
        allow(controller).to receive(:date_restrictions).and_return(date_restrictions)
        call_action
        expect(assigns[:date_restrictions]).to eq(date_restrictions)
      end
      describe 'when the current user is a securities signer' do
        allow_policy :security, :authorize?
        it 'sets the proper @form_data for an authorized securities signer' do
          form_data = {
            url: securities_release_submit_path,
            submit_text: I18n.t('securities.release.authorize')
          }
          call_action
          expect(assigns[:form_data]).to eq(form_data)
        end
      end
    end

    describe '`populate_securities_table_data_view_variable`' do
      release_headings = [
        I18n.t('common_table_headings.cusip'),
        I18n.t('common_table_headings.description'),
        fhlb_add_unit_to_table_header(I18n.t('common_table_headings.original_par'), '$'),
        I18n.t('securities.release.settlement_amount', unit: fhlb_add_unit_to_table_header('', '$'), footnote_marker: fhlb_footnote_marker)
      ]
      transfer_headings = [
        I18n.t('common_table_headings.cusip'),
        I18n.t('common_table_headings.description'),
        fhlb_add_unit_to_table_header(I18n.t('common_table_headings.original_par'), '$')
      ]
      safekeep_and_pledge_headings = [
        I18n.t('common_table_headings.cusip'),
        fhlb_add_unit_to_table_header(I18n.t('common_table_headings.original_par'), '$'),
        I18n.t('securities.release.settlement_amount', unit: fhlb_add_unit_to_table_header('', '$'), footnote_marker: fhlb_footnote_marker),
        I18n.t('securities.safekeep.custodian_name', footnote_marker: fhlb_footnote_marker(1))
      ]
      let(:securities) { [FactoryGirl.build(:security)] }
      let(:call_method) { controller.send(:populate_securities_table_data_view_variable, :release, securities) }

      it 'sets `column_headings` for release' do
        call_method
        expect(assigns[:securities_table_data][:column_headings]).to eq(release_headings)
      end

      it 'sets `column_headings` for transfer' do
        controller.send(:populate_securities_table_data_view_variable, :transfer, securities)
        expect(assigns[:securities_table_data][:column_headings]).to eq(transfer_headings)
      end

      it 'sets `column_headings` for pledge' do
        controller.send(:populate_securities_table_data_view_variable, :pledge, securities)
        expect(assigns[:securities_table_data][:column_headings]).to eq(safekeep_and_pledge_headings)
      end

      it 'sets `column_headings` for safekeep' do
        controller.send(:populate_securities_table_data_view_variable, :safekeep, securities)
        expect(assigns[:securities_table_data][:column_headings]).to eq(safekeep_and_pledge_headings)
      end

      [:transfer, :release].each do |action|
        describe "when `#{action}` is passed in as the type" do
          let(:call_method) { controller.send(:populate_securities_table_data_view_variable, action, securities) }
          it 'contains rows of columns that have a `cusip` value' do
            call_method
            expect(assigns[:securities_table_data][:rows].length).to be > 0
            assigns[:securities_table_data][:rows].each do |row|
              expect(row[:columns].first[:value]).to eq(securities.first.cusip)
            end
          end
          it "contains rows of columns that have a `cusip` value equal to `#{I18n.t('global.missing_value')}` if the security has no cusip value" do
            securities = [FactoryGirl.build(:security, cusip: nil)]
            controller.send(:populate_securities_table_data_view_variable, action, securities)
            expect(assigns[:securities_table_data][:rows].length).to be > 0
            assigns[:securities_table_data][:rows].each do |row|
              expect(row[:columns].first[:value]).to eq(I18n.t('global.missing_value'))
            end
          end
          it 'contains rows of columns that have a `description` value' do
            call_method
            expect(assigns[:securities_table_data][:rows].length).to be > 0
            assigns[:securities_table_data][:rows].each do |row|
              expect(row[:columns][1][:value]).to eq(securities.first.description)
            end
          end
          it "contains rows of columns that have a `description` value equal to `#{I18n.t('global.missing_value')}` if the security has no description value" do
            securities = [FactoryGirl.build(:security, description: nil)]
            controller.send(:populate_securities_table_data_view_variable, action, securities)
            expect(assigns[:securities_table_data][:rows].length).to be > 0
            assigns[:securities_table_data][:rows].each do |row|
              expect(row[:columns][1][:value]).to eq(I18n.t('global.missing_value'))
            end
          end
          it 'contains rows of columns that have an `original_par` value' do
            call_method
            expect(assigns[:securities_table_data][:rows].length).to be > 0
            assigns[:securities_table_data][:rows].each do |row|
              expect(row[:columns][2][:value]).to eq(securities.first.original_par)
            end
          end
          it 'contains rows of columns whose `original_par` value has a type of `number`' do
            call_method
            expect(assigns[:securities_table_data][:rows].length).to be > 0
            assigns[:securities_table_data][:rows].each do |row|
              expect(row[:columns][2][:type]).to eq(:number)
            end
          end
          if action == :release
            it 'contains rows of columns whose last member has a `payment_amount` value' do
              call_method
              expect(assigns[:securities_table_data][:rows].length).to be > 0
              assigns[:securities_table_data][:rows].each do |row|
                expect(row[:columns].last[:value]).to eq(securities.first.payment_amount)
              end
            end
            it 'contains rows of columns whose last member has a type of `:number`' do
              call_method
              expect(assigns[:securities_table_data][:rows].length).to be > 0
              assigns[:securities_table_data][:rows].each do |row|
                expect(row[:columns].last[:type]).to eq(:number)
              end
            end
          end
          it 'contains an empty array for rows if no securities are passed in' do
            controller.send(:populate_securities_table_data_view_variable, action)
            expect(assigns[:securities_table_data][:rows]).to eq([])
          end
        end
      end

      [:pledge, :safekeep].each do |action|
        describe "when `#{action}` is passed in as the type" do
          let(:call_method) { controller.send(:populate_securities_table_data_view_variable, action, securities) }
          it 'contains rows of columns that have a `cusip` value' do
            call_method
            expect(assigns[:securities_table_data][:rows].length).to be > 0
            assigns[:securities_table_data][:rows].each do |row|
              expect(row[:columns].first[:value]).to eq(securities.first.cusip)
            end
          end
          it "contains rows of columns that have a `cusip` value equal to `#{I18n.t('global.missing_value')}` if the security has no cusip value" do
            securities = [FactoryGirl.build(:security, cusip: nil)]
            controller.send(:populate_securities_table_data_view_variable, action, securities)
            expect(assigns[:securities_table_data][:rows].length).to be > 0
            assigns[:securities_table_data][:rows].each do |row|
              expect(row[:columns].first[:value]).to eq(I18n.t('global.missing_value'))
            end
          end
          it 'contains rows of columns that have an `original_par` value' do
            call_method
            expect(assigns[:securities_table_data][:rows].length).to be > 0
            assigns[:securities_table_data][:rows].each do |row|
              expect(row[:columns][1][:value]).to eq(securities.first.original_par)
            end
          end
          it 'contains rows of columns whose `original_par` value has a type of `number`' do
            call_method
            expect(assigns[:securities_table_data][:rows].length).to be > 0
            assigns[:securities_table_data][:rows].each do |row|
              expect(row[:columns][1][:type]).to eq(:number)
            end
          end
          it 'contains rows of columns that have a `payment_amount` value' do
            call_method
            expect(assigns[:securities_table_data][:rows].length).to be > 0
            assigns[:securities_table_data][:rows].each do |row|
              expect(row[:columns][2][:value]).to eq(securities.first.payment_amount)
            end
          end
          it 'contains rows of columns whose `payment_amount` value has a type of `number`' do
            call_method
            expect(assigns[:securities_table_data][:rows].length).to be > 0
            assigns[:securities_table_data][:rows].each do |row|
              expect(row[:columns][2][:type]).to eq(:number)
            end
          end
          it 'contains rows of columns that have a `custodian_name` value' do
            call_method
            expect(assigns[:securities_table_data][:rows].length).to be > 0
            assigns[:securities_table_data][:rows].each do |row|
              expect(row[:columns][3][:value]).to eq(securities.first.custodian_name)
            end
          end
          it "contains rows of columns that have a `custodian_name` value equal to `#{I18n.t('global.missing_value')}` if the security has no custodian_name value" do
            securities = [FactoryGirl.build(:security, custodian_name: nil)]
            controller.send(:populate_securities_table_data_view_variable, action, securities)
            expect(assigns[:securities_table_data][:rows].length).to be > 0
            assigns[:securities_table_data][:rows].each do |row|
              expect(row[:columns][3][:value]).to eq(I18n.t('global.missing_value'))
            end
          end
          it 'contains an empty array for rows if no securities are passed in' do
            controller.send(:populate_securities_table_data_view_variable, action)
            expect(assigns[:securities_table_data][:rows]).to eq([])
          end
        end
      end
    end

    describe '`translated_dropdown_mapping`' do
      let(:translated_string_1) { instance_double(String) }
      let(:translated_string_2) { instance_double(String) }
      let(:dropdown_hash) {{
        foo: {
          whiz: instance_double(String),
          text: instance_double(String)
        },
        bar: {
          bang: instance_double(String),
          text: instance_double(String)
        }
      }}
      let(:translated_hash) {{
        foo: {
          whiz: dropdown_hash[:foo][:whiz],
          text: translated_string_1
        },
        bar: {
          bang: dropdown_hash[:bar][:bang],
          text: translated_string_2
        }
      }}
      let(:call_method) { subject.send(:translated_dropdown_mapping, dropdown_hash) }
      before do
        allow(I18n).to receive(:t).with(dropdown_hash[:foo][:text]).and_return(translated_string_1)
        allow(I18n).to receive(:t).with(dropdown_hash[:bar][:text]).and_return(translated_string_2)
      end
      it 'returns a hash with I18n translated `text` values' do
        expect(call_method).to eq(translated_hash)
      end
    end

    describe '`date_restrictions`' do
      let(:today) { Time.zone.today }
      let(:max_date) { today + SecuritiesRequest::MAX_DATE_RESTRICTION }
      let(:holidays) do
        holidays = []
        rand(2..4).times do
          holidays << (today + rand(1..70).days).iso8601
        end
        holidays
      end
      let(:weekends) do
        weekends = []
        date_iterator = today.clone
        while date_iterator <= max_date do
          weekends << date_iterator.iso8601 if (date_iterator.sunday? || date_iterator.saturday?)
          date_iterator += 1.day
        end
      end
      let(:calendar_service) { instance_double(CalendarService, holidays: holidays) }
      let(:call_method) { subject.send(:date_restrictions) }

      before { allow(CalendarService).to receive(:new).and_return(calendar_service) }

      it 'creates a new instance of the CalendarService with the request as an arg' do
        expect(CalendarService).to receive(:new).with(request).and_return(calendar_service)
        call_method
      end
      it 'calls `holidays` on the service instance with today as an arg' do
        expect(calendar_service).to receive(:holidays).with(today, any_args).and_return(holidays)
        call_method
      end
      it 'calls `holidays` on the service instance with a date three months from today as an arg' do
        expect(calendar_service).to receive(:holidays).with(anything, max_date).and_return(holidays)
        call_method
      end
      describe 'the returned hash' do
        it 'has a `min_date` of today' do
          expect(call_method[:min_date]).to eq(today)
        end
        it 'has a `max_date` of today plus the `SecuritiesRequest::MAX_DATE_RESTRICTION`' do
          expect(call_method[:max_date]).to eq(max_date)
        end
        describe 'the `invalid_dates` array' do
          it 'includes all dates returned from the CalendarService' do
            expect(call_method[:invalid_dates]).to include(*holidays)
          end
          it 'includes all weekends between the today and the max date' do
            expect(call_method[:invalid_dates]).to include(*weekends)
          end
        end
      end
    end

    describe '`prioritized_securities_request_error`' do
      generic_error_message = I18n.t('securities.release.edit.generic_error', phone_number: securities_services_phone_number, email: securities_services_email_text)
      let(:errors) {{
        foo: [SecureRandom.hex],
        bar: [SecureRandom.hex],
        settlement_date: [SecureRandom.hex],
        securities: [SecureRandom.hex],
        base: [SecureRandom.hex]
      }}
      let(:securities_request) { instance_double(SecuritiesRequest, errors: errors) }
      let(:call_method) { subject.send(:prioritized_securities_request_error, securities_request) }

      it 'returns nil if no errors are present on the securities_request' do
        allow(securities_request).to receive(:errors).and_return({})
        expect(call_method).to be_nil
      end
      describe 'when the error object contains standard error keys' do
        it 'returns the standard message for the first key it finds' do
          expect(call_method).to eq(errors[:foo].first)
        end
      end
      describe 'when the error object does not contain standard error keys' do
        let(:errors) {{
          settlement_date: [SecureRandom.hex],
          securities: [SecureRandom.hex],
          base: [SecureRandom.hex]
        }}

        it 'returns the standard message for the `settlement_date` error' do
          expect(call_method).to eq(errors[:settlement_date].first)
        end

        describe 'when there is a `securities` error but no `settlement_date` error' do
          let(:errors) {{
            securities: [SecureRandom.hex],
            base: [SecureRandom.hex]
          }}

          it 'returns the standard message for the `securities` error' do
            expect(call_method).to eq(errors[:securities].first)
          end
        end

        describe 'when there is a `base` error but no other specific error' do
          let(:errors) {{
            base: [SecureRandom.hex]
          }}

          it 'returns a generic error message' do
            expect(call_method).to eq(generic_error_message)
          end
        end
      end
    end
    describe '`prioritized_security_error`' do
      let(:security) { instance_double(Security, errors: nil) }
      let(:error_message) { instance_double(String) }
      let(:other_error_message) { instance_double(String) }
      let(:errors) {{
        foo: [error_message, other_error_message],
        bar: [other_error_message]
      }}
      let(:call_method) { subject.send(:prioritized_security_error, security) }

      it 'returns nil if the passed security contains no errors' do
        expect(call_method).to be nil
      end
      it 'returns the first error message from the security object it is passed' do
        allow(security).to receive(:errors).and_return(errors)
        expect(call_method).to eq(error_message)
      end
      describe 'when the error hash contains Security::CURRENCY_ATTRIBUTES' do
        let(:currency_attr_error) { instance_double(String) }

        before do
          errors[Security::CURRENCY_ATTRIBUTES.sample] = [currency_attr_error]
          allow(security).to receive(:errors).and_return(errors)
        end

        it 'prioritizes other errors above the Security::CURRENCY_ATTRIBUTES errors' do
          expect(call_method).to eq(error_message)
        end
        it 'returns the first error message of the first Security::CURRENCY_ATTRIBUTES error if no other errors are present' do
          [:foo, :bar].each {|error| security.errors.delete(error) }
          expect(call_method).to eq(currency_attr_error)
        end
      end
    end

    describe '`type_matches_kind`' do
      {
        release: [:pledge_release, :safekept_release],
        transfer: [:pledge_transfer, :safekept_transfer],
        safekeep: [:safekept_intake],
        pledge: [:pledge_intake]
      }.each do |type, valid_kinds|
        invalid_kinds = SecuritiesRequest::KINDS - valid_kinds
        valid_kinds.each do |kind|
          it "returns true when `kind` is `#{kind}`" do
            expect(subject.send(:type_matches_kind, type, kind)).to be true
          end
        end
        invalid_kinds.each do |kind|
          it "returns false when `kind` is `#{kind}`" do
            expect(subject.send(:type_matches_kind, type, kind)).to be false
          end
        end
      end
      describe 'when `type` is anything other than :release, :transfer :safekeep or :pledge' do
        it 'returns nil' do
          expect(subject.send(:type_matches_kind, SecureRandom.hex, SecureRandom.hex)).to be nil
        end
      end
    end

    describe '`populate_authorize_request_view_variables`' do
      let(:sentinel) { instance_double(String) }
      before do
        allow(controller).to receive(:collateral_operations_email)
        allow(controller).to receive(:securities_services_email)
        allow(controller).to receive(:collateral_operations_phone_number)
        allow(controller).to receive(:securities_services_phone_number)
      end

      shared_examples 'it has a valid title mapping' do
        it "sets `@title` appropriately" do
          call_method
          expect(assigns[:title]).to eq(title)
        end
      end

      describe 'when passed a kind that is not a valid SecuritiesRequest `kind`' do
        let(:call_method) { controller.send(:populate_authorize_request_view_variables, SecureRandom.hex) }
        it 'does not set `@title`' do
          call_method
          expect(assigns[:title]).to be_nil
        end
        it 'does not set `@contact`' do
          call_method
          expect(assigns[:contact]).to be_nil
        end
      end
      describe 'collateral kinds' do
        {
          pledge_release: I18n.t('securities.authorize.titles.pledge_release'),
          pledge_intake: I18n.t('securities.authorize.titles.pledge_intake'),
          pledge_transfer: I18n.t('securities.authorize.titles.transfer'),
          safekept_transfer: I18n.t('securities.authorize.titles.transfer'),
        }.each do |kind, title|
          describe "when the passed `kind` is `#{kind}`" do
            let(:title) { title }
            let(:call_method) { controller.send(:populate_authorize_request_view_variables, kind) }
            it_behaves_like 'it has a valid title mapping'

            it 'sets the `@contact[:email_address]` value to the result of the `collateral_operations_email` helper method' do
              allow(controller).to receive(:collateral_operations_email).and_return(sentinel)
              call_method
              expect(assigns[:contact][:email_address]).to eq(sentinel)
            end
            it 'sets the `@contact[:phone_number]` value to the result of the `collateral_operations_phone_number` helper method' do
              allow(controller).to receive(:collateral_operations_phone_number).and_return(sentinel)
              call_method
              expect(assigns[:contact][:phone_number]).to eq(sentinel)
            end
            it 'sets the `@contact[:mailto_text]` value to the appropriate string' do
              call_method
              expect(assigns[:contact][:mailto_text]).to eq(I18n.t('contact.collateral_departments.collateral_operations.title'))
            end
          end
        end
      end
      describe 'securities kinds' do
        {
          safekept_release: I18n.t('securities.authorize.titles.safekept_release'),
          safekept_intake: I18n.t('securities.authorize.titles.safekept_intake')
        }.each do |kind, title|
          describe "when the passed `kind` is `#{kind}`" do
            let(:title) { title }
            let(:call_method) { controller.send(:populate_authorize_request_view_variables, kind) }
            it_behaves_like 'it has a valid title mapping'

            it 'sets the `@contact[:email_address]` value to the result of the `securities_services_email` helper method' do
              allow(controller).to receive(:securities_services_email).and_return(sentinel)
              call_method
              expect(assigns[:contact][:email_address]).to eq(sentinel)
            end
            it 'sets the `@contact[:phone_number]` value to the result of the `securities_services_phone_number` helper method' do
              allow(controller).to receive(:securities_services_phone_number).and_return(sentinel)
              call_method
              expect(assigns[:contact][:phone_number]).to eq(sentinel)
            end
            it 'sets the `@contact[:mailto_text]` value to the appropriate string' do
              call_method
              expect(assigns[:contact][:mailto_text]).to eq(I18n.t('contact.collateral_departments.securities_services.title'))
            end
          end
        end
      end
    end
  end
end