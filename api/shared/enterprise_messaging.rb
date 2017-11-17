require 'stomp'

module MAPI
  module Shared
    module EnterpriseMessaging
      MESSAGE_BROKER_HOSTNAME = 'msgbroker1.fhlbsf-i.com'
      CONFIG_DIR = 'config/ssl'
      CERT_FILE = "#{CONFIG_DIR}/client.crt"
      KEY_FILE = "#{CONFIG_DIR}/client.key"
      TS_FILES = "#{CONFIG_DIR}/msgbroker1.pem"
      PORT = 51515
      SLEEP_INTERVAL = 0.5
      NUM_RETRIES = 20
      CLIENT_ID = 'MemberPortal'
      FQ_QUEUE = '/queue/mcufu.ix'
      TOPIC = 'ix.portal'
      FQ_TOPIC = "/topic/#{TOPIC}"
      REPLY_TO = "topic://#{TOPIC}"

      extend ActiveSupport::Concern

      module ClassMethods
        def get_message(app, message, member_id = nil, publish_headers = {})
          @response = nil
          correlation_id = SecureRandom.hex
          client = stomp_client(app)
          begin
            client.subscribe(FQ_TOPIC, { 'correlation-id': correlation_id, 'client-id': CLIENT_ID }) do |msg|
              @response = msg
            end
          rescue Stomp::Error::DuplicateSubscription
            #ignore
          end
          default_headers = { 'JMSReplyTo': REPLY_TO, 'correlation-id': correlation_id }
          default_headers[:CMD] = message if message.present?
          client.publish("#{FQ_QUEUE}", '', default_headers.merge(publish_headers))
          NUM_RETRIES.times do
            unless @response.nil?
              body = begin
                JSON.parse(@response.body)
              rescue JSON::ParserError
                @response.body
              end
              return { body: body, headers: @response.headers }
            end
            sleep SLEEP_INTERVAL
          end
          raise 'No response received from message bus'
        end

        def post_message(app, message, publish_headers = {})
          stomp_client(app).publish(FQ_QUEUE, '', { 'JMSReplyTo': REPLY_TO, 'CMD': message }.merge(publish_headers))
        end

        def stomp_client(app)
          ssl_config = Stomp::SSLParams.new(cert_file: CERT_FILE, key_file: KEY_FILE, ts_files: TS_FILES)
          #TODO configure failover onto SFDWMSGBROKER2?
          @stomp_client ||= Stomp::Client.new( { hosts: [ { host: MESSAGE_BROKER_HOSTNAME, port: PORT, ssl: ssl_config } ], 
                                                 reliable: true, 
                                                 max_reconnect_attempts: 20, 
                                                 randomize: true, 
                                                 connect_timeout: 60, 
                                                 ssl_post_conn_check: false,
                                                 connect_headers: { host: MESSAGE_BROKER_HOSTNAME, 
                                                                    'accept-version': '1.0', 
                                                                    'client_id': CLIENT_ID }})
        end
      end
    end
  end
end