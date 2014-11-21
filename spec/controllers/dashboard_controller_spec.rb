require 'rails_helper'

RSpec.describe DashboardController, :type => :controller do
  describe "GET index" do
    it "should render the index view" do
      get :index
      expect(response.body).to render_template("index")
    end
    it "should assign @market_overview" do
      get :index
      expect(assigns[:market_overview]).to be_present
      expect(assigns[:market_overview][0]).to be_present
      expect(assigns[:market_overview][0][:name]).to be_present
      expect(assigns[:market_overview][0][:data]).to be_present
    end
    it "should assign @pledged_collateral" do
      get :index
      expect(assigns[:pledged_collateral]).to be_present
      expect(assigns[:pledged_collateral][:mortgages]).to be_present
      expect(assigns[:pledged_collateral][:mortgages][:absolute]).to be_present
      expect(assigns[:pledged_collateral][:mortgages][:percentage]).to be_present
      expect(assigns[:pledged_collateral][:agency]).to be_present
      expect(assigns[:pledged_collateral][:agency][:absolute]).to be_present
      expect(assigns[:pledged_collateral][:agency][:percentage]).to be_present
      expect(assigns[:pledged_collateral][:aaa]).to be_present
      expect(assigns[:pledged_collateral][:aaa][:absolute]).to be_present
      expect(assigns[:pledged_collateral][:aaa][:percentage]).to be_present
      expect(assigns[:pledged_collateral][:aa]).to be_present
      expect(assigns[:pledged_collateral][:aa][:absolute]).to be_present
      expect(assigns[:pledged_collateral][:aa][:percentage]).to be_present
    end
    it "should assign @total_securities" do
      get :index
      expect(assigns[:total_securities]).to be_present
      expect(assigns[:total_securities][:pledged_securities]).to be_present
      expect(assigns[:total_securities][:pledged_securities][:absolute]).to be_present
      expect(assigns[:total_securities][:pledged_securities][:percentage]).to be_present
      expect(assigns[:total_securities][:safekept_securities]).to be_present
      expect(assigns[:total_securities][:safekept_securities][:absolute]).to be_present
      expect(assigns[:total_securities][:safekept_securities][:percentage]).to be_present
    end
    it "should assign @effective_borrowing_capacity" do
      get :index
      expect(assigns[:effective_borrowing_capacity]).to be_present
      expect(assigns[:effective_borrowing_capacity][:used_capacity]).to be_present
      expect(assigns[:effective_borrowing_capacity][:used_capacity][:absolute]).to be_present
      expect(assigns[:effective_borrowing_capacity][:used_capacity][:percentage]).to be_present
      expect(assigns[:effective_borrowing_capacity][:unused_capacity]).to be_present
      expect(assigns[:effective_borrowing_capacity][:unused_capacity][:absolute]).to be_present
      expect(assigns[:effective_borrowing_capacity][:unused_capacity][:percentage]).to be_present
      expect(assigns[:effective_borrowing_capacity][:threshold_capacity]).to be_present
    end
  end

  describe "GET quick_advance_rates" do
    let(:json_response) { {some: "json"}.to_json }
    let(:RatesService) {class_double(RatesService)}
    let(:rate_service_instance) {double("rate service instance", quick_advance_rates: nil)}
    it "calls the RatesService object with quick_advance_rates and returns json" do
      expect(RatesService).to receive(:new).and_return(rate_service_instance)
      expect(rate_service_instance).to receive(:quick_advance_rates).and_return(json_response)
      get :quick_advance_rates
      expect(response.body).to eq(json_response)
    end

  end
end