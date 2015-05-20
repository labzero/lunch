require 'spec_helper'

describe MAPI::ServiceApp do
  before do
    header 'Authorization', "Token token=\"#{ENV['MAPI_SECRET_TOKEN']}\""
  end

  describe 'GET /healthy' do
    let(:make_request) { get "/healthy"; JSON.parse(last_response.body) }
    it 'should return a JSON hash' do
      expect(make_request).to be_kind_of(Hash)
    end
    describe 'CDB status' do
      let(:service_key) { 'thunderdome' }
      it 'returns `true` if the DB connection is active' do
        allow(ActiveRecord::Base.connection).to receive(:active?).and_return(true)
        expect(make_request[service_key]).to eq(true)
      end
      it 'returns `false` if the DB connection is not active' do
        allow(ActiveRecord::Base.connection).to receive(:active?).and_return(false)
        expect(make_request[service_key]).to eq(false)
      end
      it 'returns `false` if the DB connection active check raises an error' do
        allow(ActiveRecord::Base.connection).to receive(:active?).and_raise('some error')
        expect(make_request[service_key]).to eq(false)
      end
    end
    describe 'MDS status' do
      let(:service_key) { 'aunty' }
      it 'returns `true` if the MDS service is reachable and functioning' do
        allow(MAPI::Services::Health).to receive(:ping_mds_service).and_return(true)
        expect(make_request[service_key]).to eq(true)
      end
      it 'returns `false` if the MDS service is not reachable and functioning' do
        allow(MAPI::Services::Health).to receive(:ping_mds_service).and_return(false)
        expect(make_request[service_key]).to eq(false)
      end
      it 'returns `false` if the MDS service check raises an error' do
        allow(MAPI::Services::Health).to receive(:ping_mds_service).and_raise('some error')
        expect(make_request[service_key]).to eq(false)
      end
    end
    describe 'CAL status' do
      let(:service_key) { 'waterseller' }
      it 'returns `true` if the CAL service is reachable and functioning' do
        allow(MAPI::Services::Health).to receive(:ping_cal_service).and_return(true)
        expect(make_request[service_key]).to eq(true)
      end
      it 'returns `false` if the CAL service is not reachable and functioning' do
        allow(MAPI::Services::Health).to receive(:ping_cal_service).and_return(false)
        expect(make_request[service_key]).to eq(false)
      end
      it 'returns `false` if the CAL service check raises an error' do
        allow(MAPI::Services::Health).to receive(:ping_cal_service).and_raise('some error')
        expect(make_request[service_key]).to eq(false)
      end
    end
    describe 'PI status' do
      let(:service_key) { 'pigs' }
      it 'returns `true` if the PI service is reachable and functioning' do
        allow(MAPI::Services::Health).to receive(:ping_pi_service).and_return(true)
        expect(make_request[service_key]).to eq(true)
      end
      it 'returns `false` if the PI service is not reachable and functioning' do
        allow(MAPI::Services::Health).to receive(:ping_pi_service).and_return(false)
        expect(make_request[service_key]).to eq(false)
      end
      it 'returns `false` if the PI service check raises an error' do
        allow(MAPI::Services::Health).to receive(:ping_pi_service).and_raise('some error')
        expect(make_request[service_key]).to eq(false)
      end
    end
  end

  describe '`ping_pi_service` class method' do
    let(:env) { :production }
    let(:call_method) { MAPI::Services::Health.ping_pi_service(env) }
    let(:connection) { double('SOAP Connection') }
    let(:document) { double('XML Document', remove_namespaces!: nil, xpath: []) }
    let(:response) { double('SOAP Response', doc: document)}
    before do
      allow(MAPI::Services::Rates).to receive(:init_pi_connection).with(env).and_return(connection)
      allow(connection).to receive(:call).and_return(response)
    end
    it 'returns false if the connection could not be created' do
      allow(MAPI::Services::Rates).to receive(:init_pi_connection).with(env).and_return(nil)
      expect(call_method).to eq(false)
    end
    it 'returns false if the request raises a savon error' do
      allow(connection).to receive(:call).and_raise(Savon::Error)
      expect(call_method).to eq(false)
    end
    it 'returns false if no `Items` nodes are found' do
      expect(call_method).to eq(false)
    end
    it 'returns true if `Items` nodes are found' do
      allow(document).to receive(:xpath).with('//Envelope//Body//pricingIndicationsResponse//response//Items').and_return([double('A Node')])
      expect(call_method).to eq(true)
    end
  end

  describe '`ping_mds_service` class method' do
    let(:env) { :production }
    let(:call_method) { MAPI::Services::Health.ping_mds_service(env) }
    let(:connection) { double('SOAP Connection') }
    let(:document) { double('XML Document', remove_namespaces!: nil, xpath: []) }
    let(:response) { double('SOAP Response', doc: document)}
    before do
      allow(MAPI::Services::Rates).to receive(:init_mds_connection).with(env).and_return(connection)
      allow(connection).to receive(:call).and_return(response)
    end
    it 'returns false if the connection could not be created' do
      allow(MAPI::Services::Rates).to receive(:init_mds_connection).with(env).and_return(nil)
      expect(call_method).to eq(false)
    end
    it 'returns false if the request raises a savon error' do
      allow(connection).to receive(:call).and_raise(Savon::Error)
      expect(call_method).to eq(false)
    end
    it 'returns false if no `fhlbsfMarketDataResponse` nodes are found' do
      expect(call_method).to eq(false)
    end
    it 'returns true if `fhlbsfMarketDataResponse` nodes are found' do
      allow(document).to receive(:xpath).with('//fhlbsfMarketDataResponse').and_return([double('A Node')])
      expect(call_method).to eq(true)
    end
  end

  describe '`ping_cal_service` class method' do
    let(:env) { :production }
    let(:call_method) { MAPI::Services::Health.ping_cal_service(env) }
    let(:connection) { double('SOAP Connection') }
    let(:transactionResultNode) { double('A transactionResult Node', text: 'Error') }
    let(:document) { double('XML Document', remove_namespaces!: nil, xpath: []) }
    let(:response) { double('SOAP Response', doc: document)}
    before do
      allow(MAPI::Services::Rates).to receive(:init_cal_connection).with(env).and_return(connection)
      allow(connection).to receive(:call).and_return(response)
    end
    it 'returns false if the connection could not be created' do
      allow(MAPI::Services::Rates).to receive(:init_cal_connection).with(env).and_return(nil)
      expect(call_method).to eq(false)
    end
    it 'returns false if the request raises a savon error' do
      allow(connection).to receive(:call).and_raise(Savon::Error)
      expect(call_method).to eq(false)
    end
    it 'returns false if no `transactionResult` nodes are found' do
      expect(call_method).to eq(false)
    end
    it 'returns false if the `transactionResult` node contains something besides `Success`' do
      allow(document).to receive(:xpath).with('//Envelope//Body//holidayResponse//transactionResult').and_return([transactionResultNode])
      expect(call_method).to eq(false)
    end
    it 'returns true if the `transactionResult` node contains `Success`' do
      allow(transactionResultNode).to receive(:text).and_return('Success')
      allow(document).to receive(:xpath).with('//Envelope//Body//holidayResponse//transactionResult').and_return([transactionResultNode])
      expect(call_method).to eq(true)
    end
  end

end