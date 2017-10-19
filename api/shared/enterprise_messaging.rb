require 'stomp'

module MAPI
  module Shared
    module EnterpriseMessaging
      HOSTNAME = 'SFDWMSGBROKER1.fhlbsf-i.com'
      CONFIG_DIR = 'config/ssl'
      CERT_FILE = "#{CONFIG_DIR}/client.crt"
      KEY_FILE = "#{CONFIG_DIR}/client.key"
      TS_FILES = "#{CONFIG_DIR}/msgbroker1.pem"
      PORT = 51515
      SLEEP_INTERVAL = 0.5
      NUM_RETRIES = 10
      CLIENT_ID = 'MemberPortal'
      FQ_QUEUE = '/queue/mcufu.ix'
      TOPIC = 'ix.portal'
      FQ_TOPIC = "/topic/#{TOPIC}"

      extend ActiveSupport::Concern

      module ClassMethods
        def get_message(app, message, member_id = nil, headers = {})
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
          client.publish("#{FQ_QUEUE}?replyTo=#{TOPIC}", '', { 'correlation-id': correlation_id, 'CMD': message }.merge(headers))
          NUM_RETRIES.times do
            return JSON.parse(@response.body) unless @response.nil?
            sleep SLEEP_INTERVAL
          end
          raise 'No response received from message bus'
        end

        def stomp_client(app)
          ssl_config = Stomp::SSLParams.new(cert_file: CERT_FILE, key_file: KEY_FILE, ts_files: TS_FILES)
          #TODO configure failover onto SFDWMSGBROKER2
          @stomp_client ||= Stomp::Client.new( { hosts: [ { host: HOSTNAME, port: PORT, ssl: ssl_config } ], 
                                                 reliable: true, 
                                                 max_reconnect_attempts: 20, 
                                                 randomize: true, 
                                                 connect_timeout: 60, 
                                                 logger: app.logger, 
                                                 ssl_post_conn_check: false,
                                                 connect_headers: { host: HOSTNAME, 
                                                                    'accept-version': '1.0', 
                                                                    'client_id': CLIENT_ID }})
        end
      end
    end
  end
end