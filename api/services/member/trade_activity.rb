require 'date'
require 'savon'

module MAPI
  module Services
    module Member
      module TradeActivity

        TODAYS_ADVANCES_ARRAY = %w(VERIFIED OPS_REVIEW OPS_VERIFIED SEC_REVIEWED SEC_REVIEW COLLATERAL_AUTH AUTH_TERM PEND_TERM)

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

        def self.trade_activity(app, member_id, instrument)
          member_id = member_id.to_i
          trade_activity = []
          data = if MAPI::Services::Member::TradeActivity::init_trade_connection(app.settings.environment)
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
                  'status' => Date.parse(trade.at_css('tradeHeader tradeDate').content) < Date.today ? 'Outstanding' : 'Pending',
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

        def self.current_daily_total(app, instrument)
          data = if MAPI::Services::Member::TradeActivity::init_trade_connection(app.settings.environment)
            message = {
              'v11:caller' => [{'v11:id' => ENV['MAPI_FHLBSF_ACCOUNT']}],
              'v1:tradeRequestParameters' => [
                {
                  'v1:lastUpdatedDateTime' => Date.today().strftime("%Y-%m-%dT%T"),
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
      end
    end
  end
end
