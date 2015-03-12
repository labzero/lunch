require 'spec_helper'

describe MAPI::ServiceApp do
  describe "error handler" do
    let(:error) { RuntimeError.new 'An Error' }
    let(:logger) { double('Logger', :error => nil)}
    it "logs the error" do
      expect_any_instance_of(MAPI::ServiceApp).to receive(:logger).and_return(logger)
      expect(logger).to receive(:error).with(error)
      MAPI::ServiceApp.new!.error_handler(error)
    end
    it "returns an unexpected error message" do
      allow_any_instance_of(MAPI::ServiceApp).to receive(:logger).and_return(logger)
      expect(MAPI::ServiceApp.new!.error_handler(error)).to eq('Unexpected Server Error')
    end
  end
end