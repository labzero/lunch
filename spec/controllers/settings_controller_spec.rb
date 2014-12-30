require 'spec_helper'

RSpec.describe SettingsController, :type => :controller do
  describe "GET index" do
    it "should render the index view" do
      get :index
      expect(response.body).to render_template("index")
    end
  end

  describe "POST save" do
    let(:now) {Time.now}
    let(:cookie_key) {'some_key'}
    let(:cookie_value) {'some_value'}
    let(:cookie_data) { {'cookies' => {"#{cookie_key}" => cookie_value}} }
    it "should return a timestamp" do
      expect(Time).to receive(:now).at_least(:once).and_return(now)
      post :save
      hash = JSON.parse(response.body)
      expect(hash['timestamp']).to eq(now.strftime('%a %d %b %Y, %I:%M %p'))
    end
    it "should set cookies if cookie data is posted" do
      post :save, cookie_data
      expect(response.cookies[cookie_key]).to eq(cookie_value)
    end
    it "should not set cookies if no cookie data is posted" do
      post :save
      expect(response.cookies[cookie_key]).to be_nil
    end
  end
end