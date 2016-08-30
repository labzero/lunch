module MAPI
  module Services
    module Health
      include MAPI::Services::Base

      SOAP_OPEN_TIMEOUT = 0.2 # seconds
      SOAP_READ_TIMEOUT = 5 # seconds

      def self.ping_cal_service(environment)
        cal_status = false
        cal_connection = MAPI::Services::Rates.init_cal_connection(environment, false)
        if cal_connection
          message = {'v1:endDate' => '1991-01-01'}
          begin
            add_soap_timeouts(cal_connection)
            response = cal_connection.call(:get_holiday, message_tag: 'holidayRequest', message: message, :soap_header => MAPI::Services::Rates::SOAP_HEADER)
            response.doc.remove_namespaces!
            nodes = response.doc.xpath('//Envelope//Body//holidayResponse//transactionResult')
            cal_status = nodes[0].text == 'Success' if nodes.count > 0
          rescue Savon::Error => error
            cal_status = false
          end
        end
        cal_status
      end

      def self.ping_pi_service(environment)
        pi_status = false
        pi_connection = MAPI::Services::Rates.init_pi_connection(environment, false)
        if pi_connection
          begin
            add_soap_timeouts(pi_connection)
            response = pi_connection.call(:get_pricing_indications, message_tag: 'pricingIndicationsRequest', message: {}, :soap_header => MAPI::Services::Rates::SOAP_HEADER )
            response.doc.remove_namespaces!
            pi_status = response.doc.xpath('//Envelope//Body//pricingIndicationsResponse//response//Items').count > 0
          rescue Savon::Error => error
            pi_status = false
          end
        end
        pi_status
      end

      def self.ping_mds_service(environment)
        mds_status = false
        mds_connection = MAPI::Services::Rates.init_mds_connection(environment, false)
        if mds_connection
          message = {
            'v11:caller' => [{ 'v11:id' => ENV['MAPI_COF_ACCOUNT']}],
              'v1:requests' => [{
                'v1:fhlbsfMarketDataRequest' => [{
                  'v1:caller' => [{'v11:id' => ENV['MAPI_FHLBSF_ACCOUNT']}],
                  'v1:marketData' =>  [{
                    'v12:name' => 'FRC_WL',
                    'v12:pricingGroup' => [{
                      'v12:id' => 'StartOfDay',
                      'v12:groupDateTime' => Time.zone.now.iso8601
                    }],
                    'v12:data' => [{}]
                }]
              }]
            }]
          }
          begin
            add_soap_timeouts(mds_connection)
            response = mds_connection.call(:get_market_data, message_tag: 'marketDataRequest', message: message, :soap_header => MAPI::Services::Rates::SOAP_HEADER )
            response.doc.remove_namespaces!
            mds_status = response.doc.xpath('//fhlbsfMarketDataResponse').count > 0
          rescue Savon::Error => error
            mds_status = false
          end
        end
        mds_status
      end

      def self.add_soap_timeouts(connection)
        raise ArgumentError.new('connection can\'t be nil') if connection.nil?
        connection.globals[:open_timeout] = SOAP_OPEN_TIMEOUT
        connection.globals[:read_timeout] = SOAP_READ_TIMEOUT
      end

      def self.registered(app)
        service_root '/healthy', app
        swagger_api_root :healthy do
          api do
            key :path, ''
            operation do
              key :method, 'GET'
              key :summary, 'Returns reachability status of services consumed by MAPI'
              key :type, :object
              key :nickname, :healthy
            end
          end
        end

        relative_get '' do
          begin
            cdb_status = ActiveRecord::Base.connection.active?
          rescue Exception => e
            logger.error "CDB PING failed: #{e.message}"
            cdb_status = false
          end

          begin
            mds_status = MAPI::Services::Health.ping_mds_service(settings.environment)
          rescue Exception => e
            logger.error "MDS PING failed: #{e.message}"
            mds_status = false
          end

          begin
            cal_status = MAPI::Services::Health.ping_cal_service(settings.environment)
          rescue Exception => e
            logger.error "CAL PING failed: #{e.message}"
            cal_status = false
          end

          begin
            pi_status = MAPI::Services::Health.ping_pi_service(settings.environment)
          rescue Exception => e
            logger.error "PI PING failed: #{e.message}"
            pi_status = false
          end

          {
            aunty: mds_status, # MDS
            waterseller: cal_status, # CAL
            pigs: pi_status, # PI
            thunderdome: cdb_status # CDB
          }.to_json
        end
      end
    end
  end
end