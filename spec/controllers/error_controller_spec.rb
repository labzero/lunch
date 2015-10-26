require 'rails_helper'

RSpec.describe ErrorController, :type => :controller do
  it { should_not use_before_action(:authenticate_user!) }
  it { should_not use_before_action(:check_terms) }
  
  describe 'GET standard_error' do
    it 'should raise an error' do
      expect{get :standard_error}.to raise_error(StandardError)
    end

    describe 'in the production env' do
      before do
        allow(Rails.env).to receive(:production?).and_return(true)
      end
      it 'passes the exception to the `handle_exception` method' do
        expect(controller).to receive(:handle_exception)
        get :standard_error
      end
      it 'returns a 500 for its status' do
        get :standard_error
        expect(response.status).to be(500)
      end
      it 'renders the 500 view' do
        get :standard_error
        expect(response.body).to render_template('500')
      end
    end
  end

  describe 'GET not_found' do
    it 'should raise an error' do
      expect{get :not_found}.to raise_error(ActionController::RoutingError)
    end

    describe 'in the production env' do
      before do
        allow(Rails.env).to receive(:production?).and_return(true)
      end
      it 'passes the exception to the `handle_exception` method' do
        expect(controller).to receive(:handle_exception)
        get :not_found
      end
      it 'returns a 404 for its status' do
        get :not_found
        expect(response.status).to be(404)
      end
      it 'renders the 404 view' do
        get :not_found
        expect(response.body).to render_template('404')
      end
    end
  end

  describe 'GET maintenance' do
    it 'renders the maintenance view' do
      get :maintenance
      expect(response.body).to render_template('maintenance')
    end
    it 'returns a 503 for its status' do
      get :maintenance
      expect(response.status).to be(503)
    end
    it 'enables inline styles' do
      get :maintenance
      expect(assigns['inline_styles']).to eq(true)
    end
    it 'disables javascript' do
      get :maintenance
      expect(assigns['skip_javascript']).to eq(true)
    end
  end
end