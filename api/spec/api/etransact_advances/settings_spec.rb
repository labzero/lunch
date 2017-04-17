require 'spec_helper'

describe MAPI::ServiceApp do
  describe 'MAPI::Services::EtransactAdvances::Settings' do
    etransact_settings_module = MAPI::Services::EtransactAdvances::Settings
    let(:app) { double(MAPI::ServiceApp, logger: double('logger')) }

    describe '`settings`' do
      let(:call_method) {MAPI::Services::EtransactAdvances::Settings.settings(:production)}
      numeric_keys = [
        'end_of_day_extension', 'rate_timeout', 'rsa_timeout',
        'shareholder_total_daily_limit', 'shareholder_web_daily_limit',
        'maximum_online_term_days', 'rate_stale_check'
      ]
      boolean_keys = ['auto_approve', 'rates_flagged']
      settings_to_keys = {
        'AutoApprove' => 'auto_approve',
        'EndOfDayExtension' => 'end_of_day_extension',
        'RateTimeout' => 'rate_timeout',
        'RatesFlagged' => 'rates_flagged',
        'RSATimeout' => 'rsa_timeout',
        'ShareholderTotalDailyLimit' => 'shareholder_total_daily_limit',
        'ShareholderWebDailyLimit' => 'shareholder_web_daily_limit',
        'MaximumOnlineTermDays' => 'maximum_online_term_days',
        'RateStaleCheck' => 'rate_stale_check'
      }
      [:development, :production].each do |env|
        describe "in the `#{env}` environment" do
          before do
            if (env == :production)
              allow(ActiveRecord::Base.connection).to receive(:execute).and_return(nil)
            end
          end
          let(:call_method) { MAPI::Services::EtransactAdvances::Settings.settings(env) }
          it 'should return an EtransactSettings hash' do
            keys = numeric_keys + boolean_keys
            expect(call_method).to include(*keys)
          end
          numeric_keys.each do |key|
            it "`#{key} should be numeric" do
              expect(call_method[key]).to be_kind_of(Numeric)
            end
          end
          boolean_keys.each do |key|
            it "`#{key} should be boolean" do
              expect(call_method[key]).to be_boolean
            end
          end
        end
      end
      it 'should return zeros and falses if the SQL lookup failed' do
        allow(ActiveRecord::Base.connection).to receive(:execute).and_return(nil)
        settings = call_method
        numeric_keys.each do |key|
          expect(settings[key]).to be(0)
        end
        boolean_keys.each do |key|
          expect(settings[key]).to be(false)
        end
      end
      it 'should return zeros and falses if the SQL lookup returned no results' do
        allow(ActiveRecord::Base.connection).to receive(:execute).and_return(double('Results', fetch_hash: nil))
        settings = call_method
        numeric_keys.each do |key|
          expect(settings[key]).to be(0)
        end
        boolean_keys.each do |key|
          expect(settings[key]).to be(false)
        end
      end
      describe 'with results' do
        let(:results_hash) {{
          'AutoApprove' => '0', 'EndOfDayExtension' => '12345', 'RateTimeout' => '60',
          'RatesFlagged' => 'N', 'RSATimeout' => '600', 'ShareholderTotalDailyLimit' => '600,000',
          'ShareholderWebDailyLimit' => '1,800,001', 'MaximumOnlineTermDays' => '1000',
          'RateStaleCheck' => '400'
        }}
        let(:results) do
          obj = double('Results')
          rows = []
          results_hash.each do |key, value|
            rows << {'SETTING_NAME' => key, 'SETTING_VALUE' => value}
          end
          allow(obj).to receive(:fetch_hash).and_return(*(rows + [nil]))
          obj
        end
        before do
          allow(ActiveRecord::Base.connection).to receive(:execute).and_return(results)
        end
        ['EndOfDayExtension', 'RateTimeout', 'RSATimeout', 'MaximumOnlineTermDays', 'RateStaleCheck'].each do |setting|
          it "should call `to_i` on the `#{setting}` and place the result in `#{settings_to_keys[setting]}`" do
            result = double('A Result')
            allow(results_hash[setting]).to receive(:to_i).and_return(result)
            expect(call_method[settings_to_keys[setting]]).to eq(result)
          end
        end
        {
          'AutoApprove' => {'0' => false, '1' => true},
          'RatesFlagged' => {'N' => false, 'Y' => true},
          'ShareholderTotalDailyLimit' => {'600,000' => 600000, '1,800,100' => 1800100, '100' => 100},
          'ShareholderWebDailyLimit' => {'545,000' => 545000, '1,900,100' => 1900100, '123' => 123}
        }.each do |setting, tests|
          tests.each do |value, expectation|
            it "should set `#{settings_to_keys[setting]}` to #{expectation} if `#{setting}` is '#{value}'" do
              allow(results).to receive(:fetch_hash).and_return({'SETTING_NAME' => setting, 'SETTING_VALUE' => value}, nil)
              expect(call_method[settings_to_keys[setting]]).to eq(expectation)
            end
          end
        end

      end
    end

    describe '`update_settings`' do
      let(:valid_key) { etransact_settings_module::SETTING_NAMES_MAPPING.keys.sample }
      let(:invalid_key) { SecureRandom.hex }
      let(:quoted_key) { SecureRandom.hex }
      let(:value) { SecureRandom.hex }
      let(:quoted_value) { SecureRandom.hex }
      let(:settings) {{valid_key => value}}
      let(:call_method) { etransact_settings_module.update_settings(app, settings) }
      before do
        allow(etransact_settings_module).to receive(:should_fake?).and_return(true)
        allow(etransact_settings_module).to receive(:execute_sql).and_return(true)
        allow(etransact_settings_module).to receive(:quote)
      end

      context 'when `should_fake?` returns true' do
        it 'returns true' do
          expect(call_method).to be true
        end
      end
      context 'when `should_fake?` returns false' do
        before { allow(etransact_settings_module).to receive(:should_fake?).and_return(false) }

        it 'executes code within a transaction where the `isolation` has been set to `:read_committed`' do
          expect(ActiveRecord::Base).to receive(:transaction).with(isolation: :read_committed)
          call_method
        end
        it 'returns true if the transaction block executes without error' do
          allow(ActiveRecord::Base).to receive(:transaction).with(isolation: :read_committed)
          expect(call_method).to be true
        end
        describe 'the transaction block' do
          it 'raises an `MAPI::Shared::Errors::InvalidFieldError` if the setting name is not one of the keys in the SETTING_NAMES_MAPPING hash' do
            expect{etransact_settings_module.update_settings(app, {invalid_key => value})}.to raise_error(MAPI::Shared::Errors::InvalidFieldError, "#{invalid_key} is an invalid setting name")
          end
          it 'raises an `MAPI::Shared::Errors::SQLError` if `execute_sql` does not succeed' do
            allow(etransact_settings_module).to receive(:execute_sql).and_return(false)
            expect{call_method}.to raise_error(MAPI::Shared::Errors::SQLError, "Failed to update settings with setting name: #{valid_key}")
          end
          it 'calls `execute_sql` with the logger' do
            expect(etransact_settings_module).to receive(:execute_sql).with(app.logger, anything).and_return(true)
            call_method
          end
          describe 'the update_settings_sql' do
            it 'updates the `WEB_ADM.AO_SETTINGS` table' do
              matcher = Regexp.new(/\A\s*UPDATE.+WEB_ADM.AO_SETTINGS\s+/im)
              expect(etransact_settings_module).to receive(:execute_sql).with(anything, matcher).and_return(true)
              call_method
            end
            it 'quotes the setting value' do
              expect(etransact_settings_module).to receive(:quote).with(value)
              call_method
            end
            it 'quotes the mapped setting name' do
              expect(etransact_settings_module).to receive(:quote).with(etransact_settings_module::SETTING_NAMES_MAPPING[valid_key])
              call_method
            end
            it '`SET`s the `SETTING_VALUE` to the quoted setting value' do
              allow(etransact_settings_module).to receive(:quote).with(value).and_return(quoted_value)
              matcher = Regexp.new(/\A\s*UPDATE.+WEB_ADM.AO_SETTINGS\s+.*SET\s+SETTING_VALUE\s+=\s+#{quoted_value}\s+/im)
              expect(etransact_settings_module).to receive(:execute_sql).with(anything, matcher).and_return(true)
              call_method
            end
            it 'performs the update on the row where the `SETTING_NAME` equals the quoted, mapped-setting name' do
              allow(etransact_settings_module).to receive(:quote).with(etransact_settings_module::SETTING_NAMES_MAPPING[valid_key]).and_return(quoted_key)
              matcher = Regexp.new(/\A\s*UPDATE.+WEB_ADM.AO_SETTINGS\s+.*SET\s+.+WHERE\s+SETTING_NAME\s+=\s+#{quoted_key}\s*\z/im)
              expect(etransact_settings_module).to receive(:execute_sql).with(anything, matcher).and_return(true)
              call_method
            end
          end
        end
      end
    end
  end
end