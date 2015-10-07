require 'rails_helper'

RSpec.describe Users::SessionsController, :type => :controller do
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
  end
end