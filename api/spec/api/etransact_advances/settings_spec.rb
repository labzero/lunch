require 'spec_helper'

describe MAPI::ServiceApp do
  describe 'MAPI::Services::EtransactAdvances::Settings.settings' do
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
end