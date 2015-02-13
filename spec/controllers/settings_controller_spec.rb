require 'spec_helper'

RSpec.describe SettingsController, :type => :controller do
  login_user
  
  describe "GET index" do
    it "should render the index view" do
      get :index
      expect(response.body).to render_template('index')
    end
    it 'should set @sidebar_options as an array of options with a label and a value' do
      get :index
      expect(assigns[:sidebar_options]).to be_kind_of(Array)
      assigns[:sidebar_options].each do |option|
        expect(option.first).to be_kind_of(String)
        expect(option.last).to be_kind_of(String)
      end
    end
    it 'should set @email_options as an array of email categories with reports in front' do
      get :index
      expect(assigns[:email_options]).to be_kind_of(Array)
      expect(assigns[:email_options].first).to eq('reports')
      expect(assigns[:email_options][1..-1]).to eq(CorporateCommunication::VALID_CATEGORIES)
    end

  end

  describe 'POST save' do
    let(:now) {Time.now}
    let(:cookie_key) {'some_key'}
    let(:cookie_value) {'some_value'}
    let(:cookie_data) { {'cookies' => {cookie_key => cookie_value}} }
    it 'should return a timestamp' do
      expect(Time).to receive(:now).at_least(:once).and_return(now)
      post :save
      hash = JSON.parse(response.body)
      expect(hash['timestamp']).to eq(now.strftime('%a %d %b %Y, %I:%M %p'))
    end
    it 'should set cookies if cookie data is posted' do
      post :save, cookie_data
      expect(response.cookies[cookie_key]).to eq(cookie_value)
    end
    it 'should not set cookies if no cookie data is posted' do
      post :save
      expect(response.cookies[cookie_key]).to be_nil
    end
  end
end