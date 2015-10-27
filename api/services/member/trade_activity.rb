require 'date'
require 'savon'

module MAPI
  module Services
    module Member
      module TradeActivity

        include MAPI::Shared::Utils

        TODAYS_ADVANCES_ARRAY = %w(VERIFIED OPS_REVIEW OPS_VERIFIED SEC_REVIEWED SEC_REVIEW COLLATERAL_AUTH AUTH_TERM PEND_TERM)
        ACTIVE_ADVANCES_ARRAY = %w(VERIFIED OPS_REVIEW OPS_VERIFIED COLLATERAL_AUTH AUTH_TERM PEND_TERM)
        TODAYS_CREDIT_ARRAY = TODAYS_ADVANCES_ARRAY + %w(TERMINATED EXERCISED)
        TODAYS_CREDIT_KEYS = %w(instrumentType status terminationPar fundingDate maturityDate tradeID amount rate productDescription terminationFee terminationFullPartial product subProduct)

        def self.init_trade_connection(environment)
          if environment == :production
            @@trade_connection ||= Savon.client(
              wsdl: ENV['MAPI_TRADE_ENDPOINT'],
              env_namespace: :soapenv,
              namespaces: { 'xmlns:v1' => 'http://fhlbsf.com/schema/msg/trade/v1', 'xmlns:wsse' => 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd', 'xmlns:v11' => 'http://fhlbsf.com/schema/canonical/common/v1'},
              element_form_default: :qualified,
              namespace_identifier: :v1,
              pretty_print_xml: true
            )
          else
            @@trade_connection = nil
          end
        end

        def self.init_trade_activity_connection(environment)
          if environment == :production
            @@trade_activity_connection ||= Savon.client(
              wsdl: ENV['MAPI_TRADE_ACTIVITY_ENDPOINT'],
              env_namespace: :soapenv,
              namespaces: { 'xmlns:v1' => 'http://fhlbsf.com/schema/msg/trade/v1', 'xmlns:wsse' => 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd', 'xmlns:v11' => 'http://fhlbsf.com/schema/canonical/common/v1'},
              element_form_default: :qualified,
              namespace_identifier: :v1,
              pretty_print_xml: true
            )
          else
            @@trade_activity_connection = nil
          end
        end

        def self.sort_trades(trades)
          trades.sort { |a, b| [b['trade_date'], b['advance_number']] <=> [a['trade_date'], a['advance_number']] }
        end

        def self.build_trade_datetime(trade)
          date = trade.at_css('tradeHeader tradeDate').content
          time = trade.at_css('tradeHeader tradeTime').content
          return nil unless date && time
          (date.to_date.iso8601 + 'T' + time)
        end

        def self.is_large_member(environment, member_id)

          if environment == :production
            number_of_advances_query = <<-SQL
              select count(*)
              FROM ODS.DEAL@ODS_LK
              WHERE FHLB_ID = #{ActiveRecord::Base.connection.quote(member_id)} AND instrument = 'ADVS'
            SQL
            number_of_advances_cursor = ActiveRecord::Base.connection.execute(number_of_advances_query)
            number_of_advances = number_of_advances_cursor.fetch().try(:first).to_i
            if number_of_advances > 300
              return true
            else
              return false
            end
          else
            return false
          end
        end

        def self.get_trade_activity_trades(message)
          trade_activity = []
          begin
            response = @@trade_connection.call(:get_trade, message_tag: 'tradeRequest', message: message, :soap_header => MAPI::Services::Rates::SOAP_HEADER)
          rescue Savon::Error => error
            raise error
          end
          response.doc.remove_namespaces!
          fhlbsfresponse = response.doc.xpath('//Envelope//Body//tradeResponse//trades//trade')
          fhlbsfresponse.each do |trade|
            if ACTIVE_ADVANCES_ARRAY.include? trade.at_css('tradeHeader status').content
              rate = (trade.at_css('advance coupon fixedRateSchedule') ? trade.at_css('advance coupon fixedRateSchedule step rate') : trade.at_css('advance coupon initialRate')).content
              hash = {
                'trade_date' => build_trade_datetime(trade),
                'funding_date' => trade.at_css('tradeHeader settlementDate').content,
                'maturity_date' => trade.at_css('advance maturityDate') ? trade.at_css('advance maturityDate').content : 'Open',
                'advance_number' => trade.at_css('advance advanceNumber').content,
                'advance_type' => trade.at_css('advance product').content,
                'status' => Date.parse(trade.at_css('tradeHeader tradeDate').content) < Time.zone.today ? 'Outstanding' : 'Processing',
                'interest_rate' => rate,
                'current_par' => trade.at_css('advance par amount').content.to_f
              }
              trade_activity.push(hash)
            end
          end
          trade_activity
        end

        def self.trade_activity(app, member_id, instrument)
          member_id = member_id.to_i
          trade_activity = []
          data = if MAPI::Services::Member::TradeActivity.init_trade_connection(app.settings.environment)
            if MAPI::Services::Member::TradeActivity.is_large_member(app.settings.environment, member_id)
              ACTIVE_ADVANCES_ARRAY.each do |status|
                message = {
                  'v11:caller' => [{'v11:id' => ENV['MAPI_FHLBSF_ACCOUNT']}],
                  'v1:tradeRequestParameters' => [{
                    'v1:status' => status,
                    'v1:arrayOfCustomers' => [{'v1:fhlbId' => member_id}],
                    'v1:arrayOfAssetClasses' => [{'v1:assetClass' => instrument}]
                  }]
                }
                trade_activity.push(*MAPI::Services::Member::TradeActivity.get_trade_activity_trades(message))
              end
            else
              message = {
                'v11:caller' => [{'v11:id' => ENV['MAPI_FHLBSF_ACCOUNT']}],
                'v1:tradeRequestParameters' => [{
                  'v1:arrayOfCustomers' => [{'v1:fhlbId' => member_id}],
                  'v1:arrayOfAssetClasses' => [{'v1:assetClass' => instrument}]
                }]
              }
              trade_activity.push(*MAPI::Services::Member::TradeActivity.get_trade_activity_trades(message))
            end
            trade_activity
          else
            trade_activity = JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'member_advances_active.json')))
            trade_activity
          end
          data.each do |trade|
            trade['interest_rate'] = decimal_to_percentage_rate(trade['interest_rate'])
          end
          sort_trades(data)
        end

        def self.current_daily_total(env, instrument)
          data = if connection = MAPI::Services::Member::TradeActivity.init_trade_connection(env)
            message = {
              'v11:caller' => [{'v11:id' => ENV['MAPI_FHLBSF_ACCOUNT']}],
              'v1:tradeRequestParameters' => [
                {
                  'v1:lastUpdatedDateTime' => Time.zone.today().strftime("%Y-%m-%dT%T"),
                  'v1:arrayOfAssetClasses' => [{'v1:assetClass' => instrument}]
                }
              ]
            }
            begin
              response = connection.call(:get_trade, message_tag: 'tradeRequest', message: message, :soap_header => MAPI::Services::Rates::SOAP_HEADER)
            rescue Savon::Error => error
              raise error
            end
            response.doc.remove_namespaces!
            fhlbsfresponse = response.doc.xpath('//Envelope//Body//tradeResponse//trades//trade')
            advance_daily_total = 0
            fhlbsfresponse.each do |trade|
              if TODAYS_ADVANCES_ARRAY.include? trade.at_css('tradeHeader status').content
                advance_daily_total += trade.at_css('advance par amount').content.to_f
              end
            end
            advance_daily_total
          else
            # fake an advance_daily_total locally
            (rand(10000..999999999) + rand()).round(2)
          end
          data
        end

        def self.todays_trade_activity(app, member_id, instrument)
          member_id = member_id.to_i
          trade_activity = []
          data = if connection = MAPI::Services::Member::TradeActivity.init_trade_connection(app.settings.environment)
            message = {
              'v11:caller' => [{'v11:id' => ENV['MAPI_FHLBSF_ACCOUNT']}],
              'v1:tradeRequestParameters' => [{
                'v1:lastUpdatedDateTime' => Time.zone.today().strftime("%Y-%m-%dT%T"),
                'v1:arrayOfCustomers' => [{'v1:fhlbId' => member_id}],
                'v1:arrayOfAssetClasses' => [{'v1:assetClass' => instrument}]
              }]
            }
            begin
              response = connection.call(:get_trade, message_tag: 'tradeRequest', message: message, :soap_header => MAPI::Services::Rates::SOAP_HEADER)
            rescue Savon::Error => error
              raise error
            end
            response.doc.remove_namespaces!
            fhlbsfresponse = response.doc.xpath('//Envelope//Body//tradeResponse//trades//trade')
            fhlbsfresponse.each do |trade|
              if TODAYS_ADVANCES_ARRAY.include? trade.at_css('tradeHeader status').content
                rate = (trade.at_css('advance coupon fixedRateSchedule') ? trade.at_css('advance coupon fixedRateSchedule step rate') : trade.at_css('advance coupon initialRate')).content
                hash = {
                  'trade_date' => build_trade_datetime(trade),
                  'funding_date' => trade.at_css('tradeHeader settlementDate').content,
                  'maturity_date' => trade.at_css('advance maturityDate') ? trade.at_css('advance maturityDate').content : 'Open',
                  'advance_number' => trade.at_css('advance advanceNumber').content,
                  'advance_type' => trade.at_css('advance product').content,
                  'status' => Date.parse(trade.at_css('tradeHeader tradeDate').content) < Time.zone.today ? 'Outstanding' : 'Processing',
                  'interest_rate' => rate,
                  'current_par' => trade.at_css('advance par amount').content.to_f
                }
                trade_activity.push(hash)
              end
            end
            trade_activity
          else
            trade_activity = JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'member_advances_active.json')))
            trade_activity
          end
          data.each do |trade|
            trade['interest_rate'] = decimal_to_percentage_rate(trade['interest_rate'])
          end
          sort_trades(data)
        end

        def self.todays_credit_activity(env, member_id)
          member_id = member_id.to_i
          credit_activity = []

          activities = if connection = MAPI::Services::Member::TradeActivity.init_trade_activity_connection(env)
            message = {
              'v11:caller' => [{'v11:id' => ENV['MAPI_FHLBSF_ACCOUNT']}],
              'v1:tradeRequestParameters' => [{
                'v1:lastUpdatedDateTime' => Time.zone.today().strftime("%Y-%m-%dT%T"),
                'v1:arrayOfCustomers' => [{'v1:fhlbId' => member_id}]
              }]
            }
            begin
              response = connection.call(:get_trade_activity, message_tag: 'tradeRequest', message: message, :soap_header => {'wsse:Security' => {'wsse:UsernameToken' => {'wsse:Username' => ENV['MAPI_FHLBSF_ACCOUNT'], 'wsse:Password' => ENV['SOAP_SECRET_KEY']}}})
            rescue Savon::Error => error
              raise error
            end
            response.doc.remove_namespaces!
            soap_activities_array = []
            soap_activities = response.doc.xpath('//Envelope//Body//tradeActivityResponse//tradeActivities//tradeActivity')
            soap_activities.each do |activity|
              hash = {}
              TODAYS_CREDIT_KEYS.each do |key|
                node = activity.at_css(key)
                hash[key] = node.content if node
              end
              soap_activities_array.push(hash)
            end
            soap_activities_array
          else
            activities = JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'credit_activity.json')))
            activities.each do |activity|
              today_string = Time.zone.today.to_s
              activity['fundingDate'], activity['maturityDate'] = [today_string, today_string]
            end
          end

          activities.each do |activity|
            instrument_type = activity['instrumentType'].to_s if activity['instrumentType'].present?
            status = activity['status'].to_s if activity['status'].present?
            termination_par = activity['terminationPar'].to_f if activity['terminationPar'].present?
            funding_date = Time.zone.parse(activity['fundingDate']).to_date if activity['fundingDate'].present?
            maturity_date = Time.zone.parse(activity['maturityDate']).to_date if activity['maturityDate'].present?
            transaction_number = activity['tradeID'].to_s if activity['tradeID'].present?
            current_par = activity['amount'].to_f if activity['amount'].present?
            interest_rate = activity['rate'].to_f if activity['rate'].present?
            product_description = activity['productDescription'].to_s if activity['productDescription'].present?
            termination_fee = activity['terminationFee'].to_f if activity['terminationFee'].present?
            termination_full_partial = activity['terminationFullPartial'].to_s if activity['terminationFullPartial'].present?
            product = activity['product'].to_s if activity['product'].present?
            sub_product = activity['subProduct'].to_s if activity['subProduct'].present?

            # skip the trade if it is an old Advance that is not prepaid, but rather Amended
            if TODAYS_CREDIT_ARRAY.include?(status) && !(instrument_type == 'ADVANCE' && status != 'EXERCISED' && termination_par.blank? && !funding_date.blank? && funding_date < Time.zone.today)
              hash = {
                transaction_number: transaction_number,
                current_par: current_par,
                interest_rate: decimal_to_percentage_rate(interest_rate),
                funding_date: funding_date,
                maturity_date: maturity_date,
                product_description: product_description,
                instrument_type: instrument_type,
                status: status,
                termination_par: termination_par,
                termination_fee: termination_fee,
                termination_full_partial: termination_full_partial,
                product: product,
                sub_product: sub_product
              }
              credit_activity.push(hash)
            end
          end
          credit_activity
        end
      end
    end
  end
end
