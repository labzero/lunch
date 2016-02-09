require 'rails_helper'
require 'rake'
require 'fhlb_member/services/fakes'

describe FhlbMember::Services::Fakes do
  let(:service_connection) { double('service connection', call: service_response) }
  let(:private) { FhlbMember::Services::Fakes::Private }
  let(:service_response) { double('response', doc: double('doc', remove_namespaces!: double('doc', xpath: node_set))) }
  let(:node_set) { double('node set', children: [node]) }
  let(:node) { double('node', content:nil) }

  it { expect(subject).to respond_to(:use_fake_service) }

  describe '`use_fake_service` method' do
    it 'raises an error if it is passed an unknown service' do
      expect{subject.use_fake_service(:foo, true)}.to raise_error
    end
    RSpec.shared_examples 'a faked service switch' do |service, xpath, connection|
      let(:call_method) { subject.use_fake_service(service, true) }

      it "initiates a `#{connection}`" do
        expect(private).to receive(connection).and_return(service_connection)
        call_method
      end
      [true, false].each do |enable|
        it "returns true when the method is passed `#{enable.to_s}` as an argument and the response node's content is '#{enable.to_s}''" do
          allow(node).to receive(:content).and_return(enable.to_s)
          expect(subject.use_fake_service(service, enable)).to eq(true)
        end
      end
      it 'removes namespaces from the response doc' do
        expect(service_response.doc).to receive(:remove_namespaces!).and_return(double('doc', xpath: node_set))
        call_method
      end
      it 'grabs the response message from the proper node' do
        expect(service_response.doc.remove_namespaces!).to receive(:xpath).with(xpath).and_return(node_set)
        call_method
      end
      it 'raises an error if there is no response from the call to `mds_connection`' do
        allow(service_connection).to receive(:call).and_return(nil)
        expect{call_method}.to raise_error
      end
      it 'raises an error if the response has no `doc`' do
        allow(service_response).to receive(:doc).and_return(nil)
        expect{call_method}.to raise_error
      end
      it "raises an error if the response doc has no node at the `#{xpath}` xpath" do
        allow(service_response.doc.remove_namespaces!).to receive(:xpath).with(xpath).and_return(nil)
        expect{call_method}.to raise_error
      end
      it 'raises an error if the response node set is empty' do
        allow(node_set).to receive(:children).and_return([])
        expect{call_method}.to raise_error
      end
    end

    describe 'for the market data service' do
      before { allow(private).to receive(:mds_connection).and_return(service_connection) }

      it_behaves_like 'a faked service switch', :mds, '//Envelope//Body//fakeMarketDataResponse//fakeMarketDataResult', :mds_connection
      [true, false].each do |enable|
        it "calls the `:mds_connection` with the proper arguments when passed `#{enable.to_s}`" do
          expect(service_connection).to receive(:call).with(:fake_market_data, message_tag: 'fakeMarketData', message: {'v1:request' => enable.to_s}, :soap_header => {'wsse:Security' => {'wsse:UsernameToken' => {'wsse:Username' => ENV['MAPI_FHLBSF_ACCOUNT'], 'wsse:Password' => ENV['SOAP_SECRET_KEY']}}})
          subject.use_fake_service(:mds, enable)
        end
      end
    end

    describe 'for the calendar service' do
      before { allow(private).to receive(:cal_connection).and_return(service_connection) }

      it_behaves_like 'a faked service switch', :cal, '//Envelope//Body//fakeCalendarDataResponse//fakeCalendarDataResult', :cal_connection
      [true, false].each do |enable|
        it "calls the `:cal_connection` with the proper arguments when passed `#{enable.to_s}`" do
          expect(service_connection).to receive(:call).with(:fake_calendar_data, message_tag: 'fakeCalendarData', message: {'v1:request' => enable.to_s}, :soap_header => {'wsse:Security' => {'wsse:UsernameToken' => {'wsse:Username' => ENV['MAPI_FHLBSF_ACCOUNT'], 'wsse:Password' => ENV['SOAP_SECRET_KEY']}}})
          subject.use_fake_service(:cal, enable)
        end
      end
    end

    describe 'for the pricing indications service' do
      before { allow(private).to receive(:pi_connection).and_return(service_connection) }

      it_behaves_like 'a faked service switch', :pi, '//Envelope//Body//fakePricingIndicationsDataResponse//fakePricingIndicationsDataResult', :pi_connection
      [true, false].each do |enable|
        it "calls the `:mds_connection` with the proper arguments when passed `#{enable.to_s}`" do
          expect(service_connection).to receive(:call).with(:fake_pricing_indications_data, message_tag: 'fakePricingIndicationsData', message: {'v1:request' => enable.to_s}, :soap_header => {'wsse:Security' => {'wsse:UsernameToken' => {'wsse:Username' => ENV['MAPI_FHLBSF_ACCOUNT'], 'wsse:Password' => ENV['SOAP_SECRET_KEY']}}})
          subject.use_fake_service(:pi, enable)
        end
      end
    end
  end

  describe 'the `soap_client` private method' do
    let(:endpoint) { double('some endpoint') }
    let(:namespaces) { double('a hash of namespaces') }
    let(:call_method) { private.soap_client(endpoint, namespaces) }
    it 'instantiates a Savon client with the proper default arguments' do
      expect(Savon).to receive(:client).with(hash_including({env_namespace: :soapenv, element_form_default: :qualified, namespace_identifier: :v1, pretty_print_xml: true}))
      call_method
    end
    it 'instantiates a Savon client with the given endpoint' do
      expect(Savon).to receive(:client).with(hash_including(wsdl: endpoint))
      call_method
    end
    it 'instantiates a Savon client with the given namespaces' do
      expect(Savon).to receive(:client).with(hash_including(namespaces: namespaces))
      call_method
    end
  end

  describe 'the `mds_connection` private method' do
    it 'creates a soap_client with the appropriate arguments' do
      expect(private).to receive(:soap_client).with(
        ENV['MAPI_MDS_ENDPOINT'],
        { 'xmlns:v1'   => 'http://fhlbsf.com/contract/marketdata/v1',
          'xmlns:wsse' => 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd',
          'xmlns:v11'  => 'http://fhlbsf.com/schema/canonical/common/v1',
          'xmlns:v12'  => 'http://fhlbsf.com/schema/canonical/marketdata/v1',
          'xmlns:v13'  => 'http://fhlbsf.com/schema/canonical/shared/v1'
        }
      )
      private.mds_connection
    end
  end

  describe 'the `cal_connection` private method' do
    it 'creates a soap_client with the appropriate arguments' do
      expect(private).to receive(:soap_client).with(
        ENV['MAPI_CALENDAR_ENDPOINT'],
        { 'xmlns:v1' => 'http://fhlbsf.com/contract/calendar/v1',
          'xmlns:wsse' => 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd',
          'xmlns:v11' => 'http://fhlbsf.com/schema/canonical/common/v1'
        }
      )
      private.cal_connection
    end
  end

  describe 'the `pi_connection` private method' do
    it 'creates a soap_client with the appropriate arguments' do
      expect(private).to receive(:soap_client).with(
        ENV['MAPI_MDS_ENDPOINT'],
        { 'xmlns:v1' => 'http://fhlbsf.com/reports/contract/v1',
          'xmlns:wsse' => 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd',
          'xmlns:v11' => 'http://fhlbsf.com/reports/contract/v1'
        }
      )
      private.pi_connection
    end
  end
end