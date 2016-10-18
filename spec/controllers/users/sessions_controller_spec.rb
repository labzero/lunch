require 'rails_helper'

RSpec.describe Users::SessionsController, :type => :controller do
  it { should_not use_before_action(:check_password_change) }
  it { should_not use_before_action(:check_terms) }
  
  describe 'layout' do
    it 'should use the `external` layout' do
      expect(subject.class._layout).to eq('external')
    end
  end

  describe 'DELETE destroy' do
    let(:make_request) { delete :destroy }
    login_user

    it 'calls super' do
      expect_any_instance_of(described_class.superclass).to receive(:destroy).and_call_original
      make_request
    end
    it 'discards flash notices' do
      allow(subject).to receive(:flash).and_return(subject.flash)
      expect(subject.flash).to receive(:discard).with(:notice)
      make_request
    end
    it 'clears the cached user data' do
      expect(subject.current_user).to receive(:clear_cache)
      make_request
    end
  end

  describe 'POST create' do
    let(:make_request) { post :create, username: 'foo', password: 'bar' }

    before do
      @request.env["devise.mapping"] = Devise.mappings[:user]
      sign_out :user
      allow_any_instance_of(Warden::Proxy).to receive(:authenticate!).and_return(build_user)
    end

    it 'calls super' do
      expect_any_instance_of(described_class.superclass).to receive(:create).and_call_original
      make_request
    end
    it 'discards flash notices' do
      allow(subject).to receive(:flash).and_return(subject.flash)
      expect(subject.flash).to receive(:discard).with(:notice)
      make_request
    end

    context 'retrying on ActiveRecord::RecordNotUnique' do
      before do
        allow_any_instance_of(Warden::Proxy).to receive(:authenticate!).and_raise(ActiveRecord::RecordNotUnique.new('error'))
      end
      it 'retries the `authenticate!` twice on `ActiveRecord::RecordNotUnique`' do
        expect_any_instance_of(Warden::Proxy).to receive(:authenticate!).twice
        make_request rescue ActiveRecord::RecordNotUnique
      end
      it 'raises `ActiveRecord::RecordNotUnique` if all retries fail' do
        expect{make_request}.to raise_error(ActiveRecord::RecordNotUnique)
      end
    end
  end
end