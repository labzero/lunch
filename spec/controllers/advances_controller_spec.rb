require 'rails_helper'

RSpec.describe AdvancesController, :type => :controller do
  login_user

  describe 'GET manage_advances' do
    let(:member_balances_service_instance) { double('MemberBalanceService') }
    let(:response_advance_hash) { double('MemberBalanceServiceHash') }
    let(:trade_date) { double('trade_date') }
    let(:funding_date) { double('funding_date') }
    let(:maturity_date) { double('maturity_date') }
    let(:advance_number) { double('advance_number') }
    let(:advance_type) { double('advance_type') }
    let(:status) { double('status') }
    let(:interest_rate) { double('interest_rate') }
    let(:current_par) { double('current_par') }
    let(:active_advances_response) {[{'trade_date' => trade_date, 'funding_date' => funding_date, 'maturity_date' => maturity_date, 'advance_number' => advance_number, 'advance_type' => advance_type, 'status' => status, 'interest_rate' => interest_rate, 'current_par' => current_par}]}

    before do
      allow(MemberBalanceService).to receive(:new).and_return(member_balances_service_instance)
      allow(member_balances_service_instance).to receive(:active_advances).and_return(response_advance_hash)
    end
    it_behaves_like 'a user required action', :get, :manage_advances
    it 'renders the manage_advances view' do
      allow(response_advance_hash).to receive(:collect)
      get :manage_advances
      expect(response.body).to render_template('manage_advances')
    end
    it 'should return active advances data' do
      allow(member_balances_service_instance).to receive(:active_advances).and_return(active_advances_response)
      get :manage_advances
      expect(assigns[:advances_data_table][:rows][0][:columns]).to eq([{:type=>:date, :value=>trade_date}, {:type=>:date, :value=>funding_date}, {:type=>:date, :value=>maturity_date}, {:value=>advance_number}, {:value=>advance_type}, {:value=>status}, {:type=>:index, :value=>interest_rate}, {:type=>:number, :value=>current_par}])
    end
    it 'should raise an error if active_advances is nil' do
      allow(member_balances_service_instance).to receive(:active_advances).and_return(nil)
      expect{get :manage_advances}.to raise_error(StandardError)
    end
  end

end