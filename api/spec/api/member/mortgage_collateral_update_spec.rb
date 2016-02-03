require 'spec_helper'

describe MAPI::ServiceApp do
  describe 'the mortgage_collateral_update endpoint' do
    let(:call_endpoint) { get "/member/#{member_id}/mortgage_collateral_update" }
    let(:response) { double('response') }
    before { allow(MAPI::Services::Member::MortgageCollateralUpdate).to receive(:mortgage_collateral_update).and_return(response) }
    it 'calls the `mortgage_collateral_update` method with the logger' do
      expect(MAPI::Services::Member::MortgageCollateralUpdate).to receive(:mortgage_collateral_update).with(anything, ActiveRecord::Base.logger, anything)
      call_endpoint
    end
    it 'calls the `mortgage_collateral_update` method with the member id' do
      expect(MAPI::Services::Member::MortgageCollateralUpdate).to receive(:mortgage_collateral_update).with(anything, anything, member_id)
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
    string_fields  = %w(mcu_type pledge_type transaction_number).map(&:upcase)
    integer_fields = %w(accepted_count depledged_count pledged_count rejected_count renumbered_count total_count updated_count).map(&:upcase)
    float_fields   = %w(accepted_unpaid depledged_unpaid pledged_unpaid rejected_unpaid renumbered_unpaid total_unpaid updated_unpaid
                        accepted_original depledged_original pledged_original rejected_original renumbered_original total_original updated_original).map(&:upcase)
    let(:date_processed_string) { double('date_processed_string')}
    let(:date_doubles) {  { 'DATE_PROCESSED' => double('date_processed', to_s: date_processed_string)} }
    let(:string_doubles)  { Hash[(  string_fields.map { |key| [key, double(key, to_s: nil)] } )].with_indifferent_access }
    let(:integer_doubles) { Hash[( integer_fields.map { |key| [key, double(key, to_i: nil)] } )].with_indifferent_access }
    let(:float_doubles)   { Hash[(   float_fields.map { |key| [key, double(key, to_f: nil)] } )].with_indifferent_access }
    let(:mcu_data) { float_doubles.merge(integer_doubles).merge(string_doubles).merge(date_doubles).with_indifferent_access }
    let(:logger) { double('logger') }

    before { allow(Date).to receive(:parse).with(date_processed_string) }

    [:development, :test, :production].each do |env|
      describe "in the #{env} environment" do
        let(:call_method) { MAPI::Services::Member::MortgageCollateralUpdate.mortgage_collateral_update(env, logger, member_id) }

        if env == :production
          before { allow(MAPI::Services::Member::MortgageCollateralUpdate).to receive(:fetch_hash).and_return(mcu_data) }
          
          # tests specific to production environment
          it 'calls the shared utility function `fetch_hash` with the logger as an argument' do
            expect(MAPI::Services::Member::MortgageCollateralUpdate).to receive(:fetch_hash).with(logger, anything)
            call_method
          end
          it 'calls the shared utility function `fetch_hash` with the proper sql query' do
            sql_query = MAPI::Services::Member::MortgageCollateralUpdate::Private.mcu_sql(member_id)
            expect(MAPI::Services::Member::MortgageCollateralUpdate).to receive(:fetch_hash).with(anything, sql_query)
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
        it 'sets the `date_processed` field to the value of the returned data' do
          expect(call_method[:date_processed]).to eq(Date.parse(mcu_data['DATE_PROCESSED'].to_s))
        end
        string_fields.each do |field|
          it "sets the `#{field.downcase}` field with the proper string" do
            allow(mcu_data[field]).to receive(:to_s).and_return(mcu_data[field])
            expect(call_method[field.downcase]).to eq(mcu_data[field])
          end
        end
        integer_fields.each do |field|
          it "sets the `#{field.downcase}` field with the proper integer" do
            allow(mcu_data[field]).to receive(:to_i).and_return(mcu_data[field])
            expect(call_method[field.downcase]).to eq(mcu_data[field])
          end
        end
        float_fields.each do |field|
          it "sets the `#{field.downcase}` field with the proper float" do
            allow(mcu_data[field]).to receive(:to_f).and_return(mcu_data[field])
            expect(call_method[field.downcase]).to eq(mcu_data[field])
          end
        end
      end
    end
  end
end