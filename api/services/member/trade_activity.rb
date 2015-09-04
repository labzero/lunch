require 'date'
require 'savon'

module MAPI
  module Services
    module Member
      module TradeActivity

        TODAYS_ADVANCES_ARRAY = %w(VERIFIED OPS_REVIEW OPS_VERIFIED SEC_REVIEWED SEC_REVIEW COLLATERAL_AUTH AUTH_TERM PEND_TERM)

        def self.init_trade_connection(environment, type)
          if environment == :production
            endpoint = case type
              when :trade
                ENV['MAPI_TRADE_ENDPOINT']
              when :credit
                ENV['MAPI_TRADE_ACTIVITY_ENDPOINT']
              else
                raise "Unknown type for init_trade_connection"
            end
            @@trade_connection ||= Savon.client(
                wsdl: endpoint,
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

        def self.trade_activity(app, member_id, instrument)
          member_id = member_id.to_i
          trade_activity = []
          data = if MAPI::Services::Member::TradeActivity::init_trade_connection(app.settings.environment, :trade)
            message = {
              'v11:caller' => [{'v11:id' => ENV['MAPI_FHLBSF_ACCOUNT']}],
              'v1:tradeRequestParameters' => [{
                'v1:arrayOfCustomers' => [{'v1:fhlbId' => member_id}],
                'v1:arrayOfAssetClasses' => [{'v1:assetClass' => instrument}]
              }]
            }
            begin
              response = @@trade_connection.call(:get_trade, message_tag: 'tradeRequest', message: message, :soap_header => {'wsse:Security' => {'wsse:UsernameToken' => {'wsse:Username' => ENV['MAPI_FHLBSF_ACCOUNT'], 'wsse:Password' => ENV['SOAP_SECRET_KEY']}}})
            rescue Savon::Error => error
              raise error
            end
            response.doc.remove_namespaces!
            fhlbsfresponse = response.doc.xpath('//Envelope//Body//tradeResponse//trades//trade')
            fhlbsfresponse.each do |trade|
              if %w{VERIFIED OPS_REVIEW OPS_VERIFIED COLLATERAL_AUTH AUTH_TERM PEND_TERM}.include? trade.at_css('tradeHeader status').content
                hash = {
                  'trade_date' => trade.at_css('tradeHeader tradeDate').content,
                  'funding_date' => trade.at_css('tradeHeader settlementDate').content,
                  'maturity_date' => trade.at_css('advance maturityDate') ? trade.at_css('advance maturityDate').content : 'Open',
                  'advance_number' => trade.at_css('advance advanceNumber').content,
                  'advance_type' => trade.at_css('advance product').content,
                  'status' => Date.parse(trade.at_css('tradeHeader tradeDate').content) < Time.zone.today ? 'Outstanding' : 'Pending',
                  'interest_rate' => trade.at_css('advance coupon fixedRateSchedule') ? trade.at_css('advance coupon fixedRateSchedule step rate').content.to_f.round(5) : trade.at_css('advance coupon initialRate').content.to_f.round(5),
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
          data.to_json
        end

        def self.current_daily_total(env, instrument)
          data = if MAPI::Services::Member::TradeActivity::init_trade_connection(env, :trade)
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
              response = @@trade_connection.call(:get_trade, message_tag: 'tradeRequest', message: message, :soap_header => {'wsse:Security' => {'wsse:UsernameToken' => {'wsse:Username' => ENV['MAPI_FHLBSF_ACCOUNT'], 'wsse:Password' => ENV['SOAP_SECRET_KEY']}}})
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
          data = if MAPI::Services::Member::TradeActivity::init_trade_connection(app.settings.environment, :trade)
            message = {
              'v11:caller' => [{'v11:id' => ENV['MAPI_FHLBSF_ACCOUNT']}],
              'v1:tradeRequestParameters' => [{
                'v1:lastUpdatedDateTime' => Time.zone.today().strftime("%Y-%m-%dT%T"),
                'v1:arrayOfCustomers' => [{'v1:fhlbId' => member_id}],
                'v1:arrayOfAssetClasses' => [{'v1:assetClass' => instrument}]
              }]
            }
            begin
              response = @@trade_connection.call(:get_trade, message_tag: 'tradeRequest', message: message, :soap_header => {'wsse:Security' => {'wsse:UsernameToken' => {'wsse:Username' => ENV['MAPI_FHLBSF_ACCOUNT'], 'wsse:Password' => ENV['SOAP_SECRET_KEY']}}})
            rescue Savon::Error => error
              raise error
            end
            response.doc.remove_namespaces!
            fhlbsfresponse = response.doc.xpath('//Envelope//Body//tradeResponse//trades//trade')
            fhlbsfresponse.each do |trade|
              if TODAYS_ADVANCES_ARRAY.include? trade.at_css('tradeHeader status').content
                hash = {
                  'trade_date' => trade.at_css('tradeHeader tradeDate').content,
                  'funding_date' => trade.at_css('tradeHeader settlementDate').content,
                  'maturity_date' => trade.at_css('advance maturityDate') ? trade.at_css('advance maturityDate').content : 'Open',
                  'advance_number' => trade.at_css('advance advanceNumber').content,
                  'advance_type' => trade.at_css('advance product').content,
                  'status' => Date.parse(trade.at_css('tradeHeader tradeDate').content) < Time.zone.today ? 'Outstanding' : 'Pending',
                  'interest_rate' => trade.at_css('advance coupon fixedRateSchedule') ? trade.at_css('advance coupon fixedRateSchedule step rate').content.to_f.round(5) : trade.at_css('advance coupon initialRate').content.to_f.round(5),
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
          data.to_json
        end

        def self.todays_credit_activity(env, member_id)
          member_id = member_id.to_i
          credit_activity = []
          data = if MAPI::Services::Member::TradeActivity::init_trade_connection(env, :credit)
            message = {
              'v11:caller' => [{'v11:id' => ENV['MAPI_FHLBSF_ACCOUNT']}],
              'v1:tradeRequestParameters' => [{
                'v1:lastUpdatedDateTime' => Time.zone.today().strftime("%Y-%m-%dT%T"),
                'v1:arrayOfCustomers' => [{'v1:fhlbId' => member_id}]
              }]
            }
            begin
              response = @@trade_connection.call(:get_trade, message_tag: 'tradeRequest', message: message, :soap_header => {'wsse:Security' => {'wsse:UsernameToken' => {'wsse:Username' => ENV['MAPI_FHLBSF_ACCOUNT'], 'wsse:Password' => ENV['SOAP_SECRET_KEY']}}})
            rescue Savon::Error => error
              raise error
            end
            response.doc.remove_namespaces!
            activities = response.doc.xpath('//Envelope//Body//tradeActivityResponse//tradeActivities//tradeActivity')
            activities.each do |activity|
              instrument_type = activity.at_css('instrumentType').content.to_s if activity.at_css('instrumentType')
              status = activity.at_css('status').content if activity.at_css('status')
              termination_par = activity.at_css('terminationPar').content.to_f if activity.at_css('terminationPar')
              funding_date = activity.at_css('fundingDate').content if activity.at_css('fundingDate')
              maturity_date = activity.at_css('maturityDate').content if activity.at_css('maturityDate')

              if TODAYS_ADVANCES_ARRAY.include? status && !(instrument_type == 'ADVANCE' && status != 'EXERCISED' && termination_par.blank? && !funding_date.blank? && Time.zone.parse(funding_date) < Time.zone.today)
                hash = {
                  transaction_number: (activity.at_css('tradeID').content.to_s if activity.at_css('tradeID')),
                  current_par: (activity.at_css('amount').content.to_f if activity.at_css('amount')),
                  interest_rate: (activity.at_css('rate').content.to_f if activity.at_css('rate')),
                  funding_date: (Time.zone.parse(funding_date).to_date if funding_date),
                  maturity_date: (Time.zone.parse(maturity_date).to_date if maturity_date),
                  product_description: (activity.at_css('productDescription').content.to_s if activity.at_css('productDescription')),
                  instrument_type: instrument_type,
                  status: status,
                  termination_par: termination_par,
                  termination_fee: (activity.at_css('terminationFee').content.to_f if activity.at_css('terminationFee')),
                  termination_full_partial: (activity.at_css('terminationFullPartial').content.to_s if activity.at_css('terminationFullPartial')),
                  product: (activity.at_css('product').content.to_f if activity.at_css('product')),
                  sub_product: (activity.at_css('subProduct').content.to_f if activity.at_css('subProduct')),
                }
                credit_activity.push(hash)
              end
            end
            credit_activity
          else
            # fake Today's Credit Activity
            JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'credit_activity.json')))
          end
          data
        end
      end
    end
  end
end
