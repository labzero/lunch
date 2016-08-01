require 'spec_helper'
require 'date'

describe MAPI::Services::Rates::Holidays do
  subject{ MAPI::Services::Rates::Holidays }
  describe 'holidays' do
    let(:date_1) { Time.zone.today + rand(0..360).days }
    let(:date_2) { Time.zone.today + rand(0..360).days }
    let(:date_array) { [date_1, date_2] }
    let(:date_string_1) { date_1.iso8601 }
    let(:date_string_2) { date_2.iso8601 }
    let(:date_string_array) { [date_string_1, date_string_2] }
    let(:app) { instance_double(MAPI::ServiceApp, logger: double('logger'), settings: double('app settings', environment: instance_double(Symbol))) }
    let(:call_method) { subject.holidays(app) }

    describe 'when `should_fake?` returns true' do
      before { allow(subject).to receive(:should_fake?).and_return(true) }

      it 'calls `MAPI::Services::Rates.fake` with `calendar_holidays` as an arg' do
        expect(MAPI::Services::Rates).to receive(:fake).and_return(date_string_array)
        call_method
      end
      it 'returns an array of Date objects' do
        allow(MAPI::Services::Rates).to receive(:fake).and_return(date_string_array)
        expect(call_method).to eq(date_array)
      end
    end
    describe 'when `should_fake?` returns false' do
      let(:connection) { instance_double(Savon::Client) }
      let(:document) { double('xml doc', remove_namespaces!: nil, xpath: nil) }
      let(:response) { double('soap response', doc: document) }

      before do
        allow(subject).to receive(:should_fake?).and_return(false)
        allow(MAPI::Services::Rates).to receive(:init_cal_connection)
        allow(subject).to receive(:get_holidays_from_soap)
      end

      it 'initiates a calendar connection with the app\'s environment as an arg' do
        expect(MAPI::Services::Rates).to receive(:init_cal_connection).with(app.settings.environment)
        call_method
      end
      it 'returns an empty hash if `get_holidays_from_soap` returns nil' do
        expect(call_method).to eq([])
      end
      describe 'when `get_holidays_from_soap` returns a response' do
        before do
          allow(subject).to receive(:get_holidays_from_soap).and_return(response)
        end

        it 'removes namespaces from the doc' do
          expect(document).to receive(:remove_namespaces!)
          call_method
        end
        it 'retrieves the node at xpath `//Envelope//Body//holidayResponse//holidays//businessCenters`' do
          expect(document).to receive(:xpath).with('//Envelope//Body//holidayResponse//holidays//businessCenters')
          call_method
        end
        it 'returns an empty array if nothing is found at the xpath address' do
          expect(call_method).to eq([])
        end
        describe 'when a node is found at the xpath address' do
          let(:date_node_array) { [double('node', content: date_string_1), double('node', content: date_string_2)] }
          let(:node) { double('xml node', css: date_node_array) }

          before { expect(document).to receive(:xpath).and_return([node]) }

          it 'calls `css` with `days day date`' do
            expect(node).to receive(:css).with('days day date')
            call_method
          end
          it 'returns an array of dates from the strings found at `days day date`' do
            expect(call_method).to eq(date_array)
          end
        end
      end
    end
  end
end