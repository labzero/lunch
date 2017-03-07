require 'spec_helper'

describe MAPI::Logger do
  let(:logger) { instance_double(ActiveSupport::TaggedLogging) }
  let(:app) { Sinatra::Base }
  subject { described_class.new(app, logger) }

  describe '`call` method' do
    let(:env) { Hash.new }
    let(:call_method) { subject.call(env) }
    describe 'tagging with the `request_id`' do
      it 'tags the logs with the `X-Request-ID` header value if present' do
        request_id = SecureRandom.hex
        env['HTTP_X_REQUEST_ID'] = request_id
        expect(logger).to receive(:tagged).with("request_id=#{request_id}", anything)
        call_method
      end
      it 'tags the logs with a UUID if `X-Request-ID` header value is not present' do
        env['HTTP_X_REQUEST_ID'] = nil
        expect(logger).to receive(:tagged).with(match(/\Arequest_id=[a-z0-9]{8}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{12}\z/), anything)
        call_method
      end
    end
    describe 'tagging with the `user_id`' do
      it 'tags the logs with the `X-User-ID` header value if present' do
        user_id = SecureRandom.hex
        env['HTTP_X_USER_ID'] = user_id
        expect(logger).to receive(:tagged).with(anything, "user_id=#{user_id}")
        call_method
      end
      it 'tags the logs with a blank if `X-User-ID` header value is not present' do
        env['HTTP_X_USER_ID'] = nil
        expect(logger).to receive(:tagged).with(anything, 'user_id=')
        call_method
      end
    end
    describe 'extending the environment' do
      before do
        allow(logger).to receive(:tagged).and_yield
      end

      it 'passes the environment to the app' do
        expect(app).to receive(:call).with(env)
        call_method
      end

      it 'includes the `request_id` under the key `mapi.request.id`' do
        request_id = double('Request ID')
        env['HTTP_X_REQUEST_ID'] = request_id
        expect(app).to receive(:call).with(include('mapi.request.id' => request_id))
        call_method
      end

      it 'includes the `user_id` under the key `mapi.request.user_id`' do
        user_id = double('User ID')
        env['HTTP_X_USER_ID'] = user_id
        expect(app).to receive(:call).with(include('mapi.request.user_id' => user_id))
        call_method
      end
    end
  end
end