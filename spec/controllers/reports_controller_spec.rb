require 'rails_helper'

RSpec.describe ReportsController, :type => :controller do

  describe 'GET index' do
    it 'should render the index view' do
      get :index
      expect(response.body).to render_template('index')
    end
  end

  describe 'requests hitting MemberBalanceService' do
    let(:member_balance_service_instance) { double('MemberBalanceServiceInstance') }
    let(:response_hash) { double('MemberBalanceHash') }
    let(:today) {Date.new(2015,1,20)}
    let(:start_date) {Date.new(2014,12,01)}
    let(:end_date) {Date.new(2014,12,31)}
    before do
      expect(MemberBalanceService).to receive(:new).and_return(member_balance_service_instance)
    end

    describe 'GET capital_stock_activity' do
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
        let(:picker_preset_hash) {double(Hash)}
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
        it 'should pass @start_date and @end_date to DatePickerHelper#range_picker_default_presets and set @picker_presets to its outcome' do
          expect(controller).to receive(:range_picker_default_presets).with(start_date, end_date).and_return(picker_preset_hash)
          get :capital_stock_activity, start_date: start_date, end_date: end_date
          expect(assigns[:picker_presets]).to eq(picker_preset_hash)
        end
      end
    end

    describe 'GET borrowing_capacity' do
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
        let(:picker_preset_hash) {double(Hash)}
        before {
          allow(member_balance_service_instance).to receive(:settlement_transaction_account).with(kind_of(Date), kind_of(Date)).and_return(response_hash)
        }
        it 'should set @start_date to the start_date param' do
          get :settlement_transaction_account, start_date: start_date, end_date: end_date
          expect(assigns[:start_date]).to eq(start_date)
        end
        it 'should set @end_date to the end_date param' do
          get :settlement_transaction_account, start_date: start_date, end_date: end_date
          expect(assigns[:end_date]).to eq(end_date)
        end
        it 'should pass @start_date and @end_date to DatePickerHelper#range_picker_default_presets and set @picker_presets to its outcome' do
          expect(controller).to receive(:range_picker_default_presets).with(start_date, end_date).and_return(picker_preset_hash)
          get :settlement_transaction_account, start_date: start_date, end_date: end_date
          expect(assigns[:picker_presets]).to eq(picker_preset_hash)
        end
        it 'sets @daily_balance_key to the constant DAILY_BALANCE_KEY found in MemberBalanceService' do
          my_const = double('Some Constant')
          stub_const('MemberBalanceService::DAILY_BALANCE_KEY', my_const)
          get :settlement_transaction_account
          expect(assigns[:daily_balance_key]).to eq(my_const)
        end
      end
    end
  end

end