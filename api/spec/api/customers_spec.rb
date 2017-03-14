require 'spec_helper'

describe MAPI::ServiceApp do
  describe 'GET /customers/:email/' do
    let(:email) { 'local@example.com' }
    let(:make_request) { get "/customers/#{email}/" }
    let(:json) { make_request; JSON.parse(last_response.body) }
    let(:phone) { SecureRandom.uuid }
    let(:title) { SecureRandom.uuid }
    let(:customers_response) { {:phone => phone, :title => title} }
    let(:logger) { instance_double(Logger, error: nil) }
    [:production, :test, :development].each do |env|
      describe "in the `#{env}` environment" do
        before do
          allow(MAPI::ServiceApp).to receive(:environment).and_return(env)
          allow_any_instance_of(described_class).to receive(:logger).and_return(logger)
          allow(MAPI::Services::Customers::Details).to receive(:customer_details).and_return(customers_response)
        end
        it 'returns a 404 if no customers email is supplied' do
          get '/customers/'
          expect(last_response.status).to eq(404)
        end
        it 'returns a 200 if a known customers email is supplied' do
          make_request
          expect(last_response.status).to eq(200)
        end
        it 'returns customer phone' do
          expect(json['phone']).to eq(phone)
        end
        it 'returns customer title' do
          expect(json['title']).to eq(title)
        end

        describe 'if an unknonw email is supplied' do
          before do
            allow(MAPI::Services::Customers::Details).to receive(:customer_details).and_return(nil)
          end
          it 'returns a 404' do
            make_request
            expect(last_response.status).to eq(404)
          end
          it 'logs the error' do
            expect(logger).to receive(:error).with('Customer not found')
            make_request
          end
        end
      end
    end
  end
end