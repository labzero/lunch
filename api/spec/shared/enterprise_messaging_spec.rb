require 'spec_helper'

module MAPISharedEnterpriseMessaging
  include MAPI::Shared::EnterpriseMessaging
end

describe MAPI::Shared::EnterpriseMessaging::ClassMethods do
  subject { MAPISharedEnterpriseMessaging }
  let(:app) { double(MAPI::ServiceApp, logger: nil) }
  let(:num_retries) { rand(5..20) }
  let(:sleep_interval) { 0.1 }
  before do
    stub_const('MAPI::Shared::EnterpriseMessaging::HOSTNAME', 'SFDWMSGBROKER1.fhlbsf-i.com')
    stub_const('MAPI::Shared::EnterpriseMessaging::CONFIG_DIR', 'config/ssl')
    stub_const('MAPI::Shared::EnterpriseMessaging::CERT_FILE', "#{MAPI::Shared::EnterpriseMessaging::CONFIG_DIR}/client.crt")
    stub_const('MAPI::Shared::EnterpriseMessaging::KEY_FILE', "#{MAPI::Shared::EnterpriseMessaging::CONFIG_DIR}/client.key")
    stub_const('MAPI::Shared::EnterpriseMessaging::TS_FILES', "#{MAPI::Shared::EnterpriseMessaging::CONFIG_DIR}/msgbroker1.pem")
    stub_const('MAPI::Shared::EnterpriseMessaging::PORT', 51515)
    stub_const('MAPI::Shared::EnterpriseMessaging::CLIENT_ID', SecureRandom.hex)
    stub_const('MAPI::Shared::EnterpriseMessaging::SUBSCRIPTION_NAME', 'mp')
    stub_const('MAPI::Shared::EnterpriseMessaging::FQ_QUEUE', '/queue/mcufu.ix')
    stub_const('MAPI::Shared::EnterpriseMessaging::TOPIC', 'ix.portal')
    stub_const('MAPI::Shared::EnterpriseMessaging::FQ_TOPIC', "/topic/#{MAPI::Shared::EnterpriseMessaging::TOPIC}")
    stub_const('MAPI::Shared::EnterpriseMessaging::NUM_RETRIES', num_retries)
    stub_const('MAPI::Shared::EnterpriseMessaging::SLEEP_INTERVAL', sleep_interval)
  end

  describe '`get_message`' do
    let(:call_method) { subject.get_message(app, message, member_id, headers)}
    let(:correlation_id) { SecureRandom.hex }
    let(:stomp_client) { double('stomp client') }
    let(:message) { double('message') }
    let(:msg) { double('msg', body: nil) }
    let(:headers) { { name: 'value' } }
    before do
      allow(SecureRandom).to receive(:hex).and_return(correlation_id)
      allow(subject).to receive(:stomp_client).and_return(stomp_client)
      allow(stomp_client).to receive(:subscribe).and_yield(msg)
      allow(stomp_client).to receive(:publish)
      allow(stomp_client).to receive(:unsubscribe)
    end
    it 'gets the `stomp_client`' do
      expect(subject).to receive(:stomp_client).with(app)
      call_method
    end
    it 'calls `subscribe` on the `stomp_client`' do
      expect(stomp_client).to receive(:subscribe).with(MAPI::Shared::EnterpriseMessaging::FQ_TOPIC,
        { 'correlation-id': correlation_id,
          'client-id': MAPI::Shared::EnterpriseMessaging::CLIENT_ID,
          'activemq.subscriptionName': MAPI::Shared::EnterpriseMessaging::SUBSCRIPTION_NAME })
      call_method
    end
    it 'catches a `DuplicateSubscription` error' do
      allow(stomp_client).to receive(:subscribe).and_raise(Stomp::Error::DuplicateSubscription)
      expect { call_method }.not_to raise_error(Stomp::Error::DuplicateSubscription)
    end
    it 'calls `publish` on the `stomp_client`' do
      expect(stomp_client).to receive(:publish).with(
        "#{MAPI::Shared::EnterpriseMessaging::FQ_QUEUE}?replyTo=#{MAPI::Shared::EnterpriseMessaging::TOPIC}", 
        '', 
        { 'correlation-id': correlation_id, 
          'CMD': message }.merge(headers))
      call_method
    end
    it 'loops `NUM_RETRIES` times waiting for a response' do
      allow(stomp_client).to receive(:subscribe).and_yield(nil)
      expect(subject).to receive(:sleep).with(MAPI::Shared::EnterpriseMessaging::SLEEP_INTERVAL).exactly(num_retries).times
      expect { call_method }.to raise_error
    end
    it 'returns the response body if it exists' do
      response_body = double('response body')
      allow(msg).to receive(:body).and_return(response_body)
      expect(call_method).to eq(response_body)
    end
    it "calls `unsubscribe` if there are no exceptions" do
      expect(stomp_client).to receive(:unsubscribe).with(MAPI::Shared::EnterpriseMessaging::FQ_TOPIC, 
        { 'client-id': MAPI::Shared::EnterpriseMessaging::CLIENT_ID, 
          'activemq.subscriptionName': MAPI::Shared::EnterpriseMessaging::SUBSCRIPTION_NAME })
      call_method
    end
    it "calls `unsubscribe` if there is an exception" do
      allow(stomp_client).to receive(:subscribe).and_yield(nil)
      expect(stomp_client).to receive(:unsubscribe).with(MAPI::Shared::EnterpriseMessaging::FQ_TOPIC, 
        { 'client-id': MAPI::Shared::EnterpriseMessaging::CLIENT_ID, 
          'activemq.subscriptionName': MAPI::Shared::EnterpriseMessaging::SUBSCRIPTION_NAME })
      expect { call_method }.to raise_error
    end
  end

  describe '`stomp_client`' do
    let(:call_method) { subject.stomp_client(app) }
    let(:stomp_client) { double('stomp client') }
    let(:ssl_config) { double('ssl config') }
    let(:logger) { double('logger') }
    it 'creates the stomp client' do
      allow(Stomp::SSLParams).to receive(:new).and_return(ssl_config)
      allow(app).to receive(:logger).and_return(logger)
      expect(Stomp::Client).to receive(:new).with({ 
        hosts: [ { host: MAPI::Shared::EnterpriseMessaging::HOSTNAME, port: MAPI::Shared::EnterpriseMessaging::PORT, ssl: ssl_config } ], 
        reliable: true, 
        max_reconnect_attempts: 20, 
        randomize: true, 
        connect_timeout: 60, 
        logger: logger, 
        ssl_post_conn_check: false,
        connect_headers: { host: MAPI::Shared::EnterpriseMessaging::HOSTNAME, 
                                 'accept-version': '1.0', 
                                 'client_id': MAPI::Shared::EnterpriseMessaging::CLIENT_ID }})
      call_method
    end
    it 'creates an ssl config object' do
      allow(Stomp::Client).to receive(:new).and_return(stomp_client)
      expect(Stomp::SSLParams).to receive(:new).with(cert_file: MAPI::Shared::EnterpriseMessaging::CERT_FILE, 
                                                     key_file: MAPI::Shared::EnterpriseMessaging::KEY_FILE, 
                                                     ts_files: MAPI::Shared::EnterpriseMessaging::TS_FILES)
      call_method
    end
  end
end