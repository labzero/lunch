require 'spec_helper'

describe MAPI::ServiceApp do
  describe 'customer details' do
    let(:email) { SecureRandom.uuid }
    let(:call_method) { MAPI::Services::Customers::Details.customer_details(subject, ActiveRecord::Base.logger, email) }
    let(:phone) { SecureRandom.uuid }
    let(:title) { SecureRandom.uuid }
    let(:customers_response) { {'PHONE' => phone, 'TITLE'=> title} }
    let(:development_json) {
      {
          'PHONE' => phone,
          'TITLE' => title
      }
    }
    [:production, :test, :development].each do |env|
      describe "in the `#{env}` environment" do
        before do
          allow(File).to receive(:read) do
            development_json.to_json
          end
          allow(MAPI::ServiceApp).to receive(:environment).and_return(env)
          allow(MAPI::Services::Customers::Details).to receive(:fetch_hash).and_return(customers_response)
        end
        it 'returns nil if no user_email is supplied' do
          expect(MAPI::Services::Customers::Details.customer_details(subject, ActiveRecord::Base.logger, nil)).to eq(nil)
        end
        if env == :production
          it 'returns nil if customer data is not found' do
            allow(MAPI::Services::Customers::Details).to receive(:fetch_hash).and_return(nil)
            expect(call_method).to eq(nil)
          end
        end
        it 'returns customer phone' do
          expect(call_method[:phone]).to eq(phone)
        end
        it 'returns customer title' do
          expect(call_method[:title]).to eq(title)
        end
      end
    end
  end
end