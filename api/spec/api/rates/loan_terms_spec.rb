require 'spec_helper'
require 'date'

describe MAPI::Services::Rates::LoanTerms do
  describe 'production' do
    subject { MAPI::Services::Rates::LoanTerms }

    describe 'loan_terms' do
      let(:now_time_string)         { double( 'now time as HHMM')}
      let(:now)                     { double( 'Time.zone.now' ) }
      let(:now_date)                { double( 'now date') }
      let(:long_ago_date)           { double( 'long ago date' ) }
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
      before do
        allow(MAPI::ServiceApp).to receive(:environment).and_return(:production)
        allow(ActiveRecord::Base).to receive(:connection).and_return(double('OCI8 Connection'))
        allow(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(result_set)
        allow(result_set).to receive(:fetch_hash).and_return(hash1, hash2, hash3, nil)
        allow(now).to receive(:to_date).and_return(now_date)
        allow(now).to receive(:strftime).with('%H%M').and_return(now_time_string)
        allow(Time.zone).to receive(:now).and_return(now)
        allow(now_time_string).to receive(:<).with('0001').and_return(false)
        allow(now_time_string).to receive(:<).with('2000').and_return(true)
        allow(now_time_string).to receive(:<).with('2359').and_return(true)
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
      it 'should log warnings for exceptions' do
        allow(connection).to receive(:execute).and_return(cursor)
        allow(ActiveRecord::Base).to receive(:connection).and_return(connection)
        allow(cursor).to receive(:fetch_hash).and_raise(:bad_shit)
        expect(logger).to receive(:error)
        MAPI::Services::Rates::LoanTerms.term_bucket_data_production(logger)
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
end