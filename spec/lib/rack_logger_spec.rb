require 'rails_helper'

describe FhlbMember::Rack::Logger do
  subject { described_class.new(double('App')) }

  it 'inherits from Rails::Rack::Logger' do
    expect(subject).to be_kind_of(Rails::Rack::Logger)
  end
  describe '`started_request_message` protected method' do
    let(:request) { double(ActionDispatch::Request, request_method: SecureRandom.hex, filtered_path: SecureRandom.hex, remote_ip: SecureRandom.hex) }
    let(:now) { double('Now', to_default_s: SecureRandom.hex) }
    let(:call_method) { subject.send(:started_request_message, request) }

    before do
      allow(Time).to receive(:now).and_return(now)
    end

    it 'includes the `request_method`' do
      expect(call_method).to match(request.request_method)
    end
    it 'includes the `filtered_path`' do
      expect(call_method).to match(request.filtered_path)
    end
    it 'includes the `remote_ip`' do
      expect(call_method).to match(request.remote_ip)
    end
    it 'includes the current timestamp' do
      expect(call_method).to match(now.to_default_s)
    end
  end

end
