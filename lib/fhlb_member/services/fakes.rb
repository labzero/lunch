require 'savon'
require 'nokogiri'

module FhlbMember
  module Services
    module Fakes

      def self.use_fake_service(service, enable)
        service_data = case service
          when :mds
            [Private.mds_connection, :fake_market_data, 'fakeMarketData', '//Envelope//Body//fakeMarketDataResponse//fakeMarketDataResult']
          when :cal
            [Private.cal_connection, :fake_calendar_data, 'fakeCalendarData', '//Envelope//Body//fakeCalendarDataResponse//fakeCalendarDataResult']
          when :pi
            [Private.pi_connection, :fake_pricing_indications_data, 'fakePricingIndicationsData', '//Envelope//Body//fakePricingIndicationsDataResponse//fakePricingIndicationsDataResult']
          else
            raise "Requested service is invalid: #{service}. `use_fake_service` only supports these fake services: [:mds, :cal, :pi]"
        end
        enable = enable ? 'true' : 'false'
        response = service_data[0].call(service_data[1], message_tag: service_data[2], message: {'v1:request' => enable}, :soap_header => {'wsse:Security' => {'wsse:UsernameToken' => {'wsse:Username' => ENV['MAPI_FHLBSF_ACCOUNT'], 'wsse:Password' => ENV['SOAP_SECRET_KEY']}}})
        raise "no response from `#{service}" unless response
        raise "malformed response from `#{service}" unless response.doc
        result_nodes = response.doc.remove_namespaces!.xpath(service_data[3])
        raise "malformed response from `#{service}" unless result_nodes 
        response_node = result_nodes.children.first
        raise "malformed response from `#{service}" unless response_node 
        response_node.content == enable
      end

      module Private

        def self.soap_client(endpoint, namespaces)
          Savon.client( { env_namespace: :soapenv, element_form_default: :qualified, namespace_identifier: :v1, pretty_print_xml: true, wsdl: endpoint, namespaces: namespaces } )
        end

        def self.mds_connection
          self.soap_client(
            ENV['MAPI_MDS_ENDPOINT'],
            { 'xmlns:v1'   => 'http://fhlbsf.com/contract/marketdata/v1',
              'xmlns:wsse' => 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd',
              'xmlns:v11'  => 'http://fhlbsf.com/schema/canonical/common/v1',
              'xmlns:v12'  => 'http://fhlbsf.com/schema/canonical/marketdata/v1',
              'xmlns:v13'  => 'http://fhlbsf.com/schema/canonical/shared/v1'
            }
          )
        end

        def self.cal_connection
          self.soap_client(
            ENV['MAPI_CALENDAR_ENDPOINT'],
            { 'xmlns:v1' => 'http://fhlbsf.com/contract/calendar/v1',
              'xmlns:wsse' => 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd',
              'xmlns:v11' => 'http://fhlbsf.com/schema/canonical/common/v1'
            }
          )
        end

        def self.pi_connection
          self.soap_client(
            ENV['MAPI_MDS_ENDPOINT'],
            { 'xmlns:v1' => 'http://fhlbsf.com/reports/contract/v1',
              'xmlns:wsse' => 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd',
              'xmlns:v11' => 'http://fhlbsf.com/reports/contract/v1'
            }
          )
        end
      end
    end
  end
end