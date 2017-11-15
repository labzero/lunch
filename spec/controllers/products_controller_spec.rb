require 'rails_helper'

RSpec.describe ProductsController, :type => :controller do
  login_user

  describe 'GET index' do
    it_behaves_like 'a user required action', :get, :index
    it_behaves_like 'a controller action with an active nav setting', :index, :products
    it_behaves_like 'a ProductsController action that pulls content from the CMS', :index
    it 'should render the index view' do
      get :index
      expect(response.body).to render_template('index')
    end
    it 'sets the active nav to :products' do
      expect(controller).to receive(:set_active_nav).with(:products)
      get :index
    end
  end

  describe 'GET loc' do
    it_behaves_like 'a user required action', :get, :loc
    it_behaves_like 'a controller action with an active nav setting', :loc, :products
    it_behaves_like 'a ProductsController action that pulls content from the CMS', :loc
    it 'should render the loc view' do
      get :loc
      expect(response.body).to render_template('loc')
    end
    it 'sets the active nav to :products' do
      expect(controller).to receive(:set_active_nav).with(:products)
      get :loc
    end
  end

  [:arc, :arc_embedded, :frc_embedded, :frc, :amortizing, :choice_libor, :knockout, :ocn, :putable, :mpf, :callable, :vrc, :sbc, :swaps, :authorizations, :convertible].each do |action|
    describe "GET #{action}" do
      it_behaves_like 'a product page', action
    end
  end

  describe 'GET vbloc' do
    it_behaves_like 'a user required action', :get, :vbloc
    it_behaves_like 'a product page', :vbloc
    it 'should render the vbloc view' do
      get :vbloc
      expect(response.body).to render_template('vbloc')
    end
  end

  describe 'GET pfi' do
    it_behaves_like 'a user required action', :get, :pfi
    it_behaves_like 'a product page', :pfi
    it 'should render the pfi view' do
      get :pfi
      expect(response.body).to render_template('pfi')
    end
    [
      :all_applicants_rows, :mpf_original_rows, :mpf_xtra_rows, :mpf_direct_rows, :mpf_gov_rows
    ].each do |var|
      it "should assign `@#{var}`" do
        get :pfi
        expect(assigns[var]).to be_present
      end
    end
  end

  {
    arc: 'arc_interest_payments',
    sbc: 'sbc_eligible_securities',
    pfi: 'pfi_forms_and_agreements',
    swaps: 'swap_term_exposure_table'
  }.each do |action, partial|
    describe "GET #{action}" do
      let(:additional_html) { instance_double(String) }

      it 'renders the `arc_interest_payments` partial to a string' do
        expect(controller).to receive(:render_to_string).with(partial: partial)
        get action
      end
      it 'sets `@additional_html` to the rendered partial string' do
        allow(controller).to receive(:render_to_string).with(partial: partial).and_return(additional_html)
        get action
        expect(assigns[:additional_html]).to eq(additional_html)
      end
    end
  end

  describe 'private methods' do
    describe '`set_body_html`' do
      let(:resolved_html) { double('link-resolved html')}
      let(:raw_html) { double('raw html')}
      let(:cms_key) { double('some key') }
      let(:product) { instance_double(Cms::Product, product_page_html: raw_html) }
      let(:call_method) { subject.send(:set_body_html, cms_key) }
      before do
        allow(Cms::Product).to receive(:new).and_return(product)
        allow(subject).to receive(:resolve_relative_prismic_links)
      end
      it 'creates a new instance of `Cms::Product` with the member id, request object and cms key' do
        expect(Cms::Product).to receive(:new).with(member_id, request, cms_key).and_return(product)
        call_method
      end
      it 'calls `product_page_html` on the instance of `Cms::Product`' do
        expect(product).to receive(:product_page_html)
        call_method
      end
      it 'calls `resolve_relative_prismic_links` with the `product_page_html`' do
        expect(subject).to receive(:resolve_relative_prismic_links).with(raw_html)
        call_method
      end
      it 'sets `@body_html` to the result of `resolve_relative_prismic_links`' do
        allow(subject).to receive(:resolve_relative_prismic_links).and_return(resolved_html)
        call_method
        expect(assigns[:body_html]).to eq(resolved_html)
      end
    end
  end

end
