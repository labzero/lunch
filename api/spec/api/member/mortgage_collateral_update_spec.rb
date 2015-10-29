require 'spec_helper'

describe MAPI::ServiceApp do
  let(:member_id) { rand(1111..9999) }

  before do
    header 'Authorization', "Token token=\"#{ENV['MAPI_SECRET_TOKEN']}\""
  end

  describe 'the mortgage_collateral_update endpoint' do
    let(:call_endpoint) { get "/member/#{member_id}/mortgage_collateral_update" }
    let(:response) { double('response') }
    before { allow(MAPI::Services::Member::MortgageCollateralUpdate).to receive(:mortgage_collateral_update).and_return(response) } 
    it 'calls the `mortgage_collateral_update` method with the member id' do
      expect(MAPI::Services::Member::MortgageCollateralUpdate).to receive(:mortgage_collateral_update).with(anything, member_id.to_s)
      call_endpoint
    end
    it 'returns the results of the method call as JSON' do
      expect(response).to receive(:to_json)
      call_endpoint
    end
    it 'returns a 200 if there are no errors' do
      call_endpoint
      expect(last_response.status).to eq(200)
    end
    describe 'error states' do
      let(:error) { Savon::Error }
      before { allow(MAPI::Services::Member::MortgageCollateralUpdate).to receive(:mortgage_collateral_update).and_raise(error) }
      it 'logs any Savon::Error that arises' do
        expect(ActiveRecord::Base.logger).to receive(:error).with(error)
        call_endpoint
      end
      it 'returns a 503 if there is a Savon::Error' do
        call_endpoint
        expect(last_response.status).to eq(503)
      end
    end
  end
  
  describe 'the mortgage_collateral_update method' do
    string_fields = MAPI::Services::Member::MortgageCollateralUpdate::STRING_FIELDS
    integer_fields = MAPI::Services::Member::MortgageCollateralUpdate::INTEGER_FIELDS
    let(:date_doubles) { {date_processed: double('date_processed', downcase: nil)} }
    let(:string_doubles) { Hash[( string_fields.map { |key| [key.to_s, double(key, to_s: nil)] } )].with_indifferent_access }
    let(:integer_doubles) { Hash[( integer_fields.map { |key| [key.to_s, double(key, round: nil)] } )].with_indifferent_access  }
    let(:mcu_data) { integer_doubles.merge(string_doubles).merge(date_doubles).with_indifferent_access }
    let(:call_method) { MAPI::Services::Member::MortgageCollateralUpdate.mortgage_collateral_update(env, member_id) }
    
    before { allow(Date).to receive(:parse).with(mcu_data[:date_processed]) }
    
    [:development, :test, :production].each do |env|
      describe "in the #{env} environment" do
        let(:call_method) { MAPI::Services::Member::MortgageCollateralUpdate.mortgage_collateral_update(env, member_id) }
        
        if env == :production
          let(:sql_response) { double('result of sql query') }
          before do
            allow(ActiveRecord::Base.connection).to receive(:execute).and_return(sql_response)
            allow(sql_response).to receive(:fetch_hash).and_return(mcu_data)
          end
          
          # tests specific to production environment
          it 'executes a SQL query on the ActiveRecord::Base.connection' do
            expect(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String))
            call_method
          end
          it 'fetches a hash of the results of the SQL query' do
            expect(sql_response).to receive(:fetch_hash)
            call_method
          end
        else
          before { allow(MAPI::Services::Member::MortgageCollateralUpdate).to receive(:fake_hash).with('mortgage_collateral_update').and_return(mcu_data) }

          # test specific to development and test environments
          it 'calls the `fake_hash` class method with `mortgage_collateral_update` to fetch the fake data' do
            expect(MAPI::Services::Member::MortgageCollateralUpdate).to receive(:fake_hash).with('mortgage_collateral_update')
            call_method
          end
        end

        # tests common to all environments
        it 'parses the `date_processed` field into a date if it is available' do
          expect(Date).to receive(:parse).with(mcu_data[:date_processed])
          call_method
        end
        string_fields.each do |field|
          it "sets the `#{field}` field with the proper string" do
            allow(mcu_data[field]).to receive(:to_s).and_return(mcu_data[field])
            expect(call_method[field]).to eq(mcu_data[field])
          end
        end
        integer_fields.each do |field|
          it "sets the `#{field}` field with the proper rounded integer" do
            allow(mcu_data[field]).to receive(:round).and_return(mcu_data[field])
            expect(call_method[field]).to eq(mcu_data[field])
          end
        end
      end
    end
  end  
end