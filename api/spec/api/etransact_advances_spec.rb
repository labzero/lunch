require 'spec_helper'

describe MAPI::ServiceApp do
  before do
    header 'Authorization', "Token token=\"#{ENV['MAPI_SECRET_TOKEN']}\""
  end

  [:test, :production].each do |env|
    describe "etransact advances limits in the #{env} environment" do
      let(:etransact_advances_limits) { get '/etransact_advances/limits'; JSON.parse(last_response.body) }
      let(:some_status_data) {{"WHOLE_LOAN_ENABLED" => "N", "SBC_AGENCY_ENABLED" => "Y", "SBC_AAA_ENABLED" => "Y", "SBC_AA_ENABLED" => "Y",
          "LOW_DAYS_TO_MATURITY" => 0, "HIGH_DAYS_TO_MATURITY" => 1, "MIN_ONLINE_ADVANCE" => "100000", "TERM_DAILY_LIMIT" => "201000000",
          "PRODUCT_TYPE" => "VRC", "END_TIME" => "1700", "OVERRIDE_END_DATE" => "01-JAN-2006 12:00 AM", "OVERRIDE_END_TIME" => "1700"}} if env == :production
      let(:result_set) {double('Oracle Result Set', fetch: nil)} if env == :production
      before do
        if env == :production
          allow(MAPI::ServiceApp).to receive(:environment).at_least(1).times.and_return(:production)
          allow(ActiveRecord::Base).to receive(:connection).and_return(double('OCI8 Connection'))
          allow(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(result_set)
          allow(result_set).to receive(:fetch_hash).and_return(some_status_data, nil)
        end
      end
      it 'should return the expected limits for all types of advances' do
        expect(etransact_advances_limits.length).to be >=1
        etransact_advances_limits.each do |row|
          expect(row['WHOLE_LOAN_ENABLED']).to be_kind_of(String)
          expect(row['SBC_AGENCY_ENABLED']).to be_kind_of(String)
          expect(row['SBC_AAA_ENABLED']).to be_kind_of(String)
          expect(row['SBC_AA_ENABLED']).to be_kind_of(String)
          expect(row['LOW_DAYS_TO_MATURITY']).to be_kind_of(Numeric)
          expect(row['HIGH_DAYS_TO_MATURITY']).to be_kind_of(Numeric)
          expect(row['MIN_ONLINE_ADVANCE']).to be_kind_of(String)
          expect(row['TERM_DAILY_LIMIT']).to be_kind_of(String)
          expect(row['PRODUCT_TYPE']).to be_kind_of(String)
          expect(row['END_TIME']).to be_kind_of(String)
          expect(row['OVERRIDE_END_DATE']).to be_kind_of(String)
          expect(row['OVERRIDE_END_TIME']).to be_kind_of(String)
        end
      end
    end
  end

  describe "etransact advances status" do
    let(:etransact_advances_status) { get '/etransact_advances/status'; JSON.parse(last_response.body) }
    it "should return 2 etransact advances status" do
      expect(etransact_advances_status.length).to be >=1
      expect(etransact_advances_status['etransact_advances_status']).to be_boolean
      expect(etransact_advances_status['wl_vrc_status']).to be_boolean
      expect(etransact_advances_status['eod_reached']).to be_boolean
      expect(etransact_advances_status['disabled']).to be_boolean
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
                                 "SBC_AA_ENABLED"=>  "Y", "END_TIME" => "2000",  "OVERRIDE_END_DATE" =>  "01-JAN-2006 12:00 AM", "OVERRIDE_END_TIME"=>  "0700"}}
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
      let(:now_time_string)       { double( 'now time as HHMMSS')}# { '010000' }
      let(:now)                   { double( 'Time.zone.now' ) } #Time.zone.parse( now_string ) }
      let(:today_time)            { double( 'today time') }
      let(:today_time_with_TZ)    { double( 'today time with TZ') }
      let(:today_date_with_TZ)    { double( 'today date withn TZ') }
      let(:long_ago_time)         { double( 'long ago time' ) }
      let(:long_ago_time_with_TZ) { double( 'long ago time with TZ' ) }
      let(:long_ago_date_with_TZ) { double( 'long ago date with TZ' ) }
      let(:hash1) do
        {
            "AO_TERM_BUCKET_ID"  => 1,
            "TERM_BUCKET_LABEL"  => "Open and O/N",
            "WHOLE_LOAN_ENABLED" => "Y",
            "SBC_AGENCY_ENABLED" => "Y",
            "SBC_AAA_ENABLED"    => "Y",
            "SBC_AA_ENABLED"     => "Y",
            "END_TIME"           => "0001",
            "OVERRIDE_END_DATE"  => long_ago_time,
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
            "OVERRIDE_END_DATE"  => long_ago_time,
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
            "OVERRIDE_END_DATE"  => today_time,
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
        allow(now).to receive(:to_date).and_return(today_date_with_TZ)
        allow(today_time).to receive(:in_time_zone).with( "Pacific Time (US & Canada)").and_return(today_time_with_TZ)
        allow(long_ago_time).to receive(:in_time_zone).with( "Pacific Time (US & Canada)").and_return(long_ago_time_with_TZ)
        allow(today_time_with_TZ).to receive(:to_date).and_return(today_date_with_TZ)
        allow(long_ago_time_with_TZ).to receive(:to_date).and_return(long_ago_date_with_TZ)
        allow(now).to receive(:strftime).with("%H%M%S").and_return(now_time_string)
        allow(Time.zone).to receive(:now).and_return(now)
        allow(now_time_string).to receive(:<).with('000100').and_return(false)
        allow(now_time_string).to receive(:<).with('120000').and_return(true)
        allow(now_time_string).to receive(:<).with('200000').and_return(true)
        allow(now_time_string).to receive(:<).with('235900').and_return(true)      end

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
                                    "OVERRIDE_END_DATE" => long_ago_time,
                                    "OVERRIDE_END_TIME" => "0700"}, nil).at_least(1).times
        expect(etransact_advances_status['etransact_advances_status']).to be false
        expect(etransact_advances_status['wl_vrc_status']).to be true
      end
    end
  end

  describe 'eTransact Advances Settings' do
    let(:make_request) { get '/etransact_advances/settings' }
    it 'should call `MAPI::Services::EtransactAdvances::Settings.settings`' do
      expect(MAPI::Services::EtransactAdvances::Settings).to receive(:settings)
      make_request
    end
    it 'should call `to_json` on the settings returned' do
      settings = double('Settings')
      allow(MAPI::Services::EtransactAdvances::Settings).to receive(:settings).and_return(settings)
      expect(settings).to receive(:to_json)
      make_request
    end
    it 'should return a 503 if no settings are found' do
      allow(MAPI::Services::EtransactAdvances::Settings).to receive(:settings).and_return(nil)
      make_request
      expect(last_response.status).to be(503)
    end
  end
end