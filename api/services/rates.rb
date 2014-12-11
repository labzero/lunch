require 'date'
require 'savon'
require 'active_support/core_ext/hash/indifferent_access'

module MAPI
  module Services
    module Rates
      include MAPI::Services::Base
      LOAN_TYPES = [:whole, :agency, :aaa, :aa]
      LOAN_TERMS = [:overnight, :open, :'1week', :'2week', :'3week', :'1month', :'2month', :'3month', :'6month', :'1year', :'2year', :'3year']

      LOAN_MAPPING = {
        whole: 'FRC_WL'
      }.with_indifferent_access

      TERM_MAPPING = {
        overnight: {
          frequency: '1',
          frequency_unit: 'D',
        }
      }.with_indifferent_access

      def self.registered(app)
        if app.environment == :production
          @@mds_connection = Savon.client(
              wsdl: 'http://appservices/MarketDataServicesNoAuth/MarketDataService.svc?wsdl',
              env_namespace: :soapenv,
              namespaces: { 'xmlns:v1' => 'http://fhlbsf.com/schema/msg/marketdata/v1', 'xmlns:v11' => 'http://fhlbsf.com/schema/canonical/common/v1', 'xmlns:v12' => 'http://fhlbsf.com/schema/canonical/marketdata/v1', 'xmlns:v13' => 'http://fhlbsf.com/schema/canonical/shared/v1'},
              element_form_default: :qualified,
              namespace_identifier: :v1,
              pretty_print_xml: true
          )
        else
          @@mds_connection = nil
        end


        service_root '/rates', app
        swagger_api_root :rates do
          api do
            key :path, "/historic/overnight"
            operation do
              key :method, 'GET'
              key :summary, 'Retrieve historic overnight rates'
              key :notes, 'Returns a list of the opening overnight rates'
              key :type, :HistoricRate
              key :nickname, :historicOvernightVRCRate
              parameter do
                key :paramType, :query
                key :name, :limit
                key :required, false
                key :type, :integer
                key :defaultValue, 30
                key :minimum, 0
                key :maximum, 30
                key :description, 'How many rates to return. Default is 30.'
              end
              response_message do
                key :code, 200
                key :message, 'OK'
              end
            end
          end

          api do
            key :path, "/{loan}/{term}"
            operation do
              key :method, 'GET'
              key :summary, 'Retrieve current rates for a given loan type and term.'
              key :notes, 'Returns the current rate and the time at which it was considered current.'
              key :type, :RealtimeRate
              key :nickname, :currentRates
              parameter do
                key :paramType, :path
                key :name, :loan
                key :required, true
                key :type, :string
                key :enum, LOAN_TYPES
                key :description, 'The type of loan. Describes the collateral behind the loan.'
              end
              parameter do
                key :paramType, :path
                key :name, :term
                key :required, true
                key :type, :string
                key :enum, LOAN_TERMS
                key :description, 'The term of the loan.'
              end
              response_message do
                key :code, 200
                key :message, 'OK'
              end
              response_message do
                key :code, 404
                key :message, 'Term Not Found'
              end
              response_message do
                key :code, 404
                key :message, 'Loan Not Found'
              end
            end
          end

          # This is ambiguous right now as we wait to see what we can get back from Calypso in a single request.
          # We'll probably pull all the rates we can get (assuming no performance hit) and handle the logic of which we
          # want to show in app/services/rates_service.rb
          api do
            key :path, "/summary"
            operation do
              key :method, 'GET'
              key :summary, 'Retrieve current rates for standard loan types and terms.'
              key :notes, 'Returns an object containing rate data for each loan type of a given term, as well as a timestamp to indicate when the rates were fetched'
              key :type, :SummaryRates
              key :nickname, :SummaryRates
              response_message do
                key :code, 200
                key :message, 'OK'
              end
            end
          end
        end

        relative_get "/historic/overnight" do
          days = (params[:limit] || 30).to_i
          connection_string = <<-SQL
              SELECT * FROM (SELECT TRX_EFFECTIVE_DATE, TRX_VALUE
              FROM IRDB.IRDB_TRANS T
              WHERE TRX_IR_CODE = 'FRADVN'
              AND (TRX_TERM_VALUE || TRX_TERM_UOM  = '1D' )
              ORDER BY TRX_EFFECTIVE_DATE DESC) WHERE ROWNUM <= #{days}
          SQL

          data = if settings.environment == :production
            cursor = ActiveRecord::Base.connection.execute(connection_string)
            rows = []
            while row = cursor.fetch()
              rows.push([row[0], row[1]])
            end
            rows
          else
            rows = JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'rates_historic_overnight.json')))[0..(days - 1)]
            rows.collect do |row|
              [Date.parse(row[0]), row[1]]
            end
          end

          data.reverse!.collect! do |row|
            [row[0].to_date, row[1].to_f]
          end

          data.to_json
        end

        relative_get "/:loan/:term" do
          if params[:loan] != 'whole'
            halt 404, 'Loan Not Found'
          end
          if params[:term] != 'overnight'
            halt 404, 'Term Not Found'
          end
          data = if @@mds_connection
            @@mds_connection.operations
            lookup_term = TERM_MAPPING[params[:term]]
            message = {
              'v11:caller' => [{ 'v11:id' => ENV['MAPI_COF_ACCOUNT']}],
                'v1:requests' => [{
                  'v1:fhlbsfMarketDataRequest' => [{
                    'v1:caller' => [{'v11:id' => ENV['MAPI_FHLBSF_ACCOUNT']}],
                    'v1:marketData' =>  [{
                      'v12:customRollingDay' => '0',
                      'v12:name' => LOAN_MAPPING[params[:loan]],
                      'v12:pricingGroup' => [{'v12:id' => 'Live'}],
                      'v12:data' => [{
                        'v12:FhlbsfDataPoint' => [{
                        'v12:tenor' => [{
                          'v12:interval' => [{
                            'v13:frequency' => lookup_term[:frequency],
                            'v13:frequencyUnit' => lookup_term[:frequency_unit]
                          }]
                        }]
                      }]
                    }]
                  }]
                }]
              }]
            }
            response = @@mds_connection.call(:get_market_data, message_tag: 'marketDataRequest', message: message )
            namespaces = {'a' => 'http://fhlbsf.com/schema/canonical/marketdata/v1', 'xmlns' => 'http://fhlbsf.com/schema/msg/marketdata/v1'}
            if response.success? && response.doc.search('//xmlns:transactionResult', namespaces).text != 'Error'
              # @name = response.doc.search('//a:name', namespaces).text
              # @pricingenv = pricingenv
              # @snaptime = response.doc.search('//a:snapTime', namespaces).text
              # @rate = response.doc.search('//a:value', namespaces).text
              {rate: response.doc.search('//a:value', namespaces).text.to_f, updated_at: DateTime.parse(response.doc.search('//a:snapTime', namespaces).text).to_time}
            else
              halt 503, 'Service Unavailable'
            end
          else
            # We have no real data source yet.
            rows = JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'rates_current_overnight.json')))
            rate = rows.sample
            now = Time.now
            {rate: rate, updated_at: Time.mktime(now.year, now.month, now.day, now.hour, now.min).to_s}
          end

          data.to_json
        end

        relative_get "/summary" do
          # We have no real data source yet and are not yet aware of the format in which we'll get data back. We know for
          # sure we'll need to hit the CDB when calculating maturity date (to account for weekends, holidays and other checks).
          hash = JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'rates_summary.json'))).with_indifferent_access
          now = Time.now
          # The maturity_date property might end up being calculated in the service object and not here. TBD once we know more.
          LOAN_TERMS.each do |term|
            hash[term][:maturity_date] = (Time.mktime(now.year, now.month, now.day, now.hour, now.min) + hash[term][:days_to_maturity].days).to_s
          end
          hash.to_json
        end
      end
    end
  end
end