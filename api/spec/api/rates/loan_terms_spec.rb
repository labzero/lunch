require 'spec_helper'
require 'date'

describe MAPI::Services::Rates::LoanTerms do
  describe 'production' do
    subject { MAPI::Services::Rates::LoanTerms }

    describe 'loan_terms' do
      let(:now)                     { '2016-03-02 13:00'.to_datetime }
      let(:now_time_string)         { now.strftime('%H%M') }
      let(:now_date)                { now.to_date }
      let(:long_ago_date)           { '2001-03-23'.to_date }
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
      let(:result_set) { double('Oracle Result Set', fetch_hash: nil) }
      let(:logger) { double('logger') }
      let(:grace_period) { rand(1..10) }
      let(:environment) { :production }
      let(:call_method) { subject.loan_terms(logger, environment) }
      before do
        allow(ActiveRecord::Base).to receive(:connection).and_return(double('OCI8 Connection'))
        allow(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(result_set)
        allow(result_set).to receive(:fetch_hash).and_return(hash1, hash2, hash3, nil)
        allow(Time.zone).to receive(:now).and_return(now)
        allow(MAPI::Services::EtransactAdvances::Settings).to receive(:settings).and_return({'end_of_day_extension' => grace_period})
      end

      it 'should return the expected status type and label for ALL LOAN_TERMS, LOAN_TYPES' do
        result = subject.loan_terms(logger, :production)
        MAPI::Services::Rates::LOAN_TERMS.each do |term|
          MAPI::Services::Rates::LOAN_TYPES.each do |type|
            expect(result[term][type]['trade_status']).to be_boolean
            expect(result[term][type]['display_status']).to be_boolean
            expect(result[term][type]['bucket_label']).to be_kind_of(String)
          end
        end
      end

      it 'should return trade status false if passed end time but display_status is true and there is no override for today' do
        result = subject.loan_terms(logger, :production)
        MAPI::Shared::Constants::LOAN_TYPES.each do |type|
          expect(result[:overnight][type]['trade_status']).to be false
          expect(result[:overnight][type]['display_status']).to be true
          expect(result[:overnight][type]['bucket_label']).to eq('Open and O/N')
        end
      end

      it 'should return trade status and display status to be false if type and term is disabled' do
        result = subject.loan_terms(logger, :production)
        MAPI::Shared::Constants::LOAN_TYPES.each do |type|
          if type == :aa
            expect(result['1week'][type]['trade_status']).to be false
            expect(result['1week'][type]['display_status']).to be false
          else
            expect(result['1week'][type]['trade_status']).to be true
            expect(result['1week'][type]['display_status']).to be true
          end
          expect(result['1week'][type]['bucket_label']).to eq('1 Week')
        end
      end

      it 'should return trade status and display status to true if override_end_time for the override_end_date is not over regardless of end_time' do
        result = subject.loan_terms(logger, :production)
        MAPI::Shared::Constants::LOAN_TYPES.each do |type|
          expect(result['2week'][type]['trade_status']).to be true
          expect(result['2week'][type]['display_status']).to be true
          expect(result['2week'][type]['bucket_label']).to eq('2 Weeks')
        end
      end

      let(:result_hash4) do
        {"AO_TERM_BUCKET_ID" => 3,
         "TERM_BUCKET_LABEL" => "2 Week",
         "WHOLE_LOAN_ENABLED" => "Y",
         "SBC_AGENCY_ENABLED" => "Y",
         "SBC_AAA_ENABLED" => "Y",
         "SBC_AA_ENABLED" => "Y",
         "END_TIME" => "2359",
         "OVERRIDE_END_DATE" => now_date,
         "OVERRIDE_END_TIME" => "0001"}
      end
      it 'should return trade status to false if override_end_time for the override_end_date that is set for today has passed the current time' do
        allow(result_set).to receive(:fetch_hash).and_return(result_hash4, nil)
        result = subject.loan_terms(logger, :production)
        MAPI::Shared::Constants::LOAN_TYPES.each do |type|
          expect(result['2week'][type]['trade_status']).to be false
          expect(result['2week'][type]['display_status']).to be true
          expect(result['2week'][type]['bucket_label']).to eq('2 Week')
        end
      end

      it 'fetches the eTransact settings' do
        expect(MAPI::Services::EtransactAdvances::Settings).to receive(:settings).with(environment)
        call_method
      end
      it 'passes the grace_period into the `value_for_term`' do
        expect(subject).to receive(:value_for_term).with(anything, include(grace_period: anything)).exactly(described_class::LOAN_TERMS.count)
        call_method
      end
      it 'sets the grace_period to 0 if its not allowed' do
        expect(subject).to receive(:value_for_term).with(anything, include(grace_period: 0)).exactly(described_class::LOAN_TERMS.count)
        call_method
      end
      it 'sets the grace_period to the `end_of_day_extension` if it is allowed' do
        expect(subject).to receive(:value_for_term).with(anything, include(grace_period: grace_period)).exactly(described_class::LOAN_TERMS.count)
        subject.loan_terms(logger, environment, true)
      end
    end

    describe 'term_bucket_data' do
      let (:environment) { double("environment") }
      let (:logger) { double("logger") }
      it 'should call term_bucket_data_production in production' do
        expect(MAPI::Services::Rates::LoanTerms).to receive(:term_bucket_data_production).with(logger)
        MAPI::Services::Rates::LoanTerms.term_bucket_data(logger, :production)
      end

      it 'should call term_bucket_data_development in non-production environment' do
        allow(environment).to receive(:==).with(:production).and_return(false)
        expect(MAPI::Services::Rates::LoanTerms).to receive(:term_bucket_data_development)
        MAPI::Services::Rates::LoanTerms.term_bucket_data(logger, environment)
      end
    end
  end

  describe 'development' do
    describe 'term_bucket_data_production' do
      let(:connection) { double('connection') }
      let(:cursor) { double('cursor') }
      let(:logger) { double('logger') }
      let(:call_method) { MAPI::Services::Rates::LoanTerms.term_bucket_data_production(logger) }
      it 'log warnings for exceptions' do
        allow(connection).to receive(:execute).and_return(cursor)
        allow(ActiveRecord::Base).to receive(:connection).and_return(connection)
        allow(cursor).to receive(:fetch_hash).and_raise(:bad_shit)
        expect(logger).to receive(:error)
        call_method
      end
      it 'maps the OVERRIDE_END_DATE to a Date object' do
        expect(subject).to receive(:fetch_hashes).with(logger, described_class::SQL, include(to_date: include('OVERRIDE_END_DATE')))
        call_method
      end
    end

    describe 'term_bucket_data_development' do
      let(:file_contents){ double( 'Fake json file' ) }
      let(:json) { double( 'JSON' ) }
      it "should call JSON.parse" do
        allow(File).to receive(:read).and_return(file_contents)
        allow(json).to receive(:each).and_return(nil)
        allow(json).to receive(:index).and_return(0)
        allow(json).to receive(:[]).and_return({})
        expect(JSON).to receive(:parse).with(file_contents).and_return(json)
        MAPI::Services::Rates::LoanTerms.term_bucket_data_development
      end
    end

    describe 'term_bucket_data_development' do
      let (:yes_or_no)    { /\A(n|y)\Z/i }
      let (:compact_time) { /\A\d{4}\Z/ }
      let (:bucket_label) { /\A(open and o\/n|\d+(-\d+)?\s+(week|month|year)(s)?)\Z/i }
      MAPI::Services::Rates::LoanTerms.term_bucket_data_development.each do |row|
        it 'should have the correct shape' do
          expect(row['AO_TERM_BUCKET_ID']).to be_kind_of Numeric
          expect(row['TERM_BUCKET_LABEL']).to  match(bucket_label)
          expect(row['WHOLE_LOAN_ENABLED']).to match(yes_or_no)
          expect(row['SBC_AGENCY_ENABLED']).to match(yes_or_no)
          expect(row['SBC_AAA_ENABLED']).to    match(yes_or_no)
          expect(row['SBC_AA_ENABLED']).to     match(yes_or_no)
          expect(row['END_TIME']).to           match(compact_time)
          expect(row['OVERRIDE_END_DATE']).to be_kind_of Date
          expect(row['OVERRIDE_END_TIME']).to  match(compact_time)

          expect(row['OVERRIDE_END_DATE']).to eq(Date.today) if row['TERM_BUCKET_LABEL'] == '2 years'
        end
      end
    end

    describe 'term_bucket_data_development' do
      let (:override_end_date_string1) { double( 'override_end_date_string1', to_date: override_end_date1 ) }
      let (:override_end_date_string2) { double( 'override_end_date_string2', to_date: override_end_date2 ) }
      let (:override_end_date1) { double( 'override_end_date1' ) }
      let (:override_end_date2) { double( 'override_end_date2' ) }
      let (:fake_data) do
        [{ 'TERM_BUCKET_LABEL' => '1 year',  'OVERRIDE_END_DATE' => override_end_date_string1},
         { 'TERM_BUCKET_LABEL' => '2 years', 'OVERRIDE_END_DATE' => override_end_date_string2}]
      end
      let (:fake_result) do
        [{ 'TERM_BUCKET_LABEL' => '1 year',  'OVERRIDE_END_DATE' => override_end_date1},
         { 'TERM_BUCKET_LABEL' => '2 years', 'OVERRIDE_END_DATE' => Time.zone.today}]
      end
      before do
        allow(subject).to receive(:fake).and_return(fake_data)
      end
      it 'should return fake_result' do
        expect(subject.term_bucket_data_development).to eq(fake_result)
      end
    end
  end

  describe 'class methods' do
    let(:now) { Time.zone.local(2016, 2, 13, 1, 23) }
    let(:grace_period) { rand(1..10) }
    let(:now_hash) { {date: now.to_date, grace_period: grace_period} }

    describe '`appropriate_end_time`' do
      let(:now) { '2016-02-13 00:00'.to_datetime }
      let(:now_hash) { {date: now.to_date} }
      let(:end_time) { double('An End Time') }
      let(:override_end_time) { now.change({hour: 12, min: 0}) }
      let(:bucket) { double('A Term Bucket') }
      let(:call_method) { subject.appropriate_end_time(bucket, now_hash) }
      before do
        allow(Time.zone).to receive(:now).and_return(now)
        allow(subject).to receive(:end_time).and_return(end_time)
      end
      it 'returns the normal end time if there is no end date override' do
        allow(subject).to receive(:override_end_time).and_return(nil)
        expect(call_method).to eq(end_time)
      end
      it 'returns the normal end time if there is an end date override but its not for today' do
        allow(subject).to receive(:override_end_time).and_return(now - 1.day)
        expect(call_method).to eq(end_time)
      end
      it 'returns the override end time if there is an end date override for today' do
        allow(subject).to receive(:override_end_time).and_return(override_end_time)
        expect(call_method).to eq(override_end_time)
      end
      it 'handles nil for the `end_time`' do
        allow(subject).to receive(:override_end_time).and_return(nil)
        allow(subject).to receive(:end_time).and_return(nil)
        expect(call_method).to be_nil
      end
    end

    describe '`override_end_time`' do
      let(:bucket) {
        {
          'OVERRIDE_END_DATE' => now.to_date.to_s,
          'OVERRIDE_END_TIME' => now.strftime('%H%M')
        }
      }
      let(:call_method) { subject.override_end_time(bucket, now_hash) }
      it 'returns the override end time + grace period' do
        expect(call_method).to eq(now + grace_period.minutes)
      end
      it 'returns nil if the override end date is missing' do
        bucket['OVERRIDE_END_DATE'] = ''
        expect(call_method).to be_nil
      end
      it 'returns nil if the override end time is missing' do
        bucket['OVERRIDE_END_TIME'] = ''
        expect(call_method).to be_nil
      end
    end

    describe '`end_time`' do
      let(:bucket) {
        {
          'END_TIME' => now.strftime('%H%M')
        }
      }
      let(:call_method) { subject.end_time(bucket, now_hash) }
      it 'returns the end time + grace period' do
        expect(call_method).to eq(now + grace_period.minutes)
      end
      it 'returns nil if the end time is missing' do
        bucket['END_TIME'] = ''
        expect(call_method).to be_nil
      end
      it 'returns nil if the current date is missing' do
        now_hash.delete(:date)
        expect(call_method).to be_nil
      end
    end

    describe '`parse_time`' do
      let(:time) { double(Time, to_s: SecureRandom.hex) }
      let(:date) { double(Date, to_s: SecureRandom.hex) }
      let(:parsed_datetime) { double(DateTime) }
      let(:parsed_timewithzone) { double(ActiveSupport::TimeWithZone) }
      let(:pst) { ActiveSupport::TimeZone.new('Pacific Time (US & Canada)') }
      let(:est) { ActiveSupport::TimeZone.new('Eastern Time (US & Canada)') }
      let(:other_zone) { Time.zone == pst ? est : pst }
      let(:call_method) { subject.parse_time(date, time) }
      before do
        allow(parsed_datetime).to receive(:in_time_zone).and_return(parsed_timewithzone)
      end
      context 'duck typing' do
        before do
          allow(DateTime).to receive(:strptime).and_return(Time.zone.now)
        end
        it 'converts the `date` to a string' do
          expect(date).to receive(:to_s)
          call_method
        end
        it 'converts the `time` to a string' do
          expect(time).to receive(:to_s)
          call_method
        end
        it 'calls `strftime` on the `date` if it responds' do
          expect(date).to receive(:strftime).with(described_class::DATE_FORMAT).and_return(date)
          call_method
        end
        it 'does not call `strftime` on the `date` if it is not supported' do
          allow(date).to receive(:respond_to?).with(:strftime).and_return(false)
          expect(date).to_not receive(:strftime)
          call_method
        end
      end
      it 'parses the supplied string according to the DATETIME_FORMAT' do
        expect(DateTime).to receive(:strptime).with(date.to_s + time.to_s + Time.zone.name, described_class::DATETIME_FORMAT).and_return(Time.zone.now)
        call_method
      end
      context 'DST correction algorithim' do
        let(:dst_corrected_timewithzone) { double(ActiveSupport::TimeWithZone) }
        let(:std_offset) { double(Numeric) }
        let(:period) { double(TZInfo::TimezonePeriod, std_offset: std_offset) }
        before do
          allow(parsed_timewithzone).to receive(:period).and_return(period)
          allow(parsed_timewithzone).to receive(:-).with(std_offset).and_return(dst_corrected_timewithzone)
          allow(DateTime).to receive(:strptime).and_return(parsed_datetime)
        end
        it 'fetches the `std_offset` from the parsed TimeWithZone' do
          expect(period).to receive(:std_offset)
          call_method
        end
        it 'subtracts the `std_offset` from the parsed TimeWithZone' do
          expect(parsed_timewithzone).to receive(:-).with(std_offset)
          call_method
        end
        it 'returns the DST shifted TimeWithZone' do
          expect(call_method).to be(dst_corrected_timewithzone)
        end
      end
      {
        Time.zone.local(2012, 2, 13, 13, 14) => ['2012-02-13', '1314'],
        Time.zone.local(2000, 1, 1, 0, 13) => ['2000-01-01', '0013'],
        Time.zone.local(2016, 2, 29, 1, 0) => ['2016-02-29', '0100']
      }.each do |time, args|
        it "parses #{args} into #{time}" do
          expect(subject.parse_time(*args)).to eq(time)
        end
      end
      it 'parses the time in the current `Time.zone` timezone' do
        Time.use_zone(other_zone) do
          time = Time.zone.local(2012, 2, 13, 13, 14)
          expect(subject.parse_time(time.strftime('%Y-%m-%d'), time.strftime('%H%M'))).to eq(time)
        end
      end
      [[2016, 3, 15, 13, 14], [2016, 3, 15, 0, 14], [2016, 3, 15, 23, 59]].each do |time_args|
        it "handles daylight savings time when parsing `#{time_args[0]}-#{time_args[1]}-#{time_args[2]} #{time_args[3]}:#{time_args[4]}`" do
          Time.use_zone(other_zone) do
            time = Time.zone.local(*time_args)
            expect(subject.parse_time(time.strftime('%Y-%m-%d'), time.strftime('%H%M'))).to eq(time)
          end
        end
      end
      it 'parses the correctly when the `date` param is a Time object' do
        time = Time.zone.local(2012, 2, 13, 13, 14)
        time_minute = time.change(sec: 0)
        time_date = time.change(hour: 0, min: 0, sec: 0)
        expect(subject.parse_time(time_date, time.strftime('%H%M'))).to eq(time_minute)
      end
    end

    describe '`value_for_term`' do
      let(:now_hash) { double('A Now Hash') }
      let(:bucket) { { 'TERM_BUCKET_LABEL' => double('A Bucket Label') } }
      let(:call_method) { subject.value_for_term(bucket, now_hash) }
      it 'returns BLANK_TYPES if the bucket is nil' do
        expect(subject.value_for_term(nil, now_hash)).to be(described_class::BLANK_TYPES)
      end
      describe 'with a bucket' do
        let(:trade_status) { double('A Trade Status') }
        before do
          allow(subject).to receive(:trade_status).and_return(trade_status)
        end
        it 'calls `trade_status` with the bucket' do
          expect(subject).to receive(:trade_status).with(bucket, anything)
          call_method
        end
        it 'calls `trade_status` with the now_hash' do
          expect(subject).to receive(:trade_status).with(anything, now_hash)
          call_method
        end
        it 'calls `hash_for_types` with the bucket' do
          expect(subject).to receive(:hash_for_types).with(bucket, anything, anything)
          call_method
        end
        it 'calls `hash_for_types` with the bucket label' do
          expect(subject).to receive(:hash_for_types).with(anything, bucket['TERM_BUCKET_LABEL'], anything)
          call_method
        end
        it 'calls `hash_for_types` with the `trade_status`' do
          expect(subject).to receive(:hash_for_types).with(anything, anything, trade_status)
          call_method
        end
      end
    end

    describe '`trade_status`' do
      let(:now) { Time.zone.now }
      let(:now_hash) { { time: now } }
      let(:bucket) { double('A Bucket Hash') }
      let(:call_method) { subject.trade_status(bucket, now_hash) }
      it 'calls `appropriate_end_time` with the bucket' do
        expect(subject).to receive(:appropriate_end_time).with(bucket, anything)
        call_method
      end
      it 'calls `appropriate_end_time` with the now_hash' do
        expect(subject).to receive(:appropriate_end_time).with(anything, now_hash)
        call_method
      end
      it 'returns false if the `appropriate_end_time` is nil' do
        allow(subject).to receive(:appropriate_end_time).and_return(nil)
        expect(call_method).to be(false)
      end
      it 'returns true if the now_hash time is less than the `appropriate_end_time`' do
        allow(subject).to receive(:appropriate_end_time).and_return(now + 1.minute)
        expect(call_method).to be(true)
      end
      it 'returns false if the now_hash time is greater than the `appropriate_end_time`' do
        allow(subject).to receive(:appropriate_end_time).and_return(now - 1.minute)
        expect(call_method).to be(false)
      end
      it 'returns false if the now_hash time is equal to the `appropriate_end_time`' do
        allow(subject).to receive(:appropriate_end_time).and_return(now)
        expect(call_method).to be(false)
      end
    end
  end
end