require 'rails_helper'

RSpec.describe ApplicationController, :type => :controller do
  it { should use_before_action(:check_password_change) }
  it { should use_before_action(:save_render_time) }
  it { should use_before_action(:check_terms) }

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

    describe 'PageRestricted' do
      let(:error) {Pundit::NotAuthorizedError.new}
      before { allow(error).to receive(:backtrace).and_return(backtrace) }
      it 'captures all PageRestricted and displays the page-restricted error view' do
        expect(controller).to receive(:render).with('error/403', {:layout=>"error", :status=>403})
        controller.send(:handle_exception, error)
      end
      it 'rescues any exceptions raised when rendering the `error/403` view' do
        expect(controller).to receive(:render).with('error/403', {:layout=>"error", :status=>403}).and_raise(error)
        expect(controller).to receive(:render).with({:text=>error, :status=>500})
        controller.send(:handle_exception, error)
      end
    end
  end

  describe '`after_sign_out_path_for(resource)` method' do
    it 'redirects to the logged_out path' do
      expect(controller).to receive(:logged_out_path)
      controller.send(:after_sign_out_path_for, 'some resource')
    end
    it 'redirects to the logged_out path when passed `nil`' do
      expect(controller).to receive(:logged_out_path)
      controller.send(:after_sign_out_path_for, nil)
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

  describe 'save_render_time' do
    let (:now) { double('Time.zone.now') }
    before{ allow(Time).to receive_message_chain(:zone, :now).and_return(now) }
    it 'should set @render_time' do
      controller.save_render_time
      expect(controller.instance_variable_get(:@render_time)).to eq(now)
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

  describe '`session_elevate!` method' do
    it 'sets `securid_authenticated` to true' do
      controller.session_elevate!
      expect(session['securid_authenticated']).to be(true)
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
  
  describe '`check_terms` method' do
    let(:call_method) { subject.check_terms }
    let(:user) { double('User', accepted_terms?: nil) }
    before do
      allow(controller).to receive(:current_user).and_return(user)
    end
    it 'redirects to the `terms_path` if the terms have not been accepted' do
      allow(user).to receive(:accepted_terms?).and_return(false)
      expect(subject).to receive(:redirect_to).with(terms_path)
      call_method
    end
    it 'does not redirect to the `terms_path` if the terms have already been accepted' do
      allow(user).to receive(:accepted_terms?).and_return(true)
      expect(subject).to_not receive(:redirect_to)
      call_method
    end
    it 'returns nil if there is no current_user' do
      allow(controller).to receive(:current_user).and_return(nil)
      expect(call_method).to be_nil
    end
    it 'returns nil if the terms have been accepted' do
      allow(user).to receive(:accepted_terms?).and_return(true)
      expect(call_method).to be_nil      
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

  describe '`new_announcements_count`' do
    let(:current_user) { double('User', new_announcements_count: nil) }
    let(:count) { double('count', :> => true) }
    let(:call_method) { subject.new_announcements_count }
    describe 'when there is no `current_user`' do
      before { allow(subject).to receive(:current_user).and_return(nil) }
      it 'returns 0' do
        expect(call_method).to eq(0)
      end
      it 'does not set the session value for `new_announcements_count`' do
        call_method
        expect(session).not_to have_key(:new_announcements_count)
      end
    end
    describe 'when there is a `current_user`' do
      before { allow(subject).to receive(:current_user).and_return(current_user) }
      describe 'when there is a value for the session key `new_announcements_count`' do
        before { session['new_announcements_count'] = count }
        it 'returns the value' do
          expect(call_method).to eq(count)
        end
        it 'does not call `new_announcements_count` on the user' do
          expect(current_user).not_to receive(:new_announcements_count)
          call_method
        end
      end
      describe 'when there is not a value for the session key `new_announcements_count`' do
        before { allow(current_user).to receive(:new_announcements_count).and_return(count) }
        it 'calls `new_announcements_count` on the user' do
          expect(current_user).to receive(:new_announcements_count)
          call_method
        end
        it 'returns the result of calling `new_announcements_count` on the current user' do
          expect(call_method).to eq(count)
        end
        it 'sets the session value for `new_announcements_count` to the one `new_announcements_count` of the current user' do
          call_method
          expect(session['new_announcements_count']).to eq(count)
        end
      end
    end
  end

  describe '`reset_new_announcements_count`' do
    let(:call_method) { subject.reset_new_announcements_count }
    it 'removes `new_announcements_count` from the session hash' do
      session['new_announcements_count'] = double('count')
      call_method
      expect(session).not_to have_key('new_announcements_count')
    end
  end

  describe '`skip_timeout_reset` private method' do
    let(:call_method) { controller.send(:skip_timeout_reset, &block) }
    let(:rack_env) { double('A Rack ENV', :[]= => nil) }
    let(:request) { double('A Request') }
    let(:dummy_obj) { double('A Dummy Obj') }
    let(:block) { ->() { dummy_obj.dummy_call } }

    before do
      allow(controller).to receive(:request).and_return(request)
      allow(request).to receive(:env).and_return(rack_env)
    end

    it 'should flag the request with `devise.skip_trackable` before yielding' do
      expect(rack_env).to receive(:[]=).with('devise.skip_trackable', true).ordered
      expect(dummy_obj).to receive(:dummy_call).ordered
      call_method
    end
    it 'should clear the `devise.skip_trackable` flag on the request after yielding' do
      expect(dummy_obj).to receive(:dummy_call).ordered
      expect(rack_env).to receive(:[]=).with('devise.skip_trackable', false).ordered
      call_method
    end
  end

  describe '`handle_bad_csrf` private method' do
    let(:call_method) { controller.send(:handle_bad_csrf) }

    before do
      allow(controller).to receive(:redirect_to)
    end

    it 'resets the session' do
      expect(controller).to receive(:reset_session)
      call_method
    end

    it 'redirects to the logged out page' do
      expect(controller).to receive(:redirect_to).with(controller.logged_out_path)
      call_method
    end
  end

  describe 'exception handling' do
    login_user
    controller do
      def index; end
    end

    let(:make_request) { get :index }

    describe '`ActionController::InvalidAuthenticityToken` exception' do
      before do
        allow(controller).to receive(:index).and_raise(ActionController::InvalidAuthenticityToken)
      end

      it 'calls `handle_bad_csrf`' do
        expect(controller).to receive(:handle_bad_csrf)
        make_request
      end
    end

    describe 'other exceptions' do
      let(:exception) { Exception.new }
      before do
        allow(controller).to receive(:index).and_raise(exception)
      end

      it 'calls `handle_exception` if the app is running in production' do
        allow(Rails.env).to receive(:production?).and_return(true)
        expect(controller).to receive(:handle_exception).with(exception)
        make_request
      end

      it 'reraises the exception if the app is not in production' do
        allow(Rails.env).to receive(:production?).and_return(false)
        expect{make_request}.to raise_error(exception)
      end
    end
  end
end