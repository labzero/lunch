require 'rails_helper'

describe StreamingHelper do
  describe '`stream_attachment_processor`' do
    let(:response) { double('response arg', headers: {}, :body= => nil, :status= => nil) }
    let(:headers) do
      {
        'Content-Type' => double(String),
        'Content-Disposition' => double(String),
        'Content-Length' => double(String)
      }
    end
    let(:body) { double('body') }
    let(:processor) { helper.stream_attachment_processor(response) }

    describe 'when the status is 200' do
      let(:call_method) { processor.call(200, headers, body) }
      ['Content-Type', 'Content-Disposition', 'Content-Length'].each do |key|
        it 'assigns `#{key}` to the response headers if present' do
          call_method
          expect(response.headers[key]).to eq(headers[key])
        end
        it 'does not assign `#{key}` to the response headers if `#{key}` is not present' do
          processor.call(200, {}, body)
          expect(response.headers[key]).to be_nil
        end
      end
      it 'assigns the `Cache-Control` response header a value of `no-cache`' do
        call_method
        expect(response.headers['Cache-Control']).to eq('no-cache')
      end
      it 'assigns the response body the value of its `body` arg' do
        expect(response).to receive(:body=).with(body)
        call_method
      end
    end
    describe 'when the status is 404' do
      let(:call_method) { processor.call(404, headers, body) }
      it 'raises an `ActionController::RoutingError`' do
        expect{call_method}.to raise_error(ActionController::RoutingError, 'Not Found')
      end
      it 'sets the response status to 404' do
        expect(response).to receive(:status=).with(404)
        begin
          processor.call(404, headers, body)
        rescue
        end
      end
    end
    describe 'when the status is not a 200 or a 404' do
      let(:status) { double(Integer, :== => nil, :>= => nil) }
      let(:call_method) { processor.call(status, headers, body) }
      before do
        allow(status).to receive(:to_i).and_return(status)
      end
      it 'raises a `StandardError` when the status is greater than or equal to 500' do
        allow(status).to receive(:>=).with(500).and_return(true)
        expect{call_method}.to raise_error(StandardError, 'Stream Error')
      end
      it 'sets the response status' do
        expect(response).to receive(:status=).with(status)
        call_method
      end
    end
  end
end