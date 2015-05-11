require 'spec_helper'

RSpec.describe SettingsController, :type => :controller do
  login_user
  before do
    allow(subject).to receive(:current_user_roles)
  end
  
  describe 'GET index' do
    it_behaves_like 'a user required action', :get, :index
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
    it_behaves_like 'a user required action', :post, :save
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

  describe 'GET two_factor' do
    it_behaves_like 'a user required action', :get, :two_factor
    it 'should set @sidebar_options as an array of options with a label and a value' do
      get :two_factor
      expect(assigns[:sidebar_options]).to be_kind_of(Array)
      assigns[:sidebar_options].each do |option|
        expect(option.first).to be_kind_of(String)
        expect(option.last).to be_kind_of(String)
      end
    end
    it 'should render a template' do
      get :two_factor
      expect(response.body).to render_template('settings/two_factor')
    end
  end

  describe 'POST reset_pin' do
    let(:securid_pin) { Random.rand(9999).to_s.rjust(4, '0') }
    let(:securid_new_pin) { Random.rand(9999).to_s.rjust(4, '0') }
    let(:securid_token) { Random.rand(999999).to_s.rjust(6, '0') }
    let!(:securid_service) { SecurIDService.new('some_user', test_mode: :change_pin) }
    let(:make_request) { post :reset_pin, securid_token: securid_token, securid_pin: securid_pin, securid_new_pin: securid_new_pin }
    it_behaves_like 'a user required action', :post, :reset_pin
    context do
      before do
        allow(SecurIDService).to receive(:new).and_return(securid_service)
      end

      it 'should attempt to authenticate the users SecurID credentials' do
        expect(securid_service).to receive(:authenticate).with(securid_pin, securid_token)
        make_request
      end
      it 'should return a status of `invalid_pin` if the original pin is malformed' do
        post :reset_pin, securid_token: securid_token, securid_pin: 'abcd', securid_new_pin: securid_new_pin
        expect(JSON.parse(response.body)['status']).to eq('invalid_pin')
      end
      it 'should return a status of `invalid_token` if the token is malformed' do
        post :reset_pin, securid_token: '123ab3', securid_pin: securid_pin, securid_new_pin: securid_new_pin
        expect(JSON.parse(response.body)['status']).to eq('invalid_token')
      end
      it 'should return a status of `invalid_new_pin` if the new pin is malformed' do
        post :reset_pin, securid_token: securid_token, securid_pin: securid_pin, securid_new_pin: '123a'
        expect(JSON.parse(response.body)['status']).to eq('invalid_new_pin')
      end
      it 'should return a status of `success` if the pin change was completed' do
        make_request
        expect(JSON.parse(response.body)['status']).to eq('success')
      end
      it 'should attempt to change the users pin if the user needs a pin change' do
        expect(securid_service).to receive(:change_pin).with(securid_new_pin).and_return(true)
        make_request
      end
    end
    it 'should return a status of `denied` if the user was not authenticated' do
      allow(SecurIDService).to receive(:new).and_return(SecurIDService.new('some_user', test_mode: :denied))
      make_request
      expect(JSON.parse(response.body)['status']).to eq('denied')
    end
    it 'should return a status of `authenticated` if the user was authenticated but no pin change was needed' do
      allow(SecurIDService).to receive(:new).and_return(SecurIDService.new('some_user', test_mode: true))
      make_request
      expect(JSON.parse(response.body)['status']).to eq('authenticated')
    end
    it 'should return a status of `must_resynchronize` if the user needs to resynchronize their token first' do
      allow(SecurIDService).to receive(:new).and_return(SecurIDService.new('some_user', test_mode: :resynchronize))
      make_request
      expect(JSON.parse(response.body)['status']).to eq('must_resynchronize')
    end
  end

  describe 'POST resynchronize' do
    let(:securid_pin) { Random.rand(9999).to_s.rjust(4, '0') }
    let(:securid_token) { Random.rand(999999).to_s.rjust(6, '0') }
    let(:securid_next_token) { Random.rand(999999).to_s.rjust(6, '0') }
    let!(:securid_service) { SecurIDService.new('some_user', test_mode: :resynchronize) }
    let(:make_request) { post :resynchronize, securid_token: securid_token, securid_pin: securid_pin, securid_next_token: securid_next_token }
    it_behaves_like 'a user required action', :post, :resynchronize
    context do
      before do
        allow(SecurIDService).to receive(:new).and_return(securid_service)
      end

      it 'should attempt to authenticate the users SecurID credentials' do
        expect(securid_service).to receive(:authenticate).with(securid_pin, securid_token)
        make_request
      end
      it 'should return a status of `invalid_pin` if the original pin is malformed' do
        post :resynchronize, securid_token: securid_token, securid_pin: 'abcd', securid_next_token: securid_next_token
        expect(JSON.parse(response.body)['status']).to eq('invalid_pin')
      end
      it 'should return a status of `invalid_token` if the token is malformed' do
        post :resynchronize, securid_token: '123ab3', securid_pin: securid_pin, securid_next_token: securid_next_token
        expect(JSON.parse(response.body)['status']).to eq('invalid_token')
      end
      it 'should return a status of `invalid_next_token` if the next token is malformed' do
        post :resynchronize, securid_token: securid_token, securid_pin: securid_pin, securid_next_token: '123a12'
        expect(JSON.parse(response.body)['status']).to eq('invalid_next_token')
      end
      it 'should return a status of `success` if the resynchronization was completed' do
        make_request
        expect(JSON.parse(response.body)['status']).to eq('success')
      end
      it 'should attempt to resynchronize the token if the user needs resynchronization' do
        expect(securid_service).to receive(:resynchronize).with(securid_pin, securid_next_token).and_return(true)
        make_request
      end
    end
    it 'should return a status of `denied` if the user was not authenticated' do
      allow(SecurIDService).to receive(:new).and_return(SecurIDService.new('some_user', test_mode: :denied))
      make_request
      expect(JSON.parse(response.body)['status']).to eq('denied')
    end
    it 'should return a status of `authenticated` if the user was authenticated but no resynchronization was needed' do
      allow(SecurIDService).to receive(:new).and_return(SecurIDService.new('some_user', test_mode: true))
      make_request
      expect(JSON.parse(response.body)['status']).to eq('authenticated')
    end
    it 'should return a status of `must_change_pin` if the user needs to change their PIN first' do
      allow(SecurIDService).to receive(:new).and_return(SecurIDService.new('some_user', test_mode: :change_pin))
      make_request
      expect(JSON.parse(response.body)['status']).to eq('must_change_pin')
    end
  end
end