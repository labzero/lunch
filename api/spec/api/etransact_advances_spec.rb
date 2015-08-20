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
      let(:today_date) { Time.zone.now }
      let(:some_status_data) {{"AO_TERM_BUCKET_ID" => 1, "TERM_BUCKET_LABEL"=> "Open and O/N", "WHOLE_LOAN_ENABLED"=>  "Y", "SBC_AGENCY_ENABLED"=> "Y", "SBC_AAA_ENABLED" =>  "Y",
                               "SBC_AA_ENABLED"=>  "Y", "END_TIME" => "0001",  "OVERRIDE_END_DATE" =>  "01-JAN-2006 12:00 AM", "OVERRIDE_END_TIME"=>  "2000"}}
      let(:some_status_data2) {{"AO_TERM_BUCKET_ID" => 2, "TERM_BUCKET_LABEL"=> "1 Week", "WHOLE_LOAN_ENABLED"=>  "Y", "SBC_AGENCY_ENABLED"=> "Y", "SBC_AAA_ENABLED" =>  "Y",
                                "SBC_AA_ENABLED"=>  "N", "END_TIME" => "2000",  "OVERRIDE_END_DATE" =>  "01-JAN-2006 12:00 AM", "OVERRIDE_END_TIME"=>  "0700"}}
      let(:some_status_data3) {{"AO_TERM_BUCKET_ID" => 3, "TERM_BUCKET_LABEL"=> "2 Weeks", "WHOLE_LOAN_ENABLED"=>  "Y", "SBC_AGENCY_ENABLED"=> "Y", "SBC_AAA_ENABLED" =>  "Y",
                                "SBC_AA_ENABLED"=>  "Y", "END_TIME" => "2000",  "OVERRIDE_END_DATE" =>  today_date, "OVERRIDE_END_TIME"=>  "2359"}}
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
        allow(result_set4).to receive(:fetch_hash).and_return(some_status_data, some_status_data2, some_status_data3, nil)
      end
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
      it 'should return trade status false if passed end time but display_status is true and there is no override for today' do
        result = etransact_advances_status['all_loan_status']
        MAPI::Shared::Constants::LOAN_TERMS.each do |term|
          MAPI::Shared::Constants::LOAN_TYPES.each do |type|
            if term.to_s == 'overnight' then
              expect(result[term.to_s][type.to_s]['trade_status']).to be false
              expect(result[term.to_s][type.to_s]['display_status']).to be true
              expect(result[term.to_s][type.to_s]['bucket_label']).to eq('Open and O/N')
            end
          end
        end
      end
      it 'should return trade status and display status to be false if type and term is disabled' do
        result = etransact_advances_status['all_loan_status']
        MAPI::Shared::Constants::LOAN_TERMS.each do |term|
          MAPI::Shared::Constants::LOAN_TYPES.each do |type|
            if term.to_s == '1week' then
              if type.to_s == 'aa' then
                expect(result[term.to_s][type.to_s]['trade_status']).to be false
                expect(result[term.to_s][type.to_s]['display_status']). to be false
              else
                expect(result[term.to_s][type.to_s]['trade_status']).to be true
                expect(result[term.to_s][type.to_s]['display_status']). to be true
              end
              expect(result[term.to_s][type.to_s]['bucket_label']).to eq('1 Week')
            end
          end
        end
      end
      it 'should return trade status and display status to true if override_end_time for the override_end_date is not over regardless of end_time' do
        result = etransact_advances_status['all_loan_status']
        MAPI::Shared::Constants::LOAN_TERMS.each do |term|
          MAPI::Shared::Constants::LOAN_TYPES.each do |type|
            if term.to_s == "2week" then
              expect(result[term.to_s][type.to_s]['trade_status']).to be true
              expect(result[term.to_s][type.to_s]['display_status']).to be true
              expect(result[term.to_s][type.to_s]['bucket_label']).to eq('2 Weeks')
            end
          end
        end
      end
      it 'should return etransact status = false if etransact is turn on but no product is available' do
        expect(result_set).to receive(:fetch).and_return([1], nil).at_least(1).times
        expect(result_set2).to receive(:fetch).and_return([0], nil).at_least(1).times
        expect(result_set3).to receive(:fetch).and_return([1], nil).at_least(1).times
        expect(result_set4).to receive(:fetch_hash).and_return({"AO_TERM_BUCKET_ID" => 3, "TERM_BUCKET_LABEL"=> "2 Week", "WHOLE_LOAN_ENABLED"=>  "Y", "SBC_AGENCY_ENABLED"=> "Y", "SBC_AAA_ENABLED" =>  "Y",
                                                                "SBC_AA_ENABLED"=>  "Y", "END_TIME" => "1200",  "OVERRIDE_END_DATE" =>  "01-JAN-2006 12:00 AM", "OVERRIDE_END_TIME"=>  "0700"}, nil).at_least(1).times
        expect(etransact_advances_status['etransact_advances_status']).to be false
        expect(etransact_advances_status['wl_vrc_status']).to be true
      end
      it 'should return trade status to false if override_end_time for the override_end_date that is set for today has passed the current time' do
        expect(result_set).to receive(:fetch).and_return([1], nil).at_least(1).times
        expect(result_set2).to receive(:fetch).and_return([0], nil).at_least(1).times
        expect(result_set3).to receive(:fetch).and_return([1], nil).at_least(1).times
        # expect(result_set4).to receive(:fetch).and_return([3, '2 Week', 'Y', 'Y', 'Y', 'Y', '2359', today_date, '0001'], nil).at_least(1).times
        expect(result_set4).to receive(:fetch_hash).and_return({"AO_TERM_BUCKET_ID" => 3, "TERM_BUCKET_LABEL"=> "2 Week", "WHOLE_LOAN_ENABLED"=>  "Y", "SBC_AGENCY_ENABLED"=> "Y", "SBC_AAA_ENABLED" =>  "Y",
         "SBC_AA_ENABLED"=>  "Y", "END_TIME" => "2359",  "OVERRIDE_END_DATE" =>  today_date, "OVERRIDE_END_TIME"=>  "0001"}, nil).at_least(1).times
        result = etransact_advances_status['all_loan_status']
        MAPI::Shared::Constants::LOAN_TERMS.each do |term|
          MAPI::Shared::Constants::LOAN_TYPES.each do |type|
            if term.to_s == "2week" then
              expect(result[term.to_s][type.to_s]['trade_status']).to be false
              expect(result[term.to_s][type.to_s]['display_status']).to be true
              expect(result[term.to_s][type.to_s]['bucket_label']).to eq('2 Week')
            end
          end
        end
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