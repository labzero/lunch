require 'rails_helper'

describe MAPIService do
  let(:user_id) { double('A User ID') }
  let(:uuid) { double('A UUID') }
  let(:request) { instance_double(ActionDispatch::Request, uuid: uuid, user_id: user_id, session: session) }
  let(:session) { double('A Session', :[] => nil) }
  let(:connection) { instance_double(RestClient::Resource, headers: {}, get: nil, put: nil, post: nil, delete: nil) }

  before do
    allow(connection).to receive(:[]).and_return(connection)
    allow(RestClient::Resource).to receive(:new).with(Rails.configuration.mapi.endpoint, any_args).and_return(connection)
  end

  subject { MAPIService.new(request) }

  describe 'initialization' do
    it 'assigns the `request` `uuid` to the `connection_request_uuid`' do
      expect(subject.connection_request_uuid).to be(uuid)
    end
    it 'assigns the `request` `user_id` to the `connection_user_id`' do
      expect(subject.connection_user_id).to be(user_id)
    end
    it 'creates a new `RestClient::Resource` with the MAPI endpoint' do
      expect(RestClient::Resource).to receive(:new).with(Rails.configuration.mapi.endpoint, any_args)
      subject
    end
    it 'creates a new `RestClient::Resource` with the MAPI endpoint secret key in its request headers' do
      expect(RestClient::Resource).to receive(:new).with(anything, include(headers: include(:'Authorization' => "Token token=\"#{ENV['MAPI_SECRET_TOKEN']}\"")))
      subject
    end
    it 'assigns the `request` to the `request` attribute' do
      expect(subject.instance_variable_get(:@request)).to be(request)
    end
  end

  describe '`ping` method' do
    let(:status) { subject.ping }
    let(:json_response) { {'foo' => 'bar'} }
    let (:mapi_response) {double('MAPI_response', body: json_response.to_json)}
    it 'returns the value of `etransact_advances_status` from a hash built from the JSON response' do
      allow(connection).to receive(:get).and_return(mapi_response)
      expect(status).to eq(json_response)
    end
    it "should return false if there was an error" do
      allow(connection).to receive(:get).and_raise(RestClient::InternalServerError)
      expect(status).to eq(false)
    end
    it "should return false if the service was unreachable" do
      allow(connection).to receive(:get).and_raise(Errno::ECONNREFUSED)
      expect(status).to eq(false)
    end
  end

  describe '`request` method' do
    it 'returns the request bound to the service object' do
      expect(subject.request).to be(request)
    end
  end

  describe '`connection_user_id` method' do
    it 'returns the `X-User-ID` header value that will be sent on all REST requests' do
      subject # force instantiation
      value = double('A Value')
      connection.headers[:'X-User-ID'] = value
      expect(subject.connection_user_id).to be(value)
    end
  end

  describe '`connection_request_uuid` method' do
    it 'returns the `X-Request-ID` header value that will be sent on all REST requests' do
      subject # force instantiation
      value = double('A Value')
      connection.headers[:'X-Request-ID'] = value
      expect(subject.connection_request_uuid).to be(value)
    end
  end

  describe '`connection_user_id=` method' do
    it 'assigns the `X-User-ID` header value that will be sent on all REST requests' do
      value = double('A Value')
      subject.connection_user_id = value
      expect(connection.headers[:'X-User-ID']).to be(value)
    end
    it 'discards the `@connection_user` value' do
      subject.instance_variable_set(:@connection_user, double('A Value'))
      subject.connection_user_id = double('Another Value')
      expect(subject.instance_variable_get(:@connection_user)).to be_nil
    end
  end

  describe '`connection_request_uuid=` method' do
    it 'assigns the `X-Request-ID` header value that will be sent on all REST requests' do
      value = double('A Value')
      subject.connection_request_uuid = value
      expect(connection.headers[:'X-Request-ID']).to be(value)
    end
  end

  describe '`connection_user` method' do
    let(:call_method) { subject.connection_user }
    let(:user) { instance_double(User) }
    before do
      allow(subject).to receive(:connection_user_id).and_return(user_id)
      allow(User).to receive(:find).with(user_id).and_return(user)
    end
    it 'find the user idenitifed by `connection_user_id`' do
      expect(User).to receive(:find).with(user_id)
      call_method
    end
    it 'returns the user idenitifed by `connection_user_id`' do
      expect(call_method).to be(user)
    end
    it 'returns the same user object on a subsequent call' do
      allow(User).to receive(:find).with(user_id).and_return(user, instance_double(User))
      call_method
      expect(call_method).to be(user)
    end
  end

  describe '`warn` method' do
    let(:name) { double('A Name', to_s: SecureRandom.hex) }
    let(:message) { double('A Message', to_s: SecureRandom.hex) }
    let(:error) { double('An Error') }
    let(:error_handler) { -> (n, m, e) {} }
    let(:call_method) { subject.warn(name, message, error, &error_handler) }

    it 'returns nil' do
      expect(call_method).to be_nil
    end

    it 'logs the message and name at a log level of `warn`' do
      expect(Rails.logger).to receive(:warn).with(/#{name.to_s}.*#{message.to_s}/)
      call_method
    end

    it 'calls the error handler if supplied' do
      expect(error_handler).to receive(:call).with(name, message, error)
      call_method
    end

    it 'does not require the error handler' do
      expect{subject.warn(name, message, error)}.to_not raise_error
    end
  end

  shared_examples_for 'a MAPI REST request' do |rest_action, *args|
    let(:error_handler) { -> (name, err_str, err) { } }
    let(:call_method) { subject.send(rest_action, name, endpoint, *args) }
    let(:call_method_with_error_handler) { subject.send(rest_action, name, endpoint, *args, &error_handler) }
    let(:response) { double('A Response') }
    {
      'RestClient' => RestClient::Exception.new,
      'network' => Errno::ECONNREFUSED.new
    }.each do |error_type, exception|
      it "handles #{error_type} errors" do
        allow(connection).to receive(rest_action).and_raise(exception)
        expect(subject).to receive(:warn).with(name, kind_of(String), exception)
        call_method
      end
      it "returns the result of `warn` on an #{error_type} error" do
        warn = double('A Warn Result')
        allow(subject).to receive(:warn).and_return(warn)
        allow(connection).to receive(rest_action).and_raise(exception)
        expect(call_method).to be(warn)
      end
      it "passes the error handler off to `warn` when handling a #{error_type} error" do
        allow(connection).to receive(rest_action).and_raise(exception)
        allow(subject).to receive(:warn).with(anything, anything, anything) do |*args, &block|
          expect(block).to be(error_handler)
        end
        call_method_with_error_handler
      end
    end
    it 'accepts a custom error handler' do
      allow(connection).to receive(rest_action).and_return(response)
      expect{call_method_with_error_handler}.to_not raise_error
    end
  end

  shared_examples_for 'a MAPI JSON REST request' do |rest_action, *args|
    let(:endpoint) { double('An Endpoint', to_s: '/') }
    let(:name) { double('A Name') }
    let(:error_handler) { -> (name, err_str, err) { } }
    let(:call_method) { subject.send(:"#{rest_action}_json", name, endpoint, *args) }
    let(:call_method_with_error_handler) { subject.send(:"#{rest_action}_json", name, endpoint, *args, &error_handler) }
    let(:anythings) { Array.new(args.length, anything) }

    before do
      allow(subject).to receive(rest_action).and_return(nil)
    end

    if rest_action == :post || rest_action == :put
      it "calls `#{rest_action}` with a JSON body and a content_type of 'application/json'" do
        new_args = args.collect{|x| x.to_json} + ['application/json']
        expect(subject).to receive(rest_action).with(name, endpoint, *new_args)
        call_method
      end
    else
      it "calls `#{rest_action}`" do
        expect(subject).to receive(rest_action).with(name, endpoint, *args)
        call_method
      end
    end
    it "passes the response from `#{rest_action}` to `parse`" do
      response = double('A Response')
      allow(subject).to receive(rest_action).and_return(response)
      expect(subject).to receive(:parse).with(name, response)
      call_method
    end
    it 'returns the result of `parse`' do
      result = double('A Result')
      allow(subject).to receive(:parse).and_return(result)
      expect(call_method).to be(result)
    end
    it "passes the error handler to `#{rest_action}`" do
      anythings = Array.new(args.length, anything)
      allow(subject).to receive(rest_action) do |*args, &block|
        expect(block).to be(error_handler)
        nil
      end
      call_method_with_error_handler
    end
    it 'passes the error handler to `parse`' do
      allow(subject).to receive(:parse).with(anything, anything) do |*args, &block|
        expect(block).to be(error_handler)
        nil
      end
      call_method_with_error_handler
    end
  end

  shared_examples_for 'a MAPI JSON REST request with Hash response' do |rest_action, *args|
    let(:endpoint) { double('An Endpoint', to_s: '/') }
    let(:name) { double('A Name') }
    let(:error_handler) { -> (name, err_str, err) { } }
    let(:call_method) { subject.send(:"#{rest_action}_hash", name, endpoint, *args) }
    let(:call_method_with_error_handler) { subject.send(:"#{rest_action}_hash", name, endpoint, *args, &error_handler) }
    let(:anythings) { Array.new(args.length, anything) }

    it "calls `#{rest_action}_json`" do
      expect(subject).to receive(:"#{rest_action}_json").with(name, endpoint, *args)
      call_method
    end
    it "converts the `#{rest_action}_json` result to an indifferent hash" do
      result = double('A Result')
      allow(subject).to receive(:"#{rest_action}_json").and_return(result)
      expect(result).to receive(:try).with(:with_indifferent_access)
      call_method
    end
    it 'returns the indifferent hash' do
      result = double('A Result')
      allow(subject).to receive_message_chain(:"#{rest_action}_json", :try).and_return(result)
      expect(call_method).to be result
    end
    it "passes the error handler to `#{rest_action}_json`" do
      allow(subject).to receive(:"#{rest_action}_json").with(anything, anything, *anythings) do |*args, &block|
        expect(block).to be(error_handler)
        nil
      end
      call_method_with_error_handler
    end
  end

  [:get, :delete].each do |action|
    describe "`#{action}` method" do
      let(:endpoint) { double('An Endpoint', to_s: '/') }
      let(:name) { double('A Name') }
      let(:endpoint_client) { double('An Endpoint Client') }
      let(:response) { double('A Response') }
      let(:params) { double('Query String Parameter Hash') }
      let(:call_method) { subject.send(action, name, endpoint, params) }
      before { allow(endpoint_client).to receive(action) }

      it_behaves_like 'a MAPI REST request', action

      it "#{action.to_s.upcase}s the `endpoint`" do
        allow(connection).to receive(:[]).with(endpoint).and_return(endpoint_client)
        expect(endpoint_client).to receive(action)
        call_method
      end
      it "returns the result of the #{action.to_s.upcase}" do
        allow(connection).to receive(action).and_return(response)
        expect(call_method).to be(response)
      end
      it 'passes along any supplied query string parameters' do
        allow(connection).to receive(:[]).with(endpoint).and_return(endpoint_client)
        expect(endpoint_client).to receive(action).with(params: params)
        call_method
      end
    end
  end

  describe '`parse` method' do
    let(:response) { double('A Response', body: double('A Response Body')) }
    let(:name) { double('A Name') }
    let(:error_handler) { -> (name, err_str, err) { } }
    let(:call_method) { subject.parse(name, response) }
    let(:call_method_with_error_handler) { subject.parse(name, response, &error_handler) }

    it 'returns nil if the response is nil' do
      expect(subject.parse(name, nil)).to be_nil
    end
    it 'parses the response body as JSON' do
      expect(JSON).to receive(:parse).with(response.body)
      call_method
    end
    it 'returns the parsed JSON' do
      parsed_json = double('Parsed JSON')
      allow(JSON).to receive(:parse).with(response.body).and_return(parsed_json)
      expect(call_method).to be(parsed_json)
    end
    it 'handles JSON parse errors' do
      exception = JSON::ParserError.new
      allow(JSON).to receive(:parse).and_raise(exception)
      expect(subject).to receive(:warn).with(name, kind_of(String), exception)
      call_method
    end
    it 'returns the result of `warn` on error' do
      warn = double('A Warn Result')
      allow(subject).to receive(:warn).and_return(warn)
      allow(JSON).to receive(:parse).and_raise(JSON::ParserError.new)
      expect(call_method).to be(warn)
    end
    it 'accepts a custom error handler' do
      allow(JSON).to receive(:parse)
      expect{call_method_with_error_handler}.to_not raise_error
    end
    it 'passes the error handler off to `warn`' do
      exception = JSON::ParserError.new
      allow(JSON).to receive(:parse).and_raise(exception)
      allow(subject).to receive(:warn).with(anything, anything, anything) do |*args, &block|
        expect(block).to be(error_handler)
      end
      call_method_with_error_handler
    end
  end

  describe '`get_json` method' do
    it_behaves_like 'a MAPI JSON REST request', :get, {SecureRandom.hex => SecureRandom.hex}
  end

  describe '`get_hash` method' do
    it_behaves_like 'a MAPI JSON REST request with Hash response', :get, {SecureRandom.hex => SecureRandom.hex}
  end

  describe '`get_fake_hash` method'

  describe '`post` method', :vcr do
    let(:endpoint) { double('An Endpoint', to_s: '/') }
    let(:name) { double('A Name') }
    let(:body) { double('Data To Post') }
    let(:content_type) { double('content type') }
    let(:endpoint_client) { double('An Endpoint Client', post: nil) }
    let(:call_method) { subject.post(name, endpoint, body, content_type) }

    it_behaves_like 'a MAPI REST request', :post, 'Data to Post', 'application/json'

    it 'POSTs to the `endpoint`' do
      expect(connection).to receive(:[]).with(endpoint).and_return(endpoint_client)
      call_method
    end
    it 'POSTs the `body`' do
      expect(connection).to receive(:post).with(body, anything)
      call_method
    end
    it 'POSTs the `content_type` if one is given' do
      expect(connection).to receive(:post).with(anything, content_type: content_type)
      call_method
    end
    it 'does not set the `content_type` if one is not given' do
      expect(connection).to receive(:post).with(anything)
      subject.post(name, endpoint, body)
    end
    it 'succeeds if a `content_type` is given' do
      expect{call_method}.to_not raise_exception
    end
    it 'succeeds if no `content_type` is given' do
      expect{subject.post(name, endpoint, body)}.to_not raise_exception
    end
  end

  describe '`put` method', :vcr do
    let(:endpoint) { double('An Endpoint', to_s: '/') }
    let(:name) { double('A Name') }
    let(:body) { double('Data To PUT') }
    let(:content_type) { double('content type') }
    let(:endpoint_client) { double('An Endpoint Client', put: nil) }
    let(:call_method) { subject.put(name, endpoint, body, content_type) }

    it_behaves_like 'a MAPI REST request', :put, 'Data to PUT', 'application/json'

    it 'PUTs to the `endpoint`' do
      expect(connection).to receive(:[]).with(endpoint).and_return(endpoint_client)
      call_method
    end
    it 'PUTs the `body`' do
      expect(connection).to receive(:put).with(body, anything)
      call_method
    end
    it 'PUTs the `content_type` if one is given' do
      expect(connection).to receive(:put).with(anything, content_type: content_type)
      call_method
    end
    it 'does not set the `content_type` if one is not given' do
      expect(connection).to receive(:put).with(anything)
      subject.put(name, endpoint, body)
    end
    it 'succeeds if a `content_type` is given' do
      expect{call_method}.to_not raise_exception
    end
    it 'succeeds if no `content_type` is given' do
      expect{subject.put(name, endpoint, body)}.to_not raise_exception
    end
  end

  describe '`post_json` method' do
    it_behaves_like 'a MAPI JSON REST request', :post, 'Data to POST'
  end

  describe '`post_hash` method' do
    it_behaves_like 'a MAPI JSON REST request with Hash response', :post, 'Data to POST'
  end

  describe '`put_json` method' do
    it_behaves_like 'a MAPI JSON REST request', :put, 'Data to PUT'
  end

  describe '`put_hash` method' do
    it_behaves_like 'a MAPI JSON REST request with Hash response', :put, 'Data to PUT'
  end

  describe '`fix_date`' do
    let(:field_1) { double('field') }
    let(:field_2) { double('field') }
    let(:data) { {field_1: field_1, field_2: field_2} }
    describe 'when passed a single field' do
      it 'calls `to_date` on the data value for that field and no others' do
        expect(field_1).to receive(:to_date)
        expect(field_2).not_to receive(:to_date)
        subject.fix_date(data, :field_1)
      end
    end
    describe 'when passed an array of fields' do
      it 'calls `to_date` on all of the data values for the corresponding fields' do
        expect(field_1).to receive(:to_date)
        expect(field_2).to receive(:to_date)
        subject.fix_date(data, [:field_1, :field_2])
      end
    end
  end

  describe '`parse_24_hour_time`' do
    it 'treats the first 2 digits of the time as hours and the last two digits as minutes' do
      time = rand(0..2400).to_s.rjust(4, '0')
      expect(Time.zone).to receive(:parse).with(include("#{time[0..1]}:#{time[2..3]}"))
      subject.parse_24_hour_time(time)
    end
  end
end