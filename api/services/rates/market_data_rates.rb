require 'savon'

module MAPI
  module Services
    module Rates
      module MarketDataRates
        include MAPI::Services::Base
        include MAPI::Shared::Constants

        def self.get_market_cof_rates(environment, term)
          mds_connection = MAPI::Services::Rates.init_mds_connection(environment)
          if mds_connection
            mds_connection.operations
            lookup_term = MAPI::Shared::Constants::TERM_MAPPING[term]
            request = MAPI::Shared::Constants::COF_TYPES.collect do |type|
            {
              'v1:caller' => [{'v11:id' => ENV['MAPI_FHLBSF_ACCOUNT']}],
              'v1:marketData' => [{
                'v12:name' => type,
                'v12:pricingGroup' => [{'v12:id' => 'Live'}],
                'v12:data' =>  [{
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
            }
            end
            message = {
              'v11:caller' => [{ 'v11:id' => ENV['MAPI_COF_ACCOUNT']}],
              'v1:requests' =>  [{'v1:fhlbsfMarketDataRequest' => request}]
            }
            begin
              response = mds_connection.call(:get_market_data, message_tag: 'marketDataRequest', message: message, :soap_header => {'wsse:Security' => {'wsse:UsernameToken' => {'wsse:Username' => ENV['MAPI_FHLBSF_ACCOUNT'], 'wsse:Password' => ENV['SOAP_SECRET_KEY']}}} )
            rescue Savon::Error => error
              raise error
            end
            response.doc.remove_namespaces!
            fhlbsfresponse = response.doc.xpath('//Envelope//Body//marketDataResponse//responses//fhlbsfMarketDataResponse')
            hash = {}
            COF_TYPES.each_with_index do |type, ctr_type|
              if fhlbsfresponse.present?
                if fhlbsfresponse[ctr_type].css('marketData FhlbsfMarketData data FhlbsfDataPoint')
                  fhlbsfdatapoints = fhlbsfresponse[ctr_type].css('marketData FhlbsfMarketData data FhlbsfDataPoint')
                  hash[type] = fhlbsfdatapoints.at_css('value').content
                else
                  raise 'Missing Data'
                end
              else
                raise 'Missing Response'
              end
            end
            hash
          else
            hash = JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'rates_cof_live.json')))
            hash
          end
        end
      end
    end
  end
end