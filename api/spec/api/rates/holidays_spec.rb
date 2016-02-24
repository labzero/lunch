require 'spec_helper'
require 'date'

describe MAPI::Services::Rates::Holidays do
  subject{ MAPI::Services::Rates::Holidays }
  describe 'holidays' do
    let(:logger){ double( 'logger' ) }
    let(:environment){ double('environment') }
    let(:connection){ double('connection') }
    let(:start){ double('start') }
    let(:finish){ double('finish') }
    let(:xml_doc){ double('xml_doc') }
    let(:fake){ double('fake') }
    let(:soap_response){ double('soap_response', doc: xml_doc) }
    let(:results){ double('results') }
    let(:holiday1_string){ double('holiday1_string') }
    let(:holiday2_string){ double('holiday2_string') }
    let(:holiday3_string){ double('holiday3_string') }
    let(:holiday1_date){ double('holiday1_date') }
    let(:holiday2_date){ double('holiday2_date') }
    let(:holiday3_date){ double('holiday3_date') }
    let(:holiday1){ double('holiday1', content: holiday1_string)}
    let(:holiday2){ double('holiday2', content: holiday2_string)}
    let(:holiday3){ double('holiday3', content: holiday3_string)}
    let(:holidays_results){ [holiday1, holiday2, holiday3]}
    let(:holidays){ [holiday1_date, holiday2_date, holiday3_date] }
    before do
      allow(MAPI::Services::Rates).to receive(:init_cal_connection).with(environment).and_return(connection)
      allow(subject).to receive(:get_holidays_from_soap).with(logger, connection, start, finish).and_return(soap_response)
      allow(xml_doc).to receive(:remove_namespaces!)
    end

    it 'returns fake results if connection is nil' do
      allow(MAPI::Services::Rates).to receive(:init_cal_connection).with(environment).and_return(nil)
      allow(MAPI::Services::Rates).to receive(:fake).with('calendar_holidays').and_return(fake)
      expect(subject.holidays(logger, environment, start, finish)).to eq(fake)
    end

    it 'returns [] if soap response is empty' do
      allow(subject).to receive(:get_holidays_from_soap).with(logger, connection, start, finish).and_return(nil)
      expect(subject.holidays(logger, environment, start, finish)).to eq([])
    end

    it 'returns [] when xpath returns []' do
      allow(xml_doc).to receive(:xpath).with('//Envelope//Body//holidayResponse//holidays//businessCenters').and_return([])
      expect(subject.holidays(logger, environment, start, finish)).to eq([])
    end

    it 'returns a list of dates extracted from the XML' do
      allow(xml_doc).to receive(:xpath).with('//Envelope//Body//holidayResponse//holidays//businessCenters').and_return([results])
      allow(results).to receive(:css).with('days day date').and_return(holidays_results)
      allow(Time).to receive_message_chain(:zone, :parse).with(holiday1_string).and_return(holiday1_date)
      allow(Time).to receive_message_chain(:zone, :parse).with(holiday2_string).and_return(holiday2_date)
      allow(Time).to receive_message_chain(:zone, :parse).with(holiday3_string).and_return(holiday3_date)
      expect(subject.holidays(logger, environment, start, finish)).to eq(holidays)
    end
  end
end