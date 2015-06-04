require 'spec_helper'

RSpec.describe SettingsController, :type => :controller do
  login_user
  deny_policy(:access_manager, :show?)
  
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

  describe 'GET users' do
    allow_policy(:access_manager, :show?)
    let(:make_request) { get :users }
    let(:users) { [build(:user), build(:user), build(:user)] }
    let(:roles) { double('Roles') }
    let(:actions) { double('Actions') }
    before do
      allow_any_instance_of(MembersService).to receive(:users).and_return(users)
      allow(users[0]).to receive(:display_name).and_return('foo')
      allow(users[1]).to receive(:display_name).and_return('bar')
      allow(users[2]).to receive(:display_name).and_return('woo')
      allow(users[0]).to receive(:id).and_return(1)
      allow(users[1]).to receive(:id).and_return(2)
      allow(users[2]).to receive(:id).and_return(3)
      allow(subject).to receive(:current_user).and_return(users[2])
      allow(subject).to receive(:roles_for_user).and_return(roles)
      allow(subject).to receive(:actions_for_user).and_return(actions)
    end
    it_behaves_like 'an authorization required method', :get, :users, :access_manager, :show?
    it 'calls MembersService to fetch the list of users' do
      expect_any_instance_of(MembersService).to receive(:users).with(subject.current_member_id)
      make_request
    end
    it 'handles MembersService returning nil' do
      allow_any_instance_of(MembersService).to receive(:users).with(subject.current_member_id).and_return(nil)
      make_request
      expect(response).to have_http_status(:success)
    end
    it 'sorts the users by `display_name`' do
      make_request
      expect(assigns[:users]).to eq([users[1], users[0], users[2]])
    end
    it 'sets `@users` to the list of users' do
      make_request
      expect(assigns[:users]).to match_array(users)
    end
    it 'sets `@roles` to a hash of human readable roles, keyed by user `id`' do
      make_request
      expect(assigns[:roles]).to eq({
        users[0].id => roles,
        users[1].id => roles,
        users[2].id => roles
      })
    end
    it 'sets `@actions` to a hash of allowed actions. keyed by user `id`' do
      make_request
      expect(assigns[:actions]).to eq({
        users[0].id => actions,
        users[1].id => actions,
        users[2].id => actions
      })
    end
  end

  describe 'GET edit_user' do
    allow_policy(:access_manager, :edit?)
    let(:user_id) { rand(10000..99999) }
    let(:make_request) { get :edit_user, id: user_id }
    let(:email) { SecureRandom.hex }
    let(:user) { double('User', id: user_id, email: email, :email_confirmation= => nil) }
    before do
      allow(User).to receive(:find).and_call_original
      allow(User).to receive(:find).with(user_id.to_s).and_return(user)
    end
    it_behaves_like 'an authorization required method', :get, :edit_user, :access_manager, :edit?, id: rand(10000..99999)
    it 'assigns the user identified by `params[:id]` to @user' do
      make_request
      expect(assigns[:user]).to be(user)
    end
    it 'returns a 404 if the user was not found' do
      expect{get :edit_user, id: 'foo'}.to raise_error(ActiveRecord::RecordNotFound)
    end
    it 'assigns the `email` to the `email_confirmation`' do
      expect(user).to receive(:email_confirmation=).with(email)
      make_request
    end
    it "renders the `edit_user` overlay" do
      expect(subject).to receive(:render_to_string).with(layout: false)
      make_request
    end
    it 'returns a JSON response' do
      make_request
      json = JSON.parse(response.body)
      expect(json).to have_key('html')
    end
  end

  describe 'POST update_user' do
    allow_policy(:access_manager, :edit?)
    let(:user_id) { rand(10000..99999) }
    let(:email) { SecureRandom.hex }
    let(:given_name) { SecureRandom.hex }
    let(:surname) { SecureRandom.hex }
    let(:attributes) { {email: email, given_name: given_name, surname: surname} }
    let(:make_request) { post :update_user, id: user_id, user: attributes }
    let(:user) { double('User', class: User, id: user_id, errors: double('Errors', full_messages: [])) }
    let(:roles) { double('Roles') }
    let(:actions) { double('Actions') }
    before do
      allow(subject).to receive(:roles_for_user).and_return(roles)
      allow(subject).to receive(:actions_for_user).and_return(actions)
      allow(subject).to receive(:render_to_string)
      allow(User).to receive(:find).and_call_original
      allow(User).to receive(:find).with(user_id.to_s).and_return(user)
      allow(user).to receive(:update_attributes!)
    end
    it { should permit(:email, :given_name, :surname, :email_confirmation).for(:update_user, verb: :post, params: {id: user_id}) }
    it_behaves_like 'an authorization required method', :post, :update_user, :access_manager, :edit?, id: rand(10000..99999)
    it 'assigns the user identified by `params[:id]` to @user' do
      make_request
      expect(assigns[:user]).to be(user)
    end
    it 'returns a 404 if the user was not found' do
      expect{post :update_user, id: 'foo'}.to raise_error(ActiveRecord::RecordNotFound)
    end
    it 'returns a 400 if the `user` parameter is missing' do
      expect{post :update_user, id: user_id}.to raise_error(ActionController::ParameterMissing)
    end
    it 'updates the user with the passed params' do
      expect(user).to receive(:update_attributes!).with(attributes)
      make_request
    end
    it 'returns a 422 if validation fails' do
      allow(user).to receive(:update_attributes!).and_raise(ActiveRecord::RecordInvalid.new(user))
      expect{make_request}.to raise_error(ActiveRecord::RecordInvalid)
    end
    it 'renders the `update_user` overlay' do
      expect(subject).to receive(:render_to_string).with(layout: false)
      make_request
    end
    it 'renders the `user_row`' do
      expect(subject).to receive(:render_to_string).with(partial: 'user_row', locals: {
        user: user,
        roles: roles,
        actions: actions
      })
      make_request
    end
    it 'returns a JSON response' do
      make_request
      json = JSON.parse(response.body)
      expect(json).to have_key('html')
      expect(json).to have_key('row_html')
    end
  end

  {unlock: :unlock!, lock: :lock!}.each do |route, method|
    describe "POST #{route}" do
      allow_policy(:access_manager, :edit?)
      let(:user_id) { rand(10000..99999) }
      let(:make_request) { post route, id: user_id }
      let(:roles) { double('Roles') }
      let(:actions) { double('Actions') }
      let(:user) { double('User', id: user_id, method => true) }
      before do
        allow(subject).to receive(:roles_for_user).and_return(roles)
        allow(subject).to receive(:actions_for_user).and_return(actions)
        allow(subject).to receive(:render_to_string)
        allow(subject).to receive(:current_user).and_return(double('Current User', id: rand(1..9999)))
        allow(User).to receive(:find).and_call_original
        allow(User).to receive(:find).with(user_id.to_s).and_return(user)
      end
      it_behaves_like 'an authorization required method', :post, route, :access_manager, :edit?, id: rand(10000..99999)
      it 'assigns the user identified by `params[:id]` to @user' do
        make_request
        expect(assigns[:user]).to be(user)
      end
      it "calls `#{method}` on the user" do
        expect(user).to receive(method)
        make_request
      end
      it "returns 500 if the user being #{route}ed is the current user" do
        allow(subject).to receive(:current_user).and_return(user)
        make_request
        expect(response).to have_http_status(:error)
      end
      it "returns 500 if the user was not #{route}ed successfully" do
        allow(user).to receive(method).and_return(false)
        make_request
        expect(response).to have_http_status(:error)
      end
      it 'returns a 404 if the user was not found' do
        expect{post route, id: 'foo'}.to raise_error(ActiveRecord::RecordNotFound)
      end
      it "renders the `#{route}` overlay" do
        expect(subject).to receive(:render_to_string).with(layout: false)
        make_request
      end
      it 'renders the `user_row`' do
        expect(subject).to receive(:render_to_string).with(partial: 'user_row', locals: {
          user: user,
          roles: roles,
          actions: actions
        })
        make_request
      end
      it 'returns a JSON response' do
        make_request
        json = JSON.parse(response.body)
        expect(json).to have_key('html')
        expect(json).to have_key('row_html')
      end
    end
  end

  describe '`roles_for_user` private method' do
    let(:user) { double('User', roles: ['foo', 'bar']) }
    let(:call_method) { subject.send(:roles_for_user, user) }
    it 'returns the default role if none of the roles match a known role' do
      expect(call_method).to eq([I18n.t('user_roles.user.title')])
    end
    it 'returns the Access Manager role if the user is an Access Manager' do
      allow(user).to receive(:roles).and_return([User::Roles::ACCESS_MANAGER, 'bar'])
      expect(call_method).to eq([I18n.t('settings.account.roles.access_manager')])
    end
    it 'returns the Authorized Signer role if the user is an Authorized Signer' do
      allow(user).to receive(:roles).and_return([User::Roles::AUTHORIZED_SIGNER, 'woot'])
      expect(call_method).to eq([I18n.t('settings.account.roles.authorized_signer')])
    end
    it 'returns multiple roles if multiple roles are matched' do
      allow(user).to receive(:roles).and_return([User::Roles::AUTHORIZED_SIGNER, User::Roles::ACCESS_MANAGER])
      expect(call_method).to eq([I18n.t('settings.account.roles.authorized_signer'), I18n.t('settings.account.roles.access_manager')])
    end
  end

  describe '`actions_for_user` private method' do
    let(:locked_status) { double('Locked Status') }
    let(:user) { double('User', id: rand(10000..99999), locked?: locked_status) }
    let(:call_method) { subject.send(:actions_for_user, user) }
    before do
      allow(subject).to receive(:current_user).and_return(double('Current User', id: rand(1..9999)))
    end
    it 'returns a hash of actions' do
      expect(call_method).to include(:locked, :locked_disabled, :reset_disabled)
    end
    it 'returns the user locked status in the key `locked`' do
      expect(call_method[:locked]).to be(locked_status)
    end
    it 'returns false for `locked_disabled` if the current user is not the passed user' do
      expect(call_method[:locked_disabled]).to be(false)
    end
    it 'returns false for `reset_disabled` if the current user is not the passed user' do
      expect(call_method[:reset_disabled]).to be(false)
    end
    describe 'if the current user is the passed user' do
      before do
        allow(subject).to receive(:current_user).and_return(user)
      end
      it 'returns true for `locked_disabled`' do
        expect(call_method[:locked_disabled]).to be(true)
      end
      it 'returns true for `reset_disabled`' do
        expect(call_method[:reset_disabled]).to be(true)
      end
    end
  end
end