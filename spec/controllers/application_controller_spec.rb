require 'rails_helper'

RSpec.describe ApplicationController, :type => :controller do
  let(:error) {StandardError.new}

  describe '`handle_exception` method' do
    let(:backtrace) {%w(some backtrace array returned by the error)}
    it 'captures all StandardErrors and displays the 500 error view' do
      expect(error).to receive(:backtrace).and_return(backtrace)
      expect(controller).to receive(:render).with('error/500', {:layout=>"error", :status=>500})
      controller.send(:handle_exception, error)
    end
    it 'rescues any exceptions raised when rendering the `error/500` view' do
      expect(error).to receive(:backtrace).at_least(1).and_return(backtrace)
      expect(controller).to receive(:render).with('error/500', {:layout=>"error", :status=>500}).and_raise(error)
      expect(controller).to receive(:render).with({:text=>error, :status=>500})
      controller.send(:handle_exception, error)
    end
  end

  describe '`after_sign_out_path_for(resource)` method' do
    it 'redirects to the root path' do
      expect(controller).to receive(:root_path)
      controller.send(:after_sign_out_path_for, 'some resource')
    end
  end

  describe '`after_sign_in_path_for(resource)` method' do
    let(:member_id) { rand(9999) }
    let(:user) { double('User', member_id: nil) }
    let(:call_method) { controller.send(:after_sign_in_path_for, 'some resource') }
    before do
      allow(controller).to receive(:current_user).and_return(user)
    end
    describe 'with a member_id in the session' do
      before do
        session['member_id'] = 750
      end
      it 'redirects to the stored location for the resource if it exists' do
        expect(controller).to receive(:stored_location_for).with('some resource')
        call_method
      end
      it 'redirects to the dashboard_path if there is no stored location for the resource' do
        expect(controller).to receive(:dashboard_path)
        expect(controller).to receive(:stored_location_for).with('some resource').and_return(nil)
        call_method
      end
    end
    it 'sets `member_id` in the session if current_user.member_id returns a member_id' do
      allow(user).to receive(:member_id).and_return(member_id)
      call_method
      expect(session['member_id']).to eq(member_id)
    end
    it 'redirects to Members#select_member if the user is an intranet user' do
      allow(user).to receive(:ldap_domain).and_return('intranet')
      expect(controller).to receive(:members_select_member_path)
      call_method
    end
    it 'raises an error if there is no member_id in the session and the current user is not an intranet user' do
      allow(user).to receive(:ldap_domain).and_return('extranet')
      expect{call_method}.to raise_error
    end
  end

  describe '`current_member_id` method' do
    let(:member_id) { double('A Member ID') }
    it 'should return the `member_id` from the session' do
      session['member_id'] = member_id
      expect(controller.current_member_id).to eq(member_id)
    end
    it 'should return nil if there is no `member_id`' do
      expect(controller.current_member_id).to be_nil
    end
  end

  describe '`session_elevated?` method' do
    it 'should return true if the session has a truthy `securid_authenticated` value' do
      session['securid_authenticated'] = 'foo'
      expect(controller.session_elevated?).to be(true)
      session['securid_authenticated'] = true
      expect(controller.session_elevated?).to be(true)
    end
    it 'should return false if the session has a falsey `securid_authenticated` value' do
      expect(controller.session_elevated?).to be(false)
      session['securid_authenticated'] = nil
      expect(controller.session_elevated?).to be(false)
      session['securid_authenticated'] = false
      expect(controller.session_elevated?).to be(false)
    end
  end

  describe '`current_member_name` method' do
    let(:member_name) { double('A Member Name') }
    it 'should return the `member_name` from the session' do
      session['member_name'] = member_name
      expect(controller.current_member_name).to eq(member_name)
    end
    it 'should return nil if there is no `member_name`' do
      expect(controller.current_member_name).to be_nil
    end
  end

  describe '`current_user_roles` method' do
    let(:user) { double('user', :roles => nil, :roles= => nil)}
    let(:session_roles) { [double('session roles')] }
    let(:user_roles) { [double('user_roles')] }
    before do
      allow(controller).to receive(:current_user).and_return(user)
    end
    it 'returns an empty array if there is no current_user' do
      allow(controller).to receive(:current_user).and_return(nil)
      expect(controller.send(:current_user_roles)).to eq([])
    end
    it 'passes the request object to `current_user.roles` ' do
      expect(user).to receive(:roles).with(an_instance_of(ActionController::TestRequest)).and_return(user_roles)
      controller.send(:current_user_roles)
    end
    it 'sets `session[:roles]` to the result of current_user.roles if that session attribute does not already exist' do
      allow(user).to receive(:roles).and_return(user_roles)
      controller.send(:current_user_roles)
      expect(session['roles']).to eq(user_roles)
    end
    it 'sets `current_user.roles` to the array of `session[\'roles\']`' do
      allow(controller.session).to receive(:[]).with('roles').and_return(session_roles)
      expect(user).to receive(:roles=).with(session_roles)
      controller.send(:current_user_roles)
    end
    it 'does not call `current_user.roles` if `session[:roles]` already exists' do
      session['roles'] = session_roles
      expect(user).not_to receive(:roles)
      controller.send(:current_user_roles)
    end
  end
end