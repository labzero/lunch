require 'rails_helper'
include CustomFormattingHelper
include ActionView::Helpers::NumberHelper

RSpec.describe ReportsController, :type => :controller do
  login_user

  let(:today) {Date.new(2015,1,20)}
  let(:start_date) {Date.new(2014,12,01)}
  let(:end_date) {Date.new(2014,12,31)}
  let(:picker_preset_hash) {double(Hash)}
  let(:zone) {double('Time.zone')}
  let(:now) {double('Time.zone.now')}

  before do
    allow(now).to receive(:to_date).at_least(1).and_return(today)
    allow(zone).to receive(:now).at_least(1).and_return(now)
    allow(Time).to receive(:zone).at_least(1).and_return(zone)
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
    end
    it 'should set @borrowing_capacity_summary to the hash returned from MemberBalanceService' do
      expect(member_balance_service_instance).to receive(:borrowing_capacity_summary).and_return(response_hash)
      get :borrowing_capacity
      expect(assigns[:borrowing_capacity_summary]).to eq(response_hash)
    end
    it 'should raise an error if @borrowing_capacity_summary is nil' do
      expect(member_balance_service_instance).to receive(:borrowing_capacity_summary).and_return(nil)
      expect{get :borrowing_capacity}.to raise_error(StandardError)
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
        it 'should raise an error if @settlement_tranasction_account is nil' do
          expect(member_balance_service_instance).to receive(:settlement_transaction_account).and_return(nil)
          expect{get :settlement_transaction_account}.to raise_error(StandardError)
        end
        describe "view instance variables" do
          before {
            allow(member_balance_service_instance).to receive(:settlement_transaction_account).with(kind_of(Date), kind_of(Date), kind_of(String)).and_return(response_hash)
          }
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
      let(:as_of_date) { Date.new(2014,12,31) }
      before do
        allow(member_balance_service_instance).to receive(:advances_details).and_return(advances_detail)
        allow(advances_detail).to receive(:[]).with(:advances_details).and_return([])
      end

      it 'should render the capital_stock_activity view' do
        get :advances_detail
        expect(response.body).to render_template('advances_detail')
      end

      it 'sets @as_of_date to param[:as_of_date] if available' do
        get :advances_detail, as_of_date: as_of_date
        expect(assigns[:as_of_date]).to eq(as_of_date)
      end

      it 'sets @as_of_date to today\'s date if param[:as_of_date] is not available' do
        get :advances_detail
        expect(assigns[:as_of_date]).to eq(today)
      end

      it 'should pass @as_of_date to DatePickerHelper#date_picker_presets and set @picker_presets to its outcome' do
        expect(controller).to receive(:date_picker_presets).with(as_of_date).and_return(picker_preset_hash)
        get :advances_detail, as_of_date: as_of_date
        expect(assigns[:picker_presets]).to eq(picker_preset_hash)
      end

      it 'should call the method `advances_details` on a MemberBalanceService instance with the `as_of` argument and set @advances_detail to its result' do
        expect(member_balance_service_instance).to receive(:advances_details).with(as_of_date).and_return(advances_detail)
        get :advances_detail, as_of_date: as_of_date
        expect(assigns[:advances_detail]).to eq(advances_detail)
      end

      it 'should raise an error if `advances_details` returns nil' do
        expect(member_balance_service_instance).to receive(:advances_details).and_return(nil)
        expect{get :advances_detail, as_of_date: as_of_date}.to raise_error
      end

      describe 'setting the `prepayment_fee_indication` attribute for a given advance record' do
        let(:advance_record) {double('Advance Record')}
        let(:advances_array) {[advance_record]}
        let(:prepayment_fee) {464654654}
        before do
          allow(advances_detail).to receive(:[]).with(:advances_details).at_least(1).and_return(advances_array)
          allow(member_balance_service_instance).to receive(:advances_details).and_return(advances_detail)
        end
        it 'sets the attribute to `unavailable online` message if `notes` attribute for that record is `unavailable_online`' do
          expect(advance_record).to receive(:[]=).with(:prepayment_fee_indication, I18n.t('reports.pages.advances_detail.unavailable_online'))
          expect(advance_record).to receive(:[]).with(:notes).and_return('unavailable_online')
          get :advances_detail
        end
        it 'sets the attribute to `not applicable for vrc` message if `notes` attribute for that record is `not_applicable_to_vrc`' do
          expect(advance_record).to receive(:[]=).with(:prepayment_fee_indication, I18n.t('reports.pages.advances_detail.not_applicable_to_vrc'))
          expect(advance_record).to receive(:[]).with(:notes).and_return('not_applicable_to_vrc')
          get :advances_detail
        end
        it 'sets the attribute to `prepayment fee restructure` message if `notes` attribute for that record is `prepayment_fee_restructure`' do
          date = Date.new(2013, 1, 1)
          expect(advance_record).to receive(:[]=).with(:prepayment_fee_indication, I18n.t('reports.pages.advances_detail.prepayment_fee_restructure_html', fee: number_to_currency(prepayment_fee), date: fhlb_date_standard_numeric(date)))
          expect(advance_record).to receive(:[]).with(:structure_product_prepay_valuation_date).and_return(date)
          expect(advance_record).to receive(:[]).with(:prepayment_fee_indication).and_return(prepayment_fee)
          expect(advance_record).to receive(:[]).with(:notes).and_return('prepayment_fee_restructure')
          get :advances_detail
        end
        it 'sets the attribute to equal the `prepayment_fee_indication` value if that attribute exists and the `note` attribute is not `unavailable_online`, `not_applicable_to_vrc`, or `prepayment_fee_restructure`' do
          expect(advance_record).to receive(:[]=).with(:prepayment_fee_indication, fhlb_formatted_currency(prepayment_fee))
          expect(advance_record).to receive(:[]).with(:notes).and_return(nil)
          expect(advance_record).to receive(:[]).with(:prepayment_fee_indication).and_return(prepayment_fee)
          get :advances_detail
        end
        it 'sets the attribute to equal the `not applicable` message if there is no value for the `prepayment_fee_indication` attribute and the `note` attribute is not `unavailable_online`, `not_applicable_to_vrc`, or `prepayment_fee_restructure`' do
          expect(advance_record).to receive(:[]=).with(:prepayment_fee_indication, I18n.t('global.not_applicable'))
          expect(advance_record).to receive(:[]).with(:notes).and_return(nil)
          expect(advance_record).to receive(:[]).with(:prepayment_fee_indication).and_return(nil)
          get :advances_detail
        end
      end
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
      describe "view instance variables" do
        it 'should set @historical_price_indications' do
          expect(rates_service_instance).to receive(:historical_price_indications).and_return(response_hash)
          get :historical_price_indications
          expect(assigns[:historical_price_indications]).to eq(response_hash)
        end
        it 'should set @start_date to the start_date param' do
          get :historical_price_indications, start_date: start_date, end_date: end_date
          expect(assigns[:start_date]).to eq(start_date)
        end
        it 'should set @end_date to the end_date param' do
          get :historical_price_indications, start_date: start_date, end_date: end_date
          expect(assigns[:end_date]).to eq(end_date)
        end
        it 'should pass @start_date, @end_date and a custom preset hash to DatePickerHelper#date_picker_presets and set @picker_presets to its outcome' do
          expect(controller).to receive(:date_picker_presets).with(start_date, end_date, anything).and_return(picker_preset_hash)
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
      end
    end

  end


end