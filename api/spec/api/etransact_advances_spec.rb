require 'spec_helper'

describe MAPI::ServiceApp do
  describe 'get `etransact_advances/limits`' do
    let(:call_endpoint) { get 'etransact_advances/limits' }

    it_behaves_like 'a MAPI endpoint with JSON error handling', 'etransact_advances/limits', :get, MAPI::Services::EtransactAdvances::Limits, :get_limits

    it 'calls `MAPI::Services::EtransactAdvances::Limits.get_limits` with the app' do
      expect(MAPI::Services::EtransactAdvances::Limits).to receive(:get_limits).with(an_instance_of(MAPI::ServiceApp))
      call_endpoint
    end
  end

  describe 'put `etransact_advances/limits`' do
    let(:post_body) { {"params" => "#{SecureRandom.hex}"} }
    let(:call_endpoint) { put 'etransact_advances/limits', post_body.to_json }

    it_behaves_like 'a MAPI endpoint with JSON error handling', 'etransact_advances/limits', :put, MAPI::Services::EtransactAdvances::Limits, :update_limits, "{}"

    it 'calls `MAPI::Services::EtransactAdvances::Limits.update_limits` with the app' do
      expect(MAPI::Services::EtransactAdvances::Limits).to receive(:update_limits).with(an_instance_of(MAPI::ServiceApp), anything)
      call_endpoint
    end
    it 'calls `MAPI::Services::EtransactAdvances::Limits.update_limits` with the parsed post body' do
      expect(MAPI::Services::EtransactAdvances::Limits).to receive(:update_limits).with(an_instance_of(MAPI::ServiceApp), post_body)
      call_endpoint
    end
    it 'returns a JSONd empty hash in the response body if the `update_limits` method is successful' do
      allow(MAPI::Services::EtransactAdvances::Limits).to receive(:update_limits).and_return(true)
      call_endpoint
      expect(last_response.body).to eq({}.to_json)
    end
  end

  describe "etransact advances status" do
    let(:etransact_advances_status) { get '/etransact_advances/status'; JSON.parse(last_response.body) }
    it "should return 2 etransact advances status" do
      expect(etransact_advances_status.length).to be >=1
      expect(etransact_advances_status['etransact_advances_status']).to be_boolean
      expect(etransact_advances_status['wl_vrc_status']).to be_boolean
      expect(etransact_advances_status['eod_reached']).to be_boolean
      expect(etransact_advances_status['enabled']).to be_boolean
    end
    it 'should return all_loan_status hash' do
      expect(etransact_advances_status['all_loan_status'].length).to be >=1
    end
    it 'should return the expected status type and label for ALL LOAN_TERMS, LOAN_TYPES' do
      result = etransact_advances_status['all_loan_status']
      MAPI::Services::Rates::LOAN_TERMS.each do |term|
         MAPI::Services::Rates::LOAN_TYPES.each do |type|
             expect(result[term.to_s][type.to_s]['trade_status']).to be_boolean
             expect(result[term.to_s][type.to_s]['display_status']).to be_boolean
             expect(result[term.to_s][type.to_s]['bucket_label']).to be_kind_of(String)
         end
       end
    end
    describe 'in the production environment for cases when etransact is turned off' do
      # let!(:some_status_data) {[1, 'Open and O/N', 'N', 'Y', 'Y', 'Y', '2000', '01-JAN-2006 12:00 AM', '0700']}
      let!(:some_status_data) {{"AO_TERM_BUCKET_ID" => 1, "TERM_BUCKET_LABEL"=> "Open and O/N", "WHOLE_LOAN_ENABLED"=>  "N", "SBC_AGENCY_ENABLED"=> "Y", "SBC_AAA_ENABLED" =>  "Y",
                                 "SBC_AA_ENABLED"=>  "Y", "END_TIME" => "2000",  "OVERRIDE_END_DATE" =>  "2006-01-01", "OVERRIDE_END_TIME"=>  "0700"}}
      let(:result_set) {double('Oracle Result Set', fetch: nil)}
      let(:result_set2) {double('Oracle Result Set', fetch: nil)}
      let(:result_set3) {double('Oracle Result Set', fetch: nil)}
      let(:result_set4) {double('Oracle Result Set', fetch_hash: nil)}
      before do
        allow(MAPI::ServiceApp).to receive(:environment).and_return(:production)
        allow(ActiveRecord::Base).to receive(:connection).and_return(double('OCI8 Connection'))
        allow(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(result_set,result_set2,result_set3,result_set4)
      end
      it 'should still return the expected status type and label for ALL LOAN_TERMS, LOAN_TYPES' do
        expect(etransact_advances_status.length).to be >=1
        expect(etransact_advances_status['etransact_advances_status']).to be_boolean
        expect(etransact_advances_status['wl_vrc_status']).to be_boolean
        result = etransact_advances_status['all_loan_status']
        MAPI::Shared::Constants::LOAN_TERMS.each do |term|
          MAPI::Shared::Constants::LOAN_TYPES.each do |type|
            expect(result[term.to_s][type.to_s]['trade_status']).to be_boolean
            expect(result[term.to_s][type.to_s]['display_status']).to be_boolean
            expect(result[term.to_s][type.to_s]['bucket_label']).to be_kind_of(String)
          end
        end
      end
      it 'should return false status if no data found' do
          expect(etransact_advances_status.length).to be >=1
          expect(etransact_advances_status['etransact_advances_status']).to be false
          expect(etransact_advances_status['wl_vrc_status']).to be false
          result = etransact_advances_status['all_loan_status']
          MAPI::Shared::Constants::LOAN_TERMS.each do |term|
            MAPI::Shared::Constants::LOAN_TYPES.each do |type|
              expect(result[term.to_s][type.to_s]['trade_status']).to be false
              expect(result[term.to_s][type.to_s]['display_status']).to be false
              expect(result[term.to_s][type.to_s]['bucket_label']).to eq("NotFound")
           end
         end
      end
    end
    describe 'in the production enviroment for cases when etransact is turned on' do
      let(:now_time_string)       { double( 'now time as HHMM')}
      let(:now)                   { double( 'Time.zone.now' ) }
      let(:now_date)              { double( 'now date') }
      let(:long_ago_date)         { double( 'long ago date' ) }
      let(:hash1) do
        {
            "AO_TERM_BUCKET_ID"  => 1,
            "TERM_BUCKET_LABEL"  => "Open and O/N",
            "WHOLE_LOAN_ENABLED" => "Y",
            "SBC_AGENCY_ENABLED" => "Y",
            "SBC_AAA_ENABLED"    => "Y",
            "SBC_AA_ENABLED"     => "Y",
            "END_TIME"           => "0001",
            "OVERRIDE_END_DATE"  => long_ago_date,
            "OVERRIDE_END_TIME"  => "2000"
        }
      end
      let(:hash2) do
        {
            "AO_TERM_BUCKET_ID"  => 2,
            "TERM_BUCKET_LABEL"  => "1 Week",
            "WHOLE_LOAN_ENABLED" => "Y",
            "SBC_AGENCY_ENABLED" => "Y",
            "SBC_AAA_ENABLED"    => "Y",
            "SBC_AA_ENABLED"     => "N",
            "END_TIME"           => "2000",
            "OVERRIDE_END_DATE"  => long_ago_date,
            "OVERRIDE_END_TIME"  => "0700"
        }
      end
      let(:hash3) do
        {
            "AO_TERM_BUCKET_ID"  => 3,
            "TERM_BUCKET_LABEL"  => "2 Weeks",
            "WHOLE_LOAN_ENABLED" => "Y",
            "SBC_AGENCY_ENABLED" => "Y",
            "SBC_AAA_ENABLED"    => "Y",
            "SBC_AA_ENABLED"     => "Y",
            "END_TIME"           => "2000",
            "OVERRIDE_END_DATE"  => now_date,
            "OVERRIDE_END_TIME"  => "2359"
        }
      end
      let(:result_set) {double('Oracle Result Set', fetch: nil)}
      let(:result_set2) {double('Oracle Result Set', fetch: nil)}
      let(:result_set3) {double('Oracle Result Set', fetch: nil)}
      let(:result_set4) {double('Oracle Result Set', fetch_hash: nil)}
      before do
        allow(MAPI::ServiceApp).to receive(:environment).at_least(1).times.and_return(:production)
        allow(ActiveRecord::Base).to receive(:connection).and_return(double('OCI8 Connection'))
        allow(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(result_set, result_set2, result_set3, result_set4)
        allow(result_set).to receive(:fetch).and_return([1], nil)
        allow(result_set2).to receive(:fetch).and_return([1], nil)
        allow(result_set3).to receive(:fetch).and_return([1], nil)
        allow(result_set4).to receive(:fetch_hash).and_return(hash1, hash2, hash3, nil)
        allow(now).to receive(:to_date).and_return(now_date)
        allow(now).to receive(:strftime).with("%H%M").and_return(now_time_string)
        allow(Time.zone).to receive(:now).and_return(now)
        allow(now_time_string).to receive(:<).with('0001').and_return(false)
        allow(now_time_string).to receive(:<).with('1200').and_return(true)
        allow(now_time_string).to receive(:<).with('2000').and_return(true)
        allow(now_time_string).to receive(:<).with('2359').and_return(true)      end

      it 'should return the expected status type and label for ALL LOAN_TERMS, LOAN_TYPES' do
        expect(etransact_advances_status.length).to be >=1
      end

      it 'should return etransact turn off as all products reach end time even though etransact is turned on' do
        allow(result_set).to receive(:fetch).and_return([0], nil)
        expect(etransact_advances_status['etransact_advances_status']).to be false
        expect(etransact_advances_status['wl_vrc_status']).to be true
      end

      it 'should return etransact turn on when EOD has been enabled and EOD hasnt been reached' do
        allow(result_set).to receive(:fetch).and_return([13], nil)
        allow(result_set2).to receive(:fetch).and_return([1], nil)
        expect(etransact_advances_status['etransact_advances_status']).to be true
      end

      it 'should return etransact status = false if etransact is turn on but no product is available' do
        expect(result_set).to receive(:fetch).and_return([1], nil).at_least(1).times
        expect(result_set2).to receive(:fetch).and_return([0], nil).at_least(1).times
        expect(result_set3).to receive(:fetch).and_return([1], nil).at_least(1).times
        expect(result_set4).to receive(:fetch_hash).and_return(
                                   {"AO_TERM_BUCKET_ID" => 3,
                                    "TERM_BUCKET_LABEL" => "2 Week",
                                    "WHOLE_LOAN_ENABLED"=> "Y",
                                    "SBC_AGENCY_ENABLED"=> "Y",
                                    "SBC_AAA_ENABLED"   => "Y",
                                    "SBC_AA_ENABLED"    => "Y",
                                    "END_TIME"          => "1200",
                                    "OVERRIDE_END_DATE" => long_ago_date,
                                    "OVERRIDE_END_TIME" => "0700"}, nil).at_least(1).times
        expect(etransact_advances_status['etransact_advances_status']).to be false
        expect(etransact_advances_status['wl_vrc_status']).to be true
      end
    end
  end

  describe 'get `etransact_advances/settings`' do
    let(:results) { {SecureRandom => 'some results'} }
    let(:call_endpoint) { get 'etransact_advances/settings' }

    it_behaves_like 'a MAPI endpoint with JSON error handling', 'etransact_advances/settings', :get, MAPI::Services::EtransactAdvances::Settings, :settings

    it 'calls `MAPI::Services::EtransactAdvances::Settings.settings`' do
      expect(MAPI::Services::EtransactAdvances::Settings).to receive(:settings)
      call_endpoint
    end
    it 'returns the JSONd results of calling `MAPI::Services::EtransactAdvances::Settings.settings` in the response body' do
      allow(MAPI::Services::EtransactAdvances::Settings).to receive(:settings).and_return(results)
      call_endpoint
      expect(last_response.body).to eq(results.to_json)
    end
  end

  describe 'put `etransact_advances/settings/enable_service`' do
    let(:call_endpoint) { put 'etransact_advances/settings/enable_service' }

    it_behaves_like 'a MAPI endpoint with JSON error handling', 'etransact_advances/settings/enable_service', :put, MAPI::Services::EtransactAdvances::Settings, :enable_service

    it 'calls `MAPI::Services::EtransactAdvances::Settings.enable_service` with the app' do
      expect(MAPI::Services::EtransactAdvances::Settings).to receive(:enable_service).with(an_instance_of(MAPI::ServiceApp))
      call_endpoint
    end
    it 'returns a JSONd empty hash in the response body if the `enable_service` method is successful' do
      allow(MAPI::Services::EtransactAdvances::Settings).to receive(:enable_service).and_return(true)
      call_endpoint
      expect(last_response.body).to eq({}.to_json)
    end
  end

  describe 'put `etransact_advances/settings/disable_service`' do
    let(:call_endpoint) { put 'etransact_advances/settings/disable_service' }

    it_behaves_like 'a MAPI endpoint with JSON error handling', 'etransact_advances/settings/disable_service', :put, MAPI::Services::EtransactAdvances::Settings, :disable_service

    it 'calls `MAPI::Services::EtransactAdvances::Settings.enable_service` with the app' do
      expect(MAPI::Services::EtransactAdvances::Settings).to receive(:disable_service).with(an_instance_of(MAPI::ServiceApp))
      call_endpoint
    end
    it 'returns a JSONd empty hash in the response body if the `enable_service` method is successful' do
      allow(MAPI::Services::EtransactAdvances::Settings).to receive(:disable_service).and_return(true)
      call_endpoint
      expect(last_response.body).to eq({}.to_json)
    end
  end

  describe 'put `etransact_advances/settings`' do
    let(:post_body) { {"params" => "#{SecureRandom.hex}"} }
    let(:call_endpoint) { put 'etransact_advances/settings', post_body.to_json }

    it_behaves_like 'a MAPI endpoint with JSON error handling', 'etransact_advances/settings', :put, MAPI::Services::EtransactAdvances::Settings, :update_settings, "{}"

    it 'calls `MAPI::Services::EtransactAdvances::Settings.update_settings` with the app' do
      expect(MAPI::Services::EtransactAdvances::Settings).to receive(:update_settings).with(an_instance_of(MAPI::ServiceApp), anything)
      call_endpoint
    end
    it 'calls `MAPI::Services::EtransactAdvances::Settings.update_settings` with the parsed post body' do
      expect(MAPI::Services::EtransactAdvances::Settings).to receive(:update_settings).with(an_instance_of(MAPI::ServiceApp), post_body)
      call_endpoint
    end
    it 'returns a JSONd empty hash in the response body if the `update_settings` method is successful' do
      allow(MAPI::Services::EtransactAdvances::Settings).to receive(:update_settings).and_return(true)
      call_endpoint
      expect(last_response.body).to eq({}.to_json)
    end
  end

  describe 'GET blockout_dates' do
    let(:logger) { instance_double(Logger) }
    let(:environment) { instance_double(Symbol, 'An Environment') }
    let(:make_request) { get '/etransact_advances/blackout_dates' }
    before do
      allow_any_instance_of(described_class).to receive(:logger).and_return(logger)
      allow(described_class).to receive(:environment).and_return(environment)
    end
    it 'calls `MAPI::Services::Rates::BlackoutDates::blackout_dates` with the `logger`' do
      expect(MAPI::Services::Rates::BlackoutDates).to receive(:blackout_dates).with(logger, any_args)
      make_request
    end
    it 'calls `MAPI::Services::Rates::BlackoutDates::blackout_dates` with the `environment`' do
      expect(MAPI::Services::Rates::BlackoutDates).to receive(:blackout_dates).with(anything, environment)
      make_request
    end
    it 'responds with the results of `MAPI::Services::Rates::BlackoutDates::blackout_dates` converted to JSON' do
      json_results = SecureRandom.hex
      results = double('Some Results', to_json: json_results)
      allow(MAPI::Services::Rates::BlackoutDates).to receive(:blackout_dates).and_return(results)
      make_request
      expect(last_response.body).to eq(json_results)
    end
  end

  describe 'get `etransact_advances/shutoff_times_by_type`' do
    let(:call_endpoint) { get 'etransact_advances/shutoff_times_by_type' }

    it_behaves_like 'a MAPI endpoint with JSON error handling', 'etransact_advances/shutoff_times_by_type', :get, MAPI::Services::EtransactAdvances::ShutoffTimes, :get_shutoff_times_by_type

    it 'calls `MAPI::Services::EtransactAdvances::ShutoffTimes.get_shutoff_times_by_type` with the app' do
      expect(MAPI::Services::EtransactAdvances::ShutoffTimes).to receive(:get_shutoff_times_by_type).with(an_instance_of(MAPI::ServiceApp))
      call_endpoint
    end
  end

  describe 'get `etransact_advances/early_shutoffs`' do
    let(:call_endpoint) { get 'etransact_advances/early_shutoffs' }

    it_behaves_like 'a MAPI endpoint with JSON error handling', 'etransact_advances/early_shutoffs', :get, MAPI::Services::EtransactAdvances::ShutoffTimes, :get_early_shutoffs

    it 'calls `MAPI::Services::EtransactAdvances::ShutoffTimes.get_early_shutoffs` with the app' do
      expect(MAPI::Services::EtransactAdvances::ShutoffTimes).to receive(:get_early_shutoffs).with(an_instance_of(MAPI::ServiceApp))
      call_endpoint
    end
  end
end