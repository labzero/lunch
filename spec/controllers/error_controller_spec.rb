require 'rails_helper'

RSpec.describe ErrorController, :type => :controller do
  describe 'GET standard_error' do
    it 'should raise an error' do
      expect{get :standard_error}.to raise_error(StandardError)
    end

    describe 'in the non-test env' do
      it 'passes the exception to the `handle_exception` method' do
        allow(Rails.env).to receive(:test?).and_return(false)
        expect(controller).to receive(:handle_exception)
        get :standard_error
      end
    end
  end
end