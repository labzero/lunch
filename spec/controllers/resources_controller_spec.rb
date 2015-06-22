require 'rails_helper'

RSpec.describe ResourcesController, type: :controller do
  login_user

  describe 'GET guides' do
    it_behaves_like 'a user required action', :get, :guides
    it "should render the guides view" do
      get :guides
      expect(response.body).to render_template('guides')
    end

  end
end
