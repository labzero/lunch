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
    it 'should use one month ago as a start date and today as an end date if no params are passed' do
      expect(member_balance_service_instance).to receive(:capital_stock_activity).with(today - 1.month, today).and_return(response_hash)
      get :capital_stock_activity
    end
    it 'should raise an error if @capital_stock_activity is nil' do
      expect(member_balance_service_instance).to receive(:capital_stock_activity).and_return(nil)
      expect{get :capital_stock_activity}.to raise_error(StandardError)
    end

  end
end