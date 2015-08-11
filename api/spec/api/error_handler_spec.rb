require 'spec_helper'

describe MAPI::ServiceApp do
  describe "error handler" do
    let(:backtrace_string) {double('Backtrace String')}
    let(:error) do
      err = RuntimeError.new 'An Error'
      backtrace = []
      allow(backtrace).to receive(:join).and_return(backtrace_string)
      err.set_backtrace(backtrace)
      err
    end
    let(:logger) { double('Logger', :error => nil)}
    let(:call_handler) { MAPI::ServiceApp.new!.error_handler(error) }
    before do
      allow_any_instance_of(MAPI::ServiceApp).to receive(:logger).and_return(logger)
    end
    describe 'in the `production` environment' do
      around do |example|
        old_env = ENV['RACK_ENV']
        begin
          ENV['RACK_ENV'] = 'production'
          example.run
        ensure
          ENV['RACK_ENV'] = old_env
        end
      end
      it "logs the error" do
        expect(logger).to receive(:error).with(error)
        call_handler
      end
      it "doesn't log the backtrace" do
        expect(logger).to_not receive(:error).with(backtrace_string)
      end
    end
    it "logs the error and backtrace" do
      expect(logger).to receive(:error).with(error)
      expect(logger).to receive(:error).with(backtrace_string)
      call_handler
    end
    it "returns an unexpected error message" do
      expect(call_handler).to eq('Unexpected Server Error')
    end
  end
end