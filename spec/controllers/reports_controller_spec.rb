require 'rails_helper'

RSpec.describe ReportsController, :type => :controller do
  describe "GET index" do
    it "should render the index view" do
      get :index
      expect(response.body).to render_template("index")
    end
  end

  describe "GET capital_stock_activity" do
    it "should render the capital_stock_activity view" do
      get :capital_stock_activity
      expect(response.body).to render_template("capital_stock_activity")
    end
  end
end