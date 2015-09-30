require 'rails_helper'

RSpec.describe ApplicationController, :type => :controller do
  it { should use_before_action(:check_password_change) }

  describe '`handle_exception` method' do
    let(:backtrace) {%w(some backtrace array returned by the error)}
    describe 'StandardError' do
      let(:error) {StandardError.new}
      before { allow(error).to receive(:backtrace).and_return(backtrace) }
      it 'captures all StandardErrors and displays the 500 error view' do
        expect(controller).to receive(:render).with('error/500', {:layout=>"error", :status=>500})
        controller.send(:handle_exception, error)
      end
      it 'rescues any exceptions raised when rendering the `error/500` view' do
        expect(controller).to receive(:render).with('error/500', {:layout=>"error", :status=>500}).and_raise(error)
        expect(controller).to receive(:render).with({:text=>error, :status=>500})
        controller.send(:handle_exception, error)
      end
    end

    ApplicationController::HTTP_404_ERRORS.each do |error_type|
      describe "#{error_type}" do
        let(:error) { error_type.new('some error') }
        before { allow(error).to receive(:backtrace).and_return(backtrace) }
        it "captures #{error_type}s and displays the 404 error view" do
          expect(controller).to receive(:render).with('error/404', {:layout=>"error", :status=>404})
          controller.send(:handle_exception, error)
        end
        it 'rescues any exceptions raised when rendering the `error/404` view' do
          allow(controller).to receive(:render).with('error/404', {:layout=>"error", :status=>404}).and_raise(error)
          expect(controller).to receive(:render).with({:text=>error, :status=>500})
          controller.send(:handle_exception, error)
        end
      end
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
    let(:user) { double('User', member_id: nil, accepted_terms?: nil, password_expired?: false) }
    let(:call_method) { controller.send(:after_sign_in_path_for, 'some resource') }
    before do
      allow(controller).to receive(:current_user).and_return(user)
    end

    describe 'user has not accepted terms' do
      it 'redirects to the `terms_path`' do
        expect(controller).to receive(:terms_path)
        call_method
      end
    end

    describe 'user has accepted terms' do
      before { allow(user).to receive(:accepted_terms?).and_return(true) }
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

    describe 'user has an expired password' do
      before do
        allow(user).to receive(:password_expired?).and_return(true)
      end
      it 'calls `password_expired?` on the current user' do
        expect(user).to receive(:password_expired?)
        call_method
      end
      it 'flags the users session as having an expired password' do
        call_method
        expect(session['password_expired']).to be(true)
      end
      it 'returns the `user_expired_password_path`' do
        expect(call_method).to eq(subject.user_expired_password_path)
      end
    end

    describe 'the password_expired session key' do
      describe 'with a value of false' do
        before do
          session['password_expired'] = false
        end
        it 'does not call `password_expired?`' do
          expect(user).to_not receive(:password_expired?)
          call_method
        end
        it 'does not return the `user_expired_password_path`' do
          expect(call_method).to_not eq(subject.user_expired_password_path)
        end
      end

      describe 'with a value of true' do
        before do
          session['password_expired'] = true
        end
        it 'does not call `password_expired?`' do
          expect(user).to_not receive(:password_expired?)
          call_method
        end
        it 'returns the `user_expired_password_path`' do
          expect(call_method).to eq(subject.user_expired_password_path)
        end
      end
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
    let(:member_id) { double('A Member ID') }
    it 'should return the `member_name` from the session' do
      session['member_name'] = member_name
      expect(controller.current_member_name).to eq(member_name)
    end
    it 'does not fecth the member details if `member_name` is in the session' do
      session['member_name'] = member_name
      expect_any_instance_of(MembersService).to_not receive(:member)
      controller.current_member_name
    end
    it 'should return nil if there is no `current_member_id`' do
      allow(subject).to receive(:current_member_id).and_return(nil)
      expect(controller.current_member_name).to be_nil
    end
    it 'fetches the member name if its absent' do
      allow(controller).to receive(:current_member_id).and_return(member_id)
      allow_any_instance_of(MembersService).to receive(:member).with(member_id).and_return({name: member_name})
      expect(controller.current_member_name).to eq(member_name)
    end
    it 'returns nil if the member name lookup fails' do
      allow_any_instance_of(MembersService).to receive(:member).and_return(nil)
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

  describe '`check_password_change` method' do
    let(:call_method) { subject.check_password_change }
    it 'redirects to the `user_expired_password_path` if the session is flagged as having an expired password' do
      session['password_expired'] = true
      expect(subject).to receive(:redirect_to).with(subject.user_expired_password_path)
      call_method
    end
    it 'does not redirect if the session is not flagged as having an expired password' do
      expect(subject).to_not receive(:redirect_to)
      call_method
    end
  end

  describe '`authenticate_user_with_authentication_flag!` method' do
    let(:call_method) { controller.authenticate_user_with_authentication_flag! }
    before do
      allow(controller).to receive(:authenticate_user_without_authentication_flag!)
    end
    it 'sets @authenticated_action to true if it has not already been set' do
      call_method
      expect(controller.instance_variable_get(:@authenticated_action)).to eq(true)
    end
    it 'does not set @authenticated_action if it has already been set' do
      controller.instance_variable_set(:@authenticated_action, false)
      call_method
      expect(controller.instance_variable_get(:@authenticated_action)).to eq(false)
    end
    it 'calls `authenticate_user_without_authentication_flag!`' do
      expect(controller).to receive(:authenticate_user_without_authentication_flag!)
      call_method
    end
  end
end