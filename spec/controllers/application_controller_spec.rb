require 'rails_helper'

RSpec.describe ApplicationController, :type => :controller do
  let(:error) {StandardError.new}

  describe '`handle_exception` method' do
    let(:backtrace) {%w(some backtrace array returned by the error)}
    it 'captures all StandardErrors and displays the 500 error view' do
      expect(error).to receive(:backtrace).and_return(backtrace)
      expect(controller).to receive(:render).with('error/500', {:layout=>false, :status=>500})
      controller.send(:handle_exception, error)
    end
    it 'rescues any exceptions raised when rendering the `error/500` view' do
      expect(error).to receive(:backtrace).at_least(1).and_return(backtrace)
      expect(controller).to receive(:render).with('error/500', {:layout=>false, :status=>500}).and_raise(error)
      expect(controller).to receive(:render).with({:text=>error, :status=>500})
      controller.send(:handle_exception, error)
    end
  end

  describe '`after_sign_out_path_for(resource)` method' do
    it 'redirects to the root path' do
      expect(controller).to receive(:root_path)
      controller.send(:after_sign_out_path_for, 'some resource')
    end
  end

  describe '`after_sign_in_path_for(resource)` method' do
    it 'redirects to the stored location for the resource if it exists' do
      expect(controller).to receive(:stored_location_for).with('some resource')
      controller.send(:after_sign_in_path_for, 'some resource')
    end
    it 'redirects to the dashboard_path if there is no stored location for the resource' do
      expect(controller).to receive(:dashboard_path)
      expect(controller).to receive(:stored_location_for).with('some resource').and_return(nil)
      controller.send(:after_sign_in_path_for, 'some resource')
    end
  end
end