require 'date'
require 'savon'
require 'active_support/core_ext/hash/indifferent_access'

module MAPI
  module Services
    module Rates
      include MAPI::Services::Base
      include MAPI::Shared::Constants
      include MAPI::Shared::Utils

      def self.holiday?(date, holidays)
        holidays.include?(date.strftime('%F'))
      end

      def self.weekend_or_holiday?(date, holidays)
        date.saturday? || date.sunday? || holiday?(date, holidays)
      end

      def self.find_nearest_business_day(original, frequency_unit, holidays)
        candidate = original.to_date
        while MAPI::Services::Rates.weekend_or_holiday?(candidate, holidays)
          candidate += 1.day
        end
        if (frequency_unit == 'M' || frequency_unit == 'Y')
          end_of_month = original.to_date.end_of_month
          if (candidate > end_of_month)
            candidate = end_of_month
            while MAPI::Services::Rates.weekend_or_holiday?(candidate, holidays)
              candidate -= 1.day
            end
          end
        end
        candidate
      end

      def self.disabled?(live, start_of_day, rate_band, loan_term, blackout_dates)
        live_rate             = live[:rate].to_f
        start_of_day_rate     = start_of_day[:rate].to_f
        threshold_min         = start_of_day_rate - rate_band['LOW_BAND_OFF_BP'].to_f/100.0
        threshold_max         = start_of_day_rate + rate_band['HIGH_BAND_OFF_BP'].to_f/100.0
        blacked_out           = blackout_dates.include?( live['maturity_date'] )
        cant_trade            = !loan_term['trade_status']
        cant_display          = !loan_term['display_status']
        blacked_out || cant_trade || cant_display || live_rate < threshold_min || live_rate > threshold_max
      end

      def self.soap_client(endpoint, namespaces)
        Savon.client( COMMON.merge( wsdl: ENV[endpoint], namespaces: namespaces ) )
      end

      def self.init_mds_connection(environment)
        return @@mds_connection = nil unless environment == :production
        @@mds_connection ||= MAPI::Services::Rates.soap_client( 'MAPI_MDS_ENDPOINT',
                                                                { 'xmlns:v1' => 'http://fhlbsf.com/schema/msg/marketdata/v1',
                                                                  'xmlns:wsse' => 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd',
                                                                  'xmlns:v11' => 'http://fhlbsf.com/schema/canonical/common/v1',
                                                                  'xmlns:v12' => 'http://fhlbsf.com/schema/canonical/marketdata/v1',
                                                                  'xmlns:v13' => 'http://fhlbsf.com/schema/canonical/shared/v1'} )
      end

      def self.init_cal_connection(environment)
        return @@cal_connection = nil unless environment == :production
        @@cal_connection ||= MAPI::Services::Rates.soap_client( 'MAPI_CALENDAR_ENDPOINT',
                                                                { 'xmlns:v1' => 'http://fhlbsf.com/schema/msg/businessCalendar/v1',
                                                                  'xmlns:wsse' => 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd',
                                                                  'xmlns:v11' => 'http://fhlbsf.com/schema/canonical/common/v1'} )
      end

      def self.init_pi_connection(environment)
        return @@pi_connection = nil unless environment == :production
        @@pi_connection ||= MAPI::Services::Rates.soap_client( 'MAPI_MDS_ENDPOINT',
                                                               { 'xmlns:v1' => 'http://fhlbsf.com/reports/msg/v1',
                                                                 'xmlns:wsse' => 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd',
                                                                 'xmlns:v11' => 'http://fhlbsf.com/reports/contract/v1'} )
      end

      def self.get_holidays_from_soap(logger, start, finish)
        begin
          @@cal_connection.call(:get_holiday,
                                message_tag: 'holidayRequest',
                                message: {'v1:endDate' => finish, 'v1:startDate' => start},
                                soap_header: SOAP_HEADER )
        rescue Savon::Error => error
          logger.error error
          nil
        end
      end

      def self.get_holidays(logger, environment)
        if MAPI::Services::Rates.init_cal_connection(environment)
          return nil unless response = MAPI::Services::Rates.get_holidays_from_soap(logger, Time.zone.today, Time.zone.today + 3.years)
          response.doc.remove_namespaces!
          response.doc.xpath('//Envelope//Body//holidayResponse//holidays//businessCenters')[0].css('days day date').map do |holiday|
            Time.zone.parse(holiday.content)
          end
        else
          MAPI::Services::Rates.fake('calendar_holidays')
        end
      end

      def self.market_data_message_for_loan_type(loan_type, live_or_start_of_day)
        {
            'v1:caller' => [{'v11:id' => ENV['MAPI_FHLBSF_ACCOUNT']}],
            'v1:marketData' => [{
                                    'v12:name'         => LOAN_MAPPING[loan_type.to_s],
                                    'v12:pricingGroup' => [{'v12:id' => live_or_start_of_day}],
                                    'v12:data'         => ''
                                }]
        }
      end

      def self.get_market_data_from_soap(logger, live_or_start_of_day)
        return nil if @@mds_connection.nil?
        begin
          @@mds_connection.call(:get_market_data,
                                message_tag: 'marketDataRequest',
                                message: {
                                    'v11:caller' => [{ 'v11:id' => ENV['MAPI_COF_ACCOUNT']}],
                                    'v1:requests' =>  [{'v1:fhlbsfMarketDataRequest' => LOAN_TYPES.map{ |lt| market_data_message_for_loan_type(lt, live_or_start_of_day)}}]
                                },
                                soap_header: SOAP_HEADER )
        rescue Savon::Error => error
          logger.error error
          return nil
        end
      end

      def self.extract_market_data_from_soap_response(response)
        hash = {}
        response.doc.remove_namespaces!
        fhlbsf_response = response.doc.xpath('//Envelope//Body//marketDataResponse//responses//fhlbsfMarketDataResponse')
        LOAN_TYPES.each_with_index do |type, ctr_type|
          hash[type] = {}
          fhlbsf_data_points = fhlbsf_response[ctr_type].css('marketData FhlbsfMarketData data FhlbsfDataPoint')
          LOAN_TERMS.each_with_index do |term, ctr_term|
            ctr_term = 1 if ctr_term == 0 # why? when commented out, all tests still pass
            hash[type][term] = {
                'payment_on'         => 'Maturity',
                'interest_day_count' => fhlbsf_response[ctr_type].at_css('marketData FhlbsfMarketData dayCountBasis').content,
                'rate'               => fhlbsf_data_points[ctr_term-1].at_css('value').content,
                'maturity_date'      => Time.zone.parse(fhlbsf_data_points[ctr_term-1].at_css('tenor maturityDate').content).to_date,
            }
          end
        end
        hash
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
              parameter do
                key :paramType, :path
                key :name, :type
                key :required, false
                key :type, :string
                key :description, 'The type of the loan.'
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
            rows = MAPI::Services::Rates.fake('rates_historic_overnight')[0..(days - 1)]
            rows.collect do |row|
              [Time.zone.parse(row[0]), row[1]]
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
              response = @@pi_connection.call(:get_pricing_indications,
                                              message_tag: 'pricingIndicationsRequest',
                                              message: message,
                                              soap_header: SOAP_HEADER )
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
            MAPI::Services::Rates.fake('rates_current_price_indications_vrc')
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
              response = @@pi_connection.call(:get_pricing_indications,
                                              message_tag: 'pricingIndicationsRequest',
                                              message: message,
                                              soap_header: SOAP_HEADER )
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
            MAPI::Services::Rates.fake('rates_current_price_indications_frc')
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
              response = @@pi_connection.call(:get_pricing_indications,
                                              message_tag: 'pricingIndicationsRequest',
                                              message: message,
                                              soap_header: SOAP_HEADER )
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
                'prime' =>  params[:collateral] == 'standard' ? result[4].at_css('Text').content : 0
              }
            end
            hash
          else
            MAPI::Services::Rates.fake('rates_current_price_indications_arc')
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

        relative_get '/:loan/:term/?:type?' do
          halt 404, 'Loan Not Found' unless LOAN_MAPPING[params[:loan]]
          halt 404, 'Term Not Found' unless TERM_MAPPING[params[:term]]
          type = params[:type] ? params[:type] : 'Live'

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
                      'v12:pricingGroup' => [{'v12:id' => type}],
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
            response = @@mds_connection.call(:get_market_data, message_tag: 'marketDataRequest', message: message, soap_header: SOAP_HEADER )
            namespaces = {'a' => 'http://fhlbsf.com/schema/canonical/marketdata/v1', 'xmlns' => 'http://fhlbsf.com/schema/msg/marketdata/v1'}
            if response.success? && response.doc.search('//xmlns:transactionResult', namespaces).text != 'Error'
              {rate: response.doc.search('//a:value', namespaces).text.to_f, updated_at: DateTime.parse(response.doc.search('//a:snapTime', namespaces).text).to_time}
            else
              halt 503, 'Service Unavailable'
            end
          else
            # We have no real data source yet.
            rows = MAPI::Services::Rates.fake('rates_current_overnight')
            rate = rows.sample
            now = Time.now
            {rate: rate, updated_at: Time.mktime(now.year, now.month, now.day, now.hour, now.min).to_s}
          end
          data.to_json
        end

        relative_get "/summary" do
          halt 503, 'Internal Service Error' unless holidays       = MAPI::Services::Rates.get_holidays(logger, settings.environment)
          halt 503, 'Internal Service Error' unless blackout_dates = MAPI::Services::Rates::BlackoutDates.blackout_dates(logger,settings.environment)
          halt 503, 'Internal Service Error' unless loan_terms     = MAPI::Services::Rates::LoanTerms.loan_terms(logger,settings.environment)
          halt 503, 'Internal Service Error' unless rate_bands     = MAPI::Services::Rates::RateBands.rate_bands(logger,settings.environment)
          if MAPI::Services::Rates.init_mds_connection(settings.environment)
            halt 503, 'Internal Service Error' unless live_data_xml    = MAPI::Services::Rates.get_market_data_from_soap(logger, 'Live')
            halt 503, 'Internal Service Error' unless start_of_day_xml = MAPI::Services::Rates.get_market_data_from_soap(logger, 'StartOfDay')
            live_data    = MAPI::Services::Rates.extract_market_data_from_soap_response(live_data_xml)
            start_of_day = MAPI::Services::Rates.extract_market_data_from_soap_response(start_of_day_xml)
          else
            # We have no real data source yet.
            live_data    = MAPI::Services::Rates.fake('market_data_live_rates').with_indifferent_access
            start_of_day = MAPI::Services::Rates.fake('market_data_start_of_day_rates').with_indifferent_access
            # The maturity_date property might end up being calculated in the service object and not here. TBD once we know more.
            LOAN_TYPES.each do |type|
              LOAN_TERMS.each do |term|
                live_data[type][term][:maturity_date] = Time.zone.today + live_data[type][term][:days_to_maturity].to_i.days
              end
            end
          end
          LOAN_TYPES.each do |type|
            LOAN_TERMS.each do |term|
              live                 = live_data[type][term]
              live[:maturity_date] = MAPI::Services::Rates.find_nearest_business_day(live[:maturity_date], TERM_MAPPING[term][:frequency_unit], holidays)
              live[:disabled]      = MAPI::Services::Rates.disabled?(live, start_of_day[type][term], rate_bands[term], loan_terms[term][type], blackout_dates)
            end
          end
          live_data.merge( timestamp: Time.zone.now ).to_json
        end


        # Price Indication Historical rates for VRC, FRC, ARC
        relative_get "/price_indication/historical/:start_date/:end_date/:collateral_type/:credit_type" do
          MAPI::Services::Rates.init_cal_connection(settings.environment)
          start_date      = params[:start_date].to_date
          end_date        = params[:end_date].to_date
          collateral_type = params[:collateral_type].to_sym
          credit_type     = params[:credit_type].to_sym
          irdb_code       = MAPI::Services::Rates::PriceIndicationHistorical::IRDB_CODE_TERM_MAPPING[collateral_type]
          halt 400, 'Invalid date range: start_date must occur earlier than end_date' unless start_date < end_date
          halt 400, "Invalid Collateral type"                                         unless irdb_code
          halt 400, "Invalid Credit type"                                             unless irdb_code[credit_type]
          MAPI::Services::Rates::PriceIndicationHistorical.price_indication_historical(self, start_date, end_date, collateral_type, credit_type).to_json
        end
      end
    end
  end
end