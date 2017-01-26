require 'rails_helper'

RSpec.describe Admin::DashboardController, :type => :controller do

  login_user(admin: true)
  it_behaves_like 'an admin controller'

  describe 'GET index' do
    let(:make_request) { get :index }
    it 'responds with success' do
      make_request
      expect(response).to be_success
    end
  end

end