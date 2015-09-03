require 'rails_helper'

RSpec.describe Users::PasswordsController, :type => :controller do
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
    let(:resource) { double('A Resource', errors:[], send_reset_password_instructions: true) }
    let(:resource_class)  { subject.send(:resource_class) }

    before do
      allow(subject).to receive(:new_password_path).and_return('')
      allow(resource_class).to receive(:find_or_create_if_valid_login)
    end

    it_behaves_like 'a user not required action', :post, :create, user: {username: SecureRandom.hex}

    it 'should call `find_or_create_if_valid_login` on the `resource_class` passing in the `resource_params`' do
      resource_params = double('Resource Params')
      allow(subject).to receive(:resource_params).and_return(resource_params)
      expect(resource_class).to receive(:find_or_create_if_valid_login).with(resource_params)
      make_request
    end

    shared_examples 'flash messaging'  do
      it 'should call `set_flash_message`' do
        expect(subject).to receive(:set_flash_message).with(:error, :username_not_found)
        make_request
      end

      it 'should not call `set_flash_message` if `is_flashing_format?` returns false' do
        allow(subject).to receive(:is_flashing_format?).and_return(false)
        expect(subject).to_not receive(:set_flash_message)
        make_request
      end
    end

    describe 'with a valid username' do
      before do
        allow(resource_class).to receive(:find_or_create_if_valid_login).and_return(resource)
      end

      it 'should call `send_reset_password_instructions` on the `resource`' do
        expect(resource).to receive(:send_reset_password_instructions)
        make_request
      end

      it 'should assign the `resource` attribute to the found resource instance' do
        expect(subject).to receive(:resource=).with(resource)
        make_request
      end

      it 'should assign `@user` to the `resource` attribute' do
        make_request
        expect(assigns[:user]).to be(resource)
      end

      it 'should call `successfully_sent?` with the resource' do
        expect(subject).to receive(:successfully_sent?).with(resource).and_return(true)
        make_request
      end

      describe 'if `successfully_sent?` returns false' do
        before do
          allow(subject).to receive(:successfully_sent?).with(resource).and_return(false)
        end

        include_examples 'flash messaging'

        it 'should redirect to the `new_password_path`' do
          path = double('new_password_path')
          allow(subject).to receive(:new_password_path).with(resource).and_return(path)
          expect(subject).to receive(:redirect_to).with(path)
          make_request
        end
      end

      describe 'if `successfully_sent?` returns true' do
        before do
          allow(subject).to receive(:successfully_sent?).with(resource).and_return(true)
        end

        it 'should render the `create` template' do
          make_request
          expect(response).to render_template('create')
        end

        it 'should not set a flash' do
          expect(subject).to_not receive(:set_flash_message)
          make_request
        end
      end
    end

    describe 'with an invalid username' do
      before do
        allow(resource_class).to receive(:find_or_create_if_valid_login).and_return(nil)
      end

      include_examples 'flash messaging'

      it 'should not call `send_reset_password_instructions` on the `resource`' do
        expect(resource).to_not receive(:send_reset_password_instructions)
        make_request
      end

      it 'should assign the `resource` attribute to nil' do
        expect(subject).to receive(:resource=).with(nil)
        make_request
      end

      it 'should assign `@user` to nil' do
        make_request
        expect(assigns[:user]).to be(nil)
      end

      it 'should not call `successfully_sent?`' do
        expect(subject).to_not receive(:successfully_sent?)
        make_request
      end

      it 'should redirect to the `new_password_path`' do
        path = double('new_password_path')
        new_resource = double('A Resource')
        allow(resource_class).to receive(:new).and_return(new_resource)
        allow(subject).to receive(:new_password_path).with(new_resource).and_return(path)
        expect(subject).to receive(:redirect_to).with(path)
        make_request
      end
    end
  end

  describe 'GET edit' do
    let(:make_request) { get :edit, reset_password_token: SecureRandom.hex }
    let(:resource_class) { subject.send(:resource_class) }
    it 'calls `super`' do
      expect_any_instance_of(described_class.superclass).to receive(:edit)
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
end