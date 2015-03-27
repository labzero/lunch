require 'date'
require 'savon'
require 'active_support/core_ext/hash/indifferent_access'
require_relative 'rates/price_indication_historical'

module MAPI
  module Services
    module Rates
      include MAPI::Services::Base
      include MAPI::Shared::Constants
      
      COLLATERAL_TYPES = [:standard, :sbc]
      COLLATERAL_MAPPING = {
          standard: 'REGULAR',
          sbc: 'CREDIT'
      }.with_indifferent_access

      CURRENT_CREDIT_TYPES = [:vrc, :frc, :arc]
      CURRENT_CREDIT_MAPPING = {
          vrc: 'VARIABLES',
          frc: 'FIXED',
          arc: 'ADJUSTABLES'
      }.with_indifferent_access

      LOAN_TYPES = [:whole, :agency, :aaa, :aa]
      LOAN_TERMS = [:overnight, :open, :'1week', :'2week', :'3week', :'1month', :'2month', :'3month', :'6month', :'1year', :'2year', :'3year']
      LOAN_MAPPING = {
        whole: 'FRC_WL',
        agency: 'FRC_AGCY',
        aaa: 'FRC_AAA',
        aa: 'FRC_AA'
      }.with_indifferent_access

      TERM_MAPPING = {
          :overnight => {
              frequency: '1',
              frequency_unit: 'D',
          },
        :open => {
            frequency: '1',
            frequency_unit: 'D'
        },
        :'1week'=> {
            frequency: '1',
            frequency_unit: 'W'
        },
        :'2week'=> {
            frequency: '2',
            frequency_unit: 'W'
        },
        :'3week'=> {
            frequency: '3',
            frequency_unit: 'W'
        },
        :'1month'=> {
            frequency: '1',
            frequency_unit: 'M'
        },
        :'2month'=> {
            frequency: '2',
            frequency_unit: 'M'
        },
        :'3month'=> {
            frequency: '3',
            frequency_unit: 'M'
        },
        :'6month'=> {
            frequency: '6',
            frequency_unit: 'M'
        },
        :'1year'=> {
            frequency: '1',
            frequency_unit: 'Y'
        },
        :'2year'=> {
            frequency: '2',
            frequency_unit: 'Y'
        },
        :'3year'=> {
            frequency: '3',
            frequency_unit: 'Y'
        }
      }.with_indifferent_access

      def self.is_weekend_or_holiday (maturity_date)
        (@@holidays.include?(maturity_date.strftime('%F')) || maturity_date.saturday? || maturity_date.sunday?) ? true : false
      end

      def self.get_maturity_date (original_maturity_date, frequency_unit)
        original_maturity_date = original_maturity_date.to_date
        maturity_date = original_maturity_date
        while MAPI::Services::Rates.is_weekend_or_holiday(maturity_date)
          maturity_date = maturity_date + 1.day
        end
        if (frequency_unit == 'M' || frequency_unit == 'Y')
          if (maturity_date > original_maturity_date.end_of_month)
            maturity_date =  original_maturity_date.end_of_month
            while MAPI::Services::Rates.is_weekend_or_holiday(maturity_date)
              maturity_date = maturity_date - 1.day
            end
          end
        end
        maturity_date
      end

      def self.init_mds_connection(environment)
        if environment == :production
          @@mds_connection ||= Savon.client(
              wsdl: ENV['MAPI_MDS_ENDPOINT'],
              env_namespace: :soapenv,
              namespaces: { 'xmlns:v1' => 'http://fhlbsf.com/schema/msg/marketdata/v1', 'xmlns:wsse' => 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd', 'xmlns:v11' => 'http://fhlbsf.com/schema/canonical/common/v1', 'xmlns:v12' => 'http://fhlbsf.com/schema/canonical/marketdata/v1', 'xmlns:v13' => 'http://fhlbsf.com/schema/canonical/shared/v1'},
              element_form_default: :qualified,
              namespace_identifier: :v1,
              pretty_print_xml: true
          )
        else
          @@mds_connection = nil
        end
      end

      def self.init_cal_connection(environment)
        if environment == :production
          @@cal_connection ||= Savon.client(
              wsdl: ENV['MAPI_CALENDAR_ENDPOINT'],
              env_namespace: :soapenv,
              namespaces: { 'xmlns:v1' => 'http://fhlbsf.com/schema/msg/businessCalendar/v1', 'xmlns:wsse' => 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd', 'xmlns:v11' => 'http://fhlbsf.com/schema/canonical/common/v1'},
              element_form_default: :qualified,
              namespace_identifier: :v1,
              pretty_print_xml: true
          )
        else
          @@cal_connection = nil
        end
      end

      def self.init_pi_connection(environment)
        if environment == :production
          @@pi_connection ||= Savon.client(
              wsdl: ENV['MAPI_MDS_ENDPOINT'],
              env_namespace: :soapenv,
              namespaces: { 'xmlns:v1' => 'http://fhlbsf.com/reports/msg/v1', 'xmlns:wsse' => 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd', 'xmlns:v11' => 'http://fhlbsf.com/reports/contract/v1'},
              element_form_default: :qualified,
              namespace_identifier: :v1,
              pretty_print_xml: true
          )
        else
          @@pi_connection = nil
        end
      end

      def self.registered(app)
        service_root '/rates', app
        swagger_api_root :rates do
          api do
            key :path, "/price_indications/current/vrc/{collateral}"
            operation do
              key :method, 'GET'
              key :summary, 'Retrieve current price indications for vrc products'
              key :notes, 'Returns current price indications based on vrc and collateral inputs'
              key :type, :CurrentPriceIndicationsVrc
              key :nickname, :CurrentPriceIndicationsVrc
              parameter do
                key :paramType, :path
                key :name, :collateral
                key :required, true
                key :type, :string
                key :enum, COLLATERAL_TYPES
                key :description, 'The type of collateral used.'
              end
              response_message do
                key :code, 200
                key :message, 'OK'
              end
            end
          end

          api do
            key :path, "/price_indications/current/frc/{collateral}"
            operation do
              key :method, 'GET'
              key :summary, 'Retrieve current price indications for frc products'
              key :notes, 'Returns current price indications based on frc and collateral inputs'
              key :type, :CurrentPriceIndicationsFrc
              key :nickname, :CurrentPriceIndicationsFrc
              parameter do
                key :paramType, :path
                key :name, :collateral
                key :required, true
                key :type, :string
                key :enum, COLLATERAL_TYPES
                key :description, 'The type of collateral used.'
              end
              response_message do
                key :code, 200
                key :message, 'OK'
              end
            end
          end

          api do
            key :path, "/price_indications/current/arc/{collateral}"
            operation do
              key :method, 'GET'
              key :summary, 'Retrieve current price indications for arc products'
              key :notes, 'Returns current price indications based on arc and collateral inputs'
              key :type, :CurrentPriceIndicationsArc
              key :nickname, :CurrentPriceIndicationsArc
              parameter do
                key :paramType, :path
                key :name, :collateral
                key :required, true
                key :type, :string
                key :enum, COLLATERAL_TYPES
                key :description, 'The type of collateral used.'
              end
              response_message do
                key :code, 200
                key :message, 'OK'
              end
            end
          end

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
              key :notes, 'Returns an object containing rate data for each loan term of a given loan type, as well as a timestamp to indicate when the rates were fetched'
              key :type, :SummaryRates
              key :nickname, :SummaryRates
              response_message do
                key :code, 200
                key :message, 'OK'
              end
            end
          end

          # Price Indication Historical rates for VRC, FRC, ARC
          api do
            key :path, '/price_indication/historical/{start_date}/{end_date}/{collateral_type}/{credit_type}'
            operation do
              key :method, 'GET'
              key :summary, 'Retrieve historical price indication rates for the selected date range for the specified collateral/credit type.'
              key :notes, 'Returns an object containing rate data for each collateral, credit type by dates and term'
              key :type, :PriceIndicationHistorical
              key :nickname, :PriceIndicationHistorical
              parameter do
                key :paramType, :path
                key :name, :start_date
                key :required, true
                key :type, :string
                key :description, 'Start date yyyy-mm-dd for the Price Indication historical rates.'
              end
              parameter do
                key :paramType, :path
                key :name, :end_date
                key :required, true
                key :type, :string
                key :description, 'End date yyyy-mm-dd for the Price Indication historical rates.'
              end
              parameter do
                key :paramType, :path
                key :name, :collateral_type
                key :required, true
                key :type, :string
                key :description, 'Collateral Type i.e. standard, sbc  Price Indication historical rates.'
              end
              parameter do
                key :paramType, :path
                key :name, :credit_type
                key :required, true
                key :type, :string
                key :description, 'Credit Type for the specified collateral type e.g. vrc, frc, 1m_libor ect.'
              end
              response_message do
                key :code, 200
                key :message, 'OK'
              end
              response_message do
                key :code, 400
                key :message, 'Invalid input'
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

        relative_get "/price_indications/current/vrc/:collateral" do
          if !COLLATERAL_MAPPING[params[:collateral]]
            halt 404, 'Collateral Not Found'
          end

          data = if MAPI::Services::Rates.init_pi_connection(settings.environment)
            @@pi_connection.operations
            message = {
              'v1:productType' => CURRENT_CREDIT_MAPPING['vrc'],
              'v1:subProductType' => COLLATERAL_MAPPING[params[:collateral]]
            }
            begin
              response = @@pi_connection.call(:get_pricing_indications, message_tag: 'pricingIndicationsRequest', message: message, :soap_header => {'wsse:Security' => {'wsse:UsernameToken' => {'wsse:Username' => ENV['MAPI_FHLBSF_ACCOUNT'], 'wsse:Password' => ENV['SOAP_SECRET_KEY']}}} )
            rescue Savon::Error => error
              logger.error error
              halt 503, 'Internal Service Error'
            end
            response.doc.remove_namespaces!
            fhlbsfresponse = response.doc.xpath('//Envelope//Body//pricingIndicationsResponse//response//Items//FhlbsfReportDataBlock//Data//FhlbsfReportData')
            fhlbsfdatapoints = fhlbsfresponse[3].css('Table Rows TableRow Cells TableCell')
            hash = {
              'advance_maturity' => fhlbsfdatapoints[0].at_css('Text').content,
              'overnight_fed_funds_benchmark' => fhlbsfdatapoints[1].at_css('Text').content,
              'basis_point_spread_to_benchmark' => fhlbsfdatapoints[2].at_css('Text').content,
              'advance_rate' => fhlbsfdatapoints[3].at_css('Text').content
            }
            hash
          else
            hash = JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'rates_current_price_indications_vrc.json'))).with_indifferent_access
            hash
          end
          hash = {
            'advance_maturity' => data['advance_maturity'].to_s,
            'overnight_fed_funds_benchmark' => data['overnight_fed_funds_benchmark'].to_f,
            'basis_point_spread_to_benchmark' => data['basis_point_spread_to_benchmark'].to_i,
            'advance_rate' => data['advance_rate'].to_f
          }
          hash.to_json
        end

        relative_get "/price_indications/current/frc/:collateral" do
          if !COLLATERAL_MAPPING[params[:collateral]]
            halt 404, 'Collateral Not Found'
          end

          data = if MAPI::Services::Rates.init_pi_connection(settings.environment)
            @@pi_connection.operations
            message = {
              'v1:productType' => CURRENT_CREDIT_MAPPING['frc'],
              'v1:subProductType' => COLLATERAL_MAPPING[params[:collateral]]
            }
            begin
              response = @@pi_connection.call(:get_pricing_indications, message_tag: 'pricingIndicationsRequest', message: message, :soap_header => {'wsse:Security' => {'wsse:UsernameToken' => {'wsse:Username' => ENV['MAPI_FHLBSF_ACCOUNT'], 'wsse:Password' => ENV['SOAP_SECRET_KEY']}}} )
            rescue Savon::Error => error
              logger.error error
              halt 503, 'Internal Service Error'
            end
            response.doc.remove_namespaces!
            fhlbsfresponse = response.doc.xpath('//Envelope//Body//pricingIndicationsResponse//response//Items//FhlbsfReportDataBlock//Data//FhlbsfReportData')
            fhlbsfdatapoints = fhlbsfresponse[3].css('Table Rows TableRow Cells')
            hash = fhlbsfdatapoints.collect do |fhlbsfdatapoint|
              result = fhlbsfdatapoint.css('TableCell')
              {
                'advance_maturity' => result[0].at_css('Text').content,
                'treasury_benchmark_maturity' => result[1].at_css('Text').content,
                'nominal_yield_of_benchmark' => result[2].at_css('Text').content,
                'basis_point_spread_to_benchmark' => result[3].at_css('Text').content,
                'advance_rate' => result[4].at_css('Text').content
              }
            end
            hash
          else
            hash = JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'rates_current_price_indications_frc.json')))
            hash
          end
          data_formatted = []
          data.each do |row|
            hash = {
              'advance_maturity' => row['advance_maturity'].to_s,
              'treasury_benchmark_maturity' => row['treasury_benchmark_maturity'].to_s,
              'nominal_yield_of_benchmark' => row['nominal_yield_of_benchmark'].to_f,
              'basis_point_spread_to_benchmark' => row['basis_point_spread_to_benchmark'].to_i,
              'advance_rate' => row['advance_rate'].to_f
            }
            data_formatted.push(hash)
          end
          data_formatted.to_json
        end

        relative_get "/price_indications/current/arc/:collateral" do
          if !COLLATERAL_MAPPING[params[:collateral]]
            halt 404, 'Collateral Not Found'
          end

          data = if MAPI::Services::Rates.init_pi_connection(settings.environment)
            @@pi_connection.operations
            message = {
              'v1:productType' => CURRENT_CREDIT_MAPPING['arc'],
              'v1:subProductType' => COLLATERAL_MAPPING[params[:collateral]]
            }
            begin
              response = @@pi_connection.call(:get_pricing_indications, message_tag: 'pricingIndicationsRequest', message: message, :soap_header => {'wsse:Security' => {'wsse:UsernameToken' => {'wsse:Username' => ENV['MAPI_FHLBSF_ACCOUNT'], 'wsse:Password' => ENV['SOAP_SECRET_KEY']}}} )
            rescue Savon::Error => error
              logger.error error
              halt 503, 'Internal Service Error'
            end
            response.doc.remove_namespaces!
            fhlbsfresponse = response.doc.xpath('//Envelope//Body//pricingIndicationsResponse//response//Items//FhlbsfReportDataBlock//Data//FhlbsfReportData')
            fhlbsfdatapoints = fhlbsfresponse[3].css('Table Rows TableRow Cells')
            hash = fhlbsfdatapoints.collect do |fhlbsfdatapoint|
              result = fhlbsfdatapoint.css('TableCell')
              {
                'advance_maturity' =>   result[0].at_css('Text').content,
                '1_month_libor' =>  result[1].at_css('Text').content,
                '3_month_libor' =>  result[2].at_css('Text').content,
                '6_month_libor' =>  result[3].at_css('Text').content,
                'prime' =>  result[4].at_css('Text').content
              }
            end
            hash
          else
            hash = JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'rates_current_price_indications_arc.json')))
            hash
          end
          data_formatted = []
          data.each do |row|
            hash = {
                'advance_maturity' => row['advance_maturity'].to_s,
                '1_month_libor' => row['1_month_libor'].to_i,
                '3_month_libor' => row['3_month_libor'].to_i,
                '6_month_libor' => row['6_month_libor'].to_i,
                'prime' => row['prime'].to_i
            }
            data_formatted.push(hash)
          end
          data_formatted.to_json
        end

        relative_get "/:loan/:term" do
          if !LOAN_MAPPING[params[:loan]]
            halt 404, 'Loan Not Found'
          end
          if !TERM_MAPPING[params[:term]]
            halt 404, 'Term Not Found'
          end

          data = if MAPI::Services::Rates.init_mds_connection(settings.environment)
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
            response = @@mds_connection.call(:get_market_data, message_tag: 'marketDataRequest', message: message, :soap_header => {'wsse:Security' => {'wsse:UsernameToken' => {'wsse:Username' => ENV['MAPI_FHLBSF_ACCOUNT'], 'wsse:Password' => ENV['SOAP_SECRET_KEY']}}} )
            namespaces = {'a' => 'http://fhlbsf.com/schema/canonical/marketdata/v1', 'xmlns' => 'http://fhlbsf.com/schema/msg/marketdata/v1'}
            if response.success? && response.doc.search('//xmlns:transactionResult', namespaces).text != 'Error'
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
          MAPI::Services::Rates.init_cal_connection(settings.environment)
          if @@cal_connection
            message = {'v1:endDate' => Date.today + 3.years, 'v1:startDate' => Date.today}
            begin
              response = @@cal_connection.call(:get_holiday, message_tag: 'holidayRequest', message: message, :soap_header => {'wsse:Security' => {'wsse:UsernameToken' => {'wsse:Username' => ENV['MAPI_FHLBSF_ACCOUNT'], 'wsse:Password' => ENV['SOAP_SECRET_KEY']}}})
            rescue Savon::Error => error
              logger.error error
              halt 503, 'Internal Service Error'
            end
            response.doc.remove_namespaces!
            @@holidays = response.doc.xpath('//Envelope//Body//holidayResponse//holidays//businessCenters')[0].css('days day date').map do |holiday|
              Date.parse(holiday.content)
            end
          else
            @@holidays = JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'calendar_holidays.json')))
          end

          MAPI::Services::Rates.init_mds_connection(settings.environment)
          data = if @@mds_connection
            request = LOAN_TYPES.collect do |type|
            {
              'v1:caller' => [{'v11:id' => ENV['MAPI_FHLBSF_ACCOUNT']}],
              'v1:marketData' => [{
                'v12:name' => LOAN_MAPPING[type.to_s],
                'v12:pricingGroup' => [{'v12:id' => 'Live'}],
                'v12:data' => ''
              }]
            }
            end
            message = {
              'v11:caller' => [{ 'v11:id' => ENV['MAPI_COF_ACCOUNT']}],
              'v1:requests' =>  [{'v1:fhlbsfMarketDataRequest' => request}]
            }
            begin
              response = @@mds_connection.call(:get_market_data, message_tag: 'marketDataRequest', message: message, :soap_header => {'wsse:Security' => {'wsse:UsernameToken' => {'wsse:Username' => ENV['MAPI_FHLBSF_ACCOUNT'], 'wsse:Password' => ENV['SOAP_SECRET_KEY']}}} )
            rescue Savon::Error => error
              logger.error error
              halt 503, 'Internal Service Error'
            end
            hash = {}
            response.doc.remove_namespaces!
            fhlbsfresponse = response.doc.xpath('//Envelope//Body//marketDataResponse//responses//fhlbsfMarketDataResponse')
            LOAN_TYPES.each_with_index do |type, ctr_type|
              hash[type] ||= {}
              fhlbsfdatapoints = fhlbsfresponse[ctr_type].css('marketData FhlbsfMarketData data FhlbsfDataPoint')
              LOAN_TERMS.each_with_index do |term, ctr_term|
                if ctr_term == 0
                  ctr_term = 1
                end
                hash[type][term] = {
                  'payment_on' => 'Maturity',
                  'interest_day_count' => fhlbsfresponse[ctr_type].at_css('marketData FhlbsfMarketData dayCountBasis').content,
                  'rate' => fhlbsfdatapoints[ctr_term-1].at_css('value').content,
                  'maturity_date' => MAPI::Services::Rates.get_maturity_date(Date.parse(fhlbsfdatapoints[ctr_term-1].at_css('tenor maturityDate').content), TERM_MAPPING[term][:frequency_unit])
                }
              end
            end
            hash['timestamp'] = Time.now
            hash
          else
            # We have no real data source yet.
            hash = JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'rates_summary.json'))).with_indifferent_access
            now = Time.now
            # The maturity_date property might end up being calculated in the service object and not here. TBD once we know more.
            LOAN_TYPES.each do |type|
              LOAN_TERMS.each do |term|
                hash[type][term][:maturity_date] = MAPI::Services::Rates.get_maturity_date(DateTime.parse((Time.mktime(now.year, now.month, now.day, now.hour, now.min) + hash[type][term][:days_to_maturity].to_i.days).to_s), TERM_MAPPING[term][:frequency_unit])
              end
            end
            hash[:timestamp] = now
            hash
          end
          data.to_json
        end


        # Price Indication Historical rates for VRC, FRC, ARC
        relative_get "/price_indication/historical/:start_date/:end_date/:collateral_type/:credit_type" do
          MAPI::Services::Rates.init_cal_connection(settings.environment)
          start_date = params[:start_date].to_date
          end_date = params[:end_date].to_date
          collateral_type = params[:collateral_type].to_sym
          credit_type = params[:credit_type].to_sym
          halt 400, 'Invalid Date format of yyyy-mm-dd or date range' if start_date.to_date > end_date.to_date
          if !MAPI::Services::Rates::PriceIndicationHistorical::IRDB_CODE_TERM_MAPPING[collateral_type]
            halt 400, "Invalid Collateral type"
          elsif !MAPI::Services::Rates::PriceIndicationHistorical::IRDB_CODE_TERM_MAPPING[collateral_type][credit_type]
            halt 400, "Invalid Credit type"
          else
            result = MAPI::Services::Rates::PriceIndicationHistorical.price_indication_historical(self, start_date, end_date, collateral_type, credit_type)
            result.to_json
          end
        end
      end
    end
  end
end