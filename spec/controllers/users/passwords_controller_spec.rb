require 'rails_helper'

RSpec.describe Users::PasswordsController, :type => :controller do
  it { should_not use_before_action(:check_terms) }
  
  let(:resource_class)  { subject.send(:resource_class) }
  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
    allow(subject).to receive(:warden).and_return(double('Warden', authenticated?: false))
  end

  describe 'layout' do
    it 'should use the `external` layout' do
      expect(described_class._layout).to eq('external')
    end
  end

  describe 'POST create' do
    let(:username) { SecureRandom.hex }
    let(:make_request) { post :create, user: {username: username} }
    let(:resource) { double('A Resource', errors:[], send_reset_password_instructions: true, intranet_user?: false) }

    before do
      allow(subject).to receive(:new_password_path).and_return('')
      allow(resource_class).to receive(:find_or_create_if_valid_login)
    end

    it_behaves_like 'a user not required action', :post, :create, user: {username: SecureRandom.hex}

    it 'calls `find_or_create_if_valid_login` on the `resource_class` passing in the `resource_params`' do
      resource_params = double('Resource Params')
      allow(subject).to receive(:resource_params).and_return(resource_params)
      expect(resource_class).to receive(:find_or_create_if_valid_login).with(resource_params)
      make_request
    end

    it 'discards flash notices' do
      allow(subject).to receive(:flash).and_return(subject.flash)
      expect(subject.flash).to receive(:discard).with(:notice)
      make_request
    end

    describe 'with a valid username' do
      before do
        allow(resource_class).to receive(:find_or_create_if_valid_login).and_return(resource)
      end

      it 'calls `send_reset_password_instructions` on the `resource`' do
        expect(resource).to receive(:send_reset_password_instructions)
        make_request
      end

      it 'assigns the `resource` attribute to the found resource instance' do
        expect(subject).to receive(:resource=).with(resource)
        make_request
      end

      it 'assigns `@user` to the `resource` attribute' do
        make_request
        expect(assigns[:user]).to be(resource)
      end

      describe 'for an intranet user' do
        before do
          allow(resource).to receive(:intranet_user?).and_return(true)
        end

        it 'does not `send_reset_password_instructions`' do
          expect(resource).not_to receive(:send_reset_password_instructions)
          make_request
        end
      end
    end

    describe 'with an invalid username' do
      before do
        allow(resource_class).to receive(:find_or_create_if_valid_login).and_return(nil)
      end

      it 'does not call `send_reset_password_instructions` on the `resource`' do
        expect(resource).to_not receive(:send_reset_password_instructions)
        make_request
      end

      it 'assigns the `resource` attribute to nil' do
        expect(subject).to receive(:resource=).with(nil)
        make_request
      end

      it 'assigns `@user` to nil' do
        make_request
        expect(assigns[:user]).to be(nil)
      end
    end
  end

  describe 'GET edit' do
    let(:reset_password_token) { SecureRandom.hex }
    let(:make_request) { get :edit, reset_password_token: reset_password_token }
    let(:resource_class) { subject.send(:resource_class) }

    it_behaves_like 'a user not required action', :get, :edit

    it 'sets `resource` to the result of the `with_reset_password_token` method' do
      resource = resource_class.new
      allow(resource_class).to receive(:with_reset_password_token).with(reset_password_token).and_return(resource)
      expect(subject).to receive(:resource=).with(resource).and_call_original
      make_request
    end

    it 'calls `set_minimum_password_length`' do
      expect(subject).to receive(:set_minimum_password_length)
      make_request
    end

    it 'sets the resources `reset_password_token`' do
      expect_any_instance_of(resource_class).to receive(:reset_password_token=).with(reset_password_token)
      make_request
    end

    it 'renders `timeout` if the reset_password_period has expired' do
      allow_any_instance_of(resource_class).to receive(:reset_password_period_valid?).and_return(false)
      make_request
      expect(response.body).to render_template(:timeout)
    end

    it 'renders `edit` if the reset_password_period has not expired' do
      allow_any_instance_of(resource_class).to receive(:reset_password_period_valid?).and_return(true)
      make_request
      expect(response.body).to render_template(:edit)
    end
  end

  describe 'PUT update' do
    let(:password) { 'Abcdefg12!' }
    let(:make_request) { put :update }

    it_behaves_like 'a user not required action', :put, :update

    it 'calls `super`' do
      # this is a lame test, but we can't test super calls on controllers.
      expect(resource_class).to receive(:reset_password_by_token).and_call_original
      make_request
    end
    it 'renders the `timeout` view if there are errors with the `reset_password_token`' do
      errors = double('ActiveModel::Errors', add: nil)
      allow_any_instance_of(resource_class).to receive(:errors).and_return(errors)
      allow(errors).to receive(:include?).with(:reset_password_token).and_return(true)
      make_request
      expect(response.body).to render_template(:timeout)
    end
    it 'redirects if there are no errors' do
      errors = double('ActiveModel::Errors', add: nil, include?: false, empty?: true)
      allow_any_instance_of(resource_class).to receive(:errors).and_return(errors)
      make_request
      expect(response).to be_redirect
    end
  end
end