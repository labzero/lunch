require 'rails_helper'

RSpec.describe ReportsController, :type => :controller do
  describe 'GET index' do
    it 'should render the index view' do
      get :index
      expect(response.body).to render_template('index')
    end
  end

  describe 'GET capital_stock_activity' do
    let(:today) { Date.today }
    let(:start_date) { today - 1.month }
    let(:end_date) { today - 1.day }
    let(:member_balance_service_instance) { double('MemberBalanceServiceInstance') }
    let(:response_hash) { double('MemberBalanceHash') }
    before do
      expect(MemberBalanceService).to receive(:new).and_return(member_balance_service_instance)
    end
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

      it 'should build a presets array' do
        get :capital_stock_activity
        expect(assigns[:picker_presets].length).to be == 3
        assigns[:picker_presets].each do |preset|
          expect(preset).to be_kind_of(Hash)
          expect(preset[:start_date]).to be_kind_of(Date)
          expect(preset[:end_date]).to be_kind_of(Date)
        end
        expect(assigns[:picker_presets].last[:is_custom]).to eq(true)
        expect(assigns[:picker_presets][1][:is_default]).to eq(true)
      end
      it 'should flag the custom preset as the default if the start and end params fail to match any other preset' do
        get :capital_stock_activity, start_date: today - 1.day, end_date: today
        expect(assigns[:picker_presets].last[:is_default]).to eq(true)
      end
      it 'should flag the first preset as the detault if the start and end params match the current month to date' do
        get :capital_stock_activity, start_date: today.beginning_of_month, end_date: today
        expect(assigns[:picker_presets].first[:is_default]).to eq(true)
      end
      it 'should set @start_date to the start_date param' do
        get :capital_stock_activity, start_date: start_date, end_date: end_date
        expect(assigns[:start_date]).to eq(start_date)
      end
      it 'should set @end_date to the end_date param' do
        get :capital_stock_activity, start_date: start_date, end_date: end_date
        expect(assigns[:end_date]).to eq(end_date)
      end
    end
  end

  describe 'GET borrowing_capacity' do
    let(:member_balance_service_instance) { double('MemberBalanceServiceInstance') }
    let(:response_hash) { double('MemberBalanceHash') }
    before do
      expect(MemberBalanceService).to receive(:new).and_return(member_balance_service_instance)
    end
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
end