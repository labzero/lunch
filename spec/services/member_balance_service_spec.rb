require 'spec_helper'

describe MemberBalanceService do
  MEMBER_ID = 750
  subject { MemberBalanceService.new(MEMBER_ID, double('request', uuid: '12345')) }
  it { expect(subject).to respond_to(:pledged_collateral) }
  it { expect(subject).to respond_to(:total_securities) }
  it { expect(subject).to respond_to(:effective_borrowing_capacity) }
  it { expect(subject).to respond_to(:capital_stock_activity) }
  describe '`pledged_collateral` method', :vcr do
    let(:pledged_collateral) {subject.pledged_collateral}
    it 'should return a hash of hashes containing pledged collateral values' do
      expect(pledged_collateral.length).to be >= 1
      expect(pledged_collateral[:mortgages][:absolute]).to be_kind_of(Numeric)
      expect(pledged_collateral[:mortgages][:percentage]).to be_kind_of(Float)
      expect(pledged_collateral[:agency][:absolute]).to be_kind_of(Numeric)
      expect(pledged_collateral[:agency][:percentage]).to be_kind_of(Float)
      expect(pledged_collateral[:aaa][:absolute]).to be_kind_of(Numeric)
      expect(pledged_collateral[:aaa][:percentage]).to be_kind_of(Float)
      expect(pledged_collateral[:aa][:absolute]).to be_kind_of(Numeric)
      expect(pledged_collateral[:aa][:percentage]).to be_kind_of(Float)
    end
    it 'should return nil if there was an API error' do
      expect_any_instance_of(RestClient::Resource).to receive(:get).and_raise(RestClient::InternalServerError)
      expect(pledged_collateral).to eq(nil)
    end
    it 'should return nil if there was a connection error' do
      expect_any_instance_of(RestClient::Resource).to receive(:get).and_raise(Errno::ECONNREFUSED)
      expect(pledged_collateral).to eq(nil)
    end
  end
  describe '`total_securities` method', :vcr do
    let(:total_securities) {subject.total_securities}
    it 'should return a hash of hashes containing total security values' do
      expect(total_securities.length).to be >= 1
      expect(total_securities[:pledged_securities][:absolute]).to be_kind_of(Integer)
      expect(total_securities[:pledged_securities][:percentage]).to be_kind_of(Float)
      expect(total_securities[:safekept_securities][:absolute]).to be_kind_of(Integer)
      expect(total_securities[:safekept_securities][:percentage]).to be_kind_of(Float)
    end
    it 'should return nil if there was an API error' do
      expect_any_instance_of(RestClient::Resource).to receive(:get).and_raise(RestClient::InternalServerError)
      expect(total_securities).to eq(nil)
    end
    it 'should return nil if there was a connection error' do
      expect_any_instance_of(RestClient::Resource).to receive(:get).and_raise(Errno::ECONNREFUSED)
      expect(total_securities).to eq(nil)
    end
  end
  describe '`effective_borrowing_capacity` method', :vcr do
    let(:effective_borrowing_capacity) {subject.effective_borrowing_capacity}
    it 'should return a hash of hashes containing effective borrowing capacity values' do
      expect(effective_borrowing_capacity.length).to be >= 1
      expect(effective_borrowing_capacity[:used_capacity]).to be_kind_of(Hash)
      expect(effective_borrowing_capacity[:used_capacity][:absolute]).to be_kind_of(Integer)
      expect(effective_borrowing_capacity[:used_capacity][:percentage]).to be_kind_of(Float)
      expect(effective_borrowing_capacity[:unused_capacity]).to be_kind_of(Hash)
      expect(effective_borrowing_capacity[:unused_capacity][:absolute]).to be_kind_of(Integer)
      expect(effective_borrowing_capacity[:unused_capacity][:percentage]).to be_kind_of(Float)
    end
    it 'should return nil if there was an API error' do
      expect_any_instance_of(RestClient::Resource).to receive(:get).and_raise(RestClient::InternalServerError)
      expect(effective_borrowing_capacity).to eq(nil)
    end
    it 'should return nil if there was a connection error' do
      expect_any_instance_of(RestClient::Resource).to receive(:get).and_raise(Errno::ECONNREFUSED)
      expect(effective_borrowing_capacity).to eq(nil)
    end
  end

  describe '`capital_stock_activity` method', :vcr do
    let(:start_date) {Date.new(2014,12,01)}
    let(:end_date) {Date.new(2014,12,31)}
    let(:capital_stock_activity) {subject.capital_stock_activity(start_date, end_date)}
    let(:activities) { File.read(File.join(Rails.root, 'spec', 'fixtures', 'capital_stock_activities.json')) }
    let(:malformed_activities) { File.read(File.join(Rails.root, 'spec', 'fixtures', 'capital_stock_activities_malformed.json')) }
    let(:malformed_json) {"Some malformed JSON!!!"}
    let(:response_object) { double('Response')}
    let(:request_object) {double('Request')}

    it 'should return a start_date and a start_balance' do
      expect(capital_stock_activity[:start_date]).to eq(start_date)
      expect(capital_stock_activity[:start_balance]).to be_kind_of(Integer)
    end
    it 'should return an end_date and an end_balance' do
      expect(capital_stock_activity[:end_date]).to eq(end_date)
      expect(capital_stock_activity[:end_balance]).to be_kind_of(Integer)
    end
    it 'should return an array of activity hashes' do
      expect(capital_stock_activity[:activities]).to be_kind_of(Array)
    end

    describe 'activities hash happy path' do
      before do
        expect(response_object).to receive(:body).and_return(activities)
        expect(request_object).to receive(:get).and_return(response_object)
        override_activities_endpoint(start_date, end_date, request_object)
      end
      it 'should classify the shares for a given activity as either debit or credit' do
        expect(capital_stock_activity[:activities][0][:debit_shares]).to eq(0)
        expect(capital_stock_activity[:activities][0][:credit_shares]).to eq(895)
        expect(capital_stock_activity[:activities][2][:debit_shares]).to eq(2147)
        expect(capital_stock_activity[:activities][2][:credit_shares]).to eq(0)
      end
      it 'should return total_credits and total_debits from the array of activities for the given date range' do
        expect(capital_stock_activity[:total_credits]).to eq(1444)
        expect(capital_stock_activity[:total_debits]).to eq(4289)
      end
    end

    describe 'activities hash sad path' do
      it 'should return nil if an activity is not classified as a credit or debit' do # mock data includes an activity that is improperly classified
        expect(response_object).to receive(:body).and_return(malformed_activities)
        expect(request_object).to receive(:get).and_return(response_object)
        override_activities_endpoint(start_date, end_date, request_object)
        expect(capital_stock_activity).to eq(nil)
      end
    end

    describe 'error handling for MAPI endpoints' do
      it 'should return nil if there was an API error for the start_date capital_stock_balance endpoint' do
        expect(request_object).to receive(:get).and_raise(RestClient::InternalServerError)
        expect_any_instance_of(RestClient::Resource).to receive(:[]).with("member/#{MEMBER_ID}/capital_stock_balance/#{start_date}").and_return(request_object)
        expect(capital_stock_activity).to eq(nil)
      end
      it "should return nil if there was a connection error for the start_date capital_stock_balance endpoint" do
        expect(request_object).to receive(:get).and_raise(Errno::ECONNREFUSED)
        expect_any_instance_of(RestClient::Resource).to receive(:[]).with("member/#{MEMBER_ID}/capital_stock_balance/#{start_date}").and_return(request_object)
        expect(capital_stock_activity).to eq(nil)
      end
      it "should return nil if there was an API error for the end_date capital_stock_balance endpoint" do
        expect(request_object).to receive(:get).and_raise(RestClient::InternalServerError)
        expect_any_instance_of(RestClient::Resource).to receive(:[]).with("member/#{MEMBER_ID}/capital_stock_balance/#{start_date}").and_call_original
        expect_any_instance_of(RestClient::Resource).to receive(:[]).with("member/#{MEMBER_ID}/capital_stock_balance/#{end_date}").and_return(request_object)
        expect(capital_stock_activity).to eq(nil)
      end
      it "should return nil if there was a connection error for the end_date capital_stock_balance endpoint" do
        expect(request_object).to receive(:get).and_raise(Errno::ECONNREFUSED)
        expect_any_instance_of(RestClient::Resource).to receive(:[]).with("member/#{MEMBER_ID}/capital_stock_balance/#{start_date}").and_call_original
        expect_any_instance_of(RestClient::Resource).to receive(:[]).with("member/#{MEMBER_ID}/capital_stock_balance/#{end_date}").and_return(request_object)
        expect(capital_stock_activity).to eq(nil)
      end
      it 'should return nil if there was an API error for the capital_stock_activities endpoint' do
        expect(request_object).to receive(:get).and_raise(RestClient::InternalServerError)
        override_activities_endpoint(start_date, end_date, request_object)
        expect(capital_stock_activity).to eq(nil)
      end
      it 'should return nil if there was a connection error for the capital_stock_activities endpoint' do
        expect(request_object).to receive(:get).and_raise(Errno::ECONNREFUSED)
        override_activities_endpoint(start_date, end_date, request_object)
        expect(capital_stock_activity).to eq(nil)
      end
    end

    describe 'error handling for parsing MAPI JSON responses' do
      before do
        expect(response_object).to receive(:body).and_return(malformed_json)
        expect(request_object).to receive(:get).and_return(response_object)
      end
      it 'should return nil if there was malformed JSON for start_balance' do
        override_start_balance_endpoint(start_date, end_date, request_object)
        expect(capital_stock_activity).to eq(nil)
      end
      it 'should return nil if there was malformed JSON for end_balance' do
        override_end_balance_endpoint(start_date, end_date, request_object)
        expect(capital_stock_activity).to eq(nil)
      end
      it 'should return nil if there was malformed JSON for activities' do
        override_activities_endpoint(start_date, end_date, request_object)
        expect(capital_stock_activity).to eq(nil)
      end
    end

  end

  # TODO add vcr once MAPI endpoint is rigged up
  describe 'profile' do
    let(:profile) {subject.profile}
    it 'should return profile data' do
      expect(profile.length).to be >= 1
      expect(profile[:sta_balance]).to be_kind_of(Integer)
      expect(profile[:credit_outstanding]).to be_kind_of(Integer)
      expect(profile[:financial_available]).to be_kind_of(Integer)
      expect(profile[:stock_leverage]).to be_kind_of(Integer)
      expect(profile[:collateral_market_value_sbc_agency]).to be_kind_of(Integer)
      expect(profile[:collateral_market_value_sbc_aaa]).to be_kind_of(Integer)
      expect(profile[:collateral_market_value_sbc_aa]).to be_kind_of(Integer)
      expect(profile[:borrowing_capacity_standard]).to be_kind_of(Integer)
      expect(profile[:borrowing_capacity_sbc_agency]).to be_kind_of(Integer)
      expect(profile[:borrowing_capacity_sbc_aaa]).to be_kind_of(Integer)
      expect(profile[:borrowing_capacity_sbc_aa]).to be_kind_of(Integer)
    end
    describe 'bad data' do
      before do
        expect(JSON).to receive(:parse).at_least(:once).and_return(JSON.parse(File.read(File.join(Rails.root, 'spec', 'fixtures', 'profile_with_nil_values.json'))))
      end
      it 'should pass nil values if data from MAPI has nil values' do
        expect(profile[:sta_balance]).to be(nil)
        expect(profile[:credit_outstanding]).to be(nil)
        expect(profile[:financial_available]).to be(nil)
        expect(profile[:stock_leverage]).to be(nil)
        expect(profile[:collateral_market_value_sbc_agency]).to be(nil)
        expect(profile[:collateral_market_value_sbc_aaa]).to be(nil)
        expect(profile[:collateral_market_value_sbc_aa]).to be(nil)
        expect(profile[:borrowing_capacity_standard]).to be(nil)
        expect(profile[:borrowing_capacity_sbc_agency]).to be(nil)
        expect(profile[:borrowing_capacity_sbc_aaa]).to be(nil)
        expect(profile[:borrowing_capacity_sbc_aa]).to be(nil)
      end
    end
    describe 'error states' do
      it 'returns nil if there is a JSON parsing error' do
        # TODO change this stub once you implement the MAPI endpoint
        expect(File).to receive(:read).and_return('some malformed json!')
        expect(Rails.logger).to receive(:warn)
        expect(profile).to be(nil)
      end
    end
  end

  describe '`borrowing_capacity_summary` method', :vcr do
    let(:today) {Date.new(2014,12,1)}
    let(:borrowing_capacity_summary) {subject.borrowing_capacity_summary(today)}
    describe 'member has both standard collateral and securities-backed collateral' do
      it 'should return an array of standard collateral objects' do
        expect(borrowing_capacity_summary[:standard][:collateral].length).to be >= 1
        borrowing_capacity_summary[:standard][:collateral].each do |collateral_object|
          expect(collateral_object[:type]).to be_kind_of(String)
          expect(collateral_object[:count]).to be_kind_of(Integer)
          expect(collateral_object[:original_amount]).to be_kind_of(Integer)
          expect(collateral_object[:unpaid_principal]).to be_kind_of(Integer)
          expect(collateral_object[:market_value]).to be_kind_of(Integer)
          expect(collateral_object[:borrowing_capacity]).to be_kind_of(Integer)
          expect(collateral_object[:bc_upb]).to be_kind_of(Integer)
        end
      end
      it 'should return a hash of excluded standard collateral line items' do
        expect(borrowing_capacity_summary[:standard][:excluded][:blanket_lien]).to be_kind_of(Integer)
        expect(borrowing_capacity_summary[:standard][:excluded][:bank]).to be_kind_of(Integer)
        expect(borrowing_capacity_summary[:standard][:excluded][:regulatory]).to be_kind_of(Integer)
      end
      it 'should return a hash of utilized standard collateral line items' do
        expect(borrowing_capacity_summary[:standard][:utilized][:advances]).to be_kind_of(Integer)
        expect(borrowing_capacity_summary[:standard][:utilized][:letters_of_credit]).to be_kind_of(Integer)
        expect(borrowing_capacity_summary[:standard][:utilized][:swap_collateral]).to be_kind_of(Integer)
        expect(borrowing_capacity_summary[:standard][:utilized][:sbc_type_deficiencies]).to be_kind_of(Integer)
        expect(borrowing_capacity_summary[:standard][:utilized][:payment_fees]).to be_kind_of(Integer)
        expect(borrowing_capacity_summary[:standard][:utilized][:other_collateral]).to be_kind_of(Integer)
        expect(borrowing_capacity_summary[:standard][:utilized][:mpf_ce_collateral]).to be_kind_of(Integer)
      end
      it 'should return three securities-backed collateral objects' do
        expect(borrowing_capacity_summary[:sbc][:collateral][:aa].length).to be >= 1
        expect(borrowing_capacity_summary[:sbc][:collateral][:aaa].length).to be >= 1
        expect(borrowing_capacity_summary[:sbc][:collateral][:agency].length).to be >= 1
        borrowing_capacity_summary[:sbc][:collateral].each do |collateral_object, value|
          expect(value[:total_market_value]).to be_kind_of(Integer)
          expect(value[:total_borrowing_capacity]).to be_kind_of(Integer)
          expect(value[:advances]).to be_kind_of(Integer)
          expect(value[:standard_credit]).to be_kind_of(Integer)
          expect(value[:remaining_market_value]).to be_kind_of(Integer)
          expect(value[:remaining_borrowing_capacity]).to be_kind_of(Integer)
        end
      end
      it 'should return a hash of utilized securities-backed line items' do
        expect(borrowing_capacity_summary[:sbc][:utilized][:other_collateral]).to be_kind_of(Integer)
        expect(borrowing_capacity_summary[:sbc][:utilized][:excluded_regulatory]).to be_kind_of(Integer)
      end
      it 'should return values for standard credit field totals' do
        expect(borrowing_capacity_summary[:standard_credit_totals][:count]).to be_kind_of(Integer)
        expect(borrowing_capacity_summary[:standard_credit_totals][:original_amount]).to be_kind_of(Integer)
        expect(borrowing_capacity_summary[:standard_credit_totals][:unpaid_principal]).to be_kind_of(Integer)
        expect(borrowing_capacity_summary[:standard_credit_totals][:market_value]).to be_kind_of(Integer)
        expect(borrowing_capacity_summary[:standard_credit_totals][:borrowing_capacity]).to be_kind_of(Integer)
        expect(borrowing_capacity_summary[:net_loan_collateral]).to be_kind_of(Integer)
        expect(borrowing_capacity_summary[:standard_excess_capacity]).to be_kind_of(Integer)
      end
      it 'should return values for securities-backed field totals' do
        expect(borrowing_capacity_summary[:sbc_totals][:total_market_value]).to be_kind_of(Integer)
        expect(borrowing_capacity_summary[:sbc_totals][:total_borrowing_capacity]).to be_kind_of(Integer)
        expect(borrowing_capacity_summary[:sbc_totals][:advances]).to be_kind_of(Integer)
        expect(borrowing_capacity_summary[:sbc_totals][:standard_credit]).to be_kind_of(Integer)
        expect(borrowing_capacity_summary[:sbc_totals][:remaining_market_value]).to be_kind_of(Integer)
        expect(borrowing_capacity_summary[:sbc_totals][:remaining_borrowing_capacity]).to be_kind_of(Integer)
        expect(borrowing_capacity_summary[:sbc_excess_capacity]).to be_kind_of(Integer)
      end
      it 'should return total borrowing capacity and remaining borrowing capacity across all security types' do
        expect(borrowing_capacity_summary[:total_borrowing_capacity]).to be_kind_of(Integer)
        expect(borrowing_capacity_summary[:remaining_borrowing_capacity]).to be_kind_of(Integer)
      end

      describe 'mathematical operations' do
        describe 'with normal data' do
          let(:response_data) { JSON.parse(File.read(File.join(Rails.root, 'spec', 'fixtures', 'borrowing_capacity_summary', 'borrowing_capacity_summary.json'))) }
          before do
            # TODO stub out MAPI response instead of JSON.parse once the endpoint is rigged up
            expect(JSON).to receive(:parse).and_return(response_data)
          end
          it 'should total all of the standard collateral fields' do
            expect(borrowing_capacity_summary[:standard_credit_totals][:count]).to eq(2699)
            expect(borrowing_capacity_summary[:standard_credit_totals][:original_amount]).to eq(2678188589)
            expect(borrowing_capacity_summary[:standard_credit_totals][:unpaid_principal]).to eq(2455850688)
            expect(borrowing_capacity_summary[:standard_credit_totals][:market_value]).to eq(2479090494)
            expect(borrowing_capacity_summary[:standard_credit_totals][:borrowing_capacity]).to eq(2216748960)
            expect(borrowing_capacity_summary[:net_loan_collateral]).to eq(2216568960)
            expect(borrowing_capacity_summary[:standard_excess_capacity]).to eq(2207180460)
          end
          it 'should total all of the securities-backed collateral fields' do
            expect(borrowing_capacity_summary[:sbc_totals][:total_market_value]).to eq(4193763)
            expect(borrowing_capacity_summary[:sbc_totals][:total_borrowing_capacity]).to eq(601332)
            expect(borrowing_capacity_summary[:sbc_totals][:advances]).to eq(0)
            expect(borrowing_capacity_summary[:sbc_totals][:standard_credit]).to eq(0)
            expect(borrowing_capacity_summary[:sbc_totals][:remaining_market_value]).to eq(105613)
            expect(borrowing_capacity_summary[:sbc_totals][:remaining_borrowing_capacity]).to eq(100332)
            expect(borrowing_capacity_summary[:sbc_excess_capacity]).to eq(76634)
          end
          it 'should calculate total borrowing capacity and remaining borrowing capacity across all security types' do
            expect(borrowing_capacity_summary[:total_borrowing_capacity]).to eq(2216849292)
            expect(borrowing_capacity_summary[:remaining_borrowing_capacity]).to eq(2207257094)
          end
          it 'should calculate `borrowing_capacity`/`unpaid_principal_balance` as a rounded, whole-number percentage' do
            expect(borrowing_capacity_summary[:standard][:collateral][0][:bc_upb]).to eq(95)
            expect(borrowing_capacity_summary[:standard][:collateral][1][:bc_upb]).to eq(93)
            expect(borrowing_capacity_summary[:standard][:collateral][2][:bc_upb]).to eq(79)
          end
        end
        it 'should set bc_upb to zero if borrowing_capacity is negative' do
          expect(JSON).to receive(:parse).and_return(JSON.parse(File.read(File.join(Rails.root, 'spec', 'fixtures', 'borrowing_capacity_summary', 'borrowing_capacity_summary_negative_borrowing_capacity.json'))))
          expect(borrowing_capacity_summary[:standard][:collateral][0][:bc_upb]).to eq(0)
        end
        it 'should set bc_upb to zero if borrowing_capacity is zero' do
          expect(JSON).to receive(:parse).and_return(JSON.parse(File.read(File.join(Rails.root, 'spec', 'fixtures', 'borrowing_capacity_summary', 'borrowing_capacity_summary_zero_borrowing_capacity.json'))))
          expect(borrowing_capacity_summary[:standard][:collateral][0][:bc_upb]).to eq(0)
        end
        it 'should set bc_upb to zero if unpaid_principal_balance is negative' do
          expect(JSON).to receive(:parse).and_return(JSON.parse(File.read(File.join(Rails.root, 'spec', 'fixtures', 'borrowing_capacity_summary', 'borrowing_capacity_summary_negative_unpaid_principal_balance.json'))))
          expect(borrowing_capacity_summary[:standard][:collateral][0][:bc_upb]).to eq(0)
        end
        it 'should set bc_upb to zero if unpaid_principal_balance is zero' do
          expect(JSON).to receive(:parse).and_return(JSON.parse(File.read(File.join(Rails.root, 'spec', 'fixtures', 'borrowing_capacity_summary', 'borrowing_capacity_summary_zero_unpaid_principal_balance.json'))))
          expect(borrowing_capacity_summary[:standard][:collateral][0][:bc_upb]).to eq(0)
        end
      end
    end
    describe 'member has no standard collateral but does have securities-backed collateral' do
      let(:response_data) { JSON.parse(File.read(File.join(Rails.root, 'spec', 'fixtures', 'borrowing_capacity_summary', 'borrowing_capacity_summary_no_standard_collateral.json'))) }
      before do
        # TODO stub out MAPI response instead of JSON.parse once the endpoint is rigged up
        expect(JSON).to receive(:parse).and_return(response_data)
      end
      it 'should return an empty array for standard collateral' do
        expect(borrowing_capacity_summary[:standard][:collateral]).to be_kind_of(Array)
        expect(borrowing_capacity_summary[:standard][:collateral].length).to eq(0)
      end
      it 'should return all zeros for the totals of the standard collateral fields' do
        [:count, :original_amount, :unpaid_principal, :market_value, :borrowing_capacity].each do |key|
          expect(borrowing_capacity_summary[:standard_credit_totals][key]).to eq(0)
        end
        expect(borrowing_capacity_summary[:net_loan_collateral]).to eq(-180000)
        expect(borrowing_capacity_summary[:standard_excess_capacity]).to eq(-9568500)
      end
    end
    describe 'member has neither standard collateral nor securities-backed collateral (e.g. a new member)' do
      let(:response_data) { JSON.parse(File.read(File.join(Rails.root, 'spec', 'fixtures', 'borrowing_capacity_summary', 'borrowing_capacity_summary_no_data.json'))) }
      before do
        # TODO stub out MAPI response instead of JSON.parse once the endpoint is rigged up
        expect(JSON).to receive(:parse).and_return(response_data)
      end
      it 'returns an empty `standard` object and an empty `sbc` object' do
        [:standard, :sbc].each do |key|
          expect(borrowing_capacity_summary[key]).to be_kind_of(Hash)
          expect(borrowing_capacity_summary[key].length).to eq(0)
        end
      end
      it 'returns 0 for total_borrowing_capacity and remaining_borrowing_capacity' do
        [:total_borrowing_capacity, :remaining_borrowing_capacity].each do |key|
          expect(borrowing_capacity_summary[key]).to eq(0)
          expect(borrowing_capacity_summary[key]).to eq(0)
        end
      end
    end
    describe 'error states' do
      it 'returns nil if there is a JSON parsing error' do
        expect(JSON).to receive(:parse).and_raise(JSON::ParserError)
        expect(Rails.logger).to receive(:warn)
        expect(borrowing_capacity_summary).to be(nil)
      end
      it 'returns nil if there is malformed data in the standard object' do
        expect(JSON).to receive(:parse).and_return(JSON.parse(File.read(File.join(Rails.root, 'spec', 'fixtures', 'borrowing_capacity_summary', 'borrowing_capacity_summary_malformed_standard.json'))))
        expect(Rails.logger).to receive(:warn)
        expect(borrowing_capacity_summary).to be(nil)
      end
      it 'returns nil if there is malformed data in the sbc object' do
        expect(JSON).to receive(:parse).and_return(JSON.parse(File.read(File.join(Rails.root, 'spec', 'fixtures', 'borrowing_capacity_summary', 'borrowing_capacity_summary_malformed_sbc.json'))))
        expect(Rails.logger).to receive(:warn)
        expect(borrowing_capacity_summary).to be(nil)
      end
      it 'should return nil if there was an API error' do
        expect_any_instance_of(RestClient::Resource).to receive(:get).and_raise(RestClient::InternalServerError)
        expect(borrowing_capacity_summary).to eq(nil)
      end
      it 'should return nil if there was a connection error' do
        expect_any_instance_of(RestClient::Resource).to receive(:get).and_raise(Errno::ECONNREFUSED)
        expect(borrowing_capacity_summary).to eq(nil)
      end
    end
  end

  describe '`settlement_transaction_account` method', :vcr do
    let(:start_date) {Date.new(2015,1,1)}
    let(:end_date) {Date.new(2015,1,20)}
    let(:filter) { double('filter param') }
    let(:settlement_transaction_account) {subject.settlement_transaction_account(start_date, end_date)}
    it 'should return a hash of STA values' do
      expect(settlement_transaction_account[:start_balance]).to be_kind_of(Float)
      expect(settlement_transaction_account[:end_balance]).to be_kind_of(Float)
      expect(settlement_transaction_account[:start_date]).to be_kind_of(Date)
      expect(settlement_transaction_account[:start_date]).to eq(start_date)
      expect(settlement_transaction_account[:end_date]).to be_kind_of(Date)
      expect(settlement_transaction_account[:end_date]).to eq(end_date)
      expect(settlement_transaction_account[:activities]).to be_kind_of(Array)
    end
    it 'should sort activities from newest date to oldest date' do
      last_date = end_date
      settlement_transaction_account[:activities].each do |activity|
        expect(activity[:trans_date]).to be <= last_date
        last_date = activity[:trans_date]
      end
    end
    it 'should not include any activities that are not in the given range' do
      settlement_transaction_account[:activities].each do |activity|
        expect(activity[:trans_date].between?(start_date, end_date)).to eq(true)
      end
    end
    it 'should return nil if there is a JSON parsing error' do
      expect(JSON).to receive(:parse).and_raise(JSON::ParserError)
      expect(Rails.logger).to receive(:warn)
      expect(settlement_transaction_account).to be(nil)
    end
    it 'should return nil if there was an API error' do
      expect_any_instance_of(RestClient::Resource).to receive(:get).and_raise(RestClient::InternalServerError)
      expect(settlement_transaction_account).to eq(nil)
    end
    it 'should return nil if there was a connection error' do
      expect_any_instance_of(RestClient::Resource).to receive(:get).and_raise(Errno::ECONNREFUSED)
      expect(settlement_transaction_account).to eq(nil)
    end
    it 'should log a warning if two `end of day balance`s are given for a single date' do
      expect(JSON).to receive(:parse).and_return(JSON.parse(File.read(File.join(Rails.root, 'spec', 'fixtures', 'settlement_transaction_account', 'sta_double_balance_entry_for_day.json'))))
      expect(Rails.logger).to receive(:warn)
      settlement_transaction_account
    end
    it 'should include the correct start_balance and end_balance' do
      expect(settlement_transaction_account[:start_balance]).to be_kind_of(Float)
      expect(settlement_transaction_account[:end_balance]).to be_kind_of(Float)
    end
    describe 'filtering by activity type' do
      # set start_date and end_date wide just to catch all activities in your mocked dataset
      let(:start_date) {Date.new(2000,1,1)}
      let(:end_date) {Date.new(2020,1,20)}
      before do
        expect(JSON).to receive(:parse).at_least(:once).and_return(JSON.parse(File.read(File.join(Rails.root, 'spec', 'fixtures', 'settlement_transaction_account', 'settlement_transaction_account.json'))))
      end
      it 'should only show `credit` activities if `credit` is passed in as the filter' do
        subject.settlement_transaction_account(start_date, end_date, 'credit')[:activities].each do |activity|
          expect(activity[:credit]).to be > 0
          expect(activity[:debit]).to be(nil)
          expect(activity[:balance]).to be(nil)
        end
        expect(subject.settlement_transaction_account(start_date, end_date, 'credit')[:activities].length).to eq(6)
      end
      it 'should only show `debit` activities if `debit` is passed in as the filter' do
        subject.settlement_transaction_account(start_date, end_date, 'debit')[:activities].each do |activity|
          expect(activity[:credit]).to be(nil)
          expect(activity[:debit]).to be > 0
          expect(activity[:balance]).to be(nil)
        end
        expect(subject.settlement_transaction_account(start_date, end_date, 'debit')[:activities].length).to eq(10)
      end
      it 'should show all activities if `all` is passed as the filter' do
        expect(subject.settlement_transaction_account(start_date, end_date, 'all')[:activities].length).to eq(23)
      end
      it 'should show all activities if nothing is passed as the filter argument' do
        expect(subject.settlement_transaction_account(start_date, end_date)[:activities].length).to eq(23)
      end
    end
  end

  describe '`advances_details` method', :vcr do
    let(:as_of_date) {Date.new(2015,1,20)}
    let(:advances_details) {subject.advances_details(as_of_date)}
    it 'should return a hash of advances details' do
      expect(advances_details[:as_of_date]).to be_kind_of(Date)
      expect(advances_details[:total_par]).to be_kind_of(Integer)
      expect(advances_details[:total_accrued_interest]).to be_kind_of(Float)
      expect(advances_details[:estimated_next_payment]).to be_kind_of(Float)
      expect(advances_details[:advances_details]).to be_kind_of(Array)
    end
    it 'should return nil if there is a JSON parsing error' do
      expect(JSON).to receive(:parse).and_raise(JSON::ParserError)
      expect(Rails.logger).to receive(:warn)
      expect(advances_details).to be(nil)
    end
    it 'should return nil if there was an API error' do
      expect_any_instance_of(RestClient::Resource).to receive(:get).and_raise(RestClient::InternalServerError)
      expect(advances_details).to eq(nil)
    end
    it 'should return nil if there was a connection error' do
      expect_any_instance_of(RestClient::Resource).to receive(:get).and_raise(Errno::ECONNREFUSED)
      expect(advances_details).to eq(nil)
    end
    describe 'calculating totals' do
      before do
        expect(JSON).to receive(:parse).and_return(JSON.parse(File.read(File.join(Rails.root, 'spec', 'fixtures', 'advances_details.json'))))
      end
      it 'should calculate `total_par` based on the value of the constituent advance records' do
        expect(advances_details[:total_par]).to eq(110000000)
      end
      it 'should calculate `total_accrued_interest` based on the value of the constituent advance records' do
        expect(advances_details[:total_accrued_interest]).to eq(43809.42)
      end
      it 'should calculate `estimated_next_payment` based on the value of the constituent advance records' do
        expect(advances_details[:estimated_next_payment]).to eq(50837.53)
      end
    end
  end

  # Helper Methods
  def override_start_balance_endpoint(start_date, end_date, request_object)
    expect_any_instance_of(RestClient::Resource).to receive(:[]).with("member/#{MEMBER_ID}/capital_stock_balance/#{start_date}").and_return(request_object)
    expect_any_instance_of(RestClient::Resource).to receive(:[]).with("member/#{MEMBER_ID}/capital_stock_balance/#{end_date}").and_call_original
    expect_any_instance_of(RestClient::Resource).to receive(:[]).with("member/#{MEMBER_ID}/capital_stock_activities/#{start_date}/#{end_date}").and_call_original
  end

  def override_end_balance_endpoint(start_date, end_date, request_object)
    expect_any_instance_of(RestClient::Resource).to receive(:[]).with("member/#{MEMBER_ID}/capital_stock_balance/#{start_date}").and_call_original
    expect_any_instance_of(RestClient::Resource).to receive(:[]).with("member/#{MEMBER_ID}/capital_stock_balance/#{end_date}").and_return(request_object)
    expect_any_instance_of(RestClient::Resource).to receive(:[]).with("member/#{MEMBER_ID}/capital_stock_activities/#{start_date}/#{end_date}").and_call_original
  end

  def override_activities_endpoint(start_date, end_date, request_object)
    expect_any_instance_of(RestClient::Resource).to receive(:[]).with("member/#{MEMBER_ID}/capital_stock_balance/#{start_date}").and_call_original
    expect_any_instance_of(RestClient::Resource).to receive(:[]).with("member/#{MEMBER_ID}/capital_stock_balance/#{end_date}").and_call_original
    expect_any_instance_of(RestClient::Resource).to receive(:[]).with("member/#{MEMBER_ID}/capital_stock_activities/#{start_date}/#{end_date}").and_return(request_object)
  end

end