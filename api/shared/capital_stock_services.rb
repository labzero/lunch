require 'savon'

module MAPI
  module Shared
    module CapitalStockServices

      def self.init_capital_stock_connection(environment)
        if environment == :production
          @@capstockcalc_connection = Savon.client(
              wsdl: ENV['MAPI_CAPITALSTOCK_ENDPOINT'],
              env_namespace: :soapenv,
              namespaces: { 'xmlns:v1' => 'http://fhlbsf.com/schema/msg/capitalstockfobo/v1',
                            'xmlns:wsse' => 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd',
                            'xmlns:v11' => 'http://fhlbsf.com/schema/canonical/common/v1',
                            'xmlns:v12' => 'http://fhlbsf.com/schema/canonical/capitalstockfobo/v1'},
              element_form_default: :qualified,
              namespace_identifier: :v1,
              pretty_print_xml: true
          )
        else
          @@capstockcalc_connection = nil
        end
      end

      def self.capital_stock_requirements(total_cap_stock, advances_outstanding, mpf_unpaid_balance, mortgage_related_assets, environment)
        MAPI::Shared::CapitalStockServices::init_capital_stock_connection(environment)
        data = if @@capstockcalc_connection
          message = {
            'v1:criteria' => [{
              'v12:totalCapitalStock' => total_cap_stock,
              'v12:advancesOutstanding' => advances_outstanding,
              'v12:mpfUnpaidBalance' => mpf_unpaid_balance,
              'v12:mortgageRelatedAssets' => mortgage_related_assets
            }]
          }
          begin
          response = @@capstockcalc_connection.call(:get_capital_stock_requirements, message_tag: 'capitalStockCalculatorRequest', message: message, :soap_header => {'wsse:Security' => {'wsse:UsernameToken' => {'wsse:Username' => ENV['MAPI_FHLBSF_ACCOUNT'], 'wsse:Password' => ENV['SOAP_SECRET_KEY']}}})
          rescue Savon::Error => error
            {additional_advances: nil}
          else
            response.doc.remove_namespaces!
            fhlbsfresponse = response.doc.xpath('//Envelope//Body//capitalStockCalculatorResponse//capitalStockRequirements')
            {additional_advances: fhlbsfresponse[0].css('additionalAdvances').text.to_i}.with_indifferent_access
          end
        else
          # We have no real data source yet.
          JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'capital_stock_requirements.json')))
       end
      end
    end
  end
end