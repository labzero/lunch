require 'rails_helper'

RSpec.describe ApplicationController, :type => :controller do
  it { should use_before_action(:check_password_change) }
  it { should use_before_action(:save_render_time) }
  it { should use_before_action(:check_terms) }
  it { should use_before_action(:set_default_format) }

  describe '`handle_exception` method' do
    let(:backtrace) {%w(some backtrace array returned by the error)}
    describe 'StandardError' do
      let(:error) {StandardError.new}
      let(:call_method) { controller.send(:handle_exception, error) }
      before { allow(error).to receive(:backtrace).and_return(backtrace) }
      it 'captures all StandardErrors and displays the 500 error view' do
        expect(controller).to receive(:render).with('error/500', {:layout=>"error", :status=>500})
        call_method
      end
      describe 'rescuing exceptions raised when rendering the `error/500` view' do
        before do
          allow(controller).to receive(:render).with('error/500', {:layout=>"error", :status=>500}).and_raise(error)
        end

        it 'renders the error as plain text if the request is considered local' do
          allow(Rails.configuration).to receive(:consider_all_requests_local).and_return(true)
          expect(controller).to receive(:render).with({:text=>error, :status=>500})
          call_method
        end
        it 'does not render the error if the request is consider remote' do
          allow(Rails.configuration).to receive(:consider_all_requests_local).and_return(false)
          expect(controller).to receive(:render).with({:text=>'Something went wrong!', :status=>500})
          call_method
        end
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
    let(:user) { double('User', member_id: nil, accepted_terms?: nil, password_expired?: false, intranet_user?: true) }
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
          session[described_class::SessionKeys::MEMBER_ID] = 750
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
      it 'sets `SessionKeys::MEMBER_ID` in the session if current_user.member_id returns a member_id' do
        allow(user).to receive(:member_id).and_return(member_id)
        call_method
        expect(session[described_class::SessionKeys::MEMBER_ID]).to eq(member_id)
      end
      it 'redirects to Members#select_member if the user is an intranet user' do
        allow(user).to receive(:intranet_user?).and_return(true)
        expect(controller).to receive(:members_select_member_path)
        call_method
      end
      it 'raises an error if there is no member_id in the session and the current user is not an intranet user' do
        allow(user).to receive(:intranet_user?).and_return(false)
        expect{call_method}.to raise_error(/Sign in error/)
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
        expect(session[described_class::SessionKeys::PASSWORD_EXPIRED]).to be(true)
      end
      it 'returns the `user_expired_password_path`' do
        expect(call_method).to eq(subject.user_expired_password_path)
      end
    end

    describe 'the password_expired session key' do
      describe 'with a value of false' do
        before do
          session[described_class::SessionKeys::PASSWORD_EXPIRED] = false
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
          session[described_class::SessionKeys::PASSWORD_EXPIRED] = true
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
    it 'should return the `SessionKeys::MEMBER_ID` from the session' do
      session[described_class::SessionKeys::MEMBER_ID] = member_id
      expect(controller.current_member_id).to eq(member_id)
    end
    it 'should return nil if there is no `SessionKeys::MEMBER_ID`' do
      expect(controller.current_member_id).to be_nil
    end
  end

  describe '`session_elevated?` method' do
    it 'should return true if the session has a truthy `SessionKeys::SECURID_AUTHENTICATED` value' do
      session[described_class::SessionKeys::SECURID_AUTHENTICATED] = 'foo'
      expect(controller.session_elevated?).to be(true)
      session[described_class::SessionKeys::SECURID_AUTHENTICATED] = true
      expect(controller.session_elevated?).to be(true)
    end
    it 'should return false if the session has a falsey `SessionKeys::SECURID_AUTHENTICATED` value' do
      expect(controller.session_elevated?).to be(false)
      session[described_class::SessionKeys::SECURID_AUTHENTICATED] = nil
      expect(controller.session_elevated?).to be(false)
      session[described_class::SessionKeys::SECURID_AUTHENTICATED] = false
      expect(controller.session_elevated?).to be(false)
    end
  end

  describe '`session_elevate!` method' do
    it 'sets `SessionKeys::SECURID_AUTHENTICATED` to true' do
      controller.session_elevate!
      expect(session[described_class::SessionKeys::SECURID_AUTHENTICATED]).to be(true)
    end
  end

  describe '`securid_perform_check` method' do
    let(:pin) { rand(0..9999).to_s.rjust(4, '0') }
    let(:token) { rand(0..999999).to_s.rjust(6, '0') }
    let(:securid_service) { SecurIDService.new('a user', test_mode: true) }
    let(:call_method) { subject.securid_perform_check(pin, token) }

    before do
      allow(subject).to receive(:current_user).and_return(instance_double(User, username: SecureRandom.hex))
      allow(SecurIDService).to receive(:new).and_return(securid_service)
    end

    describe 'with unelevated session' do
      before do
        allow(subject).to receive(:session_elevated?).and_return(false)
      end
      it 'returns a securid status of `invalid_pin` if the pin is malformed' do
        expect(subject.securid_perform_check('foo', token)).to eq(:invalid_pin)
      end
      it 'returns a securid status of `invalid_token` if the token is malformed' do
        expect(subject.securid_perform_check(pin, 'foo')).to eq(:invalid_token)
      end
      it 'authenticates the user via RSA SecurID if the session is not elevated' do
        expect(securid_service).to receive(:authenticate).with(pin, token)
        call_method
      end
      it 'elevates the session if RSA SecurID authentication succedes' do
        expect(securid_service).to receive(:authenticate).with(pin, token).ordered
        expect(securid_service).to receive(:authenticated?).ordered.and_return(true)
        expect(subject).to receive(:session_elevate!).ordered
        call_method
      end
      it 'does not elevate the session if RSA SecurID authentication fails' do
        expect(securid_service).to receive(:authenticate).with(pin, token).ordered
        expect(securid_service).to receive(:authenticated?).ordered.and_return(false)
        expect(subject).to_not receive(:session_elevate!).ordered
        call_method
      end
      it 'returns a securid status of `authenticated` on success' do
        expect(call_method).to eq(:authenticated)
      end
      it 'defaults the `token` to `params[:securid_token]` if not provided' do
        subject.params[:securid_token] = token
        expect(securid_service).to receive(:authenticate).with(anything, token)
        subject.securid_perform_check
      end
      it 'defaults the `pin` to `params[:securid_pin]` if not provided' do
        subject.params[:securid_pin] = pin
        expect(securid_service).to receive(:authenticate).with(pin, anything)
        subject.securid_perform_check
      end
    end

    describe 'with an elevated session' do
      before do
        allow(subject).to receive(:session_elevated?).and_return(true)
      end
      it 'returns a securid status of `authenticated`' do
        expect(call_method).to eq(:authenticated)
      end
      it 'does not hit the RSA SecurID service' do
        expect(securid_service).to_not receive(:authenticate)
        call_method
      end
    end
  end

  describe '`current_member_name` method' do
    let(:member_name) { double('A Member Name') }
    let(:member_id) { double('A Member ID') }
    it 'should return the `SessionKeys::MEMBER_NAME` from the session' do
      session[described_class::SessionKeys::MEMBER_NAME] = member_name
      expect(controller.current_member_name).to eq(member_name)
    end
    it 'does not fecth the member details if `SessionKeys::MEMBER_NAME` is in the session' do
      session[described_class::SessionKeys::MEMBER_NAME] = member_name
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

  describe '`current_user` method' do
    let(:cache_key) { double('A Cache Key') }
    let(:call_method) { subject.current_user }
    login_user

    it 'returns the logged in user' do
      expect(call_method).to be(warden_user)
    end
    it 'returns nil if there is no logged in user' do
      sign_out :user
      expect(call_method).to be(nil)
    end
    it 'sets the users cache_key to the value stored in the session' do
      session[described_class::SessionKeys::CACHE_KEY] = cache_key
      expect(warden_user).to receive(:cache_key=).with(cache_key)
      call_method
    end
    it 'sets the users cache_key to a random value if no value is in the session' do
      allow(SecureRandom).to receive(:hex).and_return(cache_key)
      call_method
      expect(warden_user.cache_key).to be(cache_key)
    end
    it 'sets the session cache_key to the users cache_key if unset in the session' do
      allow(warden_user).to receive(:cache_key).and_return(cache_key)
      call_method
      expect(session[described_class::SessionKeys::CACHE_KEY]).to be(cache_key)
    end
    it 'does not set the session cache_key if its already set' do
      session[described_class::SessionKeys::CACHE_KEY] = cache_key
      alternate_key = double('Another Cache Key')
      allow(warden_user).to receive(:cache_key).and_return(alternate_key)
      call_method
      expect(session[described_class::SessionKeys::CACHE_KEY]).to be(cache_key)
    end
  end

  describe '`check_password_change` method' do
    let(:call_method) { subject.check_password_change }
    it 'redirects to the `user_expired_password_path` if the session is flagged as having an expired password' do
      session[described_class::SessionKeys::PASSWORD_EXPIRED] = true
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
      describe 'when there is a value for the session key `SessionKeys::NEW_ANNOUNCEMENT_COUNT`' do
        before { session[described_class::SessionKeys::NEW_ANNOUNCEMENT_COUNT] = count }
        it 'returns the value' do
          expect(call_method).to eq(count)
        end
        it 'does not call `new_announcements_count` on the user' do
          expect(current_user).not_to receive(:new_announcements_count)
          call_method
        end
      end
      describe 'when there is not a value for the session key `SessionKeys::NEW_ANNOUNCEMENT_COUNT`' do
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
          expect(session[described_class::SessionKeys::NEW_ANNOUNCEMENT_COUNT]).to eq(count)
        end
      end
    end
  end

  describe '`reset_new_announcements_count`' do
    let(:call_method) { subject.reset_new_announcements_count }
    it 'removes `SessionKeys::NEW_ANNOUNCEMENT_COUNT` from the session hash' do
      session[described_class::SessionKeys::NEW_ANNOUNCEMENT_COUNT] = double('count')
      call_method
      expect(session).not_to have_key(described_class::SessionKeys::NEW_ANNOUNCEMENT_COUNT)
    end
  end

  describe '`set_active_nav`' do
    it 'sets the @active_nav instance variable to whatever it is passed' do
      [:foo, :bar, :biz].each do |name|
        subject.set_active_nav(name)
        expect(controller.instance_variable_get(:@active_nav)).to eq(name)
      end
    end
  end

  describe '`get_active_nav`' do
    let(:call_method) { controller.get_active_nav }
    let(:active_nav) { double('active nav value') }
    it 'returns the value of the instance variable @active_nav' do
      controller.instance_variable_set(:@active_nav, active_nav)
      expect(call_method).to eq(active_nav)
    end
    it 'returns nil if there is no instance variable @active_nav' do
      expect(call_method).to be_nil
    end
  end

  describe '`signer_full_name` method' do
    let(:signer) { double('A Signer Name') }
    let(:call_method) { subject.send(:signer_full_name) }
    it 'returns the signer name from the session if present' do
      session[described_class::SessionKeys::SIGNER_FULL_NAME] = signer
      expect(call_method).to be(signer)
    end
    describe 'with no signer in session' do
      let(:username) { double('A Username') }
      before do
        allow(subject).to receive_message_chain(:current_user, :username).and_return(username)
        allow_any_instance_of(EtransactAdvancesService).to receive(:signer_full_name).with(username).and_return(signer)
      end
      it 'fetches the signer from the eTransact Service' do
        expect_any_instance_of(EtransactAdvancesService).to receive(:signer_full_name).with(username)
        call_method
      end
      it 'sets the signer name in the session' do
        call_method
        expect(session[described_class::SessionKeys::SIGNER_FULL_NAME]).to be(signer)
      end
      it 'returns the signer name' do
        expect(call_method).to be(signer)
      end
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

  describe '`set_default_format` private method' do
    let(:request) { ActionDispatch::TestRequest.new }
    let(:call_method) { controller.send(:set_default_format) }
    before do
      allow(controller).to receive(:request).and_return(request)
    end
    it 'leaves `request.format` alone if its a known MIME type' do
      valid_format = Mime::SET.sample
      request.format = valid_format.to_sym
      call_method
      expect(request.format).to eq(valid_format)
    end
    it 'sets `request.format` to `:html` if its an unknown MIME type' do
      request.format = 'Accept: */*'
      call_method
      expect(request.format.html?).to be(true)
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