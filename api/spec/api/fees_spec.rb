require 'spec_helper'

describe MAPI::ServiceApp do
  before do
    header 'Authorization', "Token token=\"#{ENV['MAPI_SECRET_TOKEN']}\""
  end

  describe 'the fee_schedules endpoint' do
    let(:call_endpoint) { get "/fees/schedules" }
    let(:response) { double('response') }
    before { allow(MAPI::Services::Fees).to receive(:fee_schedules).and_return(response) }
    it 'calls the `fee_schedules` method with the logger' do
      expect(MAPI::Services::Fees).to receive(:fee_schedules).with(anything, ActiveRecord::Base.logger)
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
      before { allow(MAPI::Services::Fees).to receive(:fee_schedules).and_raise(error) }
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

  describe 'the fee_schedules method' do
    let(:securities_services_data) { double('securities services data') }
    let(:securities_services_fees) { double('processed securities services fees') }
    let(:wire_transfer_and_sta_fees) { double('wire_transfer_and_sta fees') }
    let(:letters_of_credit_fees) { double('letters_of_credit fees') }
    let(:file) { double('file') }
    let(:yaml_hash) { double('hash from yaml file', :with_indifferent_access => {}, :[] => nil) }
    let(:logger) { double('logger') }
    
    before do
      allow(File).to receive(:read).with(File.join(MAPI.root, 'config', 'fees.yml')).and_return(file)
      allow(YAML).to receive(:load).with(file).and_return(yaml_hash)
      allow(MAPI::Services::Fees::Private).to receive(:process_securities_services_fees) 
    end 

    [:development, :test, :production].each do |env|
      describe "in the #{env} environment" do
        let(:call_method) { MAPI::Services::Fees.fee_schedules(env, logger) }

        if env == :production
          before { allow(MAPI::Services::Fees).to receive(:fetch_hashes).and_return(securities_services_data) }

          # tests specific to production environment
          it 'calls the shared utility function `fetch_hashes` with the logger as an argument' do
            expect(MAPI::Services::Fees).to receive(:fetch_hashes).with(logger, anything)
            call_method
          end
          it 'calls the shared utility function `fetch_hashes` with the proper sql query' do
            expect(MAPI::Services::Fees).to receive(:fetch_hashes).with(anything, MAPI::Services::Fees::SECURITIES_SERVICES_FEE_SQL)
            call_method
          end
        else
          before { allow(MAPI::Services::Fees).to receive(:fake).with('securities_services_fees').and_return(securities_services_data) }

          # test specific to development and test environments
          it 'calls the `fake` class method with `securities_services_fees` to fetch the fake data' do
            expect(MAPI::Services::Fees).to receive(:fake).with('securities_services_fees')
            call_method
          end
        end
        
        #tests for all environments
        it 'calls the Private method `process_securities_services_fees` with the securities services data' do
          expect(MAPI::Services::Fees::Private).to receive(:process_securities_services_fees).with(securities_services_data)
          call_method
        end
        it 'loads `fees.yml` from the /config folder into a hash with indifferent access' do
          expect(yaml_hash).to receive(:with_indifferent_access)
          call_method
        end
        it 'returns a hash with a `securities_services` value set to the result of the `process_securities_services_fees` method' do
          allow(MAPI::Services::Fees::Private).to receive(:process_securities_services_fees).and_return(securities_services_fees)
          expect(call_method[:securities_services]).to eq(securities_services_fees)
        end
        it 'returns a hash with a `wire_transfer_and_sta` value set to the corresponding value loaded from the YAML file' do
          allow(yaml_hash).to receive(:with_indifferent_access).and_return(yaml_hash)
          allow(yaml_hash).to receive(:[]).with(:wire_transfer_and_sta).and_return(wire_transfer_and_sta_fees)
          expect(call_method[:wire_transfer_and_sta]).to eq(wire_transfer_and_sta_fees)
        end
        it 'returns a hash with a `letters_of_credit` value set to the corresponding value loaded from the YAML file' do
          allow(yaml_hash).to receive(:with_indifferent_access).and_return(yaml_hash)
          allow(yaml_hash).to receive(:[]).with(:letters_of_credit).and_return(letters_of_credit_fees)
          expect(call_method[:letters_of_credit]).to eq(letters_of_credit_fees)
        end
      end
    end
  end
  
  describe 'the `process_securities_services_fees` Private method' do
    let(:value) { double('a value in the row object hash') }
    let(:specific_row) { double('a row double used to stub a specific row', :[] => nil) }
    let(:row) { double('a row double used to stub all rows', :[] => nil) }
    let(:fees) { double('an array of fee objects') }
    let(:call_method) { MAPI::Services::Fees::Private.process_securities_services_fees(fees) }
    before { allow(MAPI::Services::Fees::Private).to receive(:find_row).and_return(row) }

    shared_examples 'a process_securities_services_fees attribute' do |response_key, row_id, row_key, operation|
      it "calls `find_row` with the fees it was passed and `#{row_id}`" do
        expect(MAPI::Services::Fees::Private).to receive(:find_row).with(fees, row_id)
        call_method
      end
      it "finds the value for `#{row_key}` in the hash returned from `find_row`" do
        expect(row).to receive(:[]).with(row_key)
        call_method
      end
      it "tries to call #{operation} on the `#{row_key}` value" do
        allow(MAPI::Services::Fees::Private).to receive(:find_row).with(anything, row_id).and_return(specific_row)
        allow(specific_row).to receive(:[]).with(row_key).and_return(value)
        expect(value).to receive(:try).with(operation)
        call_method
      end
    end
    
    {
      monthly_maintenance: [
        [:less_than_10, :maintenance_fee_1_to_9, 'MAINT_FEE', :to_f], 
        [:between_10_and_24, :maintenance_fee_10_to_24, 'MAINT_FEE', :to_f], 
        [:more_than_24, :maintenance_fee_25_or_more, 'MAINT_FEE', :to_f]
      ],
      monthly_securities: [
        [:fed, :federal_securities, 'FEE_PER_LOT', :to_f],
        [:dtc, :depository_securities, 'FEE_PER_LOT', :to_f],
        [:physical, :physical_securities, 'FEE_PER_LOT', :to_f]
      ],
      security_transaction: [
        [:fed, :federal_securities, 'FEE_PER_TRANS', :to_f],
        [:dtc, :depository_securities, 'FEE_PER_TRANS', :to_f],
        [:physical, :physical_securities, 'FEE_PER_TRANS', :to_f],
        [:euroclear, :euroclear_securities, 'FEE_PER_TRANS', :to_f],
      ],
      miscellaneous: [
        [:all_income_disbursement, :all_income_disbursements, 'FEE_PER_TRANS', :to_f],
        [:pledge_status_change, :pledge_status_change, 'FEE_PER_TRANS', :to_f],
        [:certificate_registration, :certificate_registration, 'FEE_PER_TRANS', :to_f],
        [:research_projects, :research_projects, 'HOURLY_RATE', :to_f],
        [:special_handling, :special_handling, 'FEE_PER_TRANS', :to_f]
      ],
      monthly_securities_euroclear_values: [
        [:fee_per_par, :euroclear_securities, 'FEE_PER_PAR', :to_f], 
        [:per_par_amount, :euroclear_securities, 'PER_PAR_AMOUNT', :to_i]
      ]
    }.each do |response_subhash, subhash_values|
      subhash_values.each do |test_values|
        response_key = test_values[0]
        row_id = test_values[1]
        row_key = test_values[2]
        operation = test_values[3]

        if response_subhash == :monthly_securities_euroclear_values
          describe "the `#{response_key}` value in the `euroclear` subhash of the `monthly_securities` hash" do
            it_behaves_like 'a process_securities_services_fees attribute', response_key, row_id, row_key, operation

            it "returns the proper value for [:monthly_securities][:euroclear][#{response_key}]" do
              allow(MAPI::Services::Fees::Private).to receive(:find_row).with(anything, row_id).and_return(specific_row)
              allow(specific_row).to receive(:[]).with(row_key).and_return(value)
              allow(value).to receive(:try).with(operation).and_return(value)
              expect(call_method[:monthly_securities][:euroclear][response_key]).to eq(value)
            end
          end
        else
          describe "the `#{response_key}` value in the `#{response_subhash}` hash" do
            it_behaves_like 'a process_securities_services_fees attribute', response_key, row_id, row_key, operation

            it "returns the proper value for [#{response_subhash}][#{response_key}]" do
              allow(MAPI::Services::Fees::Private).to receive(:find_row).with(anything, row_id).and_return(specific_row)
              allow(specific_row).to receive(:[]).with(row_key).and_return(value)
              allow(value).to receive(:try).with(operation).and_return(value)
              expect(call_method[response_subhash][response_key]).to eq(value)
            end
          end
        end
      end
    end
  end
  
  describe 'the `find_row` Private method' do
    let(:map) { MAPI::Services::Fees::SECURITIES_SERVICES_FEE_MAPPING }
    let(:key) { map.keys.sample }
    let(:matched_row_1) { double('a matching row') }
    let(:matched_row_2) { double('another matching row') }
    let(:rows) { [matched_row_1, matched_row_2] }
    let(:call_method) { MAPI::Services::Fees::Private.send(:find_row, rows, key) }
    before do
      allow(matched_row_1).to receive(:[]).with('BF_ROW_ID').and_return(map[key])
      allow(matched_row_2).to receive(:[]).with('BF_ROW_ID').and_return(map[key])
    end
    
    it 'returns only the first row it finds whose `BF_ROW_ID` matches the one mapped to by the given key' do
      expect(call_method).to eq(matched_row_1)
      expect(call_method).to_not eq(matched_row_2)
    end
    it 'returns an empty hash if no matches are found' do
      allow(matched_row_1).to receive(:[]).with('BF_ROW_ID').and_return(map[key]+1)
      allow(matched_row_2).to receive(:[]).with('BF_ROW_ID').and_return(map[key]+1)
      expect(call_method).to eq({})
    end
    it 'raises an "Invalid mapping" error if an invalid key is passed' do
      expect{MAPI::Services::Fees::Private.send(:find_row, rows, 'foo')}.to raise_error('Invalid mapping')
    end
  end
end