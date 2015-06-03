require 'spec_helper'
require 'date'

describe MAPI::ServiceApp do

  before do
    header 'Authorization', "Token token=\"#{ENV['MAPI_SECRET_TOKEN']}\""
  end

  describe 'Trade Activity' do
    let(:advances) { get "/member/#{MEMBER_ID}/active_advances"; JSON.parse(last_response.body) }
    it 'should return expected advances detail hash where value could not be nil' do
      advances.each do |row|
        expect(row['trade_date']).to be_kind_of(String)
        expect(row['funding_date']).to be_kind_of(String)
        expect(row['maturity_date']).to be_kind_of(String)
        expect(row['advance_number']).to be_kind_of(String)
        expect(row['advance_type']).to be_kind_of(String)
        expect(row['status']).to be_kind_of(String)
        expect(row['interest_rate']).to be_kind_of(Numeric)
        expect(row['current_par']).to be_kind_of(Numeric)
      end
    end
    describe 'in the production environment' do
      before do
        expect(MAPI::ServiceApp).to receive(:environment).at_least(1).and_return(:production)
      end
      it 'should return active advances', vcr: {cassette_name: 'trade_activity_service'} do
        advances.each do |row|
          expect(row['trade_date']).to be_kind_of(String)
          expect(row['funding_date']).to be_kind_of(String)
          expect(row['maturity_date']).to be_kind_of(String)
          expect(row['advance_number']).to be_kind_of(String)
          expect(row['advance_type']).to be_kind_of(String)
          expect(row['status']).to be_kind_of(String)
          expect(row['interest_rate']).to be_kind_of(Numeric)
          expect(row['current_par']).to be_kind_of(Numeric)
        end
      end
      it 'should return Internal Service Error, if trade service is unavailable', vcr: {cassette_name: 'trade_activity_service_unavailable'} do
        get "/member/#{MEMBER_ID}/active_advances"
        expect(last_response.status).to eq(503)
      end
    end
  end
end