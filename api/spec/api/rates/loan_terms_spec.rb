require 'spec_helper'
require 'date'

describe MAPI::Services::Rates::LoanTerms do
  loan_terms_module = MAPI::Services::Rates::LoanTerms
  let(:app) { double(MAPI::ServiceApp, logger: double('logger'), settings: double('settings', environment: double('environment'))) }

  describe 'class methods' do
    let(:now) { Time.zone.now }
    let(:grace_period) { rand(1..10) }
    let(:now_hash) { {time: now, date: now.to_date, grace_period: grace_period} }
    before do
      allow(Time.zone).to receive(:now).and_return(now)
    end

    describe '`loan_terms`' do
      let(:settings) {{
        'end_of_day_extension' => grace_period
      }}
      let(:call_method) { loan_terms_module.loan_terms(app) }
      before do
        allow(loan_terms_module).to receive(:value_for_term)
        allow(loan_terms_module).to receive(:should_fake?).and_return(true)
        allow(loan_terms_module).to receive(:term_to_id)
      end

      it 'calls `should_fake?` with the app' do
        expect(loan_terms_module).to receive(:should_fake?).and_return(true)
        call_method
      end
      context 'when `should_fake?` returns true' do
        before { allow(loan_terms_module).to receive(:should_fake?).and_return(true) }

        it 'calls `fake` with `etransact_advances_term_buckets_info`' do
          expect(loan_terms_module).to receive(:fake).with('etransact_advances_term_buckets_info')
          call_method
        end
      end
      context 'when `should_fake?` returns false' do
        before { allow(loan_terms_module).to receive(:should_fake?).and_return(false) }

        it 'calls `fetch_hashes` with the logger from the app' do
          expect(loan_terms_module).to receive(:fetch_hashes).with(app.logger, any_args)
          call_method
        end
        it 'calls `fetch_hashes` with the proper SQL' do
          expect(loan_terms_module).to receive(:fetch_hashes).with(anything, loan_terms_module::SQL, anything)
          call_method
        end
        it 'calls `fetch_hashes` with a hash mapping the `OVERRIDE_END_DATE` to the `to_date` proc' do
          expect(loan_terms_module).to receive(:fetch_hashes).with(anything, anything, {to_date: ['OVERRIDE_END_DATE']})
          call_method
        end
      end
      context 'when the `allow_grace_period` arg is `true`' do
        let(:call_method) { loan_terms_module.loan_terms(app, true) }

        it 'calls `MAPI::Services::EtransactAdvances::Settings.settings` with the app\'s environment' do
          expect(MAPI::Services::EtransactAdvances::Settings).to receive(:settings).with(app.settings.environment).and_return({})
          call_method
        end
        it 'uses the `end_of_day_extension` from the settings for the `grace_period` when calling `value_for_term`' do
          allow(MAPI::Services::EtransactAdvances::Settings).to receive(:settings).with(app.settings.environment).and_return(settings)
          expect(loan_terms_module).to receive(:value_for_term).with(anything, anything, hash_including(grace_period: settings['end_of_day_extension']))
          call_method
        end
      end
      context 'when the `allow_grace_period` arg is false' do
        let(:call_method) { loan_terms_module.loan_terms(app, false) }

        it 'does not call `MAPI::Services::EtransactAdvances::Settings.settings`' do
          expect(MAPI::Services::EtransactAdvances::Settings).not_to receive(:settings)
          call_method
        end
        it 'uses `0` for the `grace_period` when calling `value_for_term`' do
          expect(loan_terms_module).to receive(:value_for_term).with(anything, anything, hash_including(grace_period: 0))
          call_method
        end
      end
      it 'calls `value_for_term` with the app' do
        expect(loan_terms_module).to receive(:value_for_term).with(app, any_args)
        call_method
      end
      it 'calls `value_for_term` with a hash with a value for `time`' do
        expect(loan_terms_module).to receive(:value_for_term).with(anything, anything, hash_including(time: now))
        call_method
      end
      it 'calls `value_for_term` with a hash with a value for `date`' do
        expect(loan_terms_module).to receive(:value_for_term).with(anything, anything, hash_including(date: now.to_date))
        call_method
      end
      let(:buckets) do
        buckets = []
        loan_terms_module::TERM_BUCKET_MAPPING.values.each do |id|
          buckets << {'AO_TERM_BUCKET_ID' => id, 'sentinel' => SecureRandom.hex}
        end
        buckets
      end
      before { allow(loan_terms_module).to receive(:fake).and_return(buckets) }
      loan_terms_module::LOAN_TERMS.each do |term|
        describe "buckets pertaining to the `#{term}` term" do
          let(:bucket_value_for_term) { double('bucket value for term') }
          let(:bucket_id) { loan_terms_module.term_to_id(term) }
          before do
            allow(loan_terms_module).to receive(:term_to_id).and_call_original
          end

          it "calls `term_to_id` with `#{term}`" do
            expect(loan_terms_module).to receive(:term_to_id).with(term)
            call_method
          end
          it "calls `value_for_term` with the bucket corresponding to the `#{term}` term" do
            expect(loan_terms_module).to receive(:value_for_term).with(anything, buckets[bucket_id], anything)
            call_method
          end
          it "calls `hash_from_pairs` with an array including an array with the `#{term}` and the `value_for_term` for the corresponding bucket" do
            allow(loan_terms_module).to receive(:value_for_term).with(anything, buckets[bucket_id], anything).and_return(bucket_value_for_term)
            expect(loan_terms_module).to receive(:hash_from_pairs).with(include([term, bucket_value_for_term]))
            call_method
          end
        end
      end
      it 'returns the result of calling `hash_from_pairs`' do
        result = double('result')
        allow(loan_terms_module).to receive(:hash_from_pairs).and_return(result)
        expect(call_method).to eq(result)
      end
    end

    describe '`end_time`' do
      let(:bucket) { double('bucket') }
      let(:parsed_time) { now + rand(15..99).minutes }
      let(:call_method) { subject.end_time(app, bucket, now_hash) }

      before do
        allow(loan_terms_module).to receive(:parse_time).and_return(now)
        allow(loan_terms_module).to receive(:bucket_is_vrc?)
      end

      context 'when the `date` value of the `now_hash` arg is nil' do
        before { now_hash.delete(:date) }
        it 'returns nil' do
          expect(call_method).to be nil
        end
      end
      context 'when the `date` value of the `now_hash` arg is not nil' do
        before { allow(loan_terms_module).to receive(:early_shutoffs).with(app).and_return([]) }

        it 'calls `early_shutoffs` with the app' do
          expect(loan_terms_module).to receive(:early_shutoffs).with(app).and_return([])
          call_method
        end

        context 'when there is an early shutoff with the same date as the `date` value from the `now_hash`' do
          let(:early_shutoff) {{
            'early_shutoff_date' => now.to_date.iso8601,
            'vrc_shutoff_time' => double('vrc_shutoff_time'),
            'frc_shutoff_time' => double('frc_shutoff_time')
          }}
          before { allow(loan_terms_module).to receive(:early_shutoffs).and_return([early_shutoff]) }

          it 'calls `bucket_is_vrc?` with the bucket' do
            expect(loan_terms_module).to receive(:bucket_is_vrc?).with(bucket)
            call_method
          end

          context 'when `bucket_is_vrc?` returns `true`' do
            before { allow(loan_terms_module).to receive(:bucket_is_vrc?).and_return(true) }

            it 'calls `parse_time` with the `date` from the `now_hash` and the `vrc_shutoff_time` from the early shutoff hash' do
              expect(loan_terms_module).to receive(:parse_time).with(now_hash[:date], early_shutoff['vrc_shutoff_time']).and_return(parsed_time)
              call_method
            end
            it 'returns the result of adding the parsed `vrc_shutoff_time` to the `grace_period` from the `now_hash`' do
              allow(loan_terms_module).to receive(:parse_time).with(now_hash[:date], early_shutoff['vrc_shutoff_time']).and_return(parsed_time)
              expect(call_method).to eq(parsed_time + now_hash[:grace_period].minutes)
            end
          end
          context 'when `bucket_is_vrc?` returns `false`' do
            before { allow(loan_terms_module).to receive(:bucket_is_vrc?).and_return(false) }

            it 'calls `parse_time` with the `date` from the `now_hash` and the `frc_shutoff_time` from the early shutoff hash' do
              expect(loan_terms_module).to receive(:parse_time).with(now_hash[:date], early_shutoff['frc_shutoff_time']).and_return(parsed_time)
              call_method
            end
            it 'returns the result of adding the parsed `frc_shutoff_time` to the `grace_period` from the `now_hash`' do
              allow(loan_terms_module).to receive(:parse_time).with(now_hash[:date], early_shutoff['frc_shutoff_time']).and_return(parsed_time)
              expect(call_method).to eq(parsed_time + now_hash[:grace_period].minutes)
            end
          end
        end
        context 'when there is not an early shutoff with the same date as the `date` value from the `now_hash`' do
          let(:default_shutoffs) {{
            'vrc' => double('vrc_shutoff_time'),
            'frc' => double('frc_shutoff_time')
          }}
          before { allow(loan_terms_module).to receive(:default_shutoffs).and_return(default_shutoffs) }

          it 'calls `default_shutoffs` with the app' do
            expect(loan_terms_module).to receive(:default_shutoffs).with(app).and_return(default_shutoffs)
            call_method
          end
          it 'calls `bucket_is_vrc?` with the bucket' do
            expect(loan_terms_module).to receive(:bucket_is_vrc?).with(bucket)
            call_method
          end

          context 'when `bucket_is_vrc?` returns `true`' do
            before { allow(loan_terms_module).to receive(:bucket_is_vrc?).and_return(true) }

            it 'calls `parse_time` with the `date` from the `now_hash` and the `vrc` shutoff time from the default shutoff hash' do
              expect(loan_terms_module).to receive(:parse_time).with(now_hash[:date], default_shutoffs['vrc']).and_return(parsed_time)
              call_method
            end
            it 'returns the result of adding the parsed `vrc` shutoff time to the `grace_period` from the `now_hash`' do
              allow(loan_terms_module).to receive(:parse_time).with(now_hash[:date], default_shutoffs['vrc']).and_return(parsed_time)
              expect(call_method).to eq(parsed_time + now_hash[:grace_period].minutes)
            end
          end
          context 'when `bucket_is_vrc?` returns `false`' do
            before { allow(loan_terms_module).to receive(:bucket_is_vrc?).and_return(false) }

            it 'calls `parse_time` with the `date` from the `now_hash` and the `frc` shutoff time from the default shutoff hash' do
              expect(loan_terms_module).to receive(:parse_time).with(now_hash[:date], default_shutoffs['frc']).and_return(parsed_time)
              call_method
            end
            it 'returns the result of adding the parsed `frc` shutoff time to the `grace_period` from the `now_hash`' do
              allow(loan_terms_module).to receive(:parse_time).with(now_hash[:date], default_shutoffs['frc']).and_return(parsed_time)
              expect(call_method).to eq(parsed_time + now_hash[:grace_period].minutes)
            end
          end
        end
      end
    end

    describe '`value_for_term`' do
      let(:now_hash) { double('A Now Hash') }
      let(:bucket) { { 'TERM_BUCKET_LABEL' => double('A Bucket Label') } }
      let(:call_method) { subject.value_for_term(app, bucket, now_hash) }
      before { allow(subject).to receive(:hash_for_types) }
      it 'returns BLANK_TYPES if the bucket is nil' do
        expect(subject.value_for_term(app, nil, now_hash)).to be(described_class::BLANK_TYPES)
      end
      describe 'with a bucket' do
        let(:before_end_time) { double('before end time') }
        before do
          allow(subject).to receive(:before_end_time?).and_return(before_end_time)
        end
        it 'calls `before_end_time?` with the app' do
          expect(subject).to receive(:before_end_time?).with(app, anything, anything)
          call_method
        end
        it 'calls `before_end_time?` with the bucket' do
          expect(subject).to receive(:before_end_time?).with(anything, bucket, anything)
          call_method
        end
        it 'calls `before_end_time?` with the now_hash' do
          expect(subject).to receive(:before_end_time?).with(anything, anything, now_hash)
          call_method
        end
        it 'calls `hash_for_types` with the app' do
          expect(subject).to receive(:hash_for_types).with(app, any_args)
          call_method
        end
        it 'calls `hash_for_types` with the bucket' do
          expect(subject).to receive(:hash_for_types).with(anything, bucket, any_args)
          call_method
        end
        it 'calls `hash_for_types` with the bucket label' do
          expect(subject).to receive(:hash_for_types).with(anything, anything, bucket['TERM_BUCKET_LABEL'], any_args)
          call_method
        end
        it 'calls `hash_for_types` with the result of `before_end_time?`' do
          expect(subject).to receive(:hash_for_types).with(anything, anything, anything, before_end_time, anything)
          call_method
        end
        it 'calls `hash_for_types` with the now_hash' do
          expect(subject).to receive(:hash_for_types).with(anything, anything, anything, anything, now_hash)
          call_method
        end
      end
    end

    describe '`before_end_time?`' do
      let(:bucket) { double('bucket') }
      let(:call_method) { loan_terms_module.before_end_time?(app, bucket, now_hash) }
      before { allow(loan_terms_module).to receive(:end_time) }

      it 'calls `end_time` with the `app`' do
        expect(loan_terms_module).to receive(:end_time).with(app, anything, anything)
        call_method
      end
      it 'calls `end_time` with the `bucket`' do
        expect(loan_terms_module).to receive(:end_time).with(anything, bucket, anything)
        call_method
      end
      it 'calls `end_time` with the `now_hash`' do
        expect(loan_terms_module).to receive(:end_time).with(anything, anything, now_hash)
        call_method
      end

      context 'when `end_time` returns nil' do
        before { allow(loan_terms_module).to receive(:end_time).and_return(nil) }
        it 'returns `false`' do
          expect(call_method).to be false
        end
      end
      context 'when `end_time` returns a time that is after the `time` value of the `now_hash`' do
        let(:end_time) { now + rand(15..99).minutes }
        before { allow(loan_terms_module).to receive(:end_time).and_return(end_time) }
        it 'returns `true`' do
          expect(call_method).to be true
        end
      end
      context 'when `end_time` returns a time that is before the `time` value of the `now_hash`' do
        let(:end_time) { now - rand(15..99).minutes }
        before { allow(loan_terms_module).to receive(:end_time).and_return(end_time) }
        it 'returns `true`' do
          expect(call_method).to be false
        end
      end
    end

    describe '`hash_for_type`' do
      let(:bucket) { instance_double(Hash) }
      let(:bucket_label) { instance_double(String) }
      let(:type) { instance_double(String) }
      let(:trade_status) { instance_double(String) }
      let(:now) { instance_double(Hash) }
      let(:end_time) { instance_double(DateTime) }
      let(:display_status) { instance_double(String) }
      let(:loan_term) { instance_double(Hash) }
      let(:call_method) { subject.hash_for_type(app, bucket, type, bucket_label, trade_status, now) }
      before do
        allow(subject).to receive(:end_time).and_return(end_time)
        allow(subject).to receive(:display_status).and_return(display_status)
        allow(subject).to receive(:loan_term).and_return(loan_term)
      end

      it 'gets the `end_time`' do
        expect(subject).to receive(:end_time).with(app, bucket, now)
        call_method
      end
      it 'gets the `display_status`' do
        expect(subject).to receive(:display_status).with(bucket, type)
        call_method
      end
      it 'calls `loan_term` with the proper args' do
        expect(subject).to receive(:loan_term).with(trade_status, display_status, bucket_label, end_time)
        call_method
      end
      it 'returns the result of `loan_term`' do
        expect(call_method).to eq(loan_term)
      end
    end

    describe '`hash_for_types`' do
      let(:bucket) { double('bucket') }
      let(:bucket_label) { instance_double(String) }
      let(:before_end_time) { double('before_end_time') }
      let(:hash_for_type) { instance_double(Hash) }
      let(:result) { double('result') }
      let(:call_method) { subject.hash_for_types(app, bucket, bucket_label, before_end_time, now_hash) }

      before { allow(loan_terms_module).to receive(:hash_for_type) }

      loan_terms_module::LOAN_TYPES.each do |type|
        it "calls `hash_for_type` with args containing the `#{type}` type" do
          expect(loan_terms_module).to receive(:hash_for_type).with(app, bucket, type, bucket_label, before_end_time, now_hash)
          call_method
        end
        it "calls `hash_from_pairs` with an array containing the `#{type}` and the corresponding hash for that type" do
          allow(loan_terms_module).to receive(:hash_for_type).with(app, bucket, type, bucket_label, before_end_time, now_hash).and_return(hash_for_type)
          expect(loan_terms_module).to receive(:hash_from_pairs).with(include([type, hash_for_type]))
          call_method
        end
        it 'returns the result of calling `hash_from_pairs`' do
          allow(loan_terms_module).to receive(:hash_from_pairs).and_return(result)
          expect(call_method).to eq(result)
        end
      end
    end

    describe '`loan_term`' do
      let(:bucket_label) { instance_double(String) }
      let(:before_end_time) { instance_double(String) }
      let(:end_time) { instance_double(DateTime, strftime: nil) }
      let(:display_status) { instance_double(String) }
      let(:call_method) { subject.loan_term(before_end_time, display_status, bucket_label, end_time) }

      describe '`trade_status`' do
        it 'is true if both `display_status` and `before_end_time?` are true' do
          expect(subject.loan_term(true, true, bucket_label, end_time)[:trade_status]).to be true
        end
        it 'is false if `before_end_time?` is false' do
          expect(subject.loan_term(false, true, bucket_label, end_time)[:trade_status]).to be false
        end
        it 'is false if `display_status` is false' do
          expect(subject.loan_term(true, false, bucket_label, end_time)[:trade_status]).to be false
        end
      end
      describe '`end_time_reached`' do
        it 'is true if `before_end_time?` is false' do
          expect(subject.loan_term(false, display_status, bucket_label, end_time)[:end_time_reached]).to be true
        end
        it 'is false if `before_end_time?` is true' do
          expect(subject.loan_term(true, display_status, bucket_label, end_time)[:end_time_reached]).to be false
        end
      end
      it 'sets `display_status` to the display_status it was passed' do
        expect(call_method[:display_status]).to eq(display_status)
      end
      it 'sets `bucket_label` to the bucket_label it was passed' do
        expect(call_method[:bucket_label]).to eq(bucket_label)
      end
      it 'sets `end_time` to an iso8601 formatted string' do
        formatted_time = instance_double(String)
        allow(end_time).to receive(:iso8601).and_return(formatted_time)
        expect(call_method[:end_time]).to eq(formatted_time)
      end
      it 'sets `end_time` to nil if the passed end_time is nil' do
        expect(subject.loan_term(before_end_time, display_status, bucket_label, nil)[:end_time]).to be nil
      end
    end

    describe '`disable_term_sql` method' do
      let(:term_id) { double('A Term ID') }
      let(:quoted_term_id) { SecureRandom.hex }
      let(:call_method) { MAPI::Services::Rates::LoanTerms.disable_term_sql(term_id) }
      before do
        allow(MAPI::Services::Rates::LoanTerms).to receive(:quote).with(term_id).and_return(quoted_term_id)
      end
      it 'updates the `WEB_ADM.AO_TERM_BUCKETS`' do
        expect(call_method).to match(/^\s*UPDATE\s+WEB_ADM.AO_TERM_BUCKETS\s+SET/i)
      end
      it 'sets `WHOLE_LOAN_ENABLED` to `N`' do
        expect(call_method).to match(/\s+SET\s+(\S+\s*=\s*\S+\s+)*WHOLE_LOAN_ENABLED\s*=\s*'N'((,\s+(\S+\s*=\s*\S+\s+)*)|\s+)WHERE/i)
      end
      it 'sets `SBC_AGENCY_ENABLED` to `N`' do
        expect(call_method).to match(/\s+SET\s+(\S+\s*=\s*\S+\s+)*SBC_AGENCY_ENABLED\s*=\s*'N'((,\s+(\S+\s*=\s*\S+\s+)*)|\s+)WHERE/i)
      end
      it 'sets `SBC_AAA_ENABLED` to `N`' do
        expect(call_method).to match(/\s+SET\s+(\S+\s*=\s*\S+\s+)*SBC_AAA_ENABLED\s*=\s*'N'((,\s+(\S+\s*=\s*\S+\s+)*)|\s+)WHERE/i)
      end
      it 'sets `SBC_AA_ENABLED` to `N`' do
        expect(call_method).to match(/\s+SET\s+(\S+\s*=\s*\S+\s+)*SBC_AA_ENABLED\s*=\s*'N'((,\s+(\S+\s*=\s*\S+\s+)*)|\s+)WHERE/i)
      end
      it 'limits the update to the quoted `term_id`' do
        expect(call_method).to match(/WHERE\s+AO_TERM_BUCKET_ID\s+=\s+#{quoted_term_id}\s*$/)
      end
    end

    describe '`disable_term` method' do
      let(:term) { double('A Term') }
      let(:term_id) { double('A Term ID') }
      let(:logger) { double('A Logger') }
      let(:settings) { double('App Settings', environment: double('An Environment')) }
      let(:app) { instance_double(MAPI::ServiceApp, logger: logger, settings: settings) }
      let(:disable_term_sql) { double('Disable Term SQL') }
      let(:call_method) { MAPI::Services::Rates::LoanTerms.disable_term(app, term) }
      before do
        allow(MAPI::Services::Rates::LoanTerms).to receive(:term_to_id).with(term).and_return(term_id)
        allow(MAPI::Services::Rates::LoanTerms).to receive(:execute_sql)
        allow(MAPI::Services::Rates::LoanTerms).to receive(:disable_term_sql).with(term_id).and_return(disable_term_sql)
      end
      it 'converts the passed term to an ID' do
        expect(MAPI::Services::Rates::LoanTerms).to receive(:term_to_id).with(term)
        call_method
      end
      describe 'in the production environment' do
        before do
          allow(app.settings).to receive(:environment).and_return(:production)
        end
        it 'constructs disable term SQL' do
          expect(MAPI::Services::Rates::LoanTerms).to receive(:disable_term_sql).with(term_id)
          call_method
        end
        it 'executes the disable term SQL' do
          expect(MAPI::Services::Rates::LoanTerms).to receive(:execute_sql).with(logger, disable_term_sql)
          call_method
        end
        it 'returns true if one row was updated' do
          allow(MAPI::Services::Rates::LoanTerms).to receive(:execute_sql).and_return(1)
          expect(call_method).to be(true)
        end
        it 'returns false if no rows were updated' do
          allow(MAPI::Services::Rates::LoanTerms).to receive(:execute_sql).and_return(0)
          expect(call_method).to be(false)
        end
        it 'returns false if more than one row was updated' do
          allow(MAPI::Services::Rates::LoanTerms).to receive(:execute_sql).and_return(2)
          expect(call_method).to be(false)
        end
        it 'returns false if an error occured' do
          allow(MAPI::Services::Rates::LoanTerms).to receive(:execute_sql).and_return(nil)
          expect(call_method).to be(false)
        end
      end
      describe 'in other environments' do
        it 'does not execute any SQL' do
          expect(MAPI::Services::Rates::LoanTerms).to_not receive(:execute_sql)
          call_method
        end
        it 'returns true' do
          expect(call_method).to be(true)
        end
      end
    end

    describe '`display_status`' do
      MAPI::Services::EtransactAdvances::TYPE_BUCKET_COLUMN_NO_MAPPING.each do |type, key_mapping|
        context "when `#{type}` is passed for the `type` argument" do
          context "when the `#{MAPI::Services::EtransactAdvances::TYPE_BUCKET_COLUMN_NO_MAPPING[type]}` value for the bucket equals `Y`" do
            let(:bucket) { {MAPI::Services::EtransactAdvances::TYPE_BUCKET_COLUMN_NO_MAPPING[type] => 'Y'} }
            let(:call_method) { loan_terms_module.display_status(bucket, type) }
            it 'returns `true`' do
              expect(call_method).to be true
            end
          end

          context "when the `#{MAPI::Services::EtransactAdvances::TYPE_BUCKET_COLUMN_NO_MAPPING[type]}` value for the bucket does not equal `Y`" do
            let(:bucket) { {MAPI::Services::EtransactAdvances::TYPE_BUCKET_COLUMN_NO_MAPPING[type] => 'N'} }
            let(:call_method) { loan_terms_module.display_status(bucket, type) }
            it 'returns `false`' do
              expect(call_method).to be false
            end
          end
        end
      end
      context 'when the `type` argument is not a recognized key in the bucket' do
        let(:call_method) { loan_terms_module.display_status({}, :foo) }
        it 'returns `false`' do
          expect(call_method).to be false
        end
      end
    end

    describe '`early_shutoffs`' do
      let(:results) { double('results') }
      let(:call_method) { loan_terms_module.early_shutoffs(app) }

      it 'calls `MAPI::Services::EtransactAdvances::ShutoffTimes.get_early_shutoffs` with the app' do
        expect(MAPI::Services::EtransactAdvances::ShutoffTimes).to receive(:get_early_shutoffs).with(app)
        call_method
      end
      it 'returns the results of calling `MAPI::Services::EtransactAdvances::ShutoffTimes.get_early_shutoffs`' do
        allow(MAPI::Services::EtransactAdvances::ShutoffTimes).to receive(:get_early_shutoffs).and_return(results)
        expect(call_method).to eq(results)
      end
    end

    describe '`default_shutoffs`' do
      let(:results) { double('results') }
      let(:call_method) { loan_terms_module.default_shutoffs(app) }

      it 'calls `MAPI::Services::EtransactAdvances::ShutoffTimes.get_shutoff_times_by_type` with the app' do
        expect(MAPI::Services::EtransactAdvances::ShutoffTimes).to receive(:get_shutoff_times_by_type).with(app)
        call_method
      end
      it 'returns the results of calling `MAPI::Services::EtransactAdvances::ShutoffTimes.get_shutoff_times_by_type`' do
        allow(MAPI::Services::EtransactAdvances::ShutoffTimes).to receive(:get_shutoff_times_by_type).and_return(results)
        expect(call_method).to eq(results)
      end
    end

    describe '`bucket_is_vrc?`' do
      it "returns `true` if the `AO_TERM_BUCKET_ID` for the bucket is equal to `#{loan_terms_module::VRC_CREDIT_TYPE_BUCKET_ID}`" do
        expect(loan_terms_module.bucket_is_vrc?({'AO_TERM_BUCKET_ID' => loan_terms_module::VRC_CREDIT_TYPE_BUCKET_ID})).to be true
      end
      it "returns `false` if the `AO_TERM_BUCKET_ID` for the bucket is not equal to `#{loan_terms_module::VRC_CREDIT_TYPE_BUCKET_ID}`" do
        expect(loan_terms_module.bucket_is_vrc?({'AO_TERM_BUCKET_ID' => :foo})).to be false
      end
    end
  end
end