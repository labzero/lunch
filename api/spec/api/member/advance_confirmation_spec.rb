require 'spec_helper'
require 'date'

describe MAPI::ServiceApp do
  describe 'Advance Confirmation' do
    describe 'the `advance_confirmation` MAPI endpoint' do
      let(:advance_number) { rand(1000.99999).to_s }
      let(:confirmation_number) { rand(1000.99999).to_s }
      let(:file_location) { double(String) }
      let(:call_endpoint) { get "/member/#{member_id}/advance_confirmation/#{advance_number}/#{confirmation_number}" }
      let(:advance_confirmation) do
        {
          confirmation_number: confirmation_number,
          file_location: file_location
        }
      end

      before do
        allow(MAPI::Services::Member::TradeActivity).to receive(:advance_confirmation).and_return(advance_confirmation)
        allow(File).to receive(:open)
        allow(File).to receive(:size)
        allow(MAPI::Services::Member).to receive(:stream_attachment)
      end
      it 'retrieves advance confirmations based on member_id, advance_number and confirmation number' do
        expect(MAPI::Services::Member::TradeActivity).to receive(:advance_confirmation).with(anything, member_id.to_s, advance_number, confirmation_number).and_return(advance_confirmation)
        call_endpoint
      end
      it 'finds the appropriate confirmation based on confirmation_number and opens a stream based on its `file_location`' do
        expect(File).to receive(:open).with(file_location, 'rb')
        call_endpoint
      end
      it 'calls `stream_attachment` with `env["rack.hijack?"]`' do
        hijack_double = double('hijack')
        env("rack.hijack?", hijack_double)
        expect(MAPI::Services::Member).to receive(:stream_attachment).with(hijack_double, any_args)
        call_endpoint
      end
      it 'calls `stream_attachment` with the appropriate headers' do
        headers = double('headers', :[] => nil, :[]= => nil, each: nil)
        allow_any_instance_of(Rack::Response).to receive(:headers).and_return(headers)
        expect(MAPI::Services::Member).to receive(:stream_attachment).with(anything, headers, any_args)
        call_endpoint
      end
      it 'calls `stream_attachment` with the appropriate data stream' do
        stream = double(IO)
        allow(File).to receive(:open).and_return(stream)
        expect(MAPI::Services::Member).to receive(:stream_attachment).with(anything, anything, stream, any_args)
        call_endpoint
      end
      it 'calls `stream_attachment` with the appropriate file size' do
        size = double(Integer)
        allow(File).to receive(:size).with(file_location).and_return(size)
        expect(MAPI::Services::Member).to receive(:stream_attachment).with(anything, anything, anything, size, any_args)
        call_endpoint
      end
      it 'calls `stream_attachment` with a content type of `application/pdf`' do
        expect(MAPI::Services::Member).to receive(:stream_attachment).with(anything, anything, anything, anything, 'application/pdf', anything)
        call_endpoint
      end
      it 'calls `stream_attachment` with the appropriate file name' do
        file_name = "attachment; filename=\"advance-confirmation-#{confirmation_number}.pdf\""
        expect(MAPI::Services::Member).to receive(:stream_attachment).with(anything, anything, anything, anything, anything, file_name)
        call_endpoint
      end
      it 'returns a 404 if no advance confirmation is found' do
        allow(MAPI::Services::Member::TradeActivity).to receive(:advance_confirmation)
        call_endpoint
        expect(last_response.status).to eq(404)
      end
      it 'returns a 503 if there is an internal error' do
        allow(MAPI::Services::Member::TradeActivity).to receive(:advance_confirmation).and_raise('Some Exception')
        call_endpoint
        expect(last_response.status).to eq(503)
      end
    end

    describe 'the `stream_attachment` class method' do
      let(:input_stream) { double(IO, :eof? => true, close: nil, read: nil) }
      let(:output_stream) { double(IO, close: nil, string: nil, flush: nil, write: nil) }
      let(:headers) { double('headers', :[] => nil, :[]= => nil) }
      let(:file_size) { rand(1..9999) }
      let(:content_type) { double(String) }
      let(:file_name) { double(String) }
      let(:call_method) { MAPI::Services::Member.stream_attachment(false, headers, input_stream, file_size, content_type, file_name) }

      it 'sets the header `Content-Length`' do
        expect(headers).to receive(:[]=).with('Content-Length', file_size.to_s)
        call_method
      end
      it 'sets the header `Content-Type`' do
        expect(headers).to receive(:[]=).with('Content-Type', content_type)
        call_method
      end
      it 'sets the header `Content-Disposition`' do
        expect(headers).to receive(:[]=).with('Content-Disposition', file_name)
        call_method
      end
      describe 'when `hijack_available`' do
        let(:call_method) { MAPI::Services::Member.stream_attachment(true, headers, input_stream, file_size, content_type, file_name) }
        it 'sets the header `rack.hijack` to the hijack_stream_processor proc' do
          expect(headers).to receive(:[]=).with('rack.hijack', an_instance_of(Proc))
          call_method
        end
      end
      describe 'when hijack not available' do
        it 'returns the written data stream as a string' do
          stringed_io =  double(String)
          allow(StringIO).to receive(:new).and_return(output_stream)
          allow(output_stream).to receive(:string).and_return(stringed_io)
          expect(call_method).to eq(stringed_io)
        end
      end
      describe 'the `hijack_stream_processer` proc' do
        before do
          allow(StringIO).to receive(:new).and_return(output_stream)
        end
        describe 'while the input stream is being read' do
          before do
            allow(input_stream).to receive(:eof?).and_return(false, true)
          end
          it 'writes 1024 bytes of data from the input stream to the output stream' do
            bytes = double('bytes of data')
            allow(input_stream).to receive(:read).with(1024).and_return(bytes)
            expect(output_stream).to receive(:write).with(bytes)
            call_method
          end
          it 'flushes the output stream after writing to it' do
            expect(output_stream).to receive(:write).ordered
            expect(output_stream).to receive(:flush).ordered
            call_method
          end
        end
        describe 'once the input stream has been read' do
          it 'closes the input stream' do
            expect(input_stream).to receive(:close)
            call_method
          end
          it 'closes the output stream' do
            expect(output_stream).to receive(:close)
            call_method
          end
        end
      end
    end

    describe 'the `advance_confirmation` class method' do
      let(:app) { double(MAPI::ServiceApp) }
      let(:member_id) { rand(1..9999) }
      let(:advance_number) { rand(1000..999999) }
      let(:confirmation_number) { rand(1000..999999) }
      let(:date_offset) { (1..50).to_a.sample }
      let(:random) { double('seeded random', rand: 1) }
      let(:call_method) { MAPI::Services::Member::TradeActivity.advance_confirmation(app, member_id, advance_number) }
      before do
        allow(Random).to receive(:new).and_return(random)
      end

      it 'returns an empty array if passed no advance numbers' do
        expect(MAPI::Services::Member::TradeActivity.advance_confirmation(app, member_id, nil)).to eq([])
      end
      it 'succeeds if passed a single advance number' do
        expect{call_method}.not_to raise_error
      end
      it 'succeeds if passed an array of advance numbers' do
        expect{MAPI::Services::Member::TradeActivity.advance_confirmation(app, member_id, [1,2,3,4,5])}.not_to raise_error
      end
      it 'returns an empty array if no results are found' do
        allow(random).to receive(:rand).and_return(0, date_offset, confirmation_number)
        expect(call_method).to eq([])
      end
      it 'returns an an advance confirmation object for each advance confirmation found' do
        n = rand(1..10)
        allow(random).to receive(:rand).and_return(n, date_offset, confirmation_number)
        expect(call_method.length).to eq(n)
      end
      describe 'an advance confirmation object' do
        before do
          allow(random).to receive(:rand).and_return(1, date_offset, confirmation_number)
        end
        it 'contains a `confirmation_date`' do
          expect(call_method.first[:confirmation_date]).to eq(Time.zone.today - date_offset.days)
        end
        it 'contains a `confirmation_number`' do
          expect(call_method.first[:confirmation_number]).to eq(confirmation_number)
        end
        it 'contains the supplied `member_id`' do
          expect(call_method.first[:member_id]).to eq(member_id)
        end
        it 'contains the supplied `advance_number`' do
          expect(call_method.first[:advance_number]).to eq(advance_number)
        end
        it 'contains the proper location for the fake `advance_confirmation.pdf`' do
          expect(call_method.first[:file_location]).to eq(File.join(MAPI.root, 'fakes', 'advance_confirmation.pdf'))
        end
        describe 'when passed an advance confirmation number' do
          it 'returns the matching advance confirmation object if found' do
            result = MAPI::Services::Member::TradeActivity.advance_confirmation(app, member_id, advance_number, confirmation_number)
            expect(result[:confirmation_number]).to eq(confirmation_number)
          end
          it 'returns nil if no match is found' do
            result = MAPI::Services::Member::TradeActivity.advance_confirmation(app, member_id, advance_number, confirmation_number - rand(1..99))
            expect(result).to be_nil
          end
        end
      end
    end
  end
end