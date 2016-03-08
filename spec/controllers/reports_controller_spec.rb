require 'rails_helper'
include CustomFormattingHelper
include ActionView::Helpers::NumberHelper
include DatePickerHelper
include ActiveSupport::Inflector
include FinancialInstrumentHelper

RSpec.describe ReportsController, :type => :controller do
  shared_examples 'a date restricted report' do |action, default_start_selection=nil, start_date_offset=0|
    let(:start_date) { rand(start_date_offset..500).days.ago(Time.zone.today) }
    let(:default_start) do
      case default_start_selection
        when :this_month_start
          controller.send(:default_dates_hash)[:this_month_start]
        when :last_month_start
          controller.send(:default_dates_hash)[:last_month_start]
        when :last_month_end
          controller.send(:default_dates_hash)[:last_month_end]
        else
          raise 'Default start case not found'
      end
    end
    it 'should pass the `initialize_dates` method the `start_date` param if provided' do
      expect(controller).to receive(:initialize_dates).with(anything, start_date.to_s, any_args)
      get action, start_date: start_date
    end
  end

  shared_examples 'a report with instance variables set in a before_filter' do |action|
    let(:member_name) { double('member name') }
    it 'has a @member_name' do
      allow(controller).to receive(:current_member_name).and_return(member_name)
      get action
      expect(assigns[:member_name]).to eq(member_name)
    end
  end

  login_user

  let(:today) { Time.zone.today }
  let(:max_date) { controller.most_recent_business_day(today - 1.day)}
  let(:start_date) { today - 2.months }
  let(:restricted_start_date) { double('a restricted date')}
  let(:end_date) { today - 1.month }
  let(:min_date) { double('min date') }
  let(:picker_preset_hash) { double('date_picker_hash')}
  let(:date_picker_presets) {double('date_picker_presets')}

  before do
    allow(controller).to receive(:date_picker_presets).and_return(date_picker_presets)
    allow(controller).to receive(:most_recent_business_day).and_return(max_date)
    allow(controller).to receive(:fhlb_report_date_numeric)
    allow(ReportConfiguration).to receive(:date_bounds).with(any_args)
      .and_return({ min: min_date, start: start_date, end: end_date, max: max_date })
  end

  describe 'GET index' do
    it_behaves_like 'a user required action', :get, :index
    it_behaves_like 'a report with instance variables set in a before_filter', :index
    it_behaves_like 'a controller action with an active nav setting', :index, :reports
    it 'should render the index view' do
      get :index
      expect(response.body).to render_template('index')
    end
    describe 'flipped reports' do
      {
        securities: {
          transactions: 'report-securities-transaction',
          cash_projections: 'report-cash-projections',
          current: 'report-current-securities-positions',
          monthly: 'report-monthly-securities-positions',
          services_monthly: 'report-securities-services-monthly-statement'
        },
        capital_stock: {
          activity: 'report-capital-stock-activity-statement',
          trial_balance: 'report-capital-stock-trial-balance',
          capital_stock_and_leverage: 'report-capital-stock-position-and-leverage',
          dividend_statement: 'report-dividened-transaction-statement'
        },
        account: {
          authorizations: 'report-authorizations'
        }
      }.each do |section, reports|
        reports.each do |report, feature|
          it "marks the report `#{section}.#{report}` as disabled if the feature `#{feature}` is disabled" do
            allow(controller).to receive(:feature_enabled?).and_call_original
            allow(controller).to receive(:feature_enabled?).with(feature).and_return(false)
            get :index
            expect(assigns[:reports][section][report][:disabled]).to be(true)
          end
          it "does not mark the report `#{section}.#{report}` as disabled if its feature `#{feature}` is enabled" do
            get :index
            expect(assigns[:reports][section][report]).to_not have_key(:disabled)
          end
        end
      end
    end
  end

  describe 'requests hitting MemberBalanceService' do
    let(:member_balance_service_instance) { double('MemberBalanceServiceInstance') }
    let(:response_hash) { double('MemberBalanceHash') }

    before do
      allow(MemberBalanceService).to receive(:new).and_return(member_balance_service_instance)
    end

    describe 'GET capital_stock_activity' do
      let(:capital_stock_activity) { get :capital_stock_activity }
      let(:total_debits) { double('total debits') }
      let(:total_credits) { double('total credits') }
      let(:activity) do
        {
          trans_date: double('trans date'),
          cert_id: double('cert id'),
          trans_type: double('trans type'),
          debit_shares: double('debit shares'),
          credit_shares: double('credit shares'),
          outstanding_shares: double('outstanding shares')
        }
      end
      let(:capital_stock_hash) { {activities: [activity], total_debits: total_debits, total_credits: total_credits} }
      before do
        allow(member_balance_service_instance).to receive(:capital_stock_activity).and_return(response_hash)
        allow(response_hash).to receive(:[]).and_return({})
      end
      it_behaves_like 'a user required action', :get, :capital_stock_activity
      it_behaves_like 'a date restricted report', :capital_stock_activity, :last_month_start
      it_behaves_like 'a report with instance variables set in a before_filter', :capital_stock_activity
      it_behaves_like 'a controller action with an active nav setting', :capital_stock_activity, :reports
      it_behaves_like 'a report that can be downloaded', :capital_stock_activity, [:pdf, :xlsx]

      it 'should render the capital_stock_activity view' do
        capital_stock_activity
        expect(response.body).to render_template('capital_stock_activity')
      end
      it 'should set @capital_stock_activity' do
        capital_stock_activity
        expect(assigns[:capital_stock_activity]).to eq(response_hash)
      end
      it 'should set @capital_stock_activity to {} if the report is disabled' do
        allow(controller).to receive(:report_disabled?).with(ReportsController::CAPITAL_STOCK_ACTIVITY_WEB_FLAGS).and_return(true)
        capital_stock_activity
        expect(assigns[:capital_stock_activity]).to eq({:activities=>[]})
      end
      it 'should raise an error if the service returns nil' do
        allow(member_balance_service_instance).to receive(:capital_stock_activity).and_return(nil)
        expect{capital_stock_activity}.to raise_error(StandardError)
      end
      describe "view instance variables" do
        describe '@capital_stock_activity_table_data' do
          before do
            allow(member_balance_service_instance).to receive(:capital_stock_activity).and_return(capital_stock_hash)
          end
          it 'contains an array of appropriate column headings' do
            capital_stock_activity
            expect(assigns[:capital_stock_activity_table_data][:column_headings]).to eq([I18n.t("global.issue_date"), I18n.t('reports.pages.capital_stock_activity.certificate_sequence'), I18n.t('global.transaction_type'), I18n.t('reports.pages.capital_stock_activity.debit_shares'), I18n.t('reports.pages.capital_stock_activity.credit_shares'), I18n.t('reports.pages.capital_stock_activity.shares_outstanding')])
          end
          describe 'the `rows` array' do
            it 'returns an empty array if the report has been disabled' do
              allow(controller).to receive(:report_disabled?).with(ReportsController::CAPITAL_STOCK_ACTIVITY_WEB_FLAGS).and_return(true)
              capital_stock_activity
              expect(assigns[:capital_stock_activity_table_data][:rows]).to eq([])
            end
            it 'returns an empty array if there are no activities' do
              capital_stock_hash = {activities: [], total_debits: total_debits, total_credits: total_credits}
              allow(member_balance_service_instance).to receive(:capital_stock_activity).and_return(capital_stock_hash)
              capital_stock_activity
              expect(assigns[:capital_stock_activity_table_data][:rows]).to eq([])
            end
            describe 'the `columns` value for each row' do
              before { capital_stock_activity }
              it 'has a first member whose value is the trans_date of the activity' do
                expect(assigns[:capital_stock_activity_table_data][:rows][0][:columns][0][:value]).to eq(activity[:trans_date])
              end
              it 'has a first member whose type is set to :date' do
                expect(assigns[:capital_stock_activity_table_data][:rows][0][:columns][0][:type]).to eq(:date)
              end
              it 'has a second member whose value is the cert_id of the activity' do
                expect(assigns[:capital_stock_activity_table_data][:rows][0][:columns][1][:value]).to eq(activity[:cert_id])
              end
              it 'has a third member whose value is the trans_type of the activity' do
                expect(assigns[:capital_stock_activity_table_data][:rows][0][:columns][2][:value]).to eq(activity[:trans_type])
              end
              ['debit_shares', 'credit_shares', 'outstanding_shares'].each_with_index do |attr, i|
                it "has a #{(i+4).ordinalize} member whose value is the #{attr} of the activity" do
                  expect(assigns[:capital_stock_activity_table_data][:rows][0][:columns][i+3][:value]).to eq(activity[attr.to_sym])
                end
                it "has a #{(i+4).ordinalize} member whose type is set to :number" do
                  expect(assigns[:capital_stock_activity_table_data][:rows][0][:columns][i+3][:type]).to eq(:number)
                end
              end
            end
          end
          describe 'the `footer` array' do
            before { capital_stock_activity }
            it "has a first item with a value of `#{I18n.t('global.totals')}`" do
              expect(assigns[:capital_stock_activity_table_data][:footer][0][:value]).to eq(I18n.t('global.totals'))
            end
            it 'has a first item with a colspan of 3' do
              expect(assigns[:capital_stock_activity_table_data][:footer][0][:colspan]).to eq(3)
            end
            it 'has a second item with a value corresponding the to total debits' do
              expect(assigns[:capital_stock_activity_table_data][:footer][1][:value]).to eq(total_debits)
            end
            it 'has a second item with a type set to :number' do
              expect(assigns[:capital_stock_activity_table_data][:footer][1][:type]).to eq(:number)
            end
            it 'has a third item with a value corresponding the to total credits' do
              expect(assigns[:capital_stock_activity_table_data][:footer][2][:value]).to eq(total_credits)
            end
            it 'has a third item with a type set to :number' do
              expect(assigns[:capital_stock_activity_table_data][:footer][2][:type]).to eq(:number)
            end
          end
        end
        it 'should set @start_date to a restricted start date' do
          allow(ReportConfiguration).to receive(:date_bounds)
            .with(:capital_stock_activity, anything, anything)
            .and_return({ min: min_date, start: restricted_start_date, end: end_date, max: max_date })
          capital_stock_activity
          expect(assigns[:start_date]).to eq(restricted_start_date)
        end
        it 'should set @end_date to the end_date param' do
          get :capital_stock_activity, start_date: start_date, end_date: end_date
          expect(assigns[:end_date]).to eq(end_date)
        end
        it 'should set @end_date to the end of last month if no end_date param is provided' do
          allow(ReportConfiguration).to receive(:date_bounds)
            .with(:capital_stock_activity, anything, anything)
            .and_return({ min: min_date, start: restricted_start_date, end: default_dates_hash[:last_month_end], max: max_date })
          capital_stock_activity
          expect(assigns[:end_date]).to eq(default_dates_hash[:last_month_end])
        end
        it 'should pass @start_date, @end_date and the `date_restriction` to DatePickerHelper#date_picker_presets and set @picker_presets to its outcome' do
          allow(controller).to receive(:date_picker_presets).with(restricted_start_date, end_date, ReportsController::DATE_RESTRICTION_MAPPING[:capital_stock_activity]).and_return(date_picker_presets)
          get :capital_stock_activity, start_date: start_date, end_date: end_date
          expect(assigns[:picker_presets]).to eq(date_picker_presets)
        end
      end
    end

    describe 'GET capital_stock_trial_balance' do
      let(:start_date)                       { Date.new(2014, 12, 31) }
      let(:member_balances_service_instance) { double('MemberBalanceService') }
      let(:number_of_shares)                 { double('number_of_shares') }
      let(:number_of_certificates)           { double('number_of_certificates') }
      let(:certificate_sequence)             { double('certificate_sequence') }
      let(:issue_date)                       { double('issue_date') }
      let(:transaction_type)                 { double('transaction_type') }
      let(:shares_outstanding)               { double('shares_outstanding') }
      let(:summary) do
        {
            certificates: [certificate_hash],
            number_of_shares: number_of_shares,
            number_of_certificates: number_of_certificates
        }
      end
      let(:certificate_hash) do
        {
            certificate_sequence: certificate_sequence,
            issue_date:           issue_date,
            transaction_type:     transaction_type,
            shares_outstanding:   shares_outstanding,
        }
      end
      let(:table_data) do
        [{type: nil,     value: certificate_sequence, classes: [:'report-cell-narrow']},
         {type: :date,   value: issue_date,           classes: [:'report-cell-narrow']},
         {type: nil,     value: transaction_type,     classes: [:'report-cell-narrow']},
         {type: :number, value: shares_outstanding,   classes: [:'report-cell-narrow']}]
      end
      let(:min_date) { Date.new(2002,1,1) }
      let(:call_action) { get :capital_stock_trial_balance }
      before do
        allow(MemberBalanceService).to receive(:new).and_return(member_balances_service_instance)
        allow(member_balances_service_instance).to receive(:capital_stock_trial_balance).with(kind_of(Date)).and_return(summary)
      end
      it_behaves_like 'a user required action', :get, :capital_stock_trial_balance
      it_behaves_like 'a report that can be downloaded', :capital_stock_trial_balance, [:xlsx]
      it_behaves_like 'a report with instance variables set in a before_filter', :capital_stock_trial_balance
      it_behaves_like 'a controller action with an active nav setting', :capital_stock_trial_balance, :reports

      it 'renders the capital_stock_trial_balance view' do
        call_action
        expect(response.body).to render_template('capital_stock_trial_balance')
      end
      it 'should pass @start_date and @max_date to DatePickerHelper#date_picker_presets and set @picker_presets to its outcome' do
        allow(controller).to receive(:most_recent_business_day).and_return(max_date)
        allow(controller).to receive(:date_picker_presets).with(start_date, nil, nil, max_date).and_return(date_picker_presets)
        get :capital_stock_trial_balance, start_date: start_date
        expect(assigns[:picker_presets]).to eq(date_picker_presets)
      end
      it 'should assign @number_of_shares and @number_of_certificates' do
        call_action
        expect(assigns[:number_of_shares]).to eq(number_of_shares)
        expect(assigns[:number_of_certificates]).to eq(number_of_certificates)
      end
      it 'should assign @min_date a date of January 1st, 2002' do
        call_action
        expect(assigns[:min_date]).to eq(min_date)
      end
      it 'should assign @start_date a date of January 1st, 2002 if the start_date param occurs before that date' do
        allow(ReportConfiguration).to receive(:date_bounds).with(:capital_stock_trial_balance, anything, anything)
          .and_return({ min: min_date, start: Date.new(2002,1,1), end: end_date, max: max_date })
        get :capital_stock_trial_balance, start_date: min_date - 1.year
        expect(assigns[:start_date]).to eq(Date.new(2002,1,1))
      end
      it 'should return capital_stock_trial_balance_table_data with with columns populated' do
        call_action
        expect(assigns[:capital_stock_trial_balance_table_data][:rows][0][:columns]).to eq(table_data)
      end
      it 'sorts certificates by sequence number' do
        sequence = rand(100000..999999)
        certificate_1 = {
          certificate_sequence: sequence + rand(100..1000),
          issue_date:           issue_date,
          transaction_type:     transaction_type,
          shares_outstanding:   shares_outstanding,
        }
        certificate_2 = {
          certificate_sequence: sequence,
          issue_date:           issue_date,
          transaction_type:     transaction_type,
          shares_outstanding:   shares_outstanding,
        }
        certificate_3 = {
          certificate_sequence: sequence - rand(100..1000),
          issue_date:           issue_date,
          transaction_type:     transaction_type,
          shares_outstanding:   shares_outstanding,
        }
        summary = {
          certificates: [certificate_2, certificate_1, certificate_3],
          number_of_shares: number_of_shares,
          number_of_certificates: number_of_certificates
        }
        allow(member_balances_service_instance).to receive(:capital_stock_trial_balance).and_return(summary)
        get :capital_stock_trial_balance
        assigned_certificates = assigns[:capital_stock_trial_balance_table_data][:rows].collect {|row| row[:columns].first[:value]}
        expect(assigned_certificates).to eq([certificate_3[:certificate_sequence], certificate_2[:certificate_sequence], certificate_1[:certificate_sequence]])
      end
      RSpec.shared_examples 'a capital stock trial balance report with no data' do
        it 'returns an empty array for @capital_stock_trial_balance_table_data[:rows]' do
          call_action
          expect(assigns[:capital_stock_trial_balance_table_data][:rows]).to eq([])
        end
        [:number_of_shares, :number_of_certificates].each do |instance_var|
          it "sets @#{instance_var.to_s} to nil" do
            call_action
            expect(assigns[instance_var]).to be_nil
          end
        end
      end
      describe 'when the report is disabled' do
        before { allow(subject).to receive(:report_disabled?).and_return(true) }
        it_behaves_like 'a capital stock trial balance report with no data'
      end
      describe 'when the `member_balances.capital_stock_trial_balance` method returns an empty dataset' do
        before { allow(member_balances_service_instance).to receive(:capital_stock_trial_balance).and_return({}) }
        it_behaves_like 'a capital stock trial balance report with no data'
      end
    end

    describe 'GET settlement_transaction_account' do
      let(:filter) {'some filter'}
      let(:make_request) { get :settlement_transaction_account }
      let(:make_request_with_dates) { get :settlement_transaction_account, start_date: start_date, end_date: end_date }
      before do
        allow(member_balance_service_instance).to receive(:settlement_transaction_account).and_return(response_hash)
        allow(response_hash).to receive(:[]).with(:activities)
      end
      it_behaves_like 'a user required action', :get, :settlement_transaction_account
      it_behaves_like 'a report that can be downloaded', :settlement_transaction_account, [:pdf]
      it_behaves_like 'a date restricted report', :settlement_transaction_account, :this_month_start
      it_behaves_like 'a report with instance variables set in a before_filter', :settlement_transaction_account
      it_behaves_like 'a controller action with an active nav setting', :settlement_transaction_account, :reports
      describe 'with activities array stubbed' do
        it 'should render the settlement_transaction_account view' do
          make_request
          expect(response.body).to render_template('settlement_transaction_account')
        end
        describe "view instance variables" do
          before {
            allow(member_balance_service_instance).to receive(:settlement_transaction_account).with(kind_of(Date), kind_of(Date), kind_of(String)).and_return(response_hash)
          }
          it 'should set @settlement_transaction_account to the hash returned from MemberBalanceService' do
            expect(member_balance_service_instance).to receive(:settlement_transaction_account).and_return(response_hash)
            make_request
            expect(assigns[:settlement_transaction_account]).to eq(response_hash)
          end
          it 'should raise an error if @settlement_transaction_account is nil' do
            expect(member_balance_service_instance).to receive(:settlement_transaction_account).and_return(nil)
            expect{make_request}.to raise_error(StandardError)
          end
          it 'should set @settlement_transaction_account to {} if the report is disabled' do
            expect(controller).to receive(:report_disabled?).with(ReportsController::SETTLEMENT_TRANSACTION_ACCOUNT_WEB_FLAGS).and_return(true)
            make_request
            expect(assigns[:settlement_transaction_account]).to eq({})
          end
          it 'should set @start_date to the `start_date`' do
            allow(ReportConfiguration).to receive(:date_bounds).with(:settlement_transaction_account, start_date, anything)
              .and_return({ min: min_date, start: start_date, end: end_date, max: max_date })
            make_request
            expect(assigns[:start_date]).to eq(start_date)
          end
          it 'should set @end_date to the end_date param' do
            make_request_with_dates
            expect(assigns[:end_date]).to eq(end_date)
          end
          it 'should set @end_date to the end of last month if no end_date param is provided' do
            allow(ReportConfiguration).to receive(:date_bounds).with(:settlement_transaction_account, anything, nil)
              .and_return({ min: min_date, start: start_date, end: default_dates_hash[:last_month_end], max: max_date })
            make_request
            expect(assigns[:end_date]).to eq(default_dates_hash[:last_month_end])
          end
          it 'should pass @start_date, @end_date and `date_restriction` to DatePickerHelper#date_picker_presets and set @picker_presets to its outcome' do
            allow(controller).to receive(:date_picker_presets).with(restricted_start_date, end_date, ReportsController::DATE_RESTRICTION_MAPPING[:settlement_transaction_account]).and_return(picker_preset_hash)
            get :settlement_transaction_account, start_date: start_date, end_date: end_date, sta_filter: filter
            expect(assigns[:picker_presets]).to eq(date_picker_presets)
          end
          it 'sets @daily_balance_key to the constant DAILY_BALANCE_KEY found in MemberBalanceService' do
            my_const = double('Some Constant')
            stub_const('MemberBalanceService::DAILY_BALANCE_KEY', my_const)
            make_request
            expect(assigns[:daily_balance_key]).to eq(my_const)
          end
          it 'should set @filter to `debit` and @filter_text to the proper i18next translation for `debit` if debit is passed as the sta_filter param' do
            get :settlement_transaction_account, sta_filter: 'debit'
            expect(assigns[:filter]).to eq('debit')
            expect(assigns[:filter_text]).to eq(I18n.t('global.debits'))
          end
          it 'should set @filter to `credit` and @filter_text to the proper i18next translation for `credit` if credit is passed as the sta_filter param' do
            get :settlement_transaction_account, sta_filter: 'credit'
            expect(assigns[:filter]).to eq('credit')
            expect(assigns[:filter_text]).to eq(I18n.t('global.credits'))
          end
          it 'should set @filter to `all` and @filter_text to the proper i18next translation for `all` if nothing is passed for the sta_filter param' do
            make_request
            expect(assigns[:filter]).to eq('all')
            expect(assigns[:filter_text]).to eq(I18n.t('global.all'))
          end
          it 'should set @filter to `all` and @filter_text to the proper i18next translation for `all` if anything besides debit or credit is passed as the sta_filter param' do
            get :settlement_transaction_account, sta_filter: 'some nonsense param'
            expect(assigns[:filter]).to eq('all')
            expect(assigns[:filter_text]).to eq(I18n.t('global.all'))
          end
          it 'should set @filter_options to an array of arrays containing the appropriate values and labels for credit, debit, daily balance and all' do
            options_array = [
                [I18n.t('global.all'), 'all'],
                [I18n.t('global.debits'), 'debit'],
                [I18n.t('global.credits'), 'credit'],
                [I18n.t('global.daily_balances'), 'balance']
            ]
            make_request
            expect(assigns[:filter_options]).to eq(options_array)
          end
        end
      end
      describe 'with activities array mocked' do
        before {
          allow(member_balance_service_instance).to receive(:settlement_transaction_account).with(kind_of(Date), kind_of(Date), kind_of(String)).and_return(response_hash)
        }
        it 'should set @show_ending_balance to false if the date of the first transaction in the activity array is the same as the @end_date' do
          activities_array = [
              {  trans_date: end_date,
                 balance: 55449.6
              }
          ]
          allow(response_hash).to receive(:[]).with(:activities).at_least(:once).and_return(activities_array)
          make_request_with_dates
          expect(assigns[:show_ending_balance]).to eq(false)
        end
        it 'should set @show_ending_balance to true if the date of the first transaction in the activity array is different than the @end_date' do
          activities_array = [
            {  trans_date: end_date + 1.day,
               balance: 55449.6
            }
          ]
          allow(response_hash).to receive(:[]).with(:activities).at_least(:once).and_return(activities_array)
          make_request_with_dates
          expect(assigns[:show_ending_balance]).to eq(true)
        end
        it 'should set @show_ending_balance to true if there is no balance given for the first transaction in the activity array, even if the date of the transaction is equal to @end_date' do
          activities_array = [
              {  trans_date: end_date,
                 balance: nil
              }
          ]
          allow(response_hash).to receive(:[]).with(:activities).at_least(:once).and_return(activities_array)
          make_request_with_dates
          expect(assigns[:show_ending_balance]).to eq(true)
        end
      end
      describe 'fetching STA numbers' do
        let(:sta_number) { double('An STA Number') }
        let(:member_id) { double('A Member ID') }
        let(:members_service) { double(MembersService, report_disabled?: false) }
        before do
          allow(MembersService).to receive(:new).and_return(members_service)
          allow(members_service).to receive(:member).and_return({sta_number: sta_number}.with_indifferent_access)
          allow(controller).to receive(:current_member_id).and_return(member_id)
        end
         it 'calls MembersService.member with the current_member_id' do
           expect(members_service).to receive(:member).with(member_id)
           make_request
         end
         it 'populates @sta_number with the STA number' do
           make_request
           expect(assigns[:sta_number]).to be(sta_number)
         end
         it 'does not populate @sta_number if its already set' do
           controller.instance_variable_set(:@sta_number, sta_number)
           expect(members_service).to receive(:member).exactly(:once)
           make_request
         end
      end
    end

    describe 'GET advances_detail' do
      it_behaves_like 'a user required action', :get, :advances_detail
      let(:advances_detail) {double('Advances Detail object')}
      before do
        allow(member_balance_service_instance).to receive(:advances_details).and_return(advances_detail)
        allow(advances_detail).to receive(:[]).with(:advances_details).and_return([])
      end

      it_behaves_like 'a report that can be downloaded', :advances_detail, [:pdf, :xlsx]
      it_behaves_like 'a date restricted report', :advances_detail, nil, 1
      it_behaves_like 'a report with instance variables set in a before_filter', :advances_detail
      it_behaves_like 'a controller action with an active nav setting', :advances_detail, :reports

      it 'should render the advances_detail view' do
        get :advances_detail
        expect(response.body).to render_template('advances_detail')
      end

      describe 'view instance variables' do
        it 'sets @start_date to `start_date`' do
          get :advances_detail, start_date: start_date
          expect(assigns[:start_date]).to eq(start_date)
        end
        it 'should pass @as_of_date, `date_restriction` and @max_date to DatePickerHelper#date_picker_presets and set @picker_presets to its outcome' do
          allow(controller).to receive(:date_picker_presets).with(restricted_start_date, nil, ReportsController::DATE_RESTRICTION_MAPPING[:advances_detail], max_date).and_return(picker_preset_hash)
          get :advances_detail, start_date: start_date
          # expect(assigns[:picker_presets]).to eq(picker_preset_hash)
        end
        it 'should call the method `advances_details` on a MemberBalanceService instance with the `start` argument and set @advances_detail to its result' do
          allow(member_balance_service_instance).to receive(:advances_details).with(restricted_start_date).and_return(advances_detail)
          get :advances_detail, start_date: start_date
          expect(assigns[:advances_detail]).to eq(advances_detail)
        end
        it 'should raise an error if `advances_details` returns nil' do
          expect(member_balance_service_instance).to receive(:advances_details).and_return(nil)
          expect{get :advances_detail, start_date: start_date}.to raise_error
        end
        it 'should set @advances_detail to {} if the report is disabled' do
          expect(controller).to receive(:report_disabled?).with(ReportsController::ADVANCES_DETAIL_WEB_FLAGS).and_return(true)
          get :advances_detail
          expect(assigns[:advances_detail]).to eq({})
        end
        it 'should sort the advances found in @advances_detail[:advances_details]' do
          expect(advances_detail[:advances_details]).to receive(:sort!)
          get :advances_detail
        end
        it 'should order the advances found in @advances_detail[:advances_details] by `trade_date` ascending' do
          unsorted_advances = [
            {trade_date: Time.zone.today},
            {trade_date: Time.zone.today + 1.years},
            {trade_date: Time.zone.today - 1.years},
            {trade_date: Time.zone.today - 3.years}
          ]
          allow(advances_detail).to receive(:[]).with(:advances_details).and_return(unsorted_advances)
          get :advances_detail
          last_trade_date = nil
          assigns[:advances_detail][:advances_details].each do |advance|
            expect(advance[:trade_date]).to be >= last_trade_date if last_trade_date
            last_trade_date = advance[:trade_date]
          end
        end
        it 'should set @report_name' do
          get :advances_detail
          expect(assigns[:report_name]).to be_kind_of(String)
        end
      end

      describe 'setting the `prepayment_fee_indication_notes` attribute for a given advance record' do
        let(:advance_record) {double('Advance Record')}
        let(:advances_array) {[advance_record]}
        let(:prepayment_fee) {464654654}
        before do
          allow(advances_detail).to receive(:[]).with(:advances_details).at_least(1).and_return(advances_array)
          allow(member_balance_service_instance).to receive(:advances_details).and_return(advances_detail)
        end
        it 'sets the attribute to `unavailable online` message if `notes` attribute for that record is `unavailable_online`' do
          expect(advance_record).to receive(:[]=).with(:prepayment_fee_indication_notes, I18n.t('reports.pages.advances_detail.unavailable_online'))
          expect(advance_record).to receive(:[]).with(:notes).and_return('unavailable_online')
          get :advances_detail
        end
        it 'sets the attribute to `not applicable for vrc` message if `notes` attribute for that record is `not_applicable_to_vrc`' do
          expect(advance_record).to receive(:[]=).with(:prepayment_fee_indication_notes, I18n.t('reports.pages.advances_detail.not_applicable_to_vrc'))
          expect(advance_record).to receive(:[]).with(:notes).and_return('not_applicable_to_vrc')
          get :advances_detail
        end
        it 'sets the attribute to `prepayment fee restructure` message if `notes` attribute for that record is `prepayment_fee_restructure`' do
          date = Date.new(2013, 1, 1)
          expect(advance_record).to receive(:[]=).with(:prepayment_fee_indication_notes, I18n.t('reports.pages.advances_detail.prepayment_fee_restructure_html', date: fhlb_date_standard_numeric(date)))
          expect(advance_record).to receive(:[]).with(:structure_product_prepay_valuation_date).and_return(date)
          allow(advance_record).to receive(:[]).with(:prepayment_fee_indication).and_return(prepayment_fee)
          expect(advance_record).to receive(:[]).with(:notes).and_return('prepayment_fee_restructure')
          get :advances_detail
        end
        it 'doesn\'t set the attribute if that attribute exists and the `note` attribute is not `unavailable_online`, `not_applicable_to_vrc`, or `prepayment_fee_restructure`' do
          expect(advance_record).to_not receive(:[]=).with(:prepayment_fee_indication_notes, anything)
          expect(advance_record).to receive(:[]).with(:notes).and_return(nil)
          expect(advance_record).to receive(:[]).with(:prepayment_fee_indication).and_return(prepayment_fee)
          get :advances_detail
        end
        it 'sets the attribute to equal the `not available for past dates` message if there is no value for the `prepayment_fee_indication` attribute and the `note` attribute is not `unavailable_online`, `not_applicable_to_vrc`, or `prepayment_fee_restructure`' do
          expect(advance_record).to receive(:[]=).with(:prepayment_fee_indication_notes, I18n.t('reports.pages.advances_detail.unavailable_for_past_dates'))
          expect(advance_record).to receive(:[]).with(:notes).and_return(nil)
          expect(advance_record).to receive(:[]).with(:prepayment_fee_indication).and_return(nil)
          get :advances_detail
        end
      end
    end

    describe 'GET cash_projections' do
      let(:as_of_date) { '2014-12-12'.to_date }
      it_behaves_like 'a user required action', :get, :cash_projections


      before do
        allow(member_balance_service_instance).to receive(:cash_projections).and_return({})
      end
      it_behaves_like 'a report with instance variables set in a before_filter', :cash_projections
      it_behaves_like 'a controller action with an active nav setting', :cash_projections, :reports
      describe 'view instance variables' do
        before {
          allow(response_hash).to receive(:[]).with(:as_of_date).and_return(as_of_date)
          allow(member_balance_service_instance).to receive(:cash_projections).with(kind_of(Date)).and_return(response_hash)
        }
        it 'should set @cash_projections to the hash returned from MemberBalanceService' do
          expect(member_balance_service_instance).to receive(:cash_projections).and_return(response_hash)
          get :cash_projections
          expect(assigns[:cash_projections]).to eq(response_hash)
        end
        it 'should set @cash_projections to {} if the report is disabled' do
          expect(controller).to receive(:report_disabled?).with(ReportsController::CASH_PROJECTIONS_WEB_FLAGS).and_return(true)
          get :cash_projections
          expect(assigns[:cash_projections]).to eq({})
        end
        it 'should set @as_of_date from the @cash_projections hash' do
          expect(member_balance_service_instance).to receive(:cash_projections).and_return(response_hash)
          get :cash_projections
          expect(assigns[:as_of_date]).to eq(as_of_date)
        end
        it 'should set @as_of_date to nil if the report is disabled' do
          expect(controller).to receive(:report_disabled?).with(ReportsController::CASH_PROJECTIONS_WEB_FLAGS).and_return(true)
          get :cash_projections
          expect(assigns[:as_of_date]).to eq(nil)
        end
      end
    end

    describe 'GET dividend_statement' do
      let(:make_request) { get :dividend_statement }
      let(:response_hash) { double('A Dividend Statement', :'[]' => nil)}
      let(:year) { Array(2000..2015).sample }
      let(:quarter) { Array(1..4).sample }
      let(:div_id_regular) { "#{year}Q#{quarter}" }
      let(:div_id_special) { "#{year}Q#{quarter}#{['b', 'c', 'd'].sample}" }
      div_ids = ['2015Q2', '2015Q1', '2014Q4']
      before do
        allow(member_balance_service_instance).to receive(:dividend_statement).and_return(response_hash)
        allow(response_hash).to receive(:[]).with(:details).and_return([{}])
        allow(response_hash).to receive(:[]).with(:div_ids).and_return(div_ids)
      end
      it_behaves_like 'a user required action', :get, :dividend_statement
      it_behaves_like 'a report with instance variables set in a before_filter', :dividend_statement
      it_behaves_like 'a controller action with an active nav setting', :dividend_statement, :reports
      it 'calls MemberBalanceService.dividend_statement with the proper date restriction' do
        expect(member_balance_service_instance).to receive(:dividend_statement).with(ReportsController::DATE_RESTRICTION_MAPPING[:dividend_statement].ago.to_date, anything)
        make_request
      end
      it 'calls MemberBalanceService.dividend_statement with the dividend_transaction_filter parameter' do
        expect(member_balance_service_instance).to receive(:dividend_statement).with(anything, div_id_regular)
        get :dividend_statement, dividend_transaction_filter: div_id_regular
      end
      it 'should assign `@dividend_statement` to the result of calling MemberBalanceService.dividend_statement' do
        make_request
        expect(assigns[:dividend_statement]).to be(response_hash)
      end
      it 'should assign `@dividend_statement_details`' do
        make_request
        expect(assigns[:dividend_statement_details]).to be_present
        expect(assigns[:dividend_statement_details][:column_headings]).to be_kind_of(Array)
        expect(assigns[:dividend_statement_details][:rows]).to be_kind_of(Array)
        expect(assigns[:dividend_statement_details][:footer]).to be_kind_of(Array)
      end
      it 'should set @dividend_statement to {} if the report is disabled' do
        expect(controller).to receive(:report_disabled?).with(ReportsController::DIVIDEND_STATEMENT_WEB_FLAGS).and_return(true)
        make_request
        expect(assigns[:dividend_statement]).to eq({})
      end
      it 'should set @dividend_statement_details to have no rows if the report is disabled' do
        expect(controller).to receive(:report_disabled?).with(ReportsController::DIVIDEND_STATEMENT_WEB_FLAGS).and_return(true)
        make_request
        expect(assigns[:dividend_statement_details][:rows]).to eq([])
        expect(assigns[:dividend_statement_details][:footer]).to be_nil
      end
      it 'sets @dropdown_options labels from the div_ids returned by MemberBalanceService.dividend_statement' do
        allow(response_hash).to receive(:[]).with(:div_ids).and_return([div_id_regular])
        make_request
        expect(assigns[:dropdown_options][0][0]).to eq(I18n.t("dates.quarters.#{div_id_regular.last}", year: div_id_regular[0..3]))
      end
      it 'sets @dropdown_options labels for special dividends based on their div_id' do
        allow(response_hash).to receive(:[]).with(:div_ids).and_return([div_id_special])
        make_request
        I18n.t('reports.pages.dividend_statement.special_dividend', year: div_id_special[0..3])
      end
      it 'defaults @dropdown_options_text to the first label in @dropdown_options' do
        allow(response_hash).to receive(:[]).with(:div_ids).and_return(div_ids)
        make_request
        expect(assigns[:dropdown_options_text]).to eq(I18n.t("dates.quarters.#{div_ids.first.last}", year: div_ids.first[0..3]))
      end
      it 'defaults @div_id to the first value in @dropdown_options' do
        allow(response_hash).to receive(:[]).with(:div_ids).and_return(div_ids)
        make_request
        expect(assigns[:div_id]).to eq(div_ids.first)
      end
      div_ids.each do |div_id|
        it "sets @dropdown_options_text to the appropriate value when @div_id equals `#{div_id}`" do
          get :dividend_statement, dividend_transaction_filter: div_id
          expect(assigns[:dropdown_options_text]).to eq(I18n.t("dates.quarters.#{div_id.last}", year: div_id[0..3]))
        end
      end
      %w(1 2 3 4).each do |i|
        it "sets @show_summary_data to true if the @div_id ends in #{i}" do
          div_id = "#{year}Q#{i}"
          get :dividend_statement, dividend_transaction_filter: div_id
          expect(assigns[:show_summary_data]).to be(true)
        end
      end
      it 'does not set @show_summary_date if the @div_id ends in anything other than the numbers 1 through 4' do
        (Array(5..9) + ('a'..'z').to_a + ('A'..'Z').to_a).each do |i|
          div_id = "#{year}Q#{i}"
          get :dividend_statement, dividend_transaction_filter: div_id
          expect(assigns[:show_summary_data]).to be_nil
        end
      end
    end

    describe 'GET securities_services_statement' do
      let(:make_request) { get :securities_services_statement }
      let(:response_hash) { double('A Securities Services Statement', :'[]' => nil)}
      let(:report_end_date) { double( 'report_end_date' ) }
      let(:month_year) { double( 'month_year' ) }
      let(:start_date_param) { Date.today - rand(10000) }
      describe 'when statements are available' do
        before do
          allow(member_balance_service_instance).to receive(:securities_services_statements_available).and_return([{'month_year' => month_year, 'report_end_date' => report_end_date}])
          allow(member_balance_service_instance).to receive(:securities_services_statement).with(report_end_date).and_return([response_hash])
          allow(response_hash).to receive(:[]).with(:securities_fees).and_return([{}])
          allow(response_hash).to receive(:[]).with(:transaction_fees).and_return([{}])
        end
        it_behaves_like 'a user required action', :get, :securities_services_statement
        it_behaves_like 'a report with instance variables set in a before_filter', :securities_services_statement
        it_behaves_like 'a controller action with an active nav setting', :securities_services_statement, :reports
        it_behaves_like 'a report that can be downloaded', :securities_services_statement, [:pdf]
        it 'should set @start_date to the `report_end_date` attribute of the first entry of hash returned by securities_services_statements_available' do
          make_request
          expect(assigns[:start_date]).to eq(report_end_date)
        end
        it 'should assign `@statement` to the result of calling MemberBalanceService.securities_services_statement' do
          make_request
          expect(assigns[:statement]).to eq([response_hash])
        end
        it 'assigns @data_available a value of true' do
          make_request
          expect(assigns[:data_available]).to eq(true)
        end
        it 'should raise an error if @statement is nil' do
          expect(member_balance_service_instance).to receive(:securities_services_statement).and_return(nil)
          expect{make_request}.to raise_error(StandardError)
        end
        describe 'with the report disabled' do
          before do
            allow(controller).to receive(:report_disabled?).with(ReportsController::SECURITIES_SERVICES_STATMENT_WEB_FLAGS).and_return(true)
          end
          it 'should set @statement to {} if the report is disabled' do
            make_request
            expect(assigns[:statement]).to eq({})
          end
          it 'should set @start_date if the report is disabled' do
            make_request
            expect(assigns[:start_date]).to eq(report_end_date)
          end
        end
      end
      describe 'when no statements are available' do
        before { allow(member_balance_service_instance).to receive(:securities_services_statements_available).and_return([]) }
        it 'assigns @data_available a value of false' do
          make_request
          expect(assigns[:data_available]).to eq(false)
        end
      end
    end

    describe 'GET letters_of_credit' do
      let(:make_request) { get :letters_of_credit }
      let(:as_of_date) { double('some date') }
      let(:total_current_par) { double('total current par') }
      let(:maturity_date) {double('maturity date')}
      let(:letters_of_credit) { double('letters of credit array') }
      before do
        allow(response_hash).to receive(:[]=)
        allow(response_hash).to receive(:[]).with(:as_of_date)
        allow(response_hash).to receive(:[]).with(:total_current_par)
        allow(response_hash).to receive(:[]).with(:credits)
        allow(member_balance_service_instance).to receive(:letters_of_credit).and_return(response_hash)
        allow(controller).to receive(:sort_report_data).and_return([])
      end

      it_behaves_like 'a user required action', :get, :letters_of_credit
      it_behaves_like 'a report with instance variables set in a before_filter', :letters_of_credit
      it_behaves_like 'a controller action with an active nav setting', :letters_of_credit, :reports
      it_behaves_like 'a report that can be downloaded', :letters_of_credit, [:xlsx]

      it 'sorts the letters of credit by lc_number' do
        allow(member_balance_service_instance).to receive(:letters_of_credit).and_return({credits: letters_of_credit})
        expect(controller).to receive(:sort_report_data).with(letters_of_credit, :lc_number)
        make_request
      end
      describe 'view instance variables' do
        it 'sets @as_of_date to the value returned by MemberBalanceService.letters_of_credit' do
          expect(response_hash).to receive(:[]).with(:as_of_date).and_return(as_of_date)
          make_request
          expect(assigns[:as_of_date]).to eq(as_of_date)
        end
        it 'sets @total_current_par to the value returned by MemberBalanceService.letters_of_credit' do
          expect(response_hash).to receive(:[]).with(:total_current_par).and_return(total_current_par)
          make_request
          expect(assigns[:total_current_par]).to eq(total_current_par)
        end
        it 'sets @loc_table_data[:column_headings] to an array of column heading strings' do
          make_request
          assigns[:loc_table_data][:column_headings].each do |heading|
            expect(heading).to be_kind_of(String)
          end
        end
        it 'sets @loc_table_data[:rows] to the formatted value returned by MemberBalanceService.letters_of_credit' do
          credit_keys = [:lc_number, :current_par, :maintenance_charge, :trade_date, :maturity_date, :description]
          credit = {}
          credit_keys.each do |key|
            credit[key] = double(key.to_s)
          end
          expect(response_hash).to receive(:[]).with(:credits).at_least(:once).and_return([credit])
          make_request
          expect(assigns[:loc_table_data][:rows].length).to eq(1)
          credit_keys.each_with_index do |key, i|
            expect(assigns[:loc_table_data][:rows][0][:columns][i][:value]).to eq(credit[key])
          end
        end
        it 'sets @loc_table_data[:rows] to an empty array if no credit data is returned from MemberBalanceService.letters_of_credit' do
          make_request
          expect(assigns[:loc_table_data][:rows]).to eq([])
        end
      end
      describe 'with the report disabled' do
        before do
          allow(controller).to receive(:report_disabled?).with(ReportsController::LETTERS_OF_CREDIT_WEB_FLAGS).and_return(true)
        end
        it 'sets @as_of_date to nil if the report is disabled' do
          make_request
          expect(assigns[:as_of_date]).to be_nil
        end
        it 'sets @total_current_par to nil if the report is disabled' do
          make_request
          expect(assigns[:total_current_par]).to be_nil
        end
        it 'sets @loc_table_data[:rows] to {}' do
          make_request
          expect(assigns[:loc_table_data][:rows]).to eq([])
        end
      end
    end

    describe 'GET parallel_shift' do
      it_behaves_like 'a user required action', :get, :parallel_shift
      it_behaves_like 'a report with instance variables set in a before_filter', :parallel_shift
      it_behaves_like 'a controller action with an active nav setting', :parallel_shift, :reports
      projections = %i(shift_neg_300 shift_neg_200 shift_neg_100 shift_0 shift_100 shift_200 shift_300)
      let(:make_request) { get :parallel_shift }
      let(:as_of_date) { double('some date') }
      let(:interest_rate) { double('interest rate') }
      let(:putable_advance_data) do
        hash = {
          advance_number: nil,
          issue_date: nil,
          interest_rate: nil,
        }
        projections.each do |value|
          hash[value] = nil
        end
        hash.each do |key, value|
          if key == :interest_rate
            hash[key] = double(key.to_s, :* => interest_rate)
          else
            hash[key] = double(key.to_s)
          end
        end
        hash
      end
      let(:putable_advance_nil_data) do
        hash = putable_advance_data.dup
        hash.each do |key, value|
          hash[key] = nil if projections.include?(key)
        end
        hash
      end
      let(:parallel_shift_data) { {as_of_date: as_of_date, putable_advances: [putable_advance_data]} }
      let(:parallel_shift_nil_data) { {as_of_date: as_of_date, putable_advances: [putable_advance_nil_data]} }
      before do
        allow(member_balance_service_instance).to receive(:parallel_shift).and_return(parallel_shift_data)
      end
      it 'sorts putable advances by advance number' do
        expect(controller).to receive(:sort_report_data).with([putable_advance_data], :advance_number).and_return([])
        make_request
      end
      describe 'view instance variables' do
        it 'sets @as_of_date to the date returned from MemberBalanceService.parallel_shift' do
          make_request
          expect(assigns[:as_of_date]).to eq(as_of_date)
        end
        describe '`@parallel_shift_table_data`' do
          before do
            make_request
          end
          it 'returns a hash with `column_headings`' do
            expect(assigns[:parallel_shift_table_data][:column_headings]).to eq([I18n.t('common_table_headings.advance_number'), I18n.t('global.issue_date'), fhlb_add_unit_to_table_header(I18n.t('common_table_headings.interest_rate'), '%'), [-300,-200,-100,0,100,200,300].collect{|x| fhlb_formatted_number(x)}].flatten)
          end
          describe '`rows`' do
            it 'is an array containing a `columns` hash' do
              expect(assigns[:parallel_shift_table_data][:rows]).to be_kind_of(Array)
              assigns[:parallel_shift_table_data][:rows].each do |row|
                expect(row).to be_kind_of(Hash)
              end
            end
            describe '`columns` hash' do
              it 'contains an `advance_number` with no type' do
                assigns[:parallel_shift_table_data][:rows].each do |row|
                  expect(row[:columns].first[:type]).to be_nil
                  expect(row[:columns].first[:value]).to eq(putable_advance_data[:advance_number])
                end
              end
              it 'contains an `issue_date` with type `date`' do
                assigns[:parallel_shift_table_data][:rows].each do |row|
                  expect(row[:columns][1][:type]).to eq(:date)
                  expect(row[:columns][1][:value]).to eq(putable_advance_data[:issue_date])
                end
              end
              it 'contains a `interest_rate` with type `date`' do
                assigns[:parallel_shift_table_data][:rows].each do |row|
                  expect(row[:columns][2][:type]).to eq(:rate)
                  expect(row[:columns][2][:value]).to eq(interest_rate)
                end
              end
              projections.each_with_index do |value, i|
                it "contains a `#{value}` value with type `basis_point`" do
                  assigns[:parallel_shift_table_data][:rows].each do |row|
                    expect(row[:columns][i + 3][:type]).to eq(:rate)
                    expect(row[:columns][i + 3][:value]).to eq(putable_advance_data[value])
                  end
                end
              end
            end
          end
        end
        describe '`@parallel_shift_table_data` rows column hash with putable_advances containing nil values' do
          projections.each_with_index do |value, i|
            it "contains a `#{value}` with a value of #{I18n.t('global.na')} and no type if `#{value}` is blank" do
              allow(member_balance_service_instance).to receive(:parallel_shift).and_return(parallel_shift_nil_data)
              make_request
              assigns[:parallel_shift_table_data][:rows].each do |row|
                expect(row[:columns][i + 3][:type]).to be_nil
                expect(row[:columns][i + 3][:value]).to eq(I18n.t('global.na'))
              end
            end
          end
        end
        describe 'with the report disabled' do
          before do
            allow(controller).to receive(:report_disabled?).with(ReportsController::PARALLEL_SHIFT_WEB_FLAGS).and_return(true)
          end
          it 'sets @as_of_date to nil if the report is disabled' do
            make_request
            expect(assigns[:as_of_date]).to be_nil
          end
          it '@parallel_shift_table_data has an empty array for its rows attribute' do
            make_request
            expect(assigns[:parallel_shift_table_data][:rows]).to eq([])
          end
        end
      end
      it 'should raise an error if the MemberBalanceService returns nil' do
        expect(member_balance_service_instance).to receive(:parallel_shift).and_return(nil)
        expect{make_request}.to raise_error(StandardError)
      end
    end
    describe 'GET current_securities_position' do
      dropdown_options = [
        [I18n.t('reports.pages.securities_position.filter.all'), 'all'],
        [I18n.t('reports.pages.securities_position.filter.pledged'), 'pledged'],
        [I18n.t('reports.pages.securities_position.filter.unpledged'), 'unpledged']
      ]
      let(:securities_position_response) { double('Current Securities Position response', :[] => nil) }
      let(:as_of_date) { Date.new(2014,1,1) }
      before {
        allow(securities_position_response).to receive(:[]).with(:securities).and_return([])
        allow(securities_position_response).to receive(:[]=).with(:securities, anything)
        allow(member_balance_service_instance).to receive(:current_securities_position).and_return(securities_position_response)
      }

      it_behaves_like 'a user required action', :get, :current_securities_position
      it_behaves_like 'a report with instance variables set in a before_filter', :current_securities_position
      it_behaves_like 'a controller action with an active nav setting', :current_securities_position, :reports
      it_behaves_like 'a report that can be downloaded', :current_securities_position, [:xlsx]

      describe 'view instance variables' do
        let(:unprocessed_securities) { double('unprocessed securities details', length: nil) }
        let(:processed_securities) { double('processed securities details') }
        it 'sets @current_securities_position to the hash returned from MemberBalanceService' do
          get :current_securities_position
          expect(assigns[:current_securities_position]).to eq(securities_position_response)
        end
        it 'sets @current_securities_position to {securities:[]} if the report is disabled' do
          allow(controller).to receive(:report_disabled?).with(ReportsController::CURRENT_SECURITIES_POSITION_WEB_FLAG).and_return(true)
          get :current_securities_position
          expect(assigns[:current_securities_position]).to eq({securities:[]})
        end
        it 'sets @current_securities_position[:securities] to the result of the `format_securities_detail` method' do
          allow(securities_position_response).to receive(:[]).with(:securities).and_return(unprocessed_securities)
          allow(controller).to receive(:format_securities_detail).with(unprocessed_securities).and_return(processed_securities)
          expect(securities_position_response).to receive(:[]=).with(:securities, processed_securities)
          get :current_securities_position
        end
        it 'sets @securities_filter to `all` if no securities_filter param is provided' do
          get :current_securities_position
          expect(assigns[:securities_filter]).to eq('all')
        end
        it 'sets @securities_filter to the value of the securities_filter param' do
          get :current_securities_position, securities_filter: 'some filter'
          expect(assigns[:securities_filter]).to eq('some filter')
        end
        it 'sets @headings to a hash containing various headings for the page' do
          get :current_securities_position
          expect(assigns[:headings]).to be_kind_of(Hash)
          expect(assigns[:headings][:total_original_par]).to be_kind_of(String)
          expect(assigns[:headings][:total_current_par]).to be_kind_of(String)
          expect(assigns[:headings][:total_market_value]).to be_kind_of(String)
          expect(assigns[:headings][:table_heading]).to be_kind_of(String)
          expect(assigns[:headings][:footer_total]).to be_kind_of(String)
        end
        it 'sets @securities_filter_options to an array of arrays containing the appropriate values and labels for credit, debit, daily balance and all' do
          get :current_securities_position
          expect(assigns[:securities_filter_options]).to eq(dropdown_options)
        end
        it 'sets @report_download_column_headings to an array of column headings' do
          column_headings = [
            I18n.t('common_table_headings.custody_account_number'), I18n.t('reports.pages.securities_position.custody_account_type'), I18n.t('reports.pages.securities_position.security_pledge_type'),
            I18n.t('common_table_headings.cusip'), I18n.t('common_table_headings.security_description'), I18n.t('reports.pages.securities_position.reg_id'),
            I18n.t('common_table_headings.pool_number'), I18n.t('common_table_headings.coupon_rate'), I18n.t('common_table_headings.maturity_date'),
            I18n.t('common_table_headings.original_par_value'), I18n.t('reports.pages.securities_position.factor'), I18n.t('reports.pages.securities_position.factor_date'),
            I18n.t('common_table_headings.current_par'), I18n.t('common_table_headings.price'), I18n.t('common_table_headings.price_date'),
            I18n.t('reports.pages.securities_position.market_value')
          ]
          get :current_securities_position
          expect(assigns[:report_download_column_headings]).to eq(column_headings)
        end
        dropdown_options.each do |option|
          it "sets @securities_filter_text to the appropriate value when @securities_filter equals `#{option.last}`" do
            get :current_securities_position, securities_filter: option.last
            expect(assigns[:securities_filter_text]).to eq(option.first)
          end
        end
      end
    end
    describe 'GET monthly_securities_position' do
      dropdown_options = [
        [I18n.t('reports.pages.securities_position.filter.all'), 'all'],
        [I18n.t('reports.pages.securities_position.filter.pledged'), 'pledged'],
        [I18n.t('reports.pages.securities_position.filter.unpledged'), 'unpledged']
      ]
      let(:securities_position_response) { double('Monthly Securities Position response', :[] => nil) }
      let(:as_of_date) { Date.new(2014,1,1) }
      let(:end_of_month) { (start_date - 1.month).end_of_month }
      let(:month_restricted_start_date) { Date.today - rand(10000) }
      let(:start_date_param) { Date.today - rand(10000) }
      before {
        allow(securities_position_response).to receive(:[]).with(:securities).and_return([])
        allow(securities_position_response).to receive(:[]=).with(:securities, anything)
        allow(member_balance_service_instance).to receive(:monthly_securities_position).and_return(securities_position_response)
        allow(restricted_start_date).to receive(:end_of_month).and_return(end_of_month)
        allow(controller).to receive(:month_restricted_start_date).and_return(end_of_month)
        allow(controller).to receive(:default_dates_hash).and_return({last_month_end: end_of_month})
      }
      it_behaves_like 'a user required action', :get, :monthly_securities_position
      it_behaves_like 'a date restricted report', :monthly_securities_position, :last_month_end
      it_behaves_like 'a report with instance variables set in a before_filter', :monthly_securities_position
      it_behaves_like 'a controller action with an active nav setting', :monthly_securities_position, :reports
      it_behaves_like 'a report that can be downloaded', :monthly_securities_position, [:xlsx]
      describe 'view instance variables' do
        let(:unprocessed_securities) { double('unprocessed securities details', length: nil) }
        let(:processed_securities) { double('processed securities details') }
        it 'sets @month_end_date to end_of_month' do
          get :monthly_securities_position
          expect(assigns[:month_end_date]).to eq(end_of_month)
        end
        it 'sets @monthly_securities_position to the hash returned from MemberBalanceService' do
          get :monthly_securities_position
          expect(assigns[:monthly_securities_position]).to eq(securities_position_response)
        end
        it 'sets @monthly_securities_position to {securities:[]} if the report is disabled' do
          allow(controller).to receive(:report_disabled?).with(ReportsController::MONTHLY_SECURITIES_WEB_FLAGS).and_return(true)
          get :monthly_securities_position
          expect(assigns[:monthly_securities_position]).to eq({securities:[]})
        end
        it 'sets @monthly_securities_position[:securities] to the result of the `format_securities_detail` method' do
          allow(securities_position_response).to receive(:[]).with(:securities).and_return(unprocessed_securities)
          allow(controller).to receive(:format_securities_detail).with(unprocessed_securities).and_return(processed_securities)
          expect(securities_position_response).to receive(:[]=).with(:securities, processed_securities)
          get :monthly_securities_position
        end
        it 'sets @securities_filter to `all` if no securities_filter param is provided' do
          get :monthly_securities_position
          expect(assigns[:securities_filter]).to eq('all')
        end
        it 'sets @securities_filter to the value of the securities_filter param' do
          get :monthly_securities_position, securities_filter: 'some filter'
          expect(assigns[:securities_filter]).to eq('some filter')
        end
        it 'sets @headings to a hash containing various headings for the page' do
          get :monthly_securities_position
          expect(assigns[:headings]).to be_kind_of(Hash)
          expect(assigns[:headings][:total_original_par]).to be_kind_of(String)
          expect(assigns[:headings][:total_current_par]).to be_kind_of(String)
          expect(assigns[:headings][:total_market_value]).to be_kind_of(String)
          expect(assigns[:headings][:table_heading]).to be_kind_of(String)
          expect(assigns[:headings][:footer_total]).to be_kind_of(String)
        end
        it 'sets @securities_filter_options to an array of arrays containing the appropriate values and labels for credit, debit, daily balance and all' do
          get :monthly_securities_position
          expect(assigns[:securities_filter_options]).to eq(dropdown_options)
        end
        it 'sets @report_download_column_headings to an array of column headings' do
          column_headings = [
            I18n.t('common_table_headings.custody_account_number'), I18n.t('reports.pages.securities_position.custody_account_type'), I18n.t('reports.pages.securities_position.security_pledge_type'),
            I18n.t('common_table_headings.cusip'), I18n.t('common_table_headings.security_description'), I18n.t('reports.pages.securities_position.reg_id'),
            I18n.t('common_table_headings.pool_number'), I18n.t('common_table_headings.coupon_rate'), I18n.t('common_table_headings.maturity_date'),
            I18n.t('common_table_headings.original_par_value'), I18n.t('reports.pages.securities_position.factor'), I18n.t('reports.pages.securities_position.factor_date'),
            I18n.t('common_table_headings.current_par'), I18n.t('common_table_headings.price'), I18n.t('common_table_headings.price_date'),
            I18n.t('reports.pages.securities_position.market_value')
          ]
          get :monthly_securities_position
          expect(assigns[:report_download_column_headings]).to eq(column_headings)
        end
        dropdown_options.each do |option|
          it "sets @securities_filter_text to the appropriate value when @securities_filter equals `#{option.last}`" do
            get :monthly_securities_position, securities_filter: option.last
            expect(assigns[:securities_filter_text]).to eq(option.first)
          end
        end
        it 'should pass @start_date, nil, `date_restriction`, nil and `today` to DatePickerHelper#date_picker_presets and set @picker_presets to its outcome' do
          expect(controller).to receive(:date_picker_presets).with(anything, anything, anything, anything, [:today]).and_return(date_picker_presets)
          get :monthly_securities_position
        end
      end
    end
    describe 'GET forward_commitments' do
      let(:forward_commitments) { get :forward_commitments }
      let(:forward_commitments_response) { double('Forward Commitments response', :[] => nil) }
      let(:as_of_date) { double('Date') }
      let(:total_current_par) { double('Total current par') }
      before {
        allow(member_balance_service_instance).to receive(:forward_commitments).and_return(forward_commitments_response)
      }

      it_behaves_like 'a user required action', :get, :forward_commitments
      it_behaves_like 'a report that can be downloaded', :forward_commitments, [:xlsx]
      it_behaves_like 'a report with instance variables set in a before_filter', :forward_commitments
      it_behaves_like 'a controller action with an active nav setting', :forward_commitments, :reports
      describe 'view instance variables' do
        it 'sets @as_of_date to the value returned from the service endpoint' do
          allow(forward_commitments_response).to receive(:[]).with(:as_of_date).and_return(as_of_date)
          forward_commitments
          expect(assigns[:as_of_date]).to eq(as_of_date)
        end
        it 'sets @total_current_par to the value returned from the service endpoint' do
          allow(forward_commitments_response).to receive(:[]).with(:total_current_par).and_return(total_current_par)
          forward_commitments
          expect(assigns[:total_current_par]).to eq(total_current_par)
        end
        describe '@table_data' do
          it 'should contain a `column_headings` array containing hashes with a `title` key' do
            forward_commitments
            assigns[:table_data][:column_headings].each {|heading| expect(heading[:title]).to be_kind_of(String)}
          end
          it 'should contain a `column_headings` array containing hashes with a `sortable` key' do
            forward_commitments
            assigns[:table_data][:column_headings].each {|heading| expect(heading[:sortable]).to eq(true)}
          end
          %i(rows footer).each do |attr|
            it "should contain a #{attr} array" do
              forward_commitments
              expect(assigns[:table_data][attr]).to be_kind_of(Array)
            end
          end
          it 'sets @table_data[:rows] to the formatted value returned by MemberBalanceService.forward_commitments' do
            row_keys = [:trade_date, :funding_date, :maturity_date, :advance_number, :advance_type, :current_par]
            row = {}
            row_keys.each do |key|
              row[key] = double(key.to_s)
            end
            allow(forward_commitments_response).to receive(:[]).with(:advances).at_least(:once).and_return([row])
            forward_commitments
            expect(assigns[:table_data][:rows].length).to eq(1)
            row_keys.each_with_index do |key, i|
              expect(assigns[:table_data][:rows][0][:columns][i][:value]).to eq(row[key])
            end
          end
          it "sets the interest_rate value in @table_data[:rows] to #{I18n.t('global.tbd')} if the interest rate for that row is 0" do
            allow(forward_commitments_response).to receive(:[]).with(:advances).at_least(:once).and_return([{interest_rate: 0}])
            forward_commitments
            expect(assigns[:table_data][:rows][0][:columns].last[:value]).to eq(I18n.t('global.tbd'))
            expect(assigns[:table_data][:rows][0][:columns].last[:type]).to be_nil
          end
          it "sets the interest_rate value in @table_data[:rows] to its value if the interest rate for that row is greater than 0" do
            interest_rate = rand()
            allow(forward_commitments_response).to receive(:[]).with(:advances).at_least(:once).and_return([{interest_rate: interest_rate}])
            forward_commitments
            expect(assigns[:table_data][:rows][0][:columns].last[:value]).to eq(interest_rate)
            expect(assigns[:table_data][:rows][0][:columns].last[:type]).to eq(:rate)
          end
          it 'sets @table_data[:rows] to an empty array if no row data is returned from MemberBalanceService.forward_commitments' do
            forward_commitments
            expect(assigns[:table_data][:rows]).to eq([])
          end
        end
      end
      describe 'with the report disabled' do
        before do
          allow(controller).to receive(:report_disabled?).with(ReportsController::FORWARD_COMMITMENTS_WEB_FLAG).and_return(true)
        end
        it 'sets @as_of_date to nil if the report is disabled' do
          forward_commitments
          expect(assigns[:as_of_date]).to be_nil
        end
        it 'sets @total_current_par to nil if the report is disabled' do
          forward_commitments
          expect(assigns[:total_current_par]).to be_nil
        end
        it 'sets @table_data[:rows] to {}' do
          forward_commitments
          expect(assigns[:table_data][:rows]).to eq([])
        end
      end
    end
    describe 'GET capital_stock_and_leverage' do
      let(:capital_stock_and_leverage) { get :capital_stock_and_leverage }
      let(:capital_stock_and_leverage_response) { double('Capital stock and leverage response', :[] => nil) }
      let(:surplus_stock) { rand(1..999999999) }
      before {
        allow(member_balance_service_instance).to receive(:capital_stock_and_leverage).and_return(capital_stock_and_leverage_response)
      }

      it_behaves_like 'a user required action', :get, :capital_stock_and_leverage
      it_behaves_like 'a report with instance variables set in a before_filter', :capital_stock_and_leverage
      it_behaves_like 'a controller action with an active nav setting', :capital_stock_and_leverage, :reports
      %w(position_table_data leverage_table_data).each do |table|
        describe "the @#{table} view instance variable" do
          it 'contains a `column_headings` array containing strings' do
            capital_stock_and_leverage
            assigns[table.to_sym][:column_headings].each {|heading| expect(heading).to be_kind_of(String)}
          end

          it "sets @#{table}[:rows] column object value to the value returned by MemberBalanceService.capital_stock_and_leverage" do
            row_keys = [:stock_owned, :minimum_requirement, :excess_stock, :surplus_stock, :stock_owned, :activity_based_requirement, :remaining_stock, :remaining_leverage]
            row = {}
            row_keys.each do |key|
              row[key] = double(key.to_s)
              if key == :surplus_stock
                allow(capital_stock_and_leverage_response).to receive(:[]).with(key).and_return(surplus_stock)
              else
                allow(capital_stock_and_leverage_response).to receive(:[]).with(key).and_return(row[key])
              end
            end
            capital_stock_and_leverage
            expect(assigns[table.to_sym][:rows].length).to eq(1)
            if table == 'position_table_data'
              row_keys.each_with_index do |key, i|
                break if i > 3
                if key == :surplus_stock
                  expect(assigns[table.to_sym][:rows][0][:columns][i][:value]).to eq(surplus_stock)
                else
                  expect(assigns[table.to_sym][:rows][0][:columns][i][:value]).to eq(row[key])
                end
              end
            else
              row_keys.each_with_index do |key, i|
                next if (0..3).include?(i)
                expect(assigns[table.to_sym][:rows][0][:columns][i-4][:value]).to eq(row[key])
              end
            end
          end
          it 'returns 0 for surplus_stock that is negative' do
            surplus_stock = rand(-99999999..-1)
            allow(capital_stock_and_leverage_response).to receive(:[]).with(:surplus_stock).and_return(surplus_stock)
            capital_stock_and_leverage
            expect(assigns[:position_table_data][:rows][0][:columns].last[:value]).to eq(0)
          end
          it "sets @#{table}[:rows] column object type to `:number`" do
            capital_stock_and_leverage
            assigns[table.to_sym][:rows][0][:columns].each do |object|
              expect(object[:type]).to eq(:number)
            end
          end
        end
        describe 'with the report disabled' do
          before do
            allow(controller).to receive(:report_disabled?).with(ReportsController::CAPITAL_STOCK_AND_LEVERAGE_WEB_FLAGS).and_return(true)
          end
          it "sets @#{table}[:rows] to have a single `columns` array with objects containing nil values" do
            capital_stock_and_leverage
            assigns[table.to_sym][:rows][0][:columns].each do |column|
              expect(column[:value]).to be_nil
            end
          end
        end
      end
    end
    describe 'GET interest_rate_resets' do
      let(:rates_service_instance) { double('RatesService') }
      let(:response_hash) { double('RatesServiceHash') }
      let(:effective_date) { double('effective_date') }
      let(:advance_number) { double('advance_number') }
      let(:prior_rate) { double('prior_rate') }
      let(:new_rate) { double('new_rate') }
      let(:next_reset) { double('next_reset') }
      let(:date_processed) { double('date processed') }
      let(:advances) { [{'effective_date' => effective_date, 'advance_number' => advance_number, 'prior_rate' => prior_rate, 'new_rate' => new_rate, 'next_reset' => next_reset}] }
      let(:irr_response) {{date_processed: date_processed, interest_rate_resets: advances}}
      let(:interest_rate_resets) { get :interest_rate_resets }

      before do
        allow(member_balance_service_instance).to receive(:interest_rate_resets).and_return(irr_response)
      end
      it_behaves_like 'a user required action', :get, :interest_rate_resets
      it_behaves_like 'a report with instance variables set in a before_filter', :interest_rate_resets
      it_behaves_like 'a controller action with an active nav setting', :interest_rate_resets, :reports
      it 'renders the interest_rate_resets view' do
        interest_rate_resets
        expect(response.body).to render_template('interest_rate_resets')
      end
      it 'sorts the interest rate resets by effective date' do
        expect(controller).to receive(:sort_report_data).with(advances, :effective_date).and_return(advances)
        interest_rate_resets
      end
      describe 'view instance variables' do
        it 'sets the @irr_table_data row attribute' do
          interest_rate_resets
          expect(assigns[:irr_table_data][:rows][0][:columns]).to eq([{:type=>:date, :value=>effective_date}, {:value=>advance_number}, {:type=>:index, :value=>prior_rate}, {:type=>:index, :value=>new_rate}, {:type=>:date, :value=>next_reset}])
        end
        it 'sets the @irr_table_data column_headings attribute' do
          interest_rate_resets
          assigns[:irr_table_data][:column_headings].each do |heading|
            expect(heading).to be_kind_of(String)
          end
        end
        it 'sets @date_processed' do
          interest_rate_resets
          expect(assigns[:date_processed]).to eq(date_processed)
        end
        it "sets the `value` attribute of the @irr_table_data[:row] cell for `next_reset` equal to #{I18n.t('global.open')} if there is no data for that cell" do
          allow(member_balance_service_instance).to receive(:interest_rate_resets).and_return({interest_rate_resets: [{'next_reset' => nil}]})
          interest_rate_resets
          expect(assigns[:irr_table_data][:rows][0][:columns]).to eq([{:value=>I18n.t('global.open')}])
        end
      end
      describe 'with the report disabled' do
        before do
          allow(controller).to receive(:report_disabled?).with(ReportsController::INTEREST_RATE_RESETS_WEB_FLAGS).and_return(true)
        end
        it "sets @irr_data_table[:rows] to be an empty array" do
          interest_rate_resets
          expect(assigns[:irr_table_data][:rows]).to eq([])
        end
        it 'does not set @date_processed' do
          interest_rate_resets
          expect(assigns[:date_processed]).to be_nil
        end
      end
      it 'raises an error if the MAPI endpoint returns nil' do
        allow(member_balance_service_instance).to receive(:interest_rate_resets).and_return(nil)
        expect{interest_rate_resets}.to raise_error
      end
    end
    describe 'GET todays_credit' do
      let(:todays_credit) { get :todays_credit }
      let(:credit_activity) { {transaction_number: double('transaction_number'), current_par: double('current_par'), interest_rate: double('interest_rate'), funding_date: double('funding_date'), maturity_date: double('maturity_date', is_a?: true), product_description: double('product_description')} }
      let(:credit_activity_advance) { {instrument_type: 'ADVANCE'} }
      let(:todays_credit_response) { [credit_activity] }
      before do
        allow(member_balance_service_instance).to receive(:todays_credit_activity).and_return(todays_credit_response)
      end
      it_behaves_like 'a user required action', :get, :todays_credit
      it_behaves_like 'a report with instance variables set in a before_filter', :todays_credit
      it_behaves_like 'a controller action with an active nav setting', :todays_credit, :reports
      it 'sorts activities by funding date' do
        expect(controller).to receive(:sort_report_data).with([credit_activity], :funding_date).and_return([])
        todays_credit
      end
      describe 'view instance variables' do
        it 'sets the @todays_credit row attribute' do
          todays_credit
          expect(assigns[:todays_credit][:rows][0][:columns]).to eq([{value: credit_activity[:transaction_number]}, {type: :number, value: credit_activity[:current_par]}, {type: :index, value: credit_activity[:interest_rate]}, {type: :date, value: credit_activity[:funding_date]}, {type: :date, value: credit_activity[:maturity_date]}, {value: financial_instrument_standardize(credit_activity[:product_description])}])
        end
        it 'sets the @todays_credit column_headings attribute' do
          todays_credit
          assigns[:todays_credit][:column_headings].each do |heading|
            expect(heading).to be_kind_of(String)
          end
        end
        it "sets the `maturity_date` attribute of a given activity to #{I18n.t('global.open')} and its type to nil if the activity is an advance with no maturity date" do
          allow(member_balance_service_instance).to receive(:todays_credit_activity).and_return([credit_activity_advance])
          todays_credit
          expect(assigns[:todays_credit][:rows][0][:columns][4][:value]).to eq(I18n.t('global.open'))
          expect(assigns[:todays_credit][:rows][0][:columns][4][:type]).to be_nil
        end
      end
      describe 'with the report disabled' do
        before do
          allow(controller).to receive(:report_disabled?).with(ReportsController::TODAYS_CREDIT_ACTIVITY_WEB_FLAGS).and_return(true)
        end
        it "sets @todays_credit[:rows] to be an empty array" do
          todays_credit
          expect(assigns[:todays_credit][:rows]).to eq([])
        end
      end
      it 'raises an error if the MAPI endpoint returns nil' do
        allow(member_balance_service_instance).to receive(:todays_credit_activity).and_return(nil)
        expect{todays_credit}.to raise_error
      end
    end

    describe 'GET mortgage_collateral_update' do
      column_headings = [I18n.t('common_table_headings.transaction'), I18n.t('common_table_headings.loan_count'), fhlb_add_unit_to_table_header(I18n.t('common_table_headings.unpaid_balance'), '$'), fhlb_add_unit_to_table_header(I18n.t('global.original_amount'), '$')]
      accepted_loans_hash = {
        instance_variable: :accepted_loans_table_data,
        table_row_arg: %w(updated pledged renumbered),
        table_column_args: ['accepted', I18n.t('reports.pages.mortgage_collateral_update.total_accepted')]
      }
      submitted_loans_hash = {
        instance_variable: :submitted_loans_table_data,
        table_row_arg: %w(accepted rejected),
        table_column_args: ['total', I18n.t('reports.pages.mortgage_collateral_update.total_submitted')]
      }
      let(:mortgage_collateral_update) { get :mortgage_collateral_update }
      let(:mcu_data) { double('mcu data from service object') }
      let(:table_rows) { double('table rows') }
      let(:table_footer) { double('table footer') }
      before do
        allow(member_balance_service_instance).to receive(:mortgage_collateral_update).and_return(mcu_data)
        allow(subject).to receive(:mcu_table_rows_for)
        allow(subject).to receive(:mcu_table_columns_for)
      end

      it_behaves_like 'a user required action', :get, :mortgage_collateral_update

      it 'renders the mortgage_collateral_update view' do
        mortgage_collateral_update
        expect(response.body).to render_template('mortgage_collateral_update')
      end
      it 'sets the @mcu_data instance variable to the result of the `mortgage_collateral_update` MemberBalanceService method' do
        mortgage_collateral_update
        expect(assigns[:mcu_data]).to eq(mcu_data)
      end

      [accepted_loans_hash, submitted_loans_hash].each do |hash|
        describe "the @#{hash[:instance_variable].to_s} instance variable" do
          it "has a column_headings array equal to #{column_headings}" do
            mortgage_collateral_update
            expect(assigns[hash[:instance_variable]][:column_headings]).to eq(column_headings)
          end
          it "calls the `mcu_table_columns_for` private method with @mcu_data, #{hash[:table_column_args].first}, #{hash[:table_column_args].last}" do
            expect(subject).to receive(:mcu_table_columns_for).with(mcu_data, hash[:table_column_args].first, hash[:table_column_args].last)
            mortgage_collateral_update
          end
          it 'has a footer array equal to the result of the `mcu_table_columns_for` private method' do
            allow(subject).to receive(:mcu_table_columns_for).with(mcu_data, hash[:table_column_args].first, hash[:table_column_args].last).and_return(table_footer)
            mortgage_collateral_update
            expect(assigns[hash[:instance_variable]][:footer]).to eq(table_footer)
          end
          it "calls the `mcu_table_rows_for` private method with @mcu_data, #{hash[:table_row_arg]}" do
            expect(subject).to receive(:mcu_table_rows_for).with(mcu_data, hash[:table_row_arg])
            mortgage_collateral_update
          end
          it "has a rows array equal to the result of the `mcu_table_rows_for` private method" do
            allow(subject).to receive(:mcu_table_rows_for).with(mcu_data, hash[:table_row_arg]).and_return(table_rows)
            mortgage_collateral_update
            expect(assigns[hash[:instance_variable]][:rows]).to eq(table_rows)
          end
        end
      end
      describe 'the @depledged_loans_table_data instance variable' do
        it "has a column_headings array equal to #{column_headings}" do
          mortgage_collateral_update
          expect(assigns[:depledged_loans_table_data][:column_headings]).to eq(column_headings)
        end
        it "calls the `mcu_table_columns_for` private method with @mcu_data, 'depledged', #{I18n.t('reports.pages.mortgage_collateral_update.loans_depledged')}" do
          expect(subject).to receive(:mcu_table_columns_for).with(mcu_data, 'depledged', I18n.t('reports.pages.mortgage_collateral_update.loans_depledged'))
          mortgage_collateral_update
        end
        it "has a rows array with a row object containing the result of the `mcu_table_columns_for` private method" do
          expect(subject).to receive(:mcu_table_columns_for).with(mcu_data, 'depledged', I18n.t('reports.pages.mortgage_collateral_update.loans_depledged')).and_return(table_rows)
          mortgage_collateral_update
          expect(assigns[:depledged_loans_table_data][:rows]).to eq([{columns: table_rows}])
        end
      end
      describe 'with the report disabled' do
        before do
          allow(controller).to receive(:report_disabled?).with(ReportsController::MORTGAGE_COLLATERAL_UPDATE_WEB_FLAGS).and_return(true)
        end
        it "sets @mcu_data to an hash" do
          mortgage_collateral_update
          expect(assigns[:mcu_data]).to eq({})
        end
      end
      it 'raises an error if the MAPI endpoint returns nil' do
        allow(member_balance_service_instance).to receive(:mortgage_collateral_update).and_return(nil)
        expect{mortgage_collateral_update}.to raise_error
      end
    end
  end

  describe 'GET borrowing_capacity' do
    it_behaves_like 'a user required action', :get, :borrowing_capacity
    it_behaves_like 'a report that can be downloaded', :borrowing_capacity, [:pdf]
    it_behaves_like 'a report with instance variables set in a before_filter', :borrowing_capacity
    it_behaves_like 'a controller action with an active nav setting', :borrowing_capacity, :reports

    let(:job_status) { double('JobStatus', update_attributes!: nil, id: nil, destroy: nil, result_as_string: nil ) }
    let(:member_balance_service_job_instance) { double('member_balance_service_job_instance', job_status: job_status) }
    let(:user_id) { rand(0..99999) }
    let(:user) { double(User, id: user_id, accepted_terms?: true) }
    let(:response_hash) { double('hash of borrowing capacity data', :[] => nil) }
    let(:job_id) { rand(0..99999) }
    let(:member_id) { rand(0..99999) }
    let(:call_action) { get :borrowing_capacity }
    let(:call_action_with_job_id) { get :borrowing_capacity, job_id: job_id }
    let(:end_date) { Date.new(2016, 1, 1) }

    RSpec.shared_examples 'a borrowing_capacity path involving a MemberBalanceServiceJob' do |job_call, deferred_job = false|
      let(:job_response) {deferred_job ? response_hash : member_balance_service_job_instance}
      describe "calling `#{job_call}` on the MemberBalanceServiceJob" do
        it 'passes the member id' do
          allow(controller).to receive(:report_disabled?).and_return(false)
          allow(controller).to receive(:current_member_id).and_return(member_id)
          expect(MemberBalanceServiceJob).to receive(job_call).with(member_id, any_args).and_return(job_response)
          call_action
        end
        it 'passes `borrowing_capacity_summary`' do
          expect(MemberBalanceServiceJob).to receive(job_call).with(anything, 'borrowing_capacity_summary', any_args).and_return(job_response)
          call_action
        end
        it 'passes the proper uuid' do
          expect(MemberBalanceServiceJob).to receive(job_call).with(anything, anything, request.uuid, anything).and_return(job_response)
          call_action
        end
        describe 'additional arguments' do
          before { allow(ReportConfiguration).to receive(:date_bounds).and_call_original }
          it 'passes today as the final argument if no end_date param is provided' do
            expect(MemberBalanceServiceJob).to receive(job_call).with(anything, anything, anything, today.to_s).and_return(job_response)
            call_action
          end
          it 'passes the end_date param if one is provided' do
            expect(MemberBalanceServiceJob).to receive(job_call).with(anything, anything, anything, end_date.to_s).and_return(job_response)
            get :borrowing_capacity, end_date: end_date
          end
        end
      end
    end

    it 'should render the borrowing_capacity view' do
      call_action
      expect(response.body).to render_template('borrowing_capacity')
    end
    it 'should set @end_date if supplied' do
      get :borrowing_capacity, end_date: end_date
      expect(assigns[:end_date]).to eq(end_date)
    end

    describe 'when a job_id is not present and self.skip_deferred_load is false' do
      it_behaves_like 'a borrowing_capacity path involving a MemberBalanceServiceJob', :perform_later

      before { allow(MemberBalanceServiceJob).to receive(:perform_later).and_return(member_balance_service_job_instance) }

      it 'updates the job status with the user\'s id' do
        allow(controller).to receive(:current_user).and_return(user)
        expect(job_status).to receive(:update_attributes!).with({user_id: user_id})
        call_action
      end
      it 'sets the @job_status_url' do
        call_action
        expect(assigns[:job_status_url]).to eq(job_status_url(job_status))
      end
      it 'sets the @load_url with the appropriate params' do
        call_action
        expect(assigns[:load_url]).to eq(reports_borrowing_capacity_url(job_id: job_status.id))
      end
      it 'sets @borrowing_capacity_summary[:deferred] to true' do
        call_action
        expect(assigns[:borrowing_capacity_summary][:deferred]).to eq(true)
      end
    end

    describe 'job_id present' do
      let(:parsed_response_hash) { double('parsed hash', with_indifferent_access: response_hash) }
      before do
        allow(JobStatus).to receive(:find_by).and_return(job_status)
        allow(JSON).to receive(:parse).and_return(parsed_response_hash)
      end
      it 'finds the JobStatus by id, user_id, and status' do
        allow(controller).to receive(:current_user).and_return(user)
        expect(JobStatus).to receive(:find_by).with(id: job_id.to_s, user_id: user_id, status: JobStatus.statuses[:completed]).and_return(job_status)
        call_action_with_job_id
      end
      it 'raises an error if there is no job status found' do
        allow(JobStatus).to receive(:find_by)
        expect{call_action_with_job_id}.to raise_error
      end
      it 'parses the job_status string' do
        job_status_string = double('job status string')
        allow(job_status).to receive(:result_as_string).and_return(job_status_string)
        expect(JSON).to receive(:parse).with(job_status_string).and_return(parsed_response_hash)
        call_action_with_job_id
      end
      it 'destroys the job status' do
        expect(job_status).to receive(:destroy)
        call_action_with_job_id
      end
      it 'sets @borrowing_capacity_summary to the hash returned from the job status' do
        call_action_with_job_id
        expect(assigns[:borrowing_capacity_summary]).to eq(response_hash)
      end
      it 'sets @borrowing_capacity_summary to {} if the report is disabled' do
        expect(controller).to receive(:report_disabled?).with(ReportsController::BORROWING_CAPACITY_WEB_FLAGS).and_return(true)
        call_action_with_job_id
        expect(assigns[:borrowing_capacity_summary]).to eq({})
      end
    end
    describe '`skip_deferred_load` set to true' do
      before { controller.skip_deferred_load = true }
      it_behaves_like 'a borrowing_capacity path involving a MemberBalanceServiceJob', :perform_now, true

      it 'raises an error if @borrowing_capacity_summary is nil' do
        allow(MemberBalanceServiceJob).to receive(:perform_now)
        expect{call_action}.to raise_error(StandardError)
      end
      it 'sets @borrowing_capacity_summary to the hash returned from MemberBalanceServiceJob' do
        allow(MemberBalanceServiceJob).to receive(:perform_now).and_return(response_hash)
        call_action
        expect(assigns[:borrowing_capacity_summary]).to eq(response_hash)
      end
    end
  end

  describe 'GET current_price_indications' do
    let(:current_price_indications) { get :current_price_indications }

    it_behaves_like 'a user required action', :get, :current_price_indications
    it_behaves_like 'a report that can be downloaded', :current_price_indications, [:xlsx]
    it_behaves_like 'a report with instance variables set in a before_filter', :current_price_indications
    it_behaves_like 'a controller action with an active nav setting', :current_price_indications, :reports
    it_behaves_like 'a controller action with quick advance messaging', :current_price_indications
    it 'renders the current_price_indications view' do
      current_price_indications
      expect(response.body).to render_template('current_price_indications')
    end
    describe 'when a job_id param is present' do
      let(:job_status) { double('job status', destroy: nil) }
      let(:vrc_data) {{'advance_maturity' => 'Overnight/Open','overnight_fed_funds_benchmark' => 0.13,'basis_point_spread_to_benchmark' => 5,'advance_rate' => 0.18}}
      let(:frc_data) {[{'advance_maturity' =>'1 Month','treasury_benchmark_maturity' => '3 Months','nominal_yield_of_benchmark' => 0.01,'basis_point_spread_to_benchmark' => 20,'advance_rate' => 0.21}]}
      let(:arc_data) {[{'advance_maturity' => '1 Year','1_month_libor' => 6,'3_month_libor' => 4,'6_month_libor' => 11,'prime' => -295}]}
      let(:sta_data) { {rate: rand(0..99999)} }
      let(:member_id) { rand(1..99999) }
      let(:user_id) { rand(1..99999) }
      let(:uuid) { double('uuid') }
      let(:job_id) { rand(1..99999) }
      let(:current_price_indications) { get :current_price_indications, job_id: job_id }

      before do
        allow(JobStatus).to receive(:find_by).and_return(job_status)
        allow(job_status).to receive(:result_as_string).and_return(
          {
            standard_vrc_data: vrc_data,
            sbc_vrc_data: vrc_data,
            standard_frc_data: frc_data,
            sbc_frc_data: frc_data,
            standard_arc_data: arc_data,
            sbc_arc_data: arc_data,
            sta_data: sta_data
          }.to_json
        )
      end
      it 'returns the correct `row_value` for @sta_table_data' do
        current_price_indications
        expect(assigns[:sta_table_data][:row_value]).to eq(sta_data[:rate])
      end
      [:standard_vrc_table_data, :sbc_vrc_table_data].each do |vrc_data|
        it "returns correctly formatted `rows` for @#{vrc_data}" do
          current_price_indications
          expect(assigns[vrc_data][:rows]).to eq(
            [
              {columns: [
                {:value=>"Overnight/Open", :type=>nil}, {:value=>0.13, :type=>:rate}, {:value=>5, :type=>:basis_point}, {:value=>0.18, :type=>:rate}
              ]}
            ]
          )
        end
      end
      [:standard_frc_table_data, :sbc_frc_table_data].each do |frc_data|
        it "returns correctly formatted `rows` for @#{frc_data}" do
          current_price_indications
          expect(assigns[frc_data][:rows]).to eq(
            [
              {columns: [
                {:value=>"1 Month"}, {:value=>"3 Months"}, {:type=>:rate, :value=>0.01}, {:type=>:basis_point, :value=>20}, {:type=>:rate, :value=>0.21}
              ]}
            ]
          )
        end
      end
      it "returns correctly formatted `rows` for @standard_arc_table_data" do
        current_price_indications
        expect(assigns[:standard_arc_table_data][:rows]).to eq(
          [
            {columns: [
              {:value=>"1 Year"}, {:type=>:basis_point, :value=>6}, {:type=>:basis_point, :value=>4}, {:type=>:basis_point, :value=>11}, {:type=>:basis_point, :value=>-295}
            ]}
          ]
        )
      end
      it "returns correctly formatted `rows` for @sbc_arc_table_data" do
        current_price_indications
        expect(assigns[:sbc_arc_table_data][:rows]).to eq(
          [
            {columns: [
              {:value=>"1 Year"}, {:type=>:basis_point, :value=>6}, {:type=>:basis_point, :value=>4}, {:type=>:basis_point, :value=>11}
            ]}
          ]
        )
      end
      describe 'when the `skip_deferred_load` controller attribute is true' do
        before do
          controller.skip_deferred_load = true
          allow(controller).to receive(:current_member_id).and_return(member_id)
        end
        it 'calls `perform_now` on the ReportCurrentPriceIndicationsJob with the current member id and the request uuid' do
          allow(request).to receive(:uuid).and_return(uuid)
          expect(ReportCurrentPriceIndicationsJob).to receive(:perform_now).with(member_id, uuid).and_return({})
          current_price_indications
        end
      end
      describe 'when the `skip_deferred_load` controller attribute is not true' do
        it 'finds the proper JobStatus by job id, user id and job status' do
          allow(controller).to receive(:current_user).and_return(double(User, id: user_id, accepted_terms?: true))
          expect(JobStatus).to receive(:find_by).with(id: job_id.to_s, user_id: user_id, status: JobStatus.statuses[:completed]).and_return(job_status)
          current_price_indications
        end
        it 'raises an error if no JobStatus is found' do
          allow(JobStatus).to receive(:find_by)
          expect{current_price_indications}.to raise_error
        end
        it 'destroys the JobStatus' do
          expect(job_status).to receive(:destroy)
          current_price_indications
        end
      end
    end
    describe 'table data' do
      interest_day_count_key = I18n.t('reports.pages.price_indications.current.interest_day_count')
      payment_frequency_key = I18n.t('reports.pages.price_indications.current.payment_frequency')
      interest_rate_reset_key = I18n.t('reports.pages.price_indications.current.interest_rate_reset')
      before { current_price_indications }
      describe '@standard_vrc_table_data' do
        it "should contain a notes hash with a #{interest_day_count_key} key and a value of '#{ReportsController::INTEREST_DAY_COUNT_MAPPINGS[:standard][:vrc]}'" do
          expect(assigns[:standard_vrc_table_data][:notes][interest_day_count_key]).to eq(ReportsController::INTEREST_DAY_COUNT_MAPPINGS[:standard][:vrc])
        end
        it "should contain a notes hash with a #{payment_frequency_key} key and an array of the correct values" do
          expect(assigns[:standard_vrc_table_data][:notes][payment_frequency_key]).to eq([
            [I18n.t('reports.pages.price_indications.current.overnight'), ReportsController::INTEREST_PAYMENT_FREQUENCY_MAPPINGS[:standard][:vrc]],
            [I18n.t('reports.pages.price_indications.current.open'), ReportsController::INTEREST_PAYMENT_FREQUENCY_MAPPINGS[:standard][:vrc_open]]
          ])
        end
      end
      describe '@sbc_vrc_table_data' do
        it "should contain a notes hash with a #{interest_day_count_key} key and a value of '#{ReportsController::INTEREST_DAY_COUNT_MAPPINGS[:sbc][:vrc]}'" do
          expect(assigns[:sbc_vrc_table_data][:notes][interest_day_count_key]).to eq(ReportsController::INTEREST_DAY_COUNT_MAPPINGS[:sbc][:vrc])
        end
        it "should contain a notes hash with a #{payment_frequency_key} key and an array of the correct values" do
          expect(assigns[:sbc_vrc_table_data][:notes][payment_frequency_key]).to eq([
            [I18n.t('reports.pages.price_indications.current.overnight'), ReportsController::INTEREST_PAYMENT_FREQUENCY_MAPPINGS[:sbc][:vrc]],
            [I18n.t('reports.pages.price_indications.current.open'), ReportsController::INTEREST_PAYMENT_FREQUENCY_MAPPINGS[:sbc][:vrc_open]]
          ])
        end
      end
      describe '@standard_frc_table_data' do
        it "should contain a notes hash with a #{interest_day_count_key} key and a value of '#{ReportsController::INTEREST_DAY_COUNT_MAPPINGS[:standard][:frc]}'" do
          expect(assigns[:standard_frc_table_data][:notes][interest_day_count_key]).to eq(ReportsController::INTEREST_DAY_COUNT_MAPPINGS[:standard][:vrc])
        end
        it "should contain a notes hash with a #{payment_frequency_key} key and a value of '#{ReportsController::INTEREST_PAYMENT_FREQUENCY_MAPPINGS[:standard][:frc]}'" do
          expect(assigns[:standard_frc_table_data][:notes][payment_frequency_key]).to eq(ReportsController::INTEREST_PAYMENT_FREQUENCY_MAPPINGS[:standard][:frc])
        end
      end
      describe '@sbc_frc_table_data' do
        it "should contain a notes hash with a #{interest_day_count_key} key and a value of '#{ReportsController::INTEREST_DAY_COUNT_MAPPINGS[:sbc][:frc]}'" do
          expect(assigns[:sbc_frc_table_data][:notes][interest_day_count_key]).to eq(ReportsController::INTEREST_DAY_COUNT_MAPPINGS[:sbc][:frc])
        end
        it "should contain a notes hash with a #{payment_frequency_key} key and a value of '#{ReportsController::INTEREST_PAYMENT_FREQUENCY_MAPPINGS[:sbc][:frc]}'" do
          expect(assigns[:sbc_frc_table_data][:notes][payment_frequency_key]).to eq(ReportsController::INTEREST_PAYMENT_FREQUENCY_MAPPINGS[:sbc][:frc])
        end
      end
      describe '@standard_arc_table_data' do
        it "should contain a notes hash with a #{interest_day_count_key} key and a value of '#{ReportsController::INTEREST_DAY_COUNT_MAPPINGS[:standard][:arc]}'" do
          expect(assigns[:standard_arc_table_data][:notes][interest_day_count_key]).to eq(ReportsController::INTEREST_DAY_COUNT_MAPPINGS[:standard][:arc])
        end
        it "should contain a notes hash with a #{payment_frequency_key} key and an array of the correct values" do
          expect(assigns[:standard_arc_table_data][:notes][payment_frequency_key]).to eq([
            [I18n.t('reports.pages.price_indications.current.1_month_libor'), ReportsController::INTEREST_PAYMENT_FREQUENCY_MAPPINGS[:standard][:'1m_libor']],
            [I18n.t('reports.pages.price_indications.current.3_month_libor'), ReportsController::INTEREST_PAYMENT_FREQUENCY_MAPPINGS[:standard][:'3m_libor']],
            [I18n.t('reports.pages.price_indications.current.6_month_libor'), ReportsController::INTEREST_PAYMENT_FREQUENCY_MAPPINGS[:standard][:'6m_libor']],
            [I18n.t('reports.pages.price_indications.current.prime'), ReportsController::INTEREST_PAYMENT_FREQUENCY_MAPPINGS[:standard][:'daily_prime']]
          ])
        end
        it "should contain a notes hash with a #{interest_rate_reset_key} key and an array of the correct values" do
          expect(assigns[:standard_arc_table_data][:notes][interest_rate_reset_key]).to eq([
           [I18n.t('reports.pages.price_indications.current.1_month_libor'), ReportsController::INTEREST_RATE_RESET_MAPPINGS[:'1m_libor']],
           [I18n.t('reports.pages.price_indications.current.3_month_libor'), ReportsController::INTEREST_RATE_RESET_MAPPINGS[:'3m_libor']],
           [I18n.t('reports.pages.price_indications.current.6_month_libor'), ReportsController::INTEREST_RATE_RESET_MAPPINGS[:'6m_libor']],
           [I18n.t('reports.pages.price_indications.current.prime'), ReportsController::INTEREST_RATE_RESET_MAPPINGS[:'daily_prime']]
         ])
        end
      end
      describe '@sbc_arc_table_data' do
        it "should contain a notes hash with a #{interest_day_count_key} key and a value of '#{ReportsController::INTEREST_DAY_COUNT_MAPPINGS[:sbc][:arc]}'" do
          expect(assigns[:sbc_arc_table_data][:notes][interest_day_count_key]).to eq(ReportsController::INTEREST_DAY_COUNT_MAPPINGS[:sbc][:arc])
        end
        it "should contain a notes hash with a #{payment_frequency_key} key and an array of the correct values" do
          expect(assigns[:sbc_arc_table_data][:notes][payment_frequency_key]).to eq([
            [I18n.t('reports.pages.price_indications.current.1_month_libor'), ReportsController::INTEREST_PAYMENT_FREQUENCY_MAPPINGS[:sbc][:'1m_libor']],
            [I18n.t('reports.pages.price_indications.current.3_month_libor'), ReportsController::INTEREST_PAYMENT_FREQUENCY_MAPPINGS[:sbc][:'3m_libor']],
            [I18n.t('reports.pages.price_indications.current.6_month_libor'), ReportsController::INTEREST_PAYMENT_FREQUENCY_MAPPINGS[:sbc][:'6m_libor']]
          ])
        end
        it "should contain a notes hash with a #{interest_rate_reset_key} key and an array of the correct values" do
          expect(assigns[:sbc_arc_table_data][:notes][interest_rate_reset_key]).to eq([
            [I18n.t('reports.pages.price_indications.current.1_month_libor'), ReportsController::INTEREST_RATE_RESET_MAPPINGS[:'1m_libor']],
            [I18n.t('reports.pages.price_indications.current.3_month_libor'), ReportsController::INTEREST_RATE_RESET_MAPPINGS[:'3m_libor']],
            [I18n.t('reports.pages.price_indications.current.6_month_libor'), ReportsController::INTEREST_RATE_RESET_MAPPINGS[:'6m_libor']]
          ])
        end
      end
    end
  end

  describe 'GET securities_transactions' do
    let(:start_date)                       { Date.new(2014,12,31) }
    let(:member_balances_service_instance) { double('MemberBalanceService') }
    let(:response_hash)                    { double('MemberBalanceServiceHash') }
    let(:transaction_hash)                 { double('transaction_hash', collect: nil, sort: []) }
    let(:custody_account_no)               { double('custody_account_no') }
    let(:new_transaction)                  { double('new_transaction') }
    let(:cusip)                            { double('cusip') }
    let(:transaction_code)                 { double('transaction_code') }
    let(:security_description)             { double('security_description') }
    let(:units)                            { double('units') }
    let(:maturity_date)                    { double('maturity_date') }
    let(:payment_or_principal)             { double('payment_or_principal') }
    let(:interest)                         { double('interest') }
    let(:total)                            { double('total') }
    let(:total_net)                        { double('total_net') }
    let(:final)                            { double('final') }
    let(:previous_business_day)            { double('previous_business_day') }
    let(:securities_transactions_hash) do
      {
          'custody_account_no'   => custody_account_no,
          'new_transaction'      => false,
          'cusip'                => cusip,
          'transaction_code'     => transaction_code,
          'security_description' => security_description,
          'units'                => units,
          'maturity_date'        => maturity_date,
          'payment_or_principal' => payment_or_principal,
          'interest'             => interest,
          'total'                => total
      }
    end
    let(:securities_transactions_response) do
      [securities_transactions_hash]
    end
    let(:securities_transactions_response_with_new_transaction) do
      [securities_transactions_hash.merge('custody_account_no' => "12345", 'new_transaction' => true)]
    end
    let(:common_table_data) do
      [{:type=>nil, :value=>cusip},
       {:type=>nil, :value=>transaction_code},
       {:type=>nil, :value=>security_description},
       {:type=>:basis_point, :value=>units},
       {:type=>:date, :value=>maturity_date},
       {:type=>:rate, :value=>payment_or_principal},
       {:type=>:rate, :value=>interest},
       {:type=>:rate, :value=>total}]
    end
    let(:securities_transactions_table_data) do
      [{:type=>nil, :value=>custody_account_no}] + common_table_data
    end
    let(:securities_transactions_table_data_with_new_transaction) do
      [{:type=>nil, :value=>'12345*'}] + common_table_data
    end
    before do
      allow(MemberBalanceService).to receive(:new).and_return(member_balances_service_instance)
      allow(member_balances_service_instance).to receive(:securities_transactions).with(kind_of(Date)).at_least(1).and_return(response_hash)
      allow(member_balances_service_instance).to receive(:securities_transactions).with(restricted_start_date).at_least(1).and_return(response_hash)
      allow(response_hash).to receive(:[]).with(:total_net).and_return(total_net)
      allow(response_hash).to receive(:[]).with(:final).and_return(final)
      allow(response_hash).to receive(:[]).with(:total_payment_or_principal)
      allow(response_hash).to receive(:[]).with(:total_interest)
      allow(response_hash).to receive(:[]).with(:previous_business_day)
      allow(response_hash).to receive(:[]).with(:transactions).and_return(transaction_hash)
    end
    it_behaves_like 'a user required action', :get, :securities_transactions
    it_behaves_like 'a report with instance variables set in a before_filter', :securities_transactions
    it_behaves_like 'a controller action with an active nav setting', :securities_transactions, :reports
    it_behaves_like 'a report that can be downloaded', :securities_transactions, [:xlsx]
    it 'can be disabled' do
      allow(subject).to receive(:report_disabled?).and_return(true)
      allow(transaction_hash).to receive(:collect)
      get :securities_transactions
      expect(assigns[:securities_transactions_table_data][:rows]).to eq([])
    end
    it 'renders the securities_transactions view' do
      get :securities_transactions
      expect(response.body).to render_template('securities_transactions')
    end
    it 'sorts the transactions first by custody account number and then by cusip' do
      # uses 'transaction_code' as an id for these mock transactions for ease of testing
      transaction_1 = {
        'custody_account_no' => 5,
        'cusip' => 5,
        'transaction_code' => rand
      }
      transaction_2= {
        'custody_account_no' => 1,
        'cusip' => 55,
        'transaction_code' => rand
      }
      transaction_3= {
        'custody_account_no' => 10,
        'cusip' => 23,
        'transaction_code' => rand
      }
      transaction_4= {
        'custody_account_no' => 5,
        'cusip' => 2,
        'transaction_code' => rand
      }
      sorted_transactions = [transaction_2, transaction_4, transaction_1, transaction_3]
      expect(response_hash).to receive(:[]).with(:transactions).and_return([transaction_1, transaction_2, transaction_3, transaction_4])
      get :securities_transactions
      sorted_transactions.each_with_index do |transaction, i|
        expect(assigns[:securities_transactions_table_data][:rows][i][:columns].last[:value]).to eq(transaction['transaction_code'])
      end
    end
    it 'should pass @start_date and @max_date to DatePickerHelper#date_picker_presets and set @picker_presets to its outcome' do
      allow(controller).to receive(:most_recent_business_day).and_return(max_date)
      allow(controller).to receive(:date_picker_presets).with(restricted_start_date, nil, nil, max_date).and_return(date_picker_presets)
      allow(response_hash).to receive(:[]).with(:transactions).and_return(securities_transactions_response_with_new_transaction)
      get :securities_transactions, start_date: start_date
      expect(assigns[:picker_presets]).to eq(date_picker_presets)
    end
    it 'should return securities transactions data' do
      allow(response_hash).to receive(:[]).with(:transactions).and_return(securities_transactions_response)
      get :securities_transactions
      expect(assigns[:total_net]).to eq(total_net)
      expect(assigns[:final]).to eq(final)
      expect(assigns[:securities_transactions_table_data][:rows][0][:columns]).to eq(securities_transactions_table_data)
    end
    it 'should return securities transactions data with new transaction indicator' do
      allow(response_hash).to receive(:[]).with(:transactions).and_return(securities_transactions_response_with_new_transaction)
      get :securities_transactions
      expect(assigns[:securities_transactions_table_data][:rows][0][:columns]).to eq(securities_transactions_table_data_with_new_transaction)
    end
  end

  describe 'most_recent_business_day' do
    let (:fri) { double('fri', saturday?: false, sunday?: false) }
    let (:sat) { double('sat', saturday?: true,  sunday?: false) }
    let (:sun) { double('sun', saturday?: false, sunday?: true)  }
    before do
      allow(controller).to receive(:most_recent_business_day).and_call_original
      allow(sun).to receive(:-).with(2.day).and_return(fri)
      allow(sat).to receive(:-).with(1.day).and_return(fri)
    end
    it 'should return fri for sun' do
      expect(subject.most_recent_business_day(sun)).to be(fri)
    end
    it 'should return fri for sat' do
      expect(subject.most_recent_business_day(sat)).to be(fri)
    end
    it 'should return fri for fri' do
      expect(subject.most_recent_business_day(fri)).to be(fri)
    end
  end

  describe 'GET historical_price_indications' do
    it_behaves_like 'a user required action', :get, :historical_price_indications
    it_behaves_like 'a report that can be downloaded', :historical_price_indications, [:xlsx]
    it_behaves_like 'a report with instance variables set in a before_filter', :historical_price_indications
    it_behaves_like 'a controller action with an active nav setting', :historical_price_indications, :reports

    let(:job_status) { double('JobStatus', update_attributes!: nil, id: nil, destroy: nil, result_as_string: nil ) }
    let(:rate_service_job_instance) { double('rate_service_job_instance', job_status: job_status) }
    let(:user_id) { rand(0..99999) }
    let(:user) { double(User, id: user_id, accepted_terms?: true) }
    let(:response_hash) { double('hash of historical price indications', :[] => nil) }
    let(:job_id) { rand(0..99999) }
    let(:call_action) { get :historical_price_indications }
    let(:call_action_with_job_id) { get :historical_price_indications, job_id: job_id }

    it 'renders the historical_price_indications view' do
      call_action
      expect(response.body).to render_template('historical_price_indications')
    end
    it 'sets @start_date to the start_date param' do
      get :historical_price_indications, start_date: start_date, end_date: end_date
      expect(assigns[:start_date]).to eq(start_date)
    end
    it 'sets @end_date to the end_date param' do
      get :historical_price_indications, start_date: start_date, end_date: end_date
      expect(assigns[:end_date]).to eq(end_date)
    end
    it 'passes @start_date and @end_date to DatePickerHelper#date_picker_presets and set @picker_presets to its outcome' do
      expect(controller).to receive(:date_picker_presets).with(start_date, end_date).and_return(date_picker_presets)
      get :historical_price_indications, start_date: start_date, end_date: end_date
      expect(assigns[:picker_presets]).to eq(date_picker_presets)
    end
    it 'sets @collateral_type to `standard` and @collateral_type_text to the proper i18next translation for `standard` if standard is passed as the historical_price_collateral_type param' do
      get :historical_price_indications, historical_price_collateral_type: 'standard'
      expect(assigns[:collateral_type]).to eq('standard')
      expect(assigns[:collateral_type_text]).to eq(I18n.t('reports.pages.price_indications.standard_credit_program'))
    end
    it 'sets @collateral_type to `sbc` and @collateral_type_text to the proper i18next translation for `sbc` if sbc is passed as the historical_price_collateral_type param' do
      get :historical_price_indications, historical_price_collateral_type: 'sbc'
      expect(assigns[:collateral_type]).to eq('sbc')
      expect(assigns[:collateral_type_text]).to eq(I18n.t('reports.pages.price_indications.sbc_program'))
    end
    it 'sets @collateral_type to `standard` and @collateral_type_text to the proper i18next translation for `standard` if nothing is passed for the historical_price_collateral_type param' do
      call_action
      expect(assigns[:collateral_type_text]).to eq(I18n.t('reports.pages.price_indications.standard_credit_program'))
    end
    it 'sets @collateral_type_options to an array of arrays containing the appropriate values and labels for standard and sbc' do
      options_array = [
        [I18n.t('reports.pages.price_indications.standard_credit_program'), 'standard'],
        [I18n.t('reports.pages.price_indications.sbc_program'), 'sbc'],
        [I18n.t('reports.pages.price_indications.sta.dropdown'), 'sta']
      ]
      call_action
      expect(assigns[:collateral_type_options]).to eq(options_array)
    end
    it 'sets @credit_type to `frc` and @credit_type_text to the proper i18next translation for `frc` if frc is passed as the historical_price_credit_type param' do
      get :historical_price_indications, historical_price_credit_type: 'frc'
      expect(assigns[:credit_type]).to eq('frc')
      expect(assigns[:credit_type_text]).to eq(I18n.t('reports.pages.price_indications.frc.dropdown'))
    end
    it 'sets @credit_type to `vrc` and @credit_type_text to the proper i18next translation for `vrc` if vrc is passed as the historical_price_credit_type param' do
      get :historical_price_indications, historical_price_credit_type: 'vrc'
      expect(assigns[:credit_type]).to eq('vrc')
      expect(assigns[:credit_type_text]).to eq(I18n.t('reports.pages.price_indications.vrc.dropdown'))
    end
    it 'sets @credit_type to `sta` if sta is passed as the historical_price_collateral_type param' do
      get :historical_price_indications, historical_price_collateral_type: 'sta'
      expect(assigns[:credit_type]).to eq('sta')
    end
    ['1m_libor', '3m_libor', '6m_libor', 'daily_prime'].each do |credit_type|
      it "sets @credit_type to `#{credit_type}` and @credit_type_text to the proper i18next translation for `#{credit_type}` if #{credit_type} is passed as the historical_price_credit_type param" do
        get :historical_price_indications, historical_price_credit_type: credit_type
        expect(assigns[:credit_type]).to eq(credit_type)
        expect(assigns[:credit_type_text]).to eq(I18n.t("reports.pages.price_indications.#{credit_type}.dropdown"))
      end
    end
    it 'sets @credit_type to `frc` and @credit_type_text to the proper i18next translation for `frc` if nothing is passed for the historical_price_credit_type param' do
      call_action
      expect(assigns[:credit_type]).to eq('frc')
      expect(assigns[:credit_type_text]).to eq(I18n.t('reports.pages.price_indications.frc.dropdown'))
    end
    it 'sets @credit_type_options to an array of arrays containing the appropriate values and labels for standard and sbc' do
      options_array = [
        [I18n.t('reports.pages.price_indications.frc.dropdown'), 'frc'],
        [I18n.t('reports.pages.price_indications.vrc.dropdown'), 'vrc'],
        [I18n.t('reports.pages.price_indications.1m_libor.dropdown'), '1m_libor'],
        [I18n.t('reports.pages.price_indications.3m_libor.dropdown'), '3m_libor'],
        [I18n.t('reports.pages.price_indications.6m_libor.dropdown'), '6m_libor'],
        [I18n.t('reports.pages.price_indications.daily_prime.dropdown'), 'daily_prime']
      ]
      call_action
      expect(assigns[:credit_type_options]).to eq(options_array)
    end
    describe '@table_data' do
      interest_day_count_key = I18n.t('reports.pages.price_indications.current.interest_day_count')
      payment_frequency_key = I18n.t('reports.pages.price_indications.current.payment_frequency')
      interest_rate_reset_key = I18n.t('reports.pages.price_indications.current.interest_rate_reset')
      describe 'the notes hash' do
        let(:sta_notes) {
          {I18n.t('reports.pages.price_indications.current.interest_day_count') => I18n.t('reports.pages.price_indications.current.actual_360'),
           '' => I18n.t('reports.pages.price_indications.sta.notes')
          }
        }
        collateral_types = [:standard, :sbc]
        credit_types = [:frc, :vrc, :'1m_libor', :'3m_libor', :'6m_libor']
        collateral_types.each do |collateral_type|
          credit_types.each do |credit_type|
            describe "when the collateral type is #{collateral_type} and the credit_type is #{credit_type}" do
              it "has an #{interest_day_count_key} key with a value of #{ReportsController::INTEREST_DAY_COUNT_MAPPINGS[collateral_type][credit_type]}" do
                get :historical_price_indications, historical_price_collateral_type: collateral_type, historical_price_credit_type: credit_type
                expect(assigns[:table_data][:notes][interest_day_count_key]).to eq(ReportsController::INTEREST_DAY_COUNT_MAPPINGS[collateral_type][credit_type])
              end
              it "has an #{payment_frequency_key} key with a value of #{ReportsController::INTEREST_PAYMENT_FREQUENCY_MAPPINGS[collateral_type][credit_type]}" do
                get :historical_price_indications, historical_price_collateral_type: collateral_type, historical_price_credit_type: credit_type
                expect(assigns[:table_data][:notes][payment_frequency_key]).to eq(ReportsController::INTEREST_PAYMENT_FREQUENCY_MAPPINGS[collateral_type][credit_type])
              end
              if RatesService::ARC_CREDIT_TYPES.include?(credit_type)
                it "has an #{interest_rate_reset_key} key with a value of #{ReportsController::INTEREST_RATE_RESET_MAPPINGS[credit_type]}" do
                  get :historical_price_indications, historical_price_collateral_type: collateral_type, historical_price_credit_type: credit_type
                  expect(assigns[:table_data][:notes][interest_rate_reset_key]).to eq(ReportsController::INTEREST_RATE_RESET_MAPPINGS[credit_type])
                end
              end
            end
          end
        end
        describe 'when the collateral type is sta' do
          it 'has an interest_day_count key value of Actual/360' do
            get :historical_price_indications, historical_price_collateral_type: 'sta'
            expect((assigns[:table_data])[:notes]).to eq(sta_notes)
          end
        end
      end
    end

    RSpec.shared_examples 'a historical_price_indications path involving a RatesServiceJob' do |job_call, deferred_job = false|
      let(:job_response) {deferred_job ? response_hash : rate_service_job_instance}
      describe "calling `#{job_call}` on the RatesServiceJob" do
        it 'passes the proper uuid' do
          expect(RatesServiceJob).to receive(job_call).with(anything, request.uuid, any_args).and_return(job_response)
          call_action
        end
        it 'passes `historical_price_indications`' do
          expect(RatesServiceJob).to receive(job_call).with('historical_price_indications', any_args).and_return(job_response)
          call_action
        end
        describe 'additional arguments' do
          it 'uses the string version of start_date and end_date provided in the params hash if available' do
            expect(RatesServiceJob).to receive(job_call).with(anything, anything, start_date.to_s, end_date.to_s, anything, anything).and_return(job_response)
            get :historical_price_indications, start_date: start_date, end_date: end_date
          end
          it 'uses the last 30 days to date as the date range if no params are passed' do
            last_30_days = today - 1.month
            allow(ReportConfiguration).to receive(:date_bounds).with(:historical_price_indications, nil, nil)
                                            .and_return({ min: min_date, start: last_30_days, end: today, max: max_date })
            expect(RatesServiceJob).to receive(job_call).with(anything, anything, last_30_days.to_s, today.to_s, anything, anything).and_return(job_response)
            call_action
          end
          it 'passes credit_type and collateral_type' do
            expect(RatesServiceJob).to receive(job_call).with(anything, anything, anything, anything, 'sbc', '1m_libor').and_return(job_response)
            get :historical_price_indications, historical_price_collateral_type: 'sbc', historical_price_credit_type: '1m_libor'
          end
        end
      end
    end
    describe 'when `job_id` is not present and `self.skip_deferred_load` is false' do
      before do
        allow(RatesServiceJob).to receive(:perform_later).and_return(rate_service_job_instance)
      end
      it_behaves_like 'a historical_price_indications path involving a RatesServiceJob', :perform_later
      it 'updates the job status with the user\'s id' do
        allow(controller).to receive(:current_user).and_return(user)
        expect(job_status).to receive(:update_attributes!).with({user_id: user_id})
        call_action
      end
      it 'sets the @job_status_url' do
        call_action
        expect(assigns[:job_status_url]).to eq(job_status_url(job_status))
      end
      it 'sets the @load_url with the appropriate params' do
        params = {
          job_id: job_status.id,
          historical_price_collateral_type: 'standard',
          historical_price_credit_type: '6m_libor',
          start_date: start_date.to_s,
          end_date: end_date.to_s
        }
        get :historical_price_indications, start_date: start_date, end_date: end_date, historical_price_collateral_type: 'standard', historical_price_credit_type: '6m_libor'
        expect(assigns[:load_url]).to eq(reports_historical_price_indications_url(params))
      end
      it 'sets @table_data[:deferred] to true' do
        call_action
        expect(assigns[:table_data][:deferred]).to eq(true)
      end
      it 'sets @table_data[:hide_column_headings] to true' do
        call_action
        expect(assigns[:table_data][:hide_column_headings]).to eq(true)
      end
    end

    describe 'when there is a job id present or the controller is set to `skip_deferred_load`' do
      let(:parsed_response_hash) { double('parsed hash', with_indifferent_access: response_hash) }
      before do
        allow(JobStatus).to receive(:find_by).and_return(job_status)
        allow(JSON).to receive(:parse).and_return(parsed_response_hash)
      end
      describe 'job_id present' do
        it 'finds the JobStatus by id, user_id, and status' do
          allow(controller).to receive(:current_user).and_return(user)
          expect(JobStatus).to receive(:find_by).with(id: job_id.to_s, user_id: user_id, status: JobStatus.statuses[:completed]).and_return(job_status)
          call_action_with_job_id
        end
        it 'raises an error if there is no job status found' do
          allow(JobStatus).to receive(:find_by)
          expect{call_action_with_job_id}.to raise_error
        end
        it 'parses the job_status string' do
          job_status_string = double('job status string')
          allow(job_status).to receive(:result_as_string).and_return(job_status_string)
          expect(JSON).to receive(:parse).with(job_status_string).and_return(parsed_response_hash)
          call_action_with_job_id
        end
        it 'destroys the job status' do
          expect(job_status).to receive(:destroy)
          call_action_with_job_id
        end
      end
      describe '`skip_deferred_load` set to true' do
        before { controller.skip_deferred_load = true }
        it_behaves_like 'a historical_price_indications path involving a RatesServiceJob', :perform_now, true
      end
      describe 'credit_type of :daily_prime' do
        let(:index) {0.17564}
        let(:basis_1Y) {45}
        let(:basis_2Y) {-127}
        let(:basis_3Y) {-62}
        let(:basis_5Y) {189}
        let(:rates_by_term) { [
          {:term=>'1D', :type=>'index', :value=>index, 'day_count_basis'=>'Actual/360', :pay_freq=>'Daily'},
          {:term=>'1Y', :type=>'basis_point', :value=>basis_1Y, 'day_count_basis'=>'Actual/360', :pay_freq=>'Quarterly'},
          {:term=>'2Y', :type=>'basis_point', :value=>basis_2Y, 'day_count_basis'=>'Actual/360', :pay_freq=>'Quarterly'},
          {:term=>'3Y', :type=>'basis_point', :value=>basis_3Y, 'day_count_basis'=>'Actual/360', :pay_freq=>'Quarterly'},
          {:term=>'5Y', :type=>'basis_point', :value=>basis_5Y, 'day_count_basis'=>'Actual/360', :pay_freq=>'Quarterly'}
        ] }
        let(:rates_by_date) { [{date: today, rates_by_term: rates_by_term}] }
        it 'adds the index value for a given date as a column before each basis_point spread per term' do
          allow(response_hash).to receive(:[]).with(:rates_by_date).and_return(rates_by_date)
          allow(response_hash).to receive(:[]=)
          get :historical_price_indications, historical_price_collateral_type: 'standard', historical_price_credit_type: 'daily_prime', job_id: job_id
          expect(assigns[:table_data][:rows][0][:columns]).to eq([{:type=>:index, :value=>index}, {:type=>:basis_point, :value=>basis_1Y}, {:type=>:index, :value=>index}, {:type=>:basis_point, :value=>basis_2Y}, {:type=>:index, :value=>index}, {:type=>:basis_point, :value=>basis_3Y}, {:type=>:index, :value=>index}, {:type=>:basis_point, :value=>basis_5Y}])
        end
      end
        describe '@table_data' do
          describe 'table_heading' do
            ['1m_libor', '3m_libor', '6m_libor'].each do |credit_type|
              it "sets table_heading to the I18n translation for #{credit_type} table heading if the credit type is `#{credit_type}`" do
                get :historical_price_indications, historical_price_credit_type: credit_type, job_id: job_id
                expect((assigns[:table_data])[:table_heading]).to eq(I18n.t("reports.pages.price_indications.#{credit_type}.table_heading"))
              end
            end
          end
          describe 'column_headings' do
            let(:frc_column_headings) {[I18n.t('global.date'), I18n.t('global.dates.1_month'), I18n.t('global.dates.2_months'), I18n.t('global.dates.3_months'), I18n.t('global.dates.6_months'), I18n.t('global.dates.1_year'), I18n.t('global.dates.2_years'), I18n.t('global.dates.3_years'), I18n.t('global.dates.5_years'), I18n.t('global.dates.7_years'), I18n.t('global.dates.10_years'), I18n.t('global.dates.15_years'), I18n.t('global.dates.20_years'), I18n.t('global.dates.30_years')]}
            let(:vrc_column_headings)  {[I18n.t('global.date'), I18n.t('global.dates.1_day')]}
            let(:arc_column_headings) {[I18n.t('global.date'), I18n.t('global.dates.1_year'), I18n.t('global.dates.2_years'), I18n.t('global.dates.3_years'), I18n.t('global.dates.5_years')]}
            let(:arc_daily_prime_column_headings) {[I18n.t('global.full_dates.1_year'), I18n.t('global.full_dates.2_years'), I18n.t('global.full_dates.3_years'), I18n.t('global.full_dates.5_years')]}
            let(:sta_column_headings)  {[I18n.t('global.date'), I18n.t('advances.rate')]}
            it 'sets column_headings for the `frc` credit type' do
              get :historical_price_indications, historical_price_credit_type: 'frc', job_id: job_id
              expect((assigns[:table_data])[:column_headings]).to eq(frc_column_headings)
            end
            it 'sets column_headings for the `vrc` credit type' do
              get :historical_price_indications, historical_price_credit_type: 'vrc', job_id: job_id
              expect((assigns[:table_data])[:column_headings]).to eq(vrc_column_headings)
            end
            ['1m_libor', '3m_libor', '6m_libor'].each do |credit_type|
              it "sets column_headings for the #{credit_type} credit_type" do
                get :historical_price_indications, historical_price_credit_type: credit_type, job_id: job_id
                expect((assigns[:table_data])[:column_headings]).to eq(arc_column_headings)
              end
            end
            it 'sets column_headings for the daily_prime credit_type' do
              get :historical_price_indications, historical_price_credit_type: 'daily_prime', job_id: job_id
              expect((assigns[:table_data])[:column_headings]).to eq(arc_daily_prime_column_headings)
            end
            it 'sets column_headings for the sta collateral type' do
              get :historical_price_indications, historical_price_collateral_type: 'sta', job_id: job_id
              expect((assigns[:table_data])[:column_headings]).to eq(sta_column_headings)
            end
          end
          describe 'rows' do
            let(:row_1) {{date: 'some_date', rates_by_term: [{type: :index, value: 'rate_1'}, {type: :index, value: 'rate_2'}]}}
            let(:row_2) {{date: 'some_other_date', rates_by_term: [{type: :index, value: 'rate_3'}, {type: :index, value: 'rate_4'}]}}
            let(:rows) {[row_1, row_2]}
            let(:formatted_rows) {[{date: 'some_date', columns: [{type: :index, value: 'rate_1'}, {type: :index, value: 'rate_2'}]}, {date: 'some_other_date', columns: [{type: :index, value: 'rate_3'}, {type: :index, value: 'rate_4'}]}]}
            let(:sta_rows) {[{date: 'some_date', rate: 'rate_1'}]}
            let(:sta_formatted_rows) {[{date: 'some_date', columns: [{type: :index, value: 'rate_1'}]}]}
            before do
              allow(response_hash).to receive(:[]).with(:rates_by_date).and_return(rows)
              allow(response_hash).to receive(:[]=)
            end
            it 'is an array of rows, each containing a row object with a date and a column array containing objects with a type and a rate value' do
              get :historical_price_indications, historical_price_credit_type: 'frc', job_id: job_id
              expect((assigns[:table_data])[:rows]).to eq(formatted_rows)
            end
            it 'sorts by date' do
              expect(controller).to receive(:sort_report_data).with(formatted_rows, :date)
              get :historical_price_indications, historical_price_credit_type: 'frc', job_id: job_id
            end
            it 'is array of rows of sta data, each containing a row object with a date and a column array containing objects with a type and a rate value' do
              allow(response_hash).to receive(:[]).with(:rates_by_date).and_return(sta_rows)
              get :historical_price_indications, historical_price_collateral_type: 'sta', job_id: job_id
              expect((assigns[:table_data])[:rows]).to eq(sta_formatted_rows)
            end
            it 'is an empty array when the report is disabled' do
              allow(controller).to receive(:report_disabled?).with(ReportsController::HISTORICAL_PRICE_INDICATIONS_WEB_FLAGS).and_return(true)
              call_action_with_job_id
              expect(assigns[:table_data][:rows]).to eq([])
          end
        end
      end
    end
  end

  describe 'GET authorizations' do
    it_behaves_like 'a user required action', :get, :authorizations
    it_behaves_like 'a report that can be downloaded', :authorizations, [:pdf]
    it_behaves_like 'a report with instance variables set in a before_filter', :authorizations
    it_behaves_like 'a controller action with an active nav setting', :authorizations, :reports
    describe 'view instance variables' do
      let(:member_service_instance) {double('MembersService')}
      let(:user_no_roles) {{display_name: 'User With No Roles', roles: [], surname: 'With No Roles', given_name: 'User'}}
      let(:user_etransact) {{display_name: 'Etransact User', roles: [User::Roles::ETRANSACT_SIGNER], surname: 'User', given_name: 'Etransact'}}
      let(:user_a) { {display_name: 'R&A User', roles: [User::Roles::SIGNER_MANAGER], given_name: 'R&A', surname: 'User'} }
      let(:user_b) { {display_name: 'Collateral User', roles: [User::Roles::COLLATERAL_SIGNER], given_name: 'Collateral', surname: 'User'} }
      let(:user_c) { {display_name: 'Wire Lady', roles: [User::Roles::WIRE_SIGNER], given_name: 'Wire', surname: 'Lady'} }
      let(:user_d) { {display_name: 'No Surname', roles: [User::Roles::WIRE_SIGNER], given_name: 'No', surname: nil} }
      let(:user_e) { {display_name: 'No Given Name', roles: [User::Roles::WIRE_SIGNER], given_name: nil, surname: 'Given'} }
      let(:user_f) { {display_name: 'Entire Authority User', roles: [User::Roles::SIGNER_ENTIRE_AUTHORITY], given_name: 'Entire Authority', surname: 'User'} }
      let(:signers_and_users) {[user_no_roles, user_etransact, user_a, user_b, user_c, user_d, user_e, user_f]}
      let(:roles) {['all', User::Roles::SIGNER_MANAGER, User::Roles::SIGNER_ENTIRE_AUTHORITY, User::Roles::AFFORDABILITY_SIGNER, User::Roles::COLLATERAL_SIGNER, User::Roles::MONEYMARKET_SIGNER, User::Roles::DERIVATIVES_SIGNER, User::Roles::SECURITIES_SIGNER, User::Roles::WIRE_SIGNER, User::Roles::ACCESS_MANAGER, User::Roles::ETRANSACT_SIGNER]}
      let(:role_translations) {[t('user_roles.all_authorizations'), t('user_roles.resolution.dropdown'), t('user_roles.entire_authority.dropdown'), t('user_roles.affordable_housing.title'), t('user_roles.collateral.title'), t('user_roles.money_market.title'), t('user_roles.interest_rate_derivatives.title'), t('user_roles.securities.title'), t('user_roles.wire_transfer.title'), t('user_roles.access_manager.title'), t('user_roles.etransact.title')]}
      let(:job_id) {rand(1000..10000)}
      let(:job_status) { double('A Job Status', result_as_string: '[]', destroy: nil, id: job_id, update_attributes!: nil) }
      before do
        allow(MembersService).to receive(:new).and_return(member_service_instance)
        allow(member_service_instance).to receive(:signers_and_users).and_return(signers_and_users)
      end
      it 'sets @authorization_filter to the `authorizations_filter` param' do
        get :authorizations, :authorizations_filter => 'my filter param'
        expect(assigns[:authorizations_filter]).to eq('my filter param')
      end
      it 'sets @authorization_filter to `all` if no `authorizations_filter` param is provided' do
        get :authorizations
        expect(assigns[:authorizations_filter]).to eq('all')
      end
      it 'sets @authorizations_dropdown_options to an array containing dropdown names and values' do
        get :authorizations
        expect(assigns[:authorizations_dropdown_options]).to be_kind_of(Array)
        assigns[:authorizations_dropdown_options].each do |option|
          expect(option.first).to be_kind_of(String)
          expect(option.last).to be_kind_of(String)
        end
      end
      describe 'when not passed a Job ID' do
        let(:job) { double('MemberSignersAndUsersJob', job_status: job_status) }
        let(:make_request) { get :authorizations }
        before do
          allow(MemberSignersAndUsersJob).to receive(:perform_later).and_return(job)
        end
        it 'sets @job_status_url' do
          url = double('A URL')
          allow(subject).to receive(:reports_authorizations_url).with(job_id: job_id, authorizations_filter: 'all').and_return(url)
          make_request
          expect(assigns[:load_url]).to eq(url)
        end
        it 'sets @load_url' do
          url = double('A URL')
          allow(subject).to receive(:job_status_url).with(job_status).and_return(url)
          make_request
          expect(assigns[:job_status_url]).to eq(url)
        end
        it 'enqueues a `MemberSignersAndUsersJob` job' do
          expect(MemberSignersAndUsersJob).to receive(:perform_later).and_return(job)
          make_request
        end
        it 'sets the JobStatus `user_id`' do
          expect(job_status).to receive(:update_attributes!).with(user_id: subject.current_user.id)
          make_request
        end
        it 'should have `deferred` set to true' do
          make_request
          expect(assigns[:authorizations_table_data][:deferred]).to eq(true)
        end
      end
      describe 'when passed a Job ID' do
        let(:make_request) { get :authorizations, job_id: job_id }
        before do
          allow(JobStatus).to receive(:find_by).and_return(job_status)
        end
        it 'should look up the JobStatus related to that ID' do
          expect(JobStatus).to receive(:find_by).with(id: job_id.to_s, user_id: subject.current_user.id, status: JobStatus.statuses[:completed]).and_return(job_status)
          make_request
        end
        it 'raises an `ActiveRecord::RecordNotFound` if the JobStatus isn\'t found' do
          allow(JobStatus).to receive(:find_by).and_return(nil)
          expect{make_request}.to raise_error(ActiveRecord::RecordNotFound)
        end
        it 'parses the results of the job as JSON' do
          expect(JSON).to receive(:parse).with(job_status.result_as_string).and_return([])
          make_request
        end
        it 'destroys the JobStatus' do
          expect(job_status).to receive(:destroy)
          make_request
        end
        it 'should not have `deferred` set' do
          get :authorizations, job_id: job_id
          expect(assigns[:authorizations_table_data]).to_not include(:deferred)
        end
        it 'should render without a layout if the request is an XHR' do
          expect(subject).to receive(:render).with(layout: false).and_call_original
          xhr :get, :authorizations, job_id: job_id
        end
      end
      describe 'when the `skip_deferred_load` controller attribute is true' do
        let(:make_request) { get :authorizations }
        let(:service_instance) { double('service instance')}
        before do
          controller.skip_deferred_load = true
          allow(MembersService).to receive(:new).and_return(service_instance)
        end
        it 'gets signers and users from MembersService' do
          expect(service_instance).to receive(:signers_and_users)
          make_request
        end
      end

      describe '@authorizations_filter_text' do
        ReportsController::AUTHORIZATIONS_DROPDOWN_MAPPING.each do |role, role_name|
          it "equals #{role_name} when the authorizations_filter is set to #{role}" do
            get :authorizations, :authorizations_filter => role
            expect(assigns[:authorizations_filter_text]).to eq(role_name)
          end
        end
      end
      describe '`@authorizations_table_data`' do
        it 'returns a hash with `column_headings`' do
          get :authorizations
          expect(assigns[:authorizations_table_data][:column_headings]).to eq([I18n.t('user_roles.user.title'), I18n.t('reports.account.authorizations.title')])
        end
        describe '`rows`' do
          let(:make_request) {get :authorizations, job_id: job_id}
          before do
            allow(JobStatus).to receive(:find_by).and_return(job_status)
            allow(JSON).to receive(:parse).and_return(signers_and_users)
          end
          it 'is an array containing a `columns` hash' do
            make_request
            expect(assigns[:authorizations_table_data][:rows]).to be_kind_of(Array)
            assigns[:authorizations_table_data][:rows].each do |row|
              expect(row).to be_kind_of(Hash)
            end
          end
          describe '`columns` hash' do
            it 'contains a `display_name` with no type' do
              make_request
              assigns[:authorizations_table_data][:rows].each do |row|
                expect(row[:columns].first[:type]).to be_nil
                expect(row[:columns].first[:value]).to be_kind_of(String)
              end
            end
            it 'contains `user_roles` with a type of `list`' do
              make_request
              assigns[:authorizations_table_data][:rows].each do |row|
                expect(row[:columns].last[:type]).to eq(:list)
                expect(row[:columns].last[:value]).to be_kind_of(Array)
              end
            end
            it 'contains all users sorted by last name then first name if the authorizations_filter is set to `all`' do
              make_request
              rows = assigns[:authorizations_table_data][:rows]
              expect(rows.length).to eq(6)
              rows.zip([user_d, user_e, user_c, user_b, user_f, user_a]).each do |row, user|
                expect(row[:columns].first[:value]).to eq(user[:display_name])
              end
            end
            it 'only contains signer managers if authorizations_filter is set to SIGNER_MANAGER' do
              get :authorizations, :authorizations_filter => User::Roles::SIGNER_MANAGER, job_id: job_id
              expect(assigns[:authorizations_table_data][:rows].length).to eq(1)
              expect(assigns[:authorizations_table_data][:rows].first[:columns].first[:value]).to eq(user_a[:display_name])
              expect(assigns[:authorizations_table_data][:rows].first[:columns].last[:value]).to eq([I18n.t('user_roles.resolution.title')])
            end
            it 'only contains signer entire authority if authorizations_filter is set to SIGNER_ENTIRE_AUTHORITY' do
              get :authorizations, :authorizations_filter => User::Roles::SIGNER_ENTIRE_AUTHORITY, job_id: job_id
              expect(assigns[:authorizations_table_data][:rows].length).to eq(1)
              expect(assigns[:authorizations_table_data][:rows].first[:columns].first[:value]).to eq(user_f[:display_name])
              expect(assigns[:authorizations_table_data][:rows].first[:columns].last[:value]).to eq([I18n.t('user_roles.entire_authority.title')])
            end
            describe 'when the filtered users include a signer manager or a signer with entire authority' do
              before { get :authorizations, :authorizations_filter => User::Roles::COLLATERAL_SIGNER, job_id: job_id }
              it 'sets the @footnote_role to a downcased, then capitalized, version of the authorizations_filter' do
                human_role = ReportsController::AUTHORIZATIONS_MAPPING[User::Roles::COLLATERAL_SIGNER].downcase.capitalize
                expect(assigns[:footnote_role]).to eq(human_role)
              end
              it 'marks the signer manager and signer with entire authority roles as footnoted' do
                entire_authority = ReportsController::AUTHORIZATIONS_MAPPING[User::Roles::SIGNER_ENTIRE_AUTHORITY]
                signer_manager = ReportsController::AUTHORIZATIONS_MAPPING[User::Roles::SIGNER_MANAGER]
                expect(assigns[:authorizations_table_data][:rows][1][:columns].last[:value]).to include([entire_authority, :footnoted])
                expect(assigns[:authorizations_table_data][:rows][2][:columns].last[:value]).to include([signer_manager, :footnoted])
              end
            end
            it 'only contains collateral signers, signer managers and signer entire authority if authorizations_filter is set to COLLATERAL_SIGNER' do
              get :authorizations, :authorizations_filter => User::Roles::COLLATERAL_SIGNER, job_id: job_id
              expect(assigns[:authorizations_table_data][:rows].length).to eq(3)
              expect(assigns[:authorizations_table_data][:rows].first[:columns].first[:value]).to eq(user_b[:display_name])
              expect(assigns[:authorizations_table_data][:rows][1][:columns].first[:value]).to eq(user_f[:display_name])
              expect(assigns[:authorizations_table_data][:rows][2][:columns].first[:value]).to eq(user_a[:display_name])
              expect(assigns[:authorizations_table_data][:rows].first[:columns].last[:value]).to eq([I18n.t('user_roles.collateral.title')])
            end
            it 'only contains wire signers, signer managers and signer entire authority  if authorizations_filter is set to WIRE_SIGNER' do
              get :authorizations, :authorizations_filter => User::Roles::WIRE_SIGNER, job_id: job_id
              expect(assigns[:authorizations_table_data][:rows].length).to eq(5)
              expect(assigns[:authorizations_table_data][:rows][0][:columns].first[:value]).to eq(user_d[:display_name])
              expect(assigns[:authorizations_table_data][:rows][1][:columns].first[:value]).to eq(user_e[:display_name])
              expect(assigns[:authorizations_table_data][:rows][2][:columns].first[:value]).to eq(user_c[:display_name])
              expect(assigns[:authorizations_table_data][:rows][3][:columns].first[:value]).to eq(user_f[:display_name])
              expect(assigns[:authorizations_table_data][:rows][4][:columns].first[:value]).to eq(user_a[:display_name])
              expect(assigns[:authorizations_table_data][:rows][0][:columns].last[:value]).to eq([I18n.t('user_roles.wire_transfer.title')])
            end
            it 'ignores users with no role or the eTransact role' do
              make_request
              expect(assigns[:authorizations_table_data][:rows]).to satisfy { |rows| !rows.find {|row| [user_etransact[:display_name], user_no_roles[:display_name]].include?(row[:columns].first[:value]) } }
            end
          end
        end
      end
    end
  end

  describe 'GET account_summary', :vcr do
    let(:member_id) {6}
    let(:make_request) { get :account_summary }
    let(:now) { Date.new(2015, 1, 12).to_time }
    let(:profile) {MemberBalanceService.new(member_id, ActionDispatch::TestRequest.new).profile}
    let(:member_name) { double('A Name') }
    let(:sta_number) { double('STA Number') }
    let(:fhfa_number) { double('FHFA Number') }
    let(:member_details) { {name: member_name, sta_number: sta_number, fhfa_number: fhfa_number} }

    before do
      allow(subject).to receive(:current_member_id).and_return(member_id)
      allow(Time).to receive_message_chain(:zone, :now).and_return(now)
      allow_any_instance_of(MembersService).to receive(:member).with(member_id).and_return(member_details)
    end

    it_behaves_like 'a report that can be downloaded', :account_summary, [:pdf]
    it_behaves_like 'a report with instance variables set in a before_filter', :account_summary
    it_behaves_like 'a controller action with an active nav setting', :account_summary, :reports
    it 'should render the account_summary view' do
      make_request
      expect(response.body).to render_template('account_summary')
    end

    it 'raises an error if the report is disabled' do
      allow(controller).to receive(:report_disabled?).with(ReportsController::ACCOUNT_SUMMARY_WEB_FLAGS).and_return(true)
      expect {make_request}.to raise_error
    end
    it 'assigns @report_name' do
      make_request
      expect(assigns[:report_name]).to eq(I18n.t('reports.pages.account_summary.title'))
    end
    it 'assigns @intraday_datetime' do
      make_request
      expect(assigns[:intraday_datetime]).to eq(now)
    end
    it 'assigns @credit_datetime' do
      make_request
      expect(assigns[:credit_datetime]).to eq(now)
    end
    it 'assigns @collateral_notice to true if the collateral_delivery_status is `Y`' do
      profile[:collateral_delivery_status] = 'Y'
      allow_any_instance_of(MemberBalanceService).to receive(:profile).and_return(profile)
      make_request
      expect(assigns[:collateral_notice]).to be(true)
    end
    it 'assigns @collateral_notice to false if the collateral_delivery_status is `N`' do
      profile[:collateral_delivery_status] = 'N'
      allow_any_instance_of(MemberBalanceService).to receive(:profile).and_return(profile)
      make_request
      expect(assigns[:collateral_notice]).to be(false)
    end
    it 'assigns @sta_number' do
      make_request
      expect(assigns[:sta_number]).to be(sta_number)
    end
    it 'assigns @fhfa_number' do
      make_request
      expect(assigns[:fhfa_number]).to be(fhfa_number)
    end
    it 'assigns @member_name' do
      make_request
      expect(assigns[:member_name]).to be(member_name)
    end
    it 'assigns @financing_availability' do
      make_request
      expect(assigns[:financing_availability]).to include(:rows, :footer)
    end
    it 'assigns @credit_outstanding' do
      make_request
      expect(assigns[:credit_outstanding]).to include(:rows, :footer)
    end
    it 'assigns @standard_collateral' do
      make_request
      expect(assigns[:standard_collateral]).to include(:rows)
    end
    it 'assigns @sbc_collateral' do
      make_request
      expect(assigns[:sbc_collateral]).to include(:rows)
    end
    it 'assigns @collateral_totals' do
      make_request
      expect(assigns[:collateral_totals]).to include(:rows)
    end
    it 'assigns @capital_stock_and_leverage' do
      make_request
      expect(assigns[:capital_stock_and_leverage]).to include(:rows)
    end
    it 'assigns @date' do
      make_request
      expect(assigns[:date]).to eq(now.to_date)
    end
    it 'assigns @now' do
      make_request
      expect(assigns[:now]).to be(now)
    end
    context do
      before { allow_any_instance_of(MemberBalanceService).to receive(:profile).and_return(profile) }
      it 'adds a row to @credit_outstanding if there is a `mpf_credit`' do
        profile[:credit_outstanding][:investments] = 0
        profile[:credit_outstanding][:mpf_credit] = 1
        make_request
        expect(assigns[:credit_outstanding][:rows].length).to be(6)
      end
      it 'doesn\'t a row to @credit_outstanding if there is no `mpf_credit`' do
        profile[:credit_outstanding][:investments] = 0
        profile[:credit_outstanding].delete(:mpf_credit)
        make_request
        expect(assigns[:credit_outstanding][:rows].length).to be(5)
      end
      it 'doesn\'t a row to @credit_outstanding if `mpf_credit` is zero' do
        profile[:credit_outstanding][:investments] = 0
        profile[:credit_outstanding][:mpf_credit] = 0
        make_request
        expect(assigns[:credit_outstanding][:rows].length).to be(5)
      end
      it 'adds a row to @credit_outstanding if there are `investments`' do
        profile[:credit_outstanding][:mpf_credit] = 0
        profile[:credit_outstanding][:investments] = 1
        make_request
        expect(assigns[:credit_outstanding][:rows].length).to be(6)
      end
      it 'doesn\'t a row to @credit_outstanding if there are no `investments`' do
        profile[:credit_outstanding][:mpf_credit] = 0
        profile[:credit_outstanding].delete(:investments)
        make_request
        expect(assigns[:credit_outstanding][:rows].length).to be(5)
      end
      it 'doesn\'t a row to @credit_outstanding if `investments` are zero' do
        profile[:credit_outstanding][:mpf_credit] = 0
        profile[:credit_outstanding][:investments] = 0
        make_request
        expect(assigns[:credit_outstanding][:rows].length).to be(5)
      end
      it 'adds a row to @financing_availability if there is a `mpf_credit_available`' do
        profile[:mpf_credit_available] = 1
        make_request
        expect(assigns[:financing_availability][:rows].length).to be(8)
      end
      it 'doesn\'t add a row to @financing_availability if there is no `mpf_credit_available`' do
        profile.delete(:mpf_credit_available)
        make_request
        expect(assigns[:financing_availability][:rows].length).to be(7)
      end
      it 'doesn\'t add a row to @financing_availability if `mpf_credit_available` is zero' do
        profile[:mpf_credit_available] = 0
        make_request
        expect(assigns[:financing_availability][:rows].length).to be(7)
      end
    end
    describe "MemberBalanceService failures" do
      describe 'the member profile could not be found' do
        before do
          allow_any_instance_of(MemberBalanceService).to receive(:profile).and_return(nil)
          make_request
        end
        %w(financing_availability credit_outstanding standard_collateral sbc_collateral collateral_totals capital_stock_and_leverage).each do |instance_var|
          it "should assign nil values to all columns found in @#{instance_var}" do
            assigns[instance_var.to_sym][:rows].each do |row|
              expect(row[:columns].last[:value]).to be_nil
            end
          end
        end
      end
      describe 'the member details could not be found' do
        before do
          allow_any_instance_of(MembersService).to receive(:member).and_return(nil)
          make_request
        end
        %w(sta_number fhfa_number member_name).each do |instance_var|
          it "should not assign @#{instance_var}" do
            expect(assigns[instance_var.to_sym]).to be_nil
          end
        end
      end
    end
  end

  describe 'private methods' do
    describe '`report_disabled?` method' do
      let(:report_flags) {double('some report flags')}
      let(:member_service_instance) {instance_double('MembersService')}
      let(:response) {double('some_response')}
      let(:method_call) {controller.send(:report_disabled?, report_flags)}

      before do
        session['member_id'] = 750
      end

      it 'passes in the member_id and report_flags to the `report_disabled?` method on a newly created instance of MembersService and returns the response' do
        expect(MembersService).to receive(:new).and_return(member_service_instance)
        expect(member_service_instance).to receive(:report_disabled?).with(750, report_flags).and_return(response)
        expect(method_call).to eq(response)
      end
      it "sets the instance variable @report_disabled to true if `report_disabled?` is true" do
        allow(MembersService).to receive(:new).and_return(member_service_instance)
        allow(member_service_instance).to receive(:report_disabled?).and_return(true)
        method_call
        expect(controller.instance_variable_get(:@report_disabled)).to eq(true)
      end
    end

    describe '`add_rate_objects_for_all_terms` method' do
      let(:terms) {RatesService::HISTORICAL_ARC_TERM_MAPPINGS.keys}
      let(:rates_array) {[{date: '2014-04-01'.to_date, rates_by_term: [
                          {"term"=>"2Y", "type"=>"basis_point", "value"=>105.0, "day_count_basis"=>"Actual/360", "pay_freq"=>"Quarterly"}.with_indifferent_access,
                          {"term"=>"3Y", "type"=>"basis_point", "value"=>193.0, "day_count_basis"=>"Actual/360", "pay_freq"=>"Quarterly"}.with_indifferent_access,
                          {"term"=>"5Y", "type"=>"basis_point", "value"=>197.0, "day_count_basis"=>"Actual/360", "pay_freq"=>"Quarterly"}.with_indifferent_access
                        ]}]}
      let(:credit_type) {:'3m_libor'}
      let(:method_call) {controller.send(:add_rate_objects_for_all_terms, rates_array, terms, credit_type)}
      it 'adds `1d` to the terms array if passed :daily_prime as a credit_type' do
        controller.send(:add_rate_objects_for_all_terms, rates_array, terms, :daily_prime)
        expect(terms.first).to eq('1d')
        expect(terms.length).to eq(RatesService::HISTORICAL_ARC_TERM_MAPPINGS.keys.length + 1)
      end
      it 'iterates through all rates_by_terms arrays for the rate_array and creates empty historic_rate_objects for any terms that are missing' do
        method_call.each do |rate_by_date_object|
          expect(rate_by_date_object[:rates_by_term].length).to eq(terms.length)
        end
        [:value, :day_count_basis, :pay_freq].each do |property|
          method_call.each do |rate_by_date_object|
            terms.length.times do |i|
              if i == 0
                expect(rate_by_date_object[:rates_by_term].select {|rate_object| rate_object[:term] == terms.first.to_s.upcase}.length).to be >= 1
                (rate_by_date_object[:rates_by_term].select {|rate_object| rate_object[:term] == terms.first.to_s.upcase}).each do |rate_by_term_object|
                  expect(rate_by_term_object[property]).to be_nil
                end
              else
                expect(rate_by_date_object[:rates_by_term].select {|rate_object| rate_object[:term] == terms[i].to_s.upcase}.length).to be >= 1
                (rate_by_date_object[:rates_by_term].select {|rate_object| rate_object[:term] == terms[i].to_s.upcase}).each do |rate_by_term_object|
                  if property == :value
                    expect(rate_by_term_object[property]).to be_kind_of(Float)
                  else
                    expect(rate_by_term_object[property]).to be_kind_of(String)
                  end
                end
              end
            end
          end
        end
        method_call.each do |rate_by_date_object|
          (rate_by_date_object[:rates_by_term].select {|rate_object| rate_object[:term] == terms[1].to_s.upcase}).each do |rate_by_term_object|
            expect(rate_by_term_object[:type]).to eq('basis_point')
          end
        end
      end
    end
    describe '`roles_for_signers` method' do
      let(:role_mappings) { ReportsController::AUTHORIZATIONS_MAPPING }
      it 'returns an array containing the I18n translation of the roles for a given user' do
        role_mappings.each_key do |role|
          user = {:roles => [role]}
          expect(subject.send(:roles_for_signers, user)).to eq([role_mappings[role]])
        end
      end
      it 'returns an empty array a given user has no roles' do
        role_mappings.each_key do |role|
          user = {:roles => []}
          expect(subject.send(:roles_for_signers, user)).to eq([])
        end
      end
      it 'sorts the roles based on the `AUTHORIZATIONS_ORDER`' do
        roles = [User::Roles::COLLATERAL_SIGNER, User::Roles::WIRE_SIGNER, User::Roles::ACCESS_MANAGER]
        sorted_roles = roles.sort_by {|role| described_class::AUTHORIZATIONS_ORDER.index(role)}
        user = {:roles => roles}
        expect(subject.send(:roles_for_signers, user)).to eq(sorted_roles.collect {|role| role_mappings[role]})
      end
      it 'hides roles that are implied by a higher role' do
        roles = [User::Roles::COLLATERAL_SIGNER, User::Roles::WIRE_SIGNER, User::Roles::SIGNER_MANAGER]
        user = {:roles => roles}
        expect(subject.send(:roles_for_signers, user)).to match_array([role_mappings[User::Roles::WIRE_SIGNER], role_mappings[User::Roles::SIGNER_MANAGER]])
      end
    end

    describe 'min_and_start_dates' do
      let(:min_date_range) { 18.months }
      let(:min_date) { today - min_date_range }
      let(:valid_start_date) { today - 6.months }
      let(:invalid_start_date) { today - 20.months }
      it 'sets the min_date to today minus the min_date_range' do
        expect(controller.send(:min_and_start_dates, min_date_range).first).to eq(min_date)
      end
      it 'sets the start_date to today if no param is passed' do
        expect(controller.send(:min_and_start_dates, min_date_range).last).to eq(today)
      end
      it 'sets the start_date to the param given if it does not occur before the min_date' do
        expect(controller.send(:min_and_start_dates, min_date_range, valid_start_date).last).to eq(valid_start_date)
      end
      it 'sets the start_date to the min_date if the param given occurs before the min_date' do
        expect(controller.send(:min_and_start_dates, min_date_range, invalid_start_date).last).to eq(min_date)
      end
      it 'sets the start_date to today if the start_date provided is in the future' do
        expect(controller.send(:min_and_start_dates, min_date_range, (today + 1.day)).last).to eq(today)
      end
    end

    describe 'month_restricted_start_date' do
      before { allow(Time.zone).to receive(:today).and_return(Date.new(2015,1,1)) }
      describe 'when the start_date occurs during the current month' do
        it 'returns the end of last month unless the start_date is the last day of this month' do
          start_date = Date.new(2015,1,15)
          expect(controller.send(:month_restricted_start_date, start_date)).to eq(Date.new(2014,12,31))
        end

        it 'returns the start_date of last month if the start_date is the last day of this month' do
          start_date = Date.new(2015,1,31)
          expect(controller.send(:month_restricted_start_date, start_date)).to eq((start_date - 1.month).end_of_month)
        end
      end
      describe 'when the start date occurs before the current month' do
        it 'returns the last day of the month for the given start_date' do
          start_date = Date.new(2013,4,17)
          expect(controller.send(:month_restricted_start_date, start_date)).to eq(start_date.end_of_month)
        end
      end
    end

    describe '`mcu_table_rows_for`' do
      let(:data_hash) { double('a data hash') }
      let(:loan_type_1) { double('a loan type') }
      let(:loan_type_2) { double('another loan type') }
      let(:translation_1) { double('a translation') }
      let(:translation_2) { double('another translation') }
      let(:column_data_1) { double('some column data') }
      let(:column_data_2) { double('some more column data') }
      let(:loan_types) { [loan_type_1, loan_type_2] }
      let(:call_method) { subject.send(:mcu_table_rows_for, data_hash, loan_types) }

      it 'calls `mcu_table_columns_for` with the proper args for each supplied loan type in the correct order' do
        allow(subject).to receive(:t).with("reports.pages.mortgage_collateral_update.#{loan_type_1}").and_return(translation_1)
        allow(subject).to receive(:t).with("reports.pages.mortgage_collateral_update.#{loan_type_2}").and_return(translation_2)
        expect(subject).to receive(:mcu_table_columns_for).with(data_hash, loan_type_1, translation_1).ordered
        expect(subject).to receive(:mcu_table_columns_for).with(data_hash, loan_type_2, translation_2).ordered
        call_method
      end
      it 'returns an array of row objects constructed from the `mcu_table_columns_for` method' do
        expect(subject).to receive(:mcu_table_columns_for).and_return(column_data_1, column_data_2)
        expect(call_method).to eq([{columns: column_data_1},{columns: column_data_2}])
      end
    end

    describe '`mcu_table_columns_for`' do
      let(:data_hash) { double('a data hash', :[] => nil) }
      let(:loan_type) { double('a loan type') }
      let(:value) { double('some value') }
      let(:title) { double('title') }
      let(:call_method) { subject.send(:mcu_table_columns_for, data_hash, loan_type, title) }
      it 'returns an array whose first member is an object with a value equal to the argument supplied' do
        expect(call_method.first).to eq({value: title})
      end
      %w(count unpaid original).each_with_index do |type, i|
        it "returns an array whose #{ordinalize(i)} member is an object with the correct loan_type #{type} value from the data hash and a type of `:number`" do
          allow(data_hash).to receive(:[]).with(:"#{loan_type}_#{type}").and_return(value)
          expect(call_method[i + 1]).to eq({value: value, type: :number})
        end
      end
    end

    describe '`downloadable_report`' do
      let(:id) { rand(1..1000) }
      let(:call_method) { subject.send(:downloadable_report) }
      let(:job_status) { double('job status', :update_attributes! => nil) }
      let(:job) { double('job instance', job_status: job_status) }
      let(:action_name) { double('name of controller action', gsub: nil) }
      let(:report_download_name) { double('report_download_name') }
      let(:report_download_params) { double('report_download_params') }
      let(:job_status_url) { double('job_status_url') }
      let(:job_cancel_url) { double('job_cancel_url') }
      describe 'when there is not an `export_format` parameter' do
        it 'yields a code block' do
          expect{|x| subject.send(:downloadable_report, &x) }.to yield_with_no_args
        end
      end
      describe 'when there is an `export_format` parameter' do
        before do
          allow(subject).to receive(:params).and_return({export_format: ReportsController::DOWNLOAD_FORMATS.sample})
          allow(subject).to receive(:render)
          allow(subject).to receive(:action_name).and_return(action_name)
        end
        it 'raises an exception if the `export_format` parameter is not included in the allowed formats' do
          allow(subject).to receive(:params).and_return({export_format: 'foo'})
          expect{call_method}.to raise_error(ArgumentError, 'Format not allowed for this report')
        end
        it 'raises an exception if the `export_format` parameter is not `:pdf` or `:xlsx`, even if the format is allowed' do
          allow(subject).to receive(:params).and_return({export_format: 'foo'})
          expect{subject.send(:downloadable_report, [:foo])}.to raise_error(ArgumentError, 'Report format not recognized')
        end
        [['pdf', RenderReportPDFJob], ['xlsx', RenderReportExcelJob]].each do |format|
          describe "when the export_format is #{format.first}" do
            before do
              allow(subject).to receive(:params).and_return({export_format: format.first})
              allow(format.last).to receive(:perform_later).and_return(job)
            end
            it "calls `perform_later` on #{format.last} with the current_member_id and action_name" do
              allow(subject).to receive(:current_member_id).and_return(id)
              expect(format.last).to receive(:perform_later).with(id, action_name, anything, anything).and_return(job)
              call_method
            end
            it "passes the `report_download_name` to the `perform_later` method" do
              expect(format.last).to receive(:perform_later).with( anything, anything, report_download_name, anything).and_return(job)
              subject.send(:downloadable_report, nil, nil, report_download_name)
            end
            it "passes the `report_download_params` to the `perform_later method`" do
              expect(format.last).to receive(:perform_later).with( anything, anything, anything, report_download_params).and_return(job)
              subject.send(:downloadable_report, nil, report_download_params)
            end
            it 'updates the job_status with the current_user_id' do
              allow(subject).to receive(:current_user).and_return(double('User', id: id))
              expect(job_status).to receive(:update_attributes!).with(user_id: id)
              call_method
            end
            it 'renders a json object with the correct `job_status_url` and `job_cancel_url`' do
              allow(subject).to receive(:job_status_url).with(job_status).and_return(job_status_url)
              allow(subject).to receive(:job_cancel_url).with(job_status).and_return(job_cancel_url)
              expect(subject).to receive(:render).with({json: {job_status_url: job_status_url, job_cancel_url: job_cancel_url}})
              call_method
            end
          end
        end
      end
    end
    describe '`format_securities_detail`' do
      let(:security) { double('a security', :[] => nil) }
      let(:call_method) { subject.send(:format_securities_detail, [security]) }
      it 'assigns a `position_detail` array to each of the securities it is passed' do
        expect(security).to receive(:[]=).with(:position_detail, anything)
        call_method
      end
      describe 'the :position_detail array' do
        %w(custody_account_number security_pledge_type cusip description reg_id pool_number coupon_rate maturity_date original_par
        factor factor_date current_par price price_date market_value).each do |key|
          let(key.to_sym) { double(key) }
        end
        let(:custody_account_type) { ['U', 'P'].sample }
        let(:security) {
          {
            custody_account_type: custody_account_type,
            custody_account_number: custody_account_number,
            security_pledge_type: security_pledge_type,
            cusip: cusip,
            description: description,
            reg_id: reg_id,
            pool_number: pool_number,
            coupon_rate: coupon_rate,
            maturity_date: maturity_date,
            original_par: original_par,
            factor: factor,
            factor_date: factor_date,
            current_par: current_par,
            price: price,
            price_date: price_date,
            market_value: market_value
          }
        }
        let(:formatted_value) { double('a formatted value') }
        before do
          %i(fhlb_formatted_percentage fhlb_date_standard_numeric fhlb_formatted_currency).each do |method|
            allow(subject).to receive(method)
          end
        end
        describe 'the first sub-array' do
          describe 'the first tertiary array' do
            it 'contains a first member with appropriate details for `custody_account_number`' do
              details = {
                heading: I18n.t('common_table_headings.custody_account_number'),
                value: custody_account_number,
                raw_value: custody_account_number
              }
              expect(call_method.first[:position_detail][0][0][0]).to eq(details)
            end
            it 'contains a second member with appropriate details for `custody_account_type`' do
              details = {
                heading: I18n.t('reports.pages.securities_position.custody_account_type'),
                value: ReportsController::ACCOUNT_TYPE_MAPPING[custody_account_type],
                raw_value: ReportsController::ACCOUNT_TYPE_MAPPING[custody_account_type]
              }
              expect(call_method.first[:position_detail][0][0][1]).to eq(details)
            end
            it 'contains a third member with appropriate details for `security_pledge_type`' do
              details = {
                heading: I18n.t('reports.pages.securities_position.security_pledge_type'),
                value: security_pledge_type,
                raw_value: security_pledge_type
              }
              expect(call_method.first[:position_detail][0][0][2]).to eq(details)
            end
          end
          describe 'the second tertiary array' do
            it 'contains a first member with appropriate details for `cusip`' do
              details = {
                heading: I18n.t('common_table_headings.cusip'),
                value: cusip,
                raw_value: cusip
              }
              expect(call_method.first[:position_detail][0][1][0]).to eq(details)
            end
            it 'contains a second member with appropriate details for `description`' do
              details = {
                heading: I18n.t('common_table_headings.security_description'),
                value: description,
                raw_value: description
              }
              expect(call_method.first[:position_detail][0][1][1]).to eq(details)
            end
          end
          describe 'the third tertiary array' do
            it 'contains a first member with appropriate details for `reg_id`' do
              details = {
                heading: I18n.t('reports.pages.securities_position.reg_id'),
                value: reg_id,
                raw_value: reg_id
              }
              expect(call_method.first[:position_detail][0][2][0]).to eq(details)
            end
            it 'contains a second member with appropriate details for `pool_number`' do
              details = {
                heading: I18n.t('common_table_headings.pool_number'),
                value: pool_number,
                raw_value: pool_number
              }
              expect(call_method.first[:position_detail][0][2][1]).to eq(details)
            end
            it 'contains a third member with appropriate details for `coupon_rate`' do
              allow(subject).to receive(:fhlb_formatted_percentage).with(coupon_rate, 3).and_return(formatted_value)
              details = {
                heading: I18n.t('common_table_headings.coupon_rate'),
                value: formatted_value,
                raw_value: coupon_rate
              }
              expect(call_method.first[:position_detail][0][2][2]).to eq(details)
            end
          end
          describe 'the fourth tertiary array' do
            it 'contains a first member with appropriate details for `maturity_date`' do
              allow(subject).to receive(:fhlb_date_standard_numeric).with(maturity_date).and_return(formatted_value)
              details = {
                heading: I18n.t('common_table_headings.maturity_date'),
                value: formatted_value,
                raw_value: maturity_date,
                type: :date
              }
              expect(call_method.first[:position_detail][0][3][0]).to eq(details)
            end
            it 'contains a second member with appropriate details for `original_par`' do
              allow(subject).to receive(:fhlb_formatted_currency).with(original_par, force_unit: true, precision: 2).and_return(formatted_value)
              details = {
                heading: I18n.t('common_table_headings.original_par_value'),
                value: formatted_value,
                raw_value: original_par
              }
              expect(call_method.first[:position_detail][0][3][1]).to eq(details)
            end
          end
        end
        describe 'the second sub-array' do
          describe 'the first tertiary array' do
            it 'contains a first member with appropriate details for `coupon_rate`' do
              allow(subject).to receive(:fhlb_formatted_percentage).with(factor, 8).and_return(formatted_value)
              details = {
                heading: I18n.t('reports.pages.securities_position.factor'),
                value: formatted_value,
                raw_value: factor
              }
              expect(call_method.first[:position_detail][1][0][0]).to eq(details)
            end
            it 'contains a second member with appropriate details for `factor_date`' do
              allow(subject).to receive(:fhlb_date_standard_numeric).with(factor_date).and_return(formatted_value)
              details = {
                heading: I18n.t('reports.pages.securities_position.factor_date'),
                value: formatted_value,
                raw_value: factor_date,
                type: :date
              }
              expect(call_method.first[:position_detail][1][0][1]).to eq(details)
            end
          end
          describe 'the second tertiary array' do
            it 'contains a member with appropriate details for `current_par`' do
              allow(subject).to receive(:fhlb_formatted_currency).with(current_par, force_unit: true, precision: 2).and_return(formatted_value)
              details = {
                heading: I18n.t('common_table_headings.current_par'),
                value: formatted_value,
                raw_value: current_par
              }
              expect(call_method.first[:position_detail][1][1][0]).to eq(details)
            end
          end
          describe 'the third tertiary array' do
            it 'contains a first member with appropriate details for `price`' do
              allow(subject).to receive(:fhlb_formatted_currency).with(price, force_unit: true, precision: 2).and_return(formatted_value)
              details = {
                heading: I18n.t('common_table_headings.price'),
                value: formatted_value,
                raw_value: price
              }
              expect(call_method.first[:position_detail][1][2][0]).to eq(details)
            end
            it 'contains a second member with appropriate details for `price_date`' do
              allow(subject).to receive(:fhlb_date_standard_numeric).with(price_date).and_return(formatted_value)
              details = {
                heading: I18n.t('common_table_headings.price_date'),
                value: formatted_value,
                raw_value: price_date,
                type: :date
              }
              expect(call_method.first[:position_detail][1][2][1]).to eq(details)
            end
          end
          describe 'the fourth tertiary array' do
            it 'contains a member with appropriate details for `market_value`' do
              allow(subject).to receive(:fhlb_formatted_currency).with(market_value, force_unit: true, precision: 2).and_return(formatted_value)
              details = {
                heading: I18n.t('reports.pages.securities_position.market_value'),
                value: formatted_value,
                raw_value: market_value
              }
              expect(call_method.first[:position_detail][1][3][0]).to eq(details)
            end
          end
        end
      end
    end
    describe '`sort_report_data`' do
      let(:item_1) { {foo: 5} }
      let(:item_2) { {foo: 1} }
      let(:item_3) { {foo: 15} }
      let(:data) { [item_1, item_2, item_3] }
      it 'returns an empty array if it is passed an empty array as the first argument' do
        expect(controller.send(:sort_report_data, [], :foo)).to eq([])
      end
      describe 'default behavior' do
        it 'sorts the given data by the given field in ascending order' do
          expect(controller.send(:sort_report_data, data, :foo)).to eq([item_2, item_1, item_3])
        end
      end
      describe 'when passed a third argument that is not `asc`' do
        it 'sorts the given data by the given field in descending order' do
          expect(controller.send(:sort_report_data, data, :foo, 'desc')).to eq([item_3, item_1, item_2])
        end
      end
    end
  end
end