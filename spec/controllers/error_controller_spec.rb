require 'rails_helper'

RSpec.describe ErrorController, :type => :controller do
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