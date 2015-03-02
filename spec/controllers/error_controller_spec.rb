require 'rails_helper'

RSpec.describe ErrorController, :type => :controller do
  describe 'GET standard_error' do
    it 'should raise an error' do
      expect{get :standard_error}.to raise_error(StandardError)
    end

    describe 'in the non-test env' do
      before do
        allow(Rails.env).to receive(:test?).and_return(false)
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
  end
end