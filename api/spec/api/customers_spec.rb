require 'spec_helper'

describe MAPI::ServiceApp do
  describe 'GET /customers/:email/' do
    let(:email) { 'local@example.com' }
    let(:make_request) { get "/customers/#{email}/" }
    let(:json) { make_request; JSON.parse(last_response.body) }
    let(:phone) { SecureRandom.uuid }
    let(:title) { SecureRandom.uuid }
    let(:customers_response) { {:phone => phone, :title => title} }
    [:production, :test, :development].each do |env|
      describe "in the `#{env}` environment" do
        before do
          allow(MAPI::ServiceApp).to receive(:environment).and_return(env)
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
      end
    end
  end
end