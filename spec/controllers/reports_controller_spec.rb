require 'rails_helper'
include CustomFormattingHelper
include ActionView::Helpers::NumberHelper

RSpec.describe ReportsController, :type => :controller do
  login_user

  let(:today) {Date.new(2015,1,20)}
  let(:start_date) {Date.new(2014,12,01)}
  let(:end_date) {Date.new(2014,12,31)}
  let(:picker_preset_hash) {double(Hash)}

  before do
    allow(Time.zone).to receive(:now).and_return(today)
  end

  describe 'GET index' do
    it_behaves_like 'a user required action', :get, :index
    it 'should render the index view' do
      get :index
      expect(response.body).to render_template('index')
    end
  end

  describe 'requests hitting MemberBalanceService' do
    let(:member_balance_service_instance) { double('MemberBalanceServiceInstance') }
    let(:response_hash) { double('MemberBalanceHash') }

    before do
      allow(MemberBalanceService).to receive(:new).and_return(member_balance_service_instance)
    end

    describe 'GET capital_stock_activity' do
      it_behaves_like 'a user required action', :get, :capital_stock_activity

      it 'should render the capital_stock_activity view' do
        expect(member_balance_service_instance).to receive(:capital_stock_activity).and_return(response_hash)
        get :capital_stock_activity
        expect(response.body).to render_template('capital_stock_activity')
      end
      it 'should set @capital_stock_activity' do
        expect(member_balance_service_instance).to receive(:capital_stock_activity).and_return(response_hash)
        get :capital_stock_activity
        expect(assigns[:capital_stock_activity]).to eq(response_hash)
      end
      it 'should set @capital_stock_activity to {} if the report is disabled' do
        expect(controller).to receive(:report_disabled?).with(ReportsController::CAPITAL_STOCK_ACTIVITY_WEB_FLAGS).and_return(true)
        get :capital_stock_activity
        expect(assigns[:capital_stock_activity]).to eq({})
      end
      it 'should use the start_date and end_date provided in the params hash if available' do
        expect(member_balance_service_instance).to receive(:capital_stock_activity).with(start_date, end_date).and_return(response_hash)
        get :capital_stock_activity, start_date: start_date, end_date: end_date
      end
      it 'should use the last full month if no params are passed' do
        start_of_month = (today - 1.month).beginning_of_month
        end_of_month = start_of_month.end_of_month
        expect(member_balance_service_instance).to receive(:capital_stock_activity).with(start_of_month, end_of_month).and_return(response_hash)
        get :capital_stock_activity
      end
      it 'should raise an error if @capital_stock_activity is nil' do
        expect(member_balance_service_instance).to receive(:capital_stock_activity).and_return(nil)
        expect{get :capital_stock_activity}.to raise_error(StandardError)
      end
      describe "view instance variables" do
        before {
          allow(member_balance_service_instance).to receive(:capital_stock_activity).with(kind_of(Date), kind_of(Date)).and_return(response_hash)
        }
        it 'should set @start_date to the start_date param' do
          get :capital_stock_activity, start_date: start_date, end_date: end_date
          expect(assigns[:start_date]).to eq(start_date)
        end
        it 'should set @end_date to the end_date param' do
          get :capital_stock_activity, start_date: start_date, end_date: end_date
          expect(assigns[:end_date]).to eq(end_date)
        end
        it 'should pass @start_date and @end_date to DatePickerHelper#date_picker_presets and set @picker_presets to its outcome' do
          expect(controller).to receive(:date_picker_presets).with(start_date, end_date).and_return(picker_preset_hash)
          get :capital_stock_activity, start_date: start_date, end_date: end_date
          expect(assigns[:picker_presets]).to eq(picker_preset_hash)
        end
      end
    end

    describe 'GET borrowing_capacity' do
      it_behaves_like 'a user required action', :get, :borrowing_capacity
      it 'should render the borrowing_capacity view' do
        expect(member_balance_service_instance).to receive(:borrowing_capacity_summary).and_return(response_hash)
        get :borrowing_capacity
        expect(response.body).to render_template('borrowing_capacity')
      end
      it 'should raise an error if @borrowing_capacity_summary is nil' do
        expect(member_balance_service_instance).to receive(:borrowing_capacity_summary).and_return(nil)
        expect{get :borrowing_capacity}.to raise_error(StandardError)
      end
      it 'should set @borrowing_capacity_summary to the hash returned from MemberBalanceService' do
        expect(member_balance_service_instance).to receive(:borrowing_capacity_summary).and_return(response_hash)
        get :borrowing_capacity
        expect(assigns[:borrowing_capacity_summary]).to eq(response_hash)
      end
      it 'should set @borrowing_capacity_summary to {} if the report is disabled' do
        expect(controller).to receive(:report_disabled?).with(ReportsController::BORROWING_CAPACITY_WEB_FLAGS).and_return(true)
        get :borrowing_capacity
        expect(assigns[:borrowing_capacity_summary]).to eq({})
      end
    end

    describe 'GET settlement_transaction_account' do
      let(:filter) {'some filter'}
      it_behaves_like 'a user required action', :get, :settlement_transaction_account
      describe 'with activities array stubbed' do
        before do
          allow(response_hash).to receive(:[]).with(:activities)
        end
        it 'should render the settlement_transaction_account view' do
          expect(member_balance_service_instance).to receive(:settlement_transaction_account).and_return(response_hash)
          get :settlement_transaction_account
          expect(response.body).to render_template('settlement_transaction_account')
        end
        describe "view instance variables" do
          before {
            allow(member_balance_service_instance).to receive(:settlement_transaction_account).with(kind_of(Date), kind_of(Date), kind_of(String)).and_return(response_hash)
          }
          it 'should set @settlement_transaction_account to the hash returned from MemberBalanceService' do
            expect(member_balance_service_instance).to receive(:settlement_transaction_account).and_return(response_hash)
            get :settlement_transaction_account
            expect(assigns[:settlement_transaction_account]).to eq(response_hash)
          end
          it 'should raise an error if @settlement_transaction_account is nil' do
            expect(member_balance_service_instance).to receive(:settlement_transaction_account).and_return(nil)
            expect{get :settlement_transaction_account}.to raise_error(StandardError)
          end
          it 'should set @settlement_transaction_account to {} if the report is disabled' do
            expect(controller).to receive(:report_disabled?).with(ReportsController::SETTLEMENT_TRANSACTION_ACCOUNT_WEB_FLAGS).and_return(true)
            get :settlement_transaction_account
            expect(assigns[:settlement_transaction_account]).to eq({})
          end
          it 'should set @start_date to the start_date param' do
            get :settlement_transaction_account, start_date: start_date, end_date: end_date
            expect(assigns[:start_date]).to eq(start_date)
          end
          it 'should set @end_date to the end_date param' do
            get :settlement_transaction_account, start_date: start_date, end_date: end_date
            expect(assigns[:end_date]).to eq(end_date)
          end
          it 'should pass @start_date and @end_date to DatePickerHelper#date_picker_presets and set @picker_presets to its outcome' do
            expect(controller).to receive(:date_picker_presets).with(start_date, end_date).and_return(picker_preset_hash)
            get :settlement_transaction_account, start_date: start_date, end_date: end_date, sta_filter: filter
            expect(assigns[:picker_presets]).to eq(picker_preset_hash)
          end
          it 'sets @daily_balance_key to the constant DAILY_BALANCE_KEY found in MemberBalanceService' do
            my_const = double('Some Constant')
            stub_const('MemberBalanceService::DAILY_BALANCE_KEY', my_const)
            get :settlement_transaction_account
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
            get :settlement_transaction_account
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
            get :settlement_transaction_account
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
          get :settlement_transaction_account, start_date: start_date, end_date: end_date
          expect(assigns[:show_ending_balance]).to eq(false)
        end
        it 'should set @show_ending_balance to true if the date of the first transaction in the activity array is different than the @end_date' do
          activities_array = [
            {  trans_date: end_date + 1.day,
               balance: 55449.6
            }
          ]
          allow(response_hash).to receive(:[]).with(:activities).at_least(:once).and_return(activities_array)
          get :settlement_transaction_account, start_date: start_date, end_date: end_date
          expect(assigns[:show_ending_balance]).to eq(true)
        end
        it 'should set @show_ending_balance to true if there is no balance given for the first transaction in the activity array, even if the date of the transaction is equal to @end_date' do
          activities_array = [
              {  trans_date: end_date,
                 balance: nil
              }
          ]
          allow(response_hash).to receive(:[]).with(:activities).at_least(:once).and_return(activities_array)
          get :settlement_transaction_account, start_date: start_date, end_date: end_date
          expect(assigns[:show_ending_balance]).to eq(true)
        end
      end
    end

    describe 'GET advances_detail' do
      it_behaves_like 'a user required action', :get, :advances_detail
      let(:advances_detail) {double('Advances Detail object')}
      let(:start_date) { Date.new(2014,12,31) }
      before do
        allow(member_balance_service_instance).to receive(:advances_details).and_return(advances_detail)
        allow(advances_detail).to receive(:[]).with(:advances_details).and_return([])
      end

      it 'should render the advances_detail view' do
        get :advances_detail
        expect(response.body).to render_template('advances_detail')
      end

      [['pdf', RenderReportPDFJob], ['xlsx', RenderReportExcelJob]].each do |format|
        describe "downloading a #{format.first.upcase}" do
          let(:member_id) { double('A Member ID') }
          let(:start_date) { Date.today - 3.years }
          let(:job_status) { double('JobStatus', update_attributes!: nil)}
          let(:active_job) { double('Active Job Instance', job_status: job_status) }
          let(:user_id) { rand(1000) }
          let(:current_user) { double('User', id: user_id)}

          before do
            allow_any_instance_of(MembersService).to receive(:report_disabled?).and_return(false)
            allow_any_instance_of(MembersService).to receive(:member).with(anything).and_return({id: member_id, name: 'Foo'})
            allow_any_instance_of(subject.class).to receive(:current_member_id).and_return(member_id)
            allow(format.last).to receive(:perform_later).and_return(active_job)
            allow(controller).to receive(:current_user).and_return(current_user)
          end

          it "should enqueue a report #{format.first} job when the requested `export_format` is `#{format.first}`" do
            expect(format.last).to receive(:perform_later).with(member_id, 'advances_detail', anything, anything).and_return(active_job)
            get :advances_detail, export_format: format.first
          end
          it 'should enqueue a report #{format.first} job using the requested start_date' do
            expect(format.last).to receive(:perform_later).with(anything, anything, anything, hash_including(start_date: start_date.to_s)).and_return(active_job)
            get :advances_detail, export_format: format.first, start_date: start_date
          end
          it 'should update the job_status instance with the user_id of the current user' do
            expect(job_status).to receive(:update_attributes!).with({user_id: user_id})
            get :advances_detail, export_format: format.first
          end
          it 'should return a json response with a `job_status_url`' do
            get :advances_detail, export_format: format.first
            expect(JSON.parse(response.body).with_indifferent_access[:job_status_url]).to eq(job_status_url(job_status))
          end
          it 'should return a json response with a `job_cancel_url`' do
            get :advances_detail, export_format: format.first
            expect(JSON.parse(response.body).with_indifferent_access[:job_cancel_url]).to eq(job_cancel_url(job_status))
          end
        end
      end

      describe 'view instance variables' do
        it 'sets @start_date to param[:start_date] if available' do
          get :advances_detail, start_date: start_date
          expect(assigns[:start_date]).to eq(start_date)
        end
        it 'sets @start_date to today\'s date if param[:start_date] is not available' do
          get :advances_detail
          expect(assigns[:start_date]).to eq(today)
        end
        it 'should pass @as_of_date to DatePickerHelper#date_picker_presets and set @picker_presets to its outcome' do
          expect(controller).to receive(:date_picker_presets).with(start_date).and_return(picker_preset_hash)
          get :advances_detail, start_date: start_date
          expect(assigns[:picker_presets]).to eq(picker_preset_hash)
        end
        it 'should call the method `advances_details` on a MemberBalanceService instance with the `start` argument and set @advances_detail to its result' do
          expect(member_balance_service_instance).to receive(:advances_details).with(start_date).and_return(advances_detail)
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
            {trade_date: Date.today},
            {trade_date: Date.today + 1.years},
            {trade_date: Date.today - 1.years},
            {trade_date: Date.today - 3.years}
          ]
          allow(advances_detail).to receive(:[]).with(:advances_details).and_return(unsorted_advances)
          get :advances_detail
          last_trade_date = nil
          assigns[:advances_detail][:advances_details].each do |advance|
            expect(advance[:trade_date]).to be >= last_trade_date if last_trade_date
            last_trade_date = advance[:trade_date]
          end
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
      before do
        allow(member_balance_service_instance).to receive(:dividend_statement).with(kind_of(Date)).and_return(response_hash)
        allow(response_hash).to receive(:[]).with(:details).and_return([{}])
      end
      it_behaves_like 'a user required action', :get, :dividend_statement
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
    end

    describe 'GET securities_services_statement' do
      let(:make_request) { get :securities_services_statement }
      let(:response_hash) { double('A Securities Services Statement', :'[]' => nil)}
      before do
        allow(member_balance_service_instance).to receive(:securities_services_statement).with(kind_of(Date)).and_return(response_hash)
        allow(response_hash).to receive(:[]).with(:secutities_fees).and_return([{}])
        allow(response_hash).to receive(:[]).with(:transaction_fees).and_return([{}])
      end
      it_behaves_like 'a user required action', :get, :securities_services_statement
      it 'should assign `@statement` to the result of calling MemberBalanceService.securities_services_statement' do
        make_request
        expect(assigns[:statement]).to be(response_hash)
      end
      it 'should default @start_date to today' do
        make_request
        expect(assigns[:start_date]).to eq(Time.zone.now.to_date)
      end
      it 'should set @start_date to the `start_date` param' do
        get :securities_services_statement, start_date: '2012-02-11'
        expect(assigns[:start_date]).to eq(Date.new(2012, 2, 11))
      end
      it 'should set @picker_presets to the `date_picker_presets` for the `start_date`' do
        some_presets = double('Some Presets')
        allow(subject).to receive(:date_picker_presets).with(Time.zone.now.to_date).and_return(some_presets)
        make_request
        expect(assigns[:picker_presets]).to eq(some_presets)
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
          expect(assigns[:start_date]).to be_kind_of(Date)
        end
      end
    end

    describe 'GET letters_of_credit' do
      it_behaves_like 'a user required action', :get, :letters_of_credit

      let(:make_request) { get :letters_of_credit }
      let(:as_of_date) { double('some date') }
      let(:total_current_par) { double('total current par') }
      let(:maturity_date) {double('maturity date')}

      describe 'view instance variables' do
        before do
          allow(response_hash).to receive(:[]).with(:as_of_date)
          allow(response_hash).to receive(:[]).with(:total_current_par)
          allow(response_hash).to receive(:[]).with(:rows)
          allow(member_balance_service_instance).to receive(:letters_of_credit).and_return(response_hash)
        end
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
          row_keys = [:lc_number, :current_par, :maintenance_charge, :trade_date, :settlement_date, :maturity_date, :description]
          row = {}
          row_keys.each do |key|
            row[key] = double(key.to_s)
          end
          expect(response_hash).to receive(:[]).with(:rows).at_least(:once).and_return([row])
          make_request
          expect(assigns[:loc_table_data][:rows].length).to eq(1)
          row_keys.each_with_index do |key, i|
            expect(assigns[:loc_table_data][:rows][0][:columns][i][:value]).to eq(row[key])
          end
        end
        it 'sets @loc_table_data[:rows] to an empty array if no row data is returned from MemberBalanceService.letters_of_credit' do
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
      projections = %i(shift_neg_300 shift_neg_200 shift_neg_100 shift_0 shift_100 shift_200 shift_300)
      let(:make_request) { get :parallel_shift }
      let(:as_of_date) { double('some date') }
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
          hash[key] = double(key.to_s)
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
                  expect(row[:columns][2][:value]).to eq(putable_advance_data[:interest_rate])
                end
              end
              projections.each_with_index do |value, i|
                it "contains a `#{value}` value with type `basis_point`" do
                  assigns[:parallel_shift_table_data][:rows].each do |row|
                    expect(row[:columns][i + 3][:type]).to eq(:basis_point)
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
      it_behaves_like 'a user required action', :get, :current_securities_position
      describe 'view instance variables' do
        dropdown_options = [
          [I18n.t('reports.pages.securities_position.filter.all'), 'all'],
          [I18n.t('reports.pages.securities_position.filter.pledged'), 'pledged'],
          [I18n.t('reports.pages.securities_position.filter.unpledged'), 'unpledged']
        ]
        let(:securities_position_response) { double('Current Securities Position response', :[] => nil) }
        let(:as_of_date) { Date.new(2014,1,1) }
        before {
          allow(securities_position_response).to receive(:[]).with(:securities).and_return([])
          allow(member_balance_service_instance).to receive(:current_securities_position).and_return(securities_position_response)
        }
        it 'sets @current_securities_position to the hash returned from MemberBalanceService' do
          get :current_securities_position
          expect(assigns[:current_securities_position]).to eq(securities_position_response)
        end
        it 'sets @current_securities_position to {securities:[]} if the report is disabled' do
          allow(controller).to receive(:report_disabled?).with(ReportsController::CURRENT_SECURITIES_POSITION_WEB_FLAG).and_return(true)
          get :current_securities_position
          expect(assigns[:current_securities_position]).to eq({securities:[]})
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
        dropdown_options.each do |option|
          it "sets @securities_filter_text to the appropriate value when @securities_filter equals `#{option.last}`" do
            get :current_securities_position, securities_filter: option.last
            expect(assigns[:securities_filter_text]).to eq(option.first)
          end
        end
      end
    end
    describe 'GET monthly_securities_position' do
      it_behaves_like 'a user required action', :get, :monthly_securities_position
      describe 'view instance variables' do
        dropdown_options = [
          [I18n.t('reports.pages.securities_position.filter.all'), 'all'],
          [I18n.t('reports.pages.securities_position.filter.pledged'), 'pledged'],
          [I18n.t('reports.pages.securities_position.filter.unpledged'), 'unpledged']
        ]
        let(:securities_position_response) { double('Monthly Securities Position response', :[] => nil) }
        let(:as_of_date) { Date.new(2014,1,1) }
        before {
          allow(securities_position_response).to receive(:[]).with(:securities).and_return([])
          allow(member_balance_service_instance).to receive(:monthly_securities_position).and_return(securities_position_response)
        }
        it 'sets @current_securities_position to the hash returned from MemberBalanceService' do
          get :monthly_securities_position
          expect(assigns[:monthly_securities_position]).to eq(securities_position_response)
        end
        it 'sets @current_securities_position to {securities:[]} if the report is disabled' do
          allow(controller).to receive(:report_disabled?).with(ReportsController::MONTHLY_SECURITIES_WEB_FLAGS).and_return(true)
          get :monthly_securities_position
          expect(assigns[:monthly_securities_position]).to eq({securities:[]})
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
        dropdown_options.each do |option|
          it "sets @securities_filter_text to the appropriate value when @securities_filter equals `#{option.last}`" do
            get :monthly_securities_position, securities_filter: option.last
            expect(assigns[:securities_filter_text]).to eq(option.first)
          end
        end
      end
    end
    describe 'GET forward_commitments' do
      let(:forward_commitments) { get :forward_commitments }

      it_behaves_like 'a user required action', :get, :forward_commitments
      describe 'view instance variables' do
        let(:forward_commitments_response) { double('Forward Commitments response', :[] => nil) }
        let(:as_of_date) { double('Date') }
        let(:total_current_par) { double('Total current par') }
        before {
          allow(member_balance_service_instance).to receive(:forward_commitments).and_return(forward_commitments_response)
        }
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
  end

  describe 'GET current_price_indications' do
    let(:rates_service_instance) { double('RatesService') }
    let(:member_balances_service_instance) { double('MemberBalanceService') }
    let(:response_cpi_hash) { double('RatesServiceHash') }
    let(:response_sta_hash) { double('MemberBalanceServiceHash') }
    let(:vrc_response) {{'advance_maturity' => 'Overnight/Open','overnight_fed_funds_benchmark' => 0.13,'basis_point_spread_to_benchmark' => 5,'advance_rate' => 0.18}}
    let(:frc_response) {[{'advance_maturity' =>'1 Month','treasury_benchmark_maturity' => '3 Months','nominal_yield_of_benchmark' => 0.01,'basis_point_spread_to_benchmark' => 20,'advance_rate' => 0.21}]}
    let(:arc_response) {[{'advance_maturity' => '1 Year','1_month_libor' => 6,'3_month_libor' => 4,'6_month_libor' => 11,'prime' => -295}]}

    before do
      allow(RatesService).to receive(:new).and_return(rates_service_instance)
      allow(MemberBalanceService).to receive(:new).and_return(member_balances_service_instance)
      allow(member_balances_service_instance).to receive(:settlement_transaction_rate).and_return(response_sta_hash)
      allow(response_sta_hash).to receive(:[]).with('sta_rate')
      allow(rates_service_instance).to receive(:current_price_indications).with(kind_of(String), 'vrc').at_least(1).and_return(vrc_response)
      allow(rates_service_instance).to receive(:current_price_indications).with(kind_of(String), 'frc').at_least(1).and_return(frc_response)
      allow(rates_service_instance).to receive(:current_price_indications).with(kind_of(String), 'arc').at_least(1).and_return(arc_response)
    end
    it_behaves_like 'a user required action', :get, :current_price_indications
    it 'renders the current_price_indications view' do
      allow(rates_service_instance).to receive(:current_price_indications).and_return(response_cpi_hash)
      allow(response_cpi_hash).to receive(:collect)
      allow(member_balances_service_instance).to receive(:settlement_transaction_rate).and_return(response_sta_hash)
      get :current_price_indications
      expect(response.body).to render_template('current_price_indications')
    end
    it 'should return vrc data' do
      get :current_price_indications
      expect(assigns[:standard_vrc_data]).to eq(vrc_response)
      expect(assigns[:sbc_vrc_data]).to eq(vrc_response)
    end
    it 'should return frc data' do
      get :current_price_indications
      expect(assigns[:standard_frc_data]).to eq(frc_response)
      expect(assigns[:sbc_frc_data]).to eq(frc_response)
    end
    it 'should return arc data' do
      get :current_price_indications
      expect(assigns[:standard_arc_data]).to eq(arc_response)
      expect(assigns[:sbc_arc_data]).to eq(arc_response)
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
    let(:irr_response) {[{'effective_date' => effective_date, 'advance_number' => advance_number, 'prior_rate' => prior_rate, 'new_rate' => new_rate, 'next_reset' => next_reset}]}

    before do
      allow(RatesService).to receive(:new).and_return(rates_service_instance)
      allow(rates_service_instance).to receive(:interest_rate_resets).at_least(1).and_return(irr_response)
    end
    it_behaves_like 'a user required action', :get, :interest_rate_resets
    it 'renders the interest_rate_resets view' do
      allow(rates_service_instance).to receive(:interest_rate_resets).and_return(response_hash)
      allow(response_hash).to receive(:collect)
      get :interest_rate_resets
      expect(response.body).to render_template('interest_rate_resets')
    end
    it 'should return irr data' do
      get :interest_rate_resets
      expect(assigns[:irr_table_data][:rows][0][:columns]).to eq([{:type=>:date, :value=>effective_date}, {:value=>advance_number}, {:type=>:index, :value=>prior_rate}, {:type=>:index, :value=>new_rate}, {:value=>next_reset}])
    end
  end

  describe 'GET securities_transactions' do
    let(:start_date) { Date.new(2014,12,31) }
    let(:member_balances_service_instance) { double('MemberBalanceService') }
    let(:response_hash) { double('MemberBalanceServiceHash') }
    let(:transaction_hash) { double('transaction_hash') }
    let(:custody_account_no) { double('custody_account_no') }
    let(:new_transaction) { double('new_transaction') }
    let(:cusip) { double('cusip') }
    let(:transaction_code) { double('transaction_code') }
    let(:security_description) { double('security_description') }
    let(:units) { double('units') }
    let(:maturity_date) { double('maturity_date') }
    let(:payment_or_principal) { double('payment_or_principal') }
    let(:interest) { double('interest') }
    let(:total) { double('total') }
    let(:total_net) { double('total_net') }
    let(:final) { double('final') }
    let(:securities_transactions_response) {[{'custody_account_no' => custody_account_no, 'new_transaction' => false, 'cusip' => cusip, 'transaction_code' => transaction_code, 'security_description' => security_description, 'units' => units, 'maturity_date' => maturity_date, 'payment_or_principal' => payment_or_principal, 'interest' => interest, 'total' => total}]}
    let(:securities_transactions_response_with_new_transaction) {[{'custody_account_no' => '12345', 'new_transaction' => true, 'cusip' => cusip, 'transaction_code' => transaction_code, 'security_description' => security_description, 'units' => units, 'maturity_date' => maturity_date, 'payment_or_principal' => payment_or_principal, 'interest' => interest, 'total' => total}]}

    before do
      allow(MemberBalanceService).to receive(:new).and_return(member_balances_service_instance)
      allow(member_balances_service_instance).to receive(:securities_transactions).with(kind_of(Date)).at_least(1).and_return(response_hash)
      allow(response_hash).to receive(:[]).with(:total_net).and_return(total_net)
      allow(response_hash).to receive(:[]).with(:final).and_return(final)
      allow(response_hash).to receive(:[]).with(:total_payment_or_principal)
      allow(response_hash).to receive(:[]).with(:total_interest)
    end
    it_behaves_like 'a user required action', :get, :securities_transactions
    it 'renders the securities_transactions view' do
      allow(response_hash).to receive(:[]).with(:transactions).and_return(transaction_hash)
      allow(transaction_hash).to receive(:collect)
      get :securities_transactions
      expect(response.body).to render_template('securities_transactions')
    end
    it 'should pass @start_date to DatePickerHelper#date_picker_presets and set @picker_presets to its outcome' do
      allow(controller).to receive(:date_picker_presets).with(start_date).and_return(picker_preset_hash)
      allow(response_hash).to receive(:[]).with(:transactions).and_return(securities_transactions_response_with_new_transaction)
      get :securities_transactions, start_date: start_date
      expect(assigns[:picker_presets]).to eq(picker_preset_hash)
    end
    it 'should return securities transactions data' do
      allow(response_hash).to receive(:[]).with(:transactions).and_return(securities_transactions_response)
      get :securities_transactions
      expect(assigns[:total_net]).to eq(total_net)
      expect(assigns[:final]).to eq(final)
      expect(assigns[:securities_transactions_table_data][:rows][0][:columns]).to eq([{:type=>nil, :value=>custody_account_no}, {:type=>nil, :value=>cusip}, {:type=>nil, :value=>transaction_code}, {:type=>nil, :value=>security_description}, {:type=>:basis_point, :value=>units}, {:type=>:date, :value=>maturity_date}, {:type=>:rate, :value=>payment_or_principal}, {:type=>:rate, :value=>interest}, {:type=>:rate, :value=>total}])
    end
    it 'should return securities transactions data with new transaction indicator' do
      allow(response_hash).to receive(:[]).with(:transactions).and_return(securities_transactions_response_with_new_transaction)
      get :securities_transactions
      expect(assigns[:securities_transactions_table_data][:rows][0][:columns]).to eq([{:type=>nil, :value=>'12345*'}, {:type=>nil, :value=>cusip}, {:type=>nil, :value=>transaction_code}, {:type=>nil, :value=>security_description}, {:type=>:basis_point, :value=>units}, {:type=>:date, :value=>maturity_date}, {:type=>:rate, :value=>payment_or_principal}, {:type=>:rate, :value=>interest}, {:type=>:rate, :value=>total}])
    end
  end

  describe 'requests hitting RatesService' do
    let(:rates_service_instance) { double('RatesService') }
    let(:response_hash) { double('RatesServiceHash') }

    before do
      allow(RatesService).to receive(:new).and_return(rates_service_instance)
      allow(rates_service_instance).to receive(:historical_price_indications).and_return(response_hash)
      allow(response_hash).to receive(:[]).with(:rates_by_date)
    end

    describe 'GET historical_price_indications' do
      it_behaves_like 'a user required action', :get, :historical_price_indications
      it 'renders the historical_price_indications view' do
        expect(rates_service_instance).to receive(:historical_price_indications).and_return(response_hash)
        get :historical_price_indications
        expect(response.body).to render_template('historical_price_indications')
      end
      it 'should use the start_date and end_date provided in the params hash if available' do
        expect(rates_service_instance).to receive(:historical_price_indications).with(start_date, end_date, anything, anything).and_return(response_hash)
        get :historical_price_indications, start_date: start_date, end_date: end_date
      end
      it 'should use the start of this year to date as the date range if no params are passed' do
        start_of_year = today.beginning_of_year
        expect(rates_service_instance).to receive(:historical_price_indications).with(start_of_year, today, anything, anything).and_return(response_hash)
        get :historical_price_indications
      end
      it 'should raise an error if @historical_price_indications is nil' do
        expect(rates_service_instance).to receive(:historical_price_indications).and_return(nil)
        expect{get :historical_price_indications}.to raise_error(StandardError)
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
          get :historical_price_indications, historical_price_collateral_type: 'standard', historical_price_credit_type: 'daily_prime'
          expect(assigns[:table_data][:rows][0][:columns]).to eq([{:type=>:index, :value=>index}, {:type=>:basis_point, :value=>basis_1Y}, {:type=>:index, :value=>index}, {:type=>:basis_point, :value=>basis_2Y}, {:type=>:index, :value=>index}, {:type=>:basis_point, :value=>basis_3Y}, {:type=>:index, :value=>index}, {:type=>:basis_point, :value=>basis_5Y}])
        end
      end
      describe "view instance variables" do
        it 'should set @historical_price_indications' do
          expect(rates_service_instance).to receive(:historical_price_indications).and_return(response_hash)
          get :historical_price_indications
          expect(assigns[:historical_price_indications]).to eq(response_hash)
        end
        it 'should raise an error if @historical_price_indications is nil' do
          expect(rates_service_instance).to receive(:historical_price_indications).and_return(nil)
          expect{get :historical_price_indications}.to raise_error(StandardError)
        end
        it 'should set @historical_price_indications to {} if the report is disabled' do
          expect(controller).to receive(:report_disabled?).with(ReportsController::HISTORICAL_PRICE_INDICATIONS_WEB_FLAGS).and_return(true)
          get :historical_price_indications
          expect(assigns[:historical_price_indications]).to eq({})
        end
        it 'should set @start_date to the start_date param' do
          get :historical_price_indications, start_date: start_date, end_date: end_date
          expect(assigns[:start_date]).to eq(start_date)
        end
        it 'should set @end_date to the end_date param' do
          get :historical_price_indications, start_date: start_date, end_date: end_date
          expect(assigns[:end_date]).to eq(end_date)
        end
        it 'should pass @start_date and @end_date to DatePickerHelper#date_picker_presets and set @picker_presets to its outcome' do
          expect(controller).to receive(:date_picker_presets).with(start_date, end_date).and_return(picker_preset_hash)
          get :historical_price_indications, start_date: start_date, end_date: end_date
          expect(assigns[:picker_presets]).to eq(picker_preset_hash)
        end
        it 'should set @collateral_type to `standard` and @collateral_type_text to the proper i18next translation for `standard` if standard is passed as the historical_price_collateral_type param' do
          get :historical_price_indications, historical_price_collateral_type: 'standard'
          expect(assigns[:collateral_type]).to eq('standard')
          expect(assigns[:collateral_type_text]).to eq(I18n.t('reports.pages.price_indications.standard_credit_program'))
        end
        it 'should set @collateral_type to `sbc` and @collateral_type_text to the proper i18next translation for `sbc` if sbc is passed as the historical_price_collateral_type param' do
          get :historical_price_indications, historical_price_collateral_type: 'sbc'
          expect(assigns[:collateral_type]).to eq('sbc')
          expect(assigns[:collateral_type_text]).to eq(I18n.t('reports.pages.price_indications.sbc_program'))
        end
        it 'should set @collateral_type to `standard` and @collateral_type_text to the proper i18next translation for `standard` if nothing is passed for the historical_price_collateral_type param' do
          get :historical_price_indications
          expect(assigns[:collateral_type_text]).to eq(I18n.t('reports.pages.price_indications.standard_credit_program'))
        end
        it 'should set @collateral_type_options to an array of arrays containing the appropriate values and labels for standard and sbc' do
          options_array = [
              [I18n.t('reports.pages.price_indications.standard_credit_program'), 'standard'],
              [I18n.t('reports.pages.price_indications.sbc_program'), 'sbc']
          ]
          get :historical_price_indications
          expect(assigns[:collateral_type_options]).to eq(options_array)
        end
        it 'should set @credit_type to `frc` and @credit_type_text to the proper i18next translation for `frc` if frc is passed as the historical_price_credit_type param' do
          get :historical_price_indications, historical_price_credit_type: 'frc'
          expect(assigns[:credit_type]).to eq('frc')
          expect(assigns[:credit_type_text]).to eq(I18n.t('reports.pages.price_indications.frc.dropdown'))
        end
        it 'should set @credit_type to `vrc` and @credit_type_text to the proper i18next translation for `vrc` if vrc is passed as the historical_price_credit_type param' do
          get :historical_price_indications, historical_price_credit_type: 'vrc'
          expect(assigns[:credit_type]).to eq('vrc')
          expect(assigns[:credit_type_text]).to eq(I18n.t('reports.pages.price_indications.vrc.dropdown'))
        end
        ['1m_libor', '3m_libor', '6m_libor', 'daily_prime'].each do |credit_type|
          it "should set @credit_type to `#{credit_type}` and @credit_type_text to the proper i18next translation for `#{credit_type}` if #{credit_type} is passed as the historical_price_credit_type param" do
            get :historical_price_indications, historical_price_credit_type: credit_type
            expect(assigns[:credit_type]).to eq(credit_type)
            expect(assigns[:credit_type_text]).to eq(I18n.t("reports.pages.price_indications.#{credit_type}.dropdown"))
          end
        end
        it 'should set @credit_type to `frc` and @credit_type_text to the proper i18next translation for `frc` if nothing is passed for the historical_price_credit_type param' do
          get :historical_price_indications
          expect(assigns[:credit_type]).to eq('frc')
          expect(assigns[:credit_type_text]).to eq(I18n.t('reports.pages.price_indications.frc.dropdown'))
        end
        it 'should set @credit_type_options to an array of arrays containing the appropriate values and labels for standard and sbc' do
          options_array = [
              [I18n.t('reports.pages.price_indications.frc.dropdown'), 'frc'],
              [I18n.t('reports.pages.price_indications.vrc.dropdown'), 'vrc'],
              [I18n.t('reports.pages.price_indications.1m_libor.dropdown'), '1m_libor'],
              [I18n.t('reports.pages.price_indications.3m_libor.dropdown'), '3m_libor'],
              [I18n.t('reports.pages.price_indications.6m_libor.dropdown'), '6m_libor'],
              [I18n.t('reports.pages.price_indications.daily_prime.dropdown'), 'daily_prime'],
              [I18n.t('reports.pages.price_indications.embedded_cap.dropdown'), 'embedded_cap']
          ]
          get :historical_price_indications
          expect(assigns[:credit_type_options]).to eq(options_array)
        end
        describe '@table_data' do
          describe 'table_heading' do
            ['1m_libor', '3m_libor', '6m_libor'].each do |credit_type|
              it "should set table_heading to the I18n translation for #{credit_type} table heading if the credit type is `#{credit_type}`" do
                get :historical_price_indications, historical_price_credit_type: credit_type
                expect((assigns[:table_data])[:table_heading]).to eq(I18n.t("reports.pages.price_indications.#{credit_type}.table_heading"))
              end
            end
          end
          describe 'column_headings' do
            let(:frc_column_headings) {[I18n.t('global.date'), I18n.t('global.dates.1_month'), I18n.t('global.dates.2_months'), I18n.t('global.dates.3_months'), I18n.t('global.dates.6_months'), I18n.t('global.dates.1_year'), I18n.t('global.dates.2_years'), I18n.t('global.dates.3_years'), I18n.t('global.dates.5_years'), I18n.t('global.dates.7_years'), I18n.t('global.dates.10_years'), I18n.t('global.dates.15_years'), I18n.t('global.dates.20_years'), I18n.t('global.dates.30_years')]}
            let(:vrc_column_headings)  {[I18n.t('global.date'), I18n.t('global.dates.1_day')]}
            let(:arc_column_headings) {[I18n.t('global.date'), I18n.t('global.dates.1_year'), I18n.t('global.dates.2_years'), I18n.t('global.dates.3_years'), I18n.t('global.dates.5_years')]}
            let(:arc_daily_prime_column_headings) {[I18n.t('global.full_dates.1_year'), I18n.t('global.full_dates.2_years'), I18n.t('global.full_dates.3_years'), I18n.t('global.full_dates.5_years')]}
            it 'sets column_headings for the `frc` credit type' do
              get :historical_price_indications, historical_price_credit_type: 'frc'
              expect((assigns[:table_data])[:column_headings]).to eq(frc_column_headings)
            end
            it 'sets column_headings for the `vrc` credit type' do
              get :historical_price_indications, historical_price_credit_type: 'vrc'
              expect((assigns[:table_data])[:column_headings]).to eq(vrc_column_headings)
            end
            ['1m_libor', '3m_libor', '6m_libor'].each do |credit_type|
              it "sets column_headings for the #{credit_type} credit_type" do
                get :historical_price_indications, historical_price_credit_type: credit_type
                expect((assigns[:table_data])[:column_headings]).to eq(arc_column_headings)
              end
            end
            it 'sets column_headings for the daily_prime credit_type' do
              get :historical_price_indications, historical_price_credit_type: 'daily_prime'
              expect((assigns[:table_data])[:column_headings]).to eq(arc_daily_prime_column_headings)
            end
          end
          describe 'rows' do
            let(:row_1) {{date: 'some_date', rates_by_term: [{type: :index, value: 'rate_1'}, {type: :index, value: 'rate_2'}]}}
            let(:row_2) {{date: 'some_other_date', rates_by_term: [{type: :index, value: 'rate_3'}, {type: :index, value: 'rate_4'}]}}
            let(:rows) {[row_1, row_2]}
            let(:formatted_rows) {[{date: 'some_date', columns: [{type: :index, value: 'rate_1'}, {type: :index, value: 'rate_2'}]}, {date: 'some_other_date', columns: [{type: :index, value: 'rate_3'}, {type: :index, value: 'rate_4'}]}]}
            it 'should be an array of rows, each containing a row object with a date and a column array containing objects with a type and a rate value' do
              allow(response_hash).to receive(:[]).with(:rates_by_date).and_return(rows)
              allow(response_hash).to receive(:[]=)
              get :historical_price_indications, historical_price_credit_type: 'frc'
              expect((assigns[:table_data])[:rows]).to eq(formatted_rows)
            end
          end
        end
      end
    end
  end

  describe 'GET authorizations' do
    it_behaves_like 'a user required action', :get, :authorizations
    describe 'view instance variables' do
      let(:member_service_instance) {double('MembersService')}
      let(:user_no_roles) {OpenStruct.new(display_name: 'User With No Roles', roles: [])}
      let(:user_etransact) {OpenStruct.new(display_name: 'Etransact User', roles: [User::Roles::ETRANSACT_SIGNER])}
      let(:signers_and_users) {[user_no_roles, user_etransact]}
      let(:roles) {['all', User::Roles::SIGNER_MANAGER, User::Roles::SIGNER_ENTIRE_AUTHORITY, User::Roles::AFFORDABILITY_SIGNER, User::Roles::COLLATERAL_SIGNER, User::Roles::MONEYMARKET_SIGNER, User::Roles::DERIVATIVES_SIGNER, User::Roles::SECURITIES_SIGNER, User::Roles::WIRE_SIGNER, User::Roles::ACCESS_MANAGER, User::Roles::ETRANSACT_SIGNER]}
      let(:role_translations) {[t('user_roles.all_authorizations'), t('user_roles.resolution.dropdown'), t('user_roles.entire_authority.dropdown'), t('user_roles.affordable_housing.title'), t('user_roles.collateral.title'), t('user_roles.money_market.title'), t('user_roles.interest_rate_derivatives.title'), t('user_roles.securities.title'), t('user_roles.wire_transfer.title'), t('user_roles.access_manager.title'), t('user_roles.etransact.title')]}
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
          expect(assigns[:authorizations_table_data][:column_headings]).to eq([I18n.t('user_roles.user.title'), I18n.t('reports.authorizations.title')])
        end
        describe '`rows`' do
          it 'is an array containing a `columns` hash' do
            get :authorizations
            expect(assigns[:authorizations_table_data][:rows]).to be_kind_of(Array)
            assigns[:authorizations_table_data][:rows].each do |row|
              expect(row).to be_kind_of(Hash)
            end
          end
          describe '`columns` hash' do
            it 'contains a `display_name` with no type' do
              get :authorizations
              assigns[:authorizations_table_data][:rows].each do |row|
                expect(row[:columns].first[:type]).to be_nil
                expect(row[:columns].first[:value]).to be_kind_of(String)
              end
            end
            it 'contains `user_roles` with a type of `list`' do
              get :authorizations
              assigns[:authorizations_table_data][:rows].each do |row|
                expect(row[:columns].last[:type]).to eq(:list)
                expect(row[:columns].last[:value]).to be_kind_of(Array)
              end
            end
            it 'contains all users sorted by display_name if the authorizations_filter is set to `all`' do
              get :authorizations
              expect(assigns[:authorizations_table_data][:rows].length).to eq(2)
              expect(assigns[:authorizations_table_data][:rows].first[:columns].first[:value]).to eq('Etransact User')
              expect(assigns[:authorizations_table_data][:rows].first[:columns].last[:value]).to eq([I18n.t('user_roles.etransact.title')])
              expect(assigns[:authorizations_table_data][:rows].last[:columns].first[:value]).to eq('User With No Roles')
              expect(assigns[:authorizations_table_data][:rows].last[:columns].last[:value]).to eq([I18n.t('user_roles.user.title')])
            end
            it "only contains users with a user_role of #{I18n.t('user_roles.user.title')} if the authorizations_filter is set to `user`" do
              get :authorizations, :authorizations_filter => 'user'
              expect(assigns[:authorizations_table_data][:rows].length).to eq(1)
              expect(assigns[:authorizations_table_data][:rows].first[:columns].first[:value]).to eq('User With No Roles')
              expect(assigns[:authorizations_table_data][:rows].first[:columns].last[:value]).to eq([I18n.t('user_roles.user.title')])
            end
            it 'only contains users with the proper role if an authorization_filter is set' do
              get :authorizations, :authorizations_filter => User::Roles::ETRANSACT_SIGNER
              expect(assigns[:authorizations_table_data][:rows].length).to eq(1)
              expect(assigns[:authorizations_table_data][:rows].first[:columns].first[:value]).to eq('Etransact User')
              expect(assigns[:authorizations_table_data][:rows].first[:columns].last[:value]).to eq([I18n.t('user_roles.etransact.title')])
            end
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
          expect(controller.send(:roles_for_signers, user)).to eq([role_mappings[role]])
        end
      end
      it 'returns an array containing the I18n translation for `user` when a given user has no roles' do
        role_mappings.each_key do |role|
          user = {:roles => []}
          expect(controller.send(:roles_for_signers, user)).to eq([I18n.t('user_roles.user.title')])
        end
      end
    end
  end

end
