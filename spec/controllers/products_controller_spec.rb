require 'rails_helper'

RSpec.describe ProductsController, :type => :controller do
  login_user

  describe 'GET index' do
    it_behaves_like 'a user required action', :get, :index
    it 'should render the index view' do
      get :index
      expect(response.body).to render_template('index')
    end
  end

  [:arc, :arc_embedded, :auction_indexed, :frc_embedded, :frc, :amortizing, :choice_libor, :knockout, :ocn, :putable, :mpf, :callable, :vrc, :sbc, :swaps].each do |action|
    describe "GET #{action}" do
      it_behaves_like 'a product page', action
    end
  end

  describe 'GET pfi' do
    it_behaves_like 'a user required action', :get, :pfi
    it 'should render the pfi view' do
      get :pfi
      expect(response.body).to render_template('pfi')
    end
    [
      :all_applicants_rows, :mpf_original_rows, :mpf_government_rows, :mpf_xtra_rows, :mpf_direct_rows
    ].each do |var|
      it "should assign `@#{var}`" do
        get :pfi
        expect(assigns[var]).to be_present
      end
    end
  end

end
