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

    before { allow(MAPI::Services::EtransactAdvances).to receive(:end_of_day_reached_for_all_terms).and_return(false) }
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
      let!(:some_status_data) {{"AO_TERM_BUCKET_ID" => 1, "TERM_BUCKET_LABEL"=> "Open and O/N", "WHOLE_LOAN_ENABLED"=>  "N", "SBC_AGENCY_ENABLED"=> "Y", "SBC_AAA_ENABLED" =>  "Y",
                                 "SBC_AA_ENABLED"=>  "Y", "END_TIME" => "2000",  "OVERRIDE_END_DATE" =>  "2006-01-01", "OVERRIDE_END_TIME"=>  "0700"}}
      let(:result_set2) {double('Oracle Result Set', fetch: nil)}
      let(:result_set3) {double('Oracle Result Set', fetch: nil)}
      let(:result_set4) {double('Oracle Result Set', fetch_hash: nil)}
      before do
        allow(MAPI::ServiceApp).to receive(:environment).and_return(:production)
        allow(ActiveRecord::Base).to receive(:connection).and_return(double('OCI8 Connection'))
        allow(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(result_set2,result_set3,result_set4)
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
    describe 'in the production environment for cases when etransact is turned on' do
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
      let(:result_set2) {double('Oracle Result Set', fetch: nil)}
      let(:result_set3) {double('Oracle Result Set', fetch: nil)}
      let(:result_set4) {double('Oracle Result Set', fetch_hash: nil)}
      before do
        allow(MAPI::Services::EtransactAdvances).to receive(:end_of_day_reached_for_all_terms)
        allow(MAPI::Services::Rates::LoanTerms).to receive(:loan_terms)
        allow(MAPI::ServiceApp).to receive(:environment).at_least(1).times.and_return(:production)
        allow(ActiveRecord::Base).to receive(:connection).and_return(double('OCI8 Connection'))
        allow(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(result_set2, result_set3, result_set4)
        allow(result_set2).to receive(:fetch).and_return([1], nil)
        allow(result_set3).to receive(:fetch).and_return([1], nil)
        allow(result_set4).to receive(:fetch_hash).and_return(hash1, hash2, hash3, nil)
      end

      it 'should return the expected status type and label for ALL LOAN_TERMS, LOAN_TYPES' do
        expect(etransact_advances_status.length).to be >=1
      end

      describe 'checking to see if end of day has been reached for vrc and frc advances' do
        it 'calls `end_of_day_reached_for_all_terms` with the app as an argument' do
          expect(MAPI::Services::EtransactAdvances).to receive(:end_of_day_reached_for_all_terms).with(an_instance_of(MAPI::ServiceApp))
          etransact_advances_status
        end

        context 'when etransact is turned on' do
          before { allow(result_set2).to receive(:fetch).and_return([1], nil) }

          it 'sets `etransact_advances_status` to `true` if `end_of_day_reached_for_all_terms` returns `false`' do
            allow(MAPI::Services::EtransactAdvances).to receive(:end_of_day_reached_for_all_terms).and_return(false)
            expect(etransact_advances_status['etransact_advances_status']).to be true
          end
          it 'sets `etransact_advances_status` to `false` if `end_of_day_reached_for_all_terms` returns `true`' do
            allow(MAPI::Services::EtransactAdvances).to receive(:end_of_day_reached_for_all_terms).and_return(true)
            expect(etransact_advances_status['etransact_advances_status']).to be false
          end
        end
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

  describe 'put `etransact_advances/shutoff_times_by_type`' do
    let(:post_body) { {"params" => "#{SecureRandom.hex}"} }
    let(:call_endpoint) { put 'etransact_advances/shutoff_times_by_type', post_body.to_json }

    it_behaves_like 'a MAPI endpoint with JSON error handling', 'etransact_advances/shutoff_times_by_type', :put, MAPI::Services::EtransactAdvances::ShutoffTimes, :edit_shutoff_times_by_type, "{}"

    it 'calls `MAPI::Services::EtransactAdvances::ShutoffTimes.edit_shutoff_times_by_type` with the app' do
      expect(MAPI::Services::EtransactAdvances::ShutoffTimes).to receive(:edit_shutoff_times_by_type).with(an_instance_of(MAPI::ServiceApp), anything)
      call_endpoint
    end
    it 'calls `MAPI::Services::EtransactAdvances::ShutoffTimes.edit_shutoff_times_by_type` with the parsed post body' do
      expect(MAPI::Services::EtransactAdvances::ShutoffTimes).to receive(:edit_shutoff_times_by_type).with(an_instance_of(MAPI::ServiceApp), post_body)
      call_endpoint
    end
    it 'returns a JSONd empty hash in the response body if the `edit_shutoff_times_by_type` method is successful' do
      allow(MAPI::Services::EtransactAdvances::ShutoffTimes).to receive(:edit_shutoff_times_by_type).and_return(true)
      call_endpoint
      expect(last_response.body).to eq({}.to_json)
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

  describe 'post `etransact_advances/early_shutoff`' do
    let(:post_body) { {"params" => "#{SecureRandom.hex}"} }
    let(:call_endpoint) { post 'etransact_advances/early_shutoff', post_body.to_json }

    it_behaves_like 'a MAPI endpoint with JSON error handling', 'etransact_advances/early_shutoff', :post, MAPI::Services::EtransactAdvances::ShutoffTimes, :schedule_early_shutoff, "{}"

    it 'calls `MAPI::Services::EtransactAdvances::ShutoffTimes.schedule_early_shutoff` with the app' do
      expect(MAPI::Services::EtransactAdvances::ShutoffTimes).to receive(:schedule_early_shutoff).with(an_instance_of(MAPI::ServiceApp), anything)
      call_endpoint
    end
    it 'calls `MAPI::Services::EtransactAdvances::ShutoffTimes.schedule_early_shutoff` with the parsed post body' do
      expect(MAPI::Services::EtransactAdvances::ShutoffTimes).to receive(:schedule_early_shutoff).with(an_instance_of(MAPI::ServiceApp), post_body)
      call_endpoint
    end
    it 'returns a JSONd empty hash in the response body if the `schedule_early_shutoff` method is successful' do
      allow(MAPI::Services::EtransactAdvances::ShutoffTimes).to receive(:schedule_early_shutoff).and_return(true)
      call_endpoint
      expect(last_response.body).to eq({}.to_json)
    end
  end

  describe 'put `etransact_advances/early_shutoff`' do
    let(:put_body) { {"params" => "#{SecureRandom.hex}"} }
    let(:call_endpoint) { put 'etransact_advances/early_shutoff', put_body.to_json }

    it_behaves_like 'a MAPI endpoint with JSON error handling', 'etransact_advances/early_shutoff', :put, MAPI::Services::EtransactAdvances::ShutoffTimes, :update_early_shutoff, "{}"

    it 'calls `MAPI::Services::EtransactAdvances::ShutoffTimes.update_early_shutoff` with the app' do
      expect(MAPI::Services::EtransactAdvances::ShutoffTimes).to receive(:update_early_shutoff).with(an_instance_of(MAPI::ServiceApp), anything)
      call_endpoint
    end
    it 'calls `MAPI::Services::EtransactAdvances::ShutoffTimes.update_early_shutoff` with the parsed body' do
      expect(MAPI::Services::EtransactAdvances::ShutoffTimes).to receive(:update_early_shutoff).with(an_instance_of(MAPI::ServiceApp), put_body)
      call_endpoint
    end
    it 'returns a JSONd empty hash in the response body if the `update_early_shutoff` method is successful' do
      allow(MAPI::Services::EtransactAdvances::ShutoffTimes).to receive(:update_early_shutoff).and_return(true)
      call_endpoint
      expect(last_response.body).to eq({}.to_json)
    end
  end

  describe 'delete `etransact_advances/early_shutoff`' do
    let(:shutoff_date) { SecureRandom.hex }
    let(:call_endpoint) { delete "etransact_advances/early_shutoff/#{shutoff_date}" }

    it_behaves_like 'a MAPI endpoint with JSON error handling', "etransact_advances/early_shutoff/2017-06-20", :delete, MAPI::Services::EtransactAdvances::ShutoffTimes, :remove_early_shutoff

    it 'calls `MAPI::Services::EtransactAdvances::ShutoffTimes.remove_early_shutoff` with the app' do
      expect(MAPI::Services::EtransactAdvances::ShutoffTimes).to receive(:remove_early_shutoff).with(an_instance_of(MAPI::ServiceApp), anything)
      call_endpoint
    end
    it 'calls `MAPI::Services::EtransactAdvances::ShutoffTimes.remove_early_shutoff` with the shutoff_date parameter' do
      expect(MAPI::Services::EtransactAdvances::ShutoffTimes).to receive(:remove_early_shutoff).with(anything, shutoff_date)
      call_endpoint
    end
    it 'returns a JSONd empty hash in the response body if the `remove_early_shutoff` method is successful' do
      allow(MAPI::Services::EtransactAdvances::ShutoffTimes).to receive(:remove_early_shutoff).and_return(true)
      call_endpoint
      expect(last_response.body).to eq({}.to_json)
    end
  end

  describe '`end_of_day_reached_for_all_terms`' do
    let(:now) { Time.zone.now }
    let(:app) { instance_double(described_class) }
    let(:shutoff_times_module) { MAPI::Services::EtransactAdvances::ShutoffTimes }
    let(:etransact_module) { MAPI::Services::EtransactAdvances }
    let(:call_method) { etransact_module.end_of_day_reached_for_all_terms(app) }
    before do
      allow(shutoff_times_module).to receive(:get_early_shutoffs).and_return([])
      allow(shutoff_times_module).to receive(:get_shutoff_times_by_type).and_return({})
      allow(Time.zone).to receive(:now).and_return(now)
      allow(etransact_module).to receive(:parse_time).and_return(now - rand(15..99).minutes)
    end

    it 'retrieves the scheduled early shutoffs' do
      expect(shutoff_times_module).to receive(:get_early_shutoffs).with(app)
      call_method
    end
    context 'when there is an early shutoff scheduled for today' do
      let(:early_shutoff) {{
        'early_shutoff_date' => now.to_date.iso8601,
        'vrc_shutoff_time' => double('vrc_shutoff_time'),
        'frc_shutoff_time' => double('frc_shutoff_time')
      }}
      before { allow(shutoff_times_module).to receive(:get_early_shutoffs).and_return([early_shutoff]) }

      it 'does not call `get_shutoff_times_by_type` on the early shutoff times module' do
        expect(shutoff_times_module).not_to receive(:get_shutoff_times_by_type)
        call_method
      end
      it 'calls `parse_time` with now and the `vrc_shutoff_time` from the early shutoff' do
        expect(etransact_module).to receive(:parse_time).with(now, early_shutoff['vrc_shutoff_time']).and_return(now)
        call_method
      end
      it 'calls `parse_time` with now and the `frc_shutoff_time` from the early shutoff' do
        expect(etransact_module).to receive(:parse_time).with(now, early_shutoff['frc_shutoff_time']).and_return(now)
        call_method
      end
      context 'when the current time is not past the parsed `vrc_shutoff_time`' do
        before { allow(etransact_module).to receive(:parse_time).with(now, early_shutoff['vrc_shutoff_time']).and_return(now + rand(15..99).minutes) }
        it 'returns `false`' do
          expect(call_method).to be false
        end
      end
      context 'when the current time is past the parsed `vrc_shutoff_time`' do
        before { allow(etransact_module).to receive(:parse_time).with(now, early_shutoff['vrc_shutoff_time']).and_return(now - rand(15..99).minutes) }

        it 'returns `true` if the current time is also past the parsed `frc_shutoff_time`' do
          allow(etransact_module).to receive(:parse_time).with(now, early_shutoff['frc_shutoff_time']).and_return(now - rand(15..99).minutes)
          expect(call_method).to be true
        end
        it 'returns `false` if the current time is not past the parsed `frc_shutoff_time`' do
          allow(etransact_module).to receive(:parse_time).with(now, early_shutoff['frc_shutoff_time']).and_return(now + rand(15..99).minutes)
          expect(call_method).to be false
        end
      end
    end
    context 'when there is not an early shutoff scheduled for today' do
      let(:default_shutoffs) {{
        'vrc' => double('vrc'),
        'frc' => double('frc')
      }}
      before { allow(shutoff_times_module).to receive(:get_shutoff_times_by_type).with(app).and_return(default_shutoffs) }

      it 'fetches the default early shutoff times by type' do
        expect(shutoff_times_module).to receive(:get_shutoff_times_by_type).with(app).and_return({})
        call_method
      end
      it 'calls `parse_time` with now and the `vrc` value from the shutoff hash' do
        expect(etransact_module).to receive(:parse_time).with(now, default_shutoffs['vrc']).and_return(now)
        call_method
      end
      it 'calls `parse_time` with now and the `frc` value from the shutoff hash' do
        expect(etransact_module).to receive(:parse_time).with(now, default_shutoffs['frc']).and_return(now)
        call_method
      end
      context 'when the current time is not past the parsed `vrc` default time' do
        before { allow(etransact_module).to receive(:parse_time).with(now, default_shutoffs['vrc']).and_return(now + rand(15..99).minutes) }
        it 'returns `false`' do
          expect(call_method).to be false
        end
      end
      context 'when the current time is past the parsed `vrc` default time' do
        before { allow(etransact_module).to receive(:parse_time).with(now, default_shutoffs['vrc']).and_return(now - rand(15..99).minutes) }

        it 'returns `true` if the current time is also past the parsed `frc` default time' do
          allow(etransact_module).to receive(:parse_time).with(now, default_shutoffs['frc']).and_return(now - rand(15..99).minutes)
          expect(call_method).to be true
        end
        it 'returns `false` if the current time is not past the parsed `frc` default time' do
          allow(etransact_module).to receive(:parse_time).with(now, default_shutoffs['frc']).and_return(now + rand(15..99).minutes)
          expect(call_method).to be false
        end
      end
    end
  end
end