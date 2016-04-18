require 'rails_helper'

describe MemberBalanceService do
  RSpec::Matchers.define :be_boolean do
    match do |actual|
      expect(actual).to satisfy { |x| x.instance_of?(TrueClass) || x.instance_of?(FalseClass) }
    end
  end
  let(:member_id) { 750 }
  subject { MemberBalanceService.new(member_id, double('request', uuid: '12345')) }
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
    let(:activities_no_date) { File.read(File.join(Rails.root, 'spec', 'fixtures', 'capital_stock_activities_no_date.json')) }
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
    it 'should return nil for start_date if the MAPI response does not contain one' do
      expect(JSON).to receive(:parse).and_return({}).ordered
      expect(JSON).to receive(:parse).and_call_original.ordered
      expect(JSON).to receive(:parse).and_call_original.ordered
      expect(capital_stock_activity[:start_date]).to eq(nil)
    end
    it 'should return nil for end_date if the MAPI response does not contain one' do
      expect(JSON).to receive(:parse).and_call_original.ordered
      expect(JSON).to receive(:parse).and_return({}).ordered
      expect(JSON).to receive(:parse).and_call_original.ordered
      expect(capital_stock_activity[:end_date]).to eq(nil)
    end

    describe 'activities hash happy path' do
      before do
        allow(response_object).to receive(:body).and_return(activities)
        allow(request_object).to receive(:get).and_return(response_object)
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
      it 'should calculate a running total of the shares for each activity' do
        last_outstanding = capital_stock_activity[:start_balance]
        expect(capital_stock_activity[:activities].length).to be >= 0 # just so we fail if we have no activities, otherwise we'd test nothing
        capital_stock_activity[:activities].each do |activity|
          expect(activity[:outstanding_shares]).to eq(last_outstanding + activity[:credit_shares] - activity[:debit_shares])
          last_outstanding = activity[:outstanding_shares]
        end
      end
      it 'returns nil for the trans_date of an activity with no trans_date' do
        allow(response_object).to receive(:body).and_return(activities_no_date)
        capital_stock_activity[:activities].each do |activity|
          expect(activity[:trans_date]).to be_nil
        end
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
        expect_capital_stock_balance_to_receive(start_date).and_return(request_object)
        expect(capital_stock_activity).to eq(nil)
      end
      it "should return nil if there was a connection error for the start_date capital_stock_balance endpoint" do
        expect(request_object).to receive(:get).and_raise(Errno::ECONNREFUSED)
        expect_capital_stock_balance_to_receive(start_date).and_return(request_object)
        expect(capital_stock_activity).to eq(nil)
      end
      it "should return nil if there was an API error for the end_date capital_stock_balance endpoint" do
        expect(request_object).to receive(:get).and_raise(RestClient::InternalServerError)
        expect_capital_stock_balance_to_receive(start_date).and_call_original
        expect_capital_stock_balance_to_receive(end_date).and_return(request_object)
        expect(capital_stock_activity).to eq(nil)
      end
      it "should return nil if there was a connection error for the end_date capital_stock_balance endpoint" do
        expect(request_object).to receive(:get).and_raise(Errno::ECONNREFUSED)
        expect_capital_stock_balance_to_receive(start_date).and_call_original
        expect_capital_stock_balance_to_receive(end_date).and_return(request_object)
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
        allow(request_object).to receive(:get).and_return(response_object)
        allow(response_object).to receive(:body).and_return(malformed_json)
      end
      it 'should return nil if there was malformed JSON for start_balance' do
        #override_start_balance_endpoint(start_date, end_date, request_object)

        expect_capital_stock_balance_to_receive(start_date).and_return(request_object)
        expect(capital_stock_activity).to eq(nil)
      end
      it 'should return nil if there was malformed JSON for end_balance' do
        #override_end_balance_endpoint(start_date, end_date, request_object)
        expect_capital_stock_balance_to_receive(start_date).and_call_original
        expect_capital_stock_balance_to_receive(end_date).and_return(request_object)
        expect(capital_stock_activity).to eq(nil)
      end
      it 'should return nil if there was malformed JSON for activities' do
        override_activities_endpoint(start_date, end_date, request_object)
        expect(capital_stock_activity).to eq(nil)
      end
    end

  end

  describe 'profile', :vcr do
    let(:profile) {subject.profile}
    let(:response) { double('Profile Response', body: response_body) }
    let(:response_body) { double('Response Body') }
    it 'should return profile data' do
      decoded_results = double('Decoded Profile Results', :[]= => nil, to_i: 0)
      allow(decoded_results).to receive(:[]).and_return(decoded_results)
      allow(decoded_results).to receive(:with_indifferent_access).and_return(decoded_results)
      allow_any_instance_of(RestClient::Resource).to receive(:get).and_return(response)
      allow(JSON).to receive(:parse).with(response_body).and_return(decoded_results)
      expect(profile).to be(decoded_results)
    end
    describe 'calculated values' do
      let(:json_response) { {
        total_financing_available: rand(10000000..90000000),
        used_financing_availability: rand(1..90000000),
        collateral_borrowing_capacity: {
          total: rand(1000..1000000),
          remaining: rand(1000..1000000)
        }
      } }
      before do
        allow(JSON).to receive(:parse).and_return(json_response)
      end
      it 'should calculate `used_financing_availability`' do
        expect(profile[:used_financing_availability]).to eq(json_response[:collateral_borrowing_capacity][:total] - json_response[:collateral_borrowing_capacity][:remaining])
      end
      it 'should calculate `uncollateralized_financing_availability`' do
        expect(profile[:uncollateralized_financing_availability]).to eq(json_response[:total_financing_available] - json_response[:collateral_borrowing_capacity][:total])
      end
      it 'should set `uncollateralized_financing_availability` to zero if the calculated value would be negative' do
        json_response[:total_financing_available] = rand(1..999)
        expect(profile[:uncollateralized_financing_availability]).to eq(0)
      end
    end
    describe 'error states' do
      it 'returns nil if there is a JSON parsing error' do
        allow(JSON).to receive(:parse).and_raise(JSON::ParserError)
        expect(Rails.logger).to receive(:warn)
        expect(profile).to be(nil)
      end
      it 'should return nil if there was a connection error' do
        allow_any_instance_of(RestClient::Resource).to receive(:get).and_raise(Errno::ECONNREFUSED)
        expect(profile).to eq(nil)
      end
      it 'should return nil if there was a REST error' do
        expect_any_instance_of(RestClient::Resource).to receive(:get).and_raise(RestClient::InternalServerError)
        expect(profile).to eq(nil)
      end
    end
  end

  describe 'settlement_transaction_rate', :vcr do
    let(:settlement_transaction_rate) {subject.settlement_transaction_rate}
    it 'should return settlement transaction rate data' do
      expect(settlement_transaction_rate.length).to be >= 1
      expect(settlement_transaction_rate[:rate]).to be_kind_of(Float)
    end
    describe 'bad data' do
      it 'should pass nil values if data from MAPI has nil values' do
        allow(JSON).to receive(:parse).at_least(:once).and_return(JSON.parse(File.read(File.join(Rails.root, 'spec', 'fixtures', 'settlement_transaction_rate_with_nil_values.json'))))
        expect(settlement_transaction_rate[:rate]).to be(nil)
      end
    end
    describe 'error states' do
      it 'returns nil if there is a JSON parsing error' do
        allow(JSON).to receive(:parse).and_raise(JSON::ParserError)
        expect(Rails.logger).to receive(:warn)
        expect(settlement_transaction_rate).to be(nil)
      end
      it 'should return nil if there was a connection error' do
        allow_any_instance_of(RestClient::Resource).to receive(:get).and_raise(Errno::ECONNREFUSED)
        expect(settlement_transaction_rate).to eq(nil)
      end
      it 'should return nil if there was a REST error' do
        expect_any_instance_of(RestClient::Resource).to receive(:get).and_raise(RestClient::InternalServerError)
        expect(settlement_transaction_rate).to eq(nil)
      end
    end
  end

  describe 'lenient_sum' do
    let (:sample) { [{a: 1, b: 2}, {a:-1, c:3}, {b:-10, c:5}]}

    [[:a,0],[:b,-8],[:c,8],[:d,0]].each do |(sym,sum)|
      it "should return #{sum} for #{sym}" do
        expect(subject.lenient_sum(sample,sym)).to be(sum)
      end
    end
  end

  # TODO add vcr once MAPI endpoint is rigged up
  describe 'securities_transactions'do
    let(:as_of_date) { Date.new(2015, 1, 20) }
    describe 'happy path', :vcr  do
      let(:securities_transactions) { subject.securities_transactions(as_of_date) }
      it 'should return securities transactions data' do
        expect(securities_transactions.length).to be >= 1
        expect(securities_transactions[:final]).to be_boolean
        expect(securities_transactions[:total_payment_or_principal]).to be_kind_of(Numeric)
        expect(securities_transactions[:total_net]).to be_kind_of(Numeric)
        expect(securities_transactions[:total_interest]).to be_kind_of(Numeric)
        expect(securities_transactions[:transactions]).to be_kind_of(Array)
        securities_transactions[:transactions].each do |security|
          expect(security[:custody_account_no]).to be_kind_of(String)
          expect(security[:new_transaction]).to be_boolean
          expect(security[:cusip]).to be_kind_of(String)
          expect(security[:transaction_code]).to be_kind_of(String)
          expect(security[:security_description]).to be_kind_of(String)
          expect(security[:units]).to be_kind_of(Integer)
          expect(security[:maturity_date]).to be_kind_of(String)
          expect(security[:payment_or_principal]).to be_kind_of(Numeric)
          expect(security[:interest]).to be_kind_of(Numeric)
          expect(security[:total]).to be_kind_of(Numeric)
        end
      end
    end

    describe 'bad data' do
      let(:bad_data) do
        {
          final: nil,
          transactions: [{
            custody_account_no: nil,
            new_transaction: nil,
            cusip: nil,
            transaction_code: nil,
            security_description: nil,
            units: nil,
            maturity_date: nil,
            payment_or_principal: nil,
            interest: nil,
            total: nil
          }]
        }.with_indifferent_access
      end
      let(:securities_transactions) { subject.securities_transactions(as_of_date) }
      it 'should pass nil values if data from MAPI has nil values' do
        allow(subject).to receive(:get_hash).and_return(bad_data)
        expect(securities_transactions[:final]).to be(nil)
        expect(securities_transactions[:total_payment_or_principal]).to be(0)
        expect(securities_transactions[:total_net]).to be(0)
        expect(securities_transactions[:total_interest]).to be(0)
        securities_transactions[:transactions].each do |security|
          expect(security[:custody_account_no]).to be(nil)
          expect(security[:new_transaction]).to be(nil)
          expect(security[:cusip]).to be(nil)
          expect(security[:transaction_code]).to be(nil)
          expect(security[:security_description]).to be(nil)
          expect(security[:units]).to be(nil)
          expect(security[:maturity_date]).to be(nil)
          expect(security[:payment_or_principal]).to be(nil)
          expect(security[:interest]).to be(nil)
          expect(security[:total]).to be(nil)
        end
      end
    end

    describe 'error states' do
      it 'returns nil when the endpoint returns nil' do
        allow(subject).to receive(:parse).and_return(nil)
        expect(subject.securities_transactions(as_of_date)).to be(nil)
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
        expect(borrowing_capacity_summary[:net_plus_securities_capacity]).to be_kind_of(Integer)
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
            expect(borrowing_capacity_summary[:net_plus_securities_capacity]).to eq(2216573960)
            expect(borrowing_capacity_summary[:standard_excess_capacity]).to eq(2207185460)
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
            expect(borrowing_capacity_summary[:total_borrowing_capacity]).to eq(2217350292)
            expect(borrowing_capacity_summary[:remaining_borrowing_capacity]).to eq(2207262094)
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
    it 'should return nil if there was an API error that is not a 404' do
      expect_any_instance_of(RestClient::Resource).to receive(:get).and_raise(RestClient::InternalServerError)
      expect(settlement_transaction_account).to eq(nil)
    end
    it 'should return an empty hash if the API returns a 404' do
      expect_any_instance_of(RestClient::Resource).to receive(:get).and_raise(RestClient::Exception.new(nil, 404))
      expect(settlement_transaction_account).to eq({})
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

    describe 'nil checks for dates' do
      before { allow(JSON).to receive(:parse).and_return(JSON.parse(File.read(File.join(Rails.root, 'spec', 'fixtures', 'settlement_transaction_account', 'sta_no_dates.json')))) }
      it 'should return nil for `start_date` if there is no start_date in the response' do
        expect(settlement_transaction_account[:start_date]).to be_nil
      end
      it 'should return nil for `end_date` if there is no end_date in the response' do
        expect(settlement_transaction_account[:end_date]).to be_nil
      end
      it 'should return nil for an activity\'s trans_date if there is no trans_date in the response' do
        settlement_transaction_account[:activities].each do |activity|
          expect(activity[:trans_date]).to be_nil
        end
      end
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
    it 'should return nil for as_of_date if there is no as_of_date in the response' do
      allow(JSON).to receive(:parse).and_return(JSON.parse(File.read(File.join(Rails.root, 'spec', 'fixtures', 'advances_details_no_as_of_date.json'))))
      expect(advances_details[:as_of_date]).to be_nil
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

  describe '`cash_projections` method', :vcr do
    let(:cash_projections) {subject.cash_projections}
    it 'should return nil if there is a JSON parsing error' do
      expect(JSON).to receive(:parse).and_raise(JSON::ParserError)
      expect(Rails.logger).to receive(:warn)
      expect(cash_projections).to be(nil)
    end
    it 'should return nil if there was an API error' do
      expect_any_instance_of(RestClient::Resource).to receive(:get).and_raise(RestClient::InternalServerError)
      expect(cash_projections).to eq(nil)
    end
    it 'should return nil if there was a connection error' do
      expect_any_instance_of(RestClient::Resource).to receive(:get).and_raise(Errno::ECONNREFUSED)
      expect(cash_projections).to eq(nil)
    end
    it 'returns an object with an as_of_date indicating when FHLB most recently produced cash projections' do
      expect(cash_projections[:as_of_date]).to be_kind_of(Date)
    end
    it 'returns an object with a projections array' do
      expect(cash_projections[:projections]).to be_kind_of(Array)
    end
    it 'returns a total_net_amount that is the sum of the total_amount for each projection' do
      total = cash_projections[:projections].inject(0) { |sum, projection| sum += projection[:total] }
      expect(cash_projections[:total_net_amount]).to eq(total)
    end
    it 'returns a total_interest that is the sum of the interest for each projection' do
      interest = cash_projections[:projections].inject(0) { |sum, projection| sum += projection[:interest] }
      expect(cash_projections[:total_interest]).to eq(interest)
    end
    it 'returns a total_principal that is the sum of the interest for each projection' do
      principal = cash_projections[:projections].inject(0) { |sum, projection| sum += projection[:principal] }
      expect(cash_projections[:total_principal]).to eq(principal)
    end
    describe 'nil check for dates' do
      before { allow(JSON).to receive(:parse).and_return(JSON.parse(File.read(File.join(Rails.root, 'spec', 'fixtures', 'cash_projections_no_dates.json')))) }
      it 'returns nil for as_of_date if there is no as_of_date in the response' do
        expect(cash_projections[:as_of_date]).to be_nil
      end
      %w(settlement_date maturity_date).each do |attr|
        it "returns nil for the #{attr} of a projection if there is no #{attr} in the response" do
          cash_projections[:projections].each do |projection|
            expect(projection[attr.to_sym]).to be_nil
          end
        end
      end
    end
    describe 'projection objects' do
      %w(settlement_date maturity_date).each do |property|
        it "has a #{property}" do
          cash_projections[:projections].each do |projection|
            expect(projection[property]).to be_kind_of(Date)
          end
        end
      end
      %w(original_par coupon_rate principal interest total).each do |property|
        it "has a #{property}" do
          cash_projections[:projections].each do |projection|
            expect(projection[property]).to be_kind_of(Numeric)
          end
        end
      end
      %w(custody_account transaction_code cusip description pool_number).each do |property|
        it "has a #{property}" do
          cash_projections[:projections].each do |projection|
            expect(projection[property]).to be_kind_of(String)
          end
        end
      end
    end
  end

  describe '`dividend_statement` method', :vcr do
    let(:start_date) { Date.new(2015,1,1) }
    let(:dividend_statement) { subject.dividend_statement(start_date, '2015Q1') }
    it_should_behave_like 'a MAPI backed service object method', :dividend_statement, [Date.new(2015,1,1), '2015Q1']
    it 'passes `current` as an argument if no div_id is given' do
      expect(subject).to receive(:get_hash).with(:dividend_statement, "/member/#{member_id}/dividend_statement/#{start_date.to_date.iso8601}/current")
      subject.dividend_statement(start_date, nil)
    end
    it 'returns a date for its `transaction_date`' do
      expect(dividend_statement[:transaction_date]).to be_kind_of(Date)
    end
    it 'returns a float for its `annualized_rate`' do
      expect(dividend_statement[:annualized_rate]).to be_kind_of(Float)
    end
    it 'returns a float for its `rate`' do
      expect(dividend_statement[:rate]).to be_kind_of(Float)
    end
    it 'returns a numeric for its `average_shares_outstanding`' do
      expect(dividend_statement[:average_shares_outstanding]).to be_kind_of(Numeric)
    end
    it 'returns a fixnum for its `shares_dividend`' do
      expect(dividend_statement[:shares_dividend]).to be_kind_of(Fixnum)
    end
    it 'returns a float for its `shares_par_value`' do
      expect(dividend_statement[:shares_par_value]).to be_kind_of(Float)
    end
    it 'returns a float for its `cash_dividend`' do
      expect(dividend_statement[:cash_dividend]).to be_kind_of(Float)
    end
    it 'returns a float for its `total_dividend`' do
      expect(dividend_statement[:total_dividend]).to be_kind_of(Float)
    end
    it 'returns a string for its `sta_account_number`' do
      expect(dividend_statement[:sta_account_number]).to be_kind_of(String)
    end
    it 'returns an array of dividend details for its `details`' do
      expect(dividend_statement[:details]).to be_kind_of(Array)
      expect(dividend_statement[:details].length).to be >= 0
      dividend_statement[:details].each do |detail|
        expect(detail[:issue_date]).to be_kind_of(Date)
        expect(detail[:start_date]).to be_kind_of(Date)
        expect(detail[:end_date]).to be_kind_of(Date)
        expect(detail[:certificate_sequence]).to be_kind_of(String)
        expect(detail[:shares_outstanding]).to be_kind_of(Fixnum)
        expect(detail[:average_shares_outstanding]).to be_kind_of(Float)
        expect(detail[:dividend]).to be_kind_of(Float)
        expect(detail[:days_outstanding]).to be_kind_of(Fixnum)
        expect(detail[:start_date]).to be <= detail[:end_date]
      end
    end
    describe 'nil check for dates' do
      before { allow(JSON).to receive(:parse).and_return(JSON.parse(File.read(File.join(Rails.root, 'spec', 'fixtures', 'dividend_statement_no_dates.json')))) }
      it 'returns nil for transaction_date if there is no transaction_date in the response' do
        expect(dividend_statement[:transaction_date]).to be_nil
      end
      %w(issue_date start_date end_date).each do |attr|
        it "returns nil for the #{attr} of a dividend detail if there is no #{attr} in the response" do
          dividend_statement[:details].each do |detail|
            expect(detail[attr.to_sym]).to be_nil
          end
        end
      end
    end
    describe 'error states' do
      it 'should return nil if there is a JSON parsing error' do
        allow(JSON).to receive(:parse).and_raise(JSON::ParserError)
        expect(Rails.logger).to receive(:warn)
        expect(dividend_statement).to be(nil)
      end
      it 'should return nil if there was an API error' do
        expect_any_instance_of(RestClient::Resource).to receive(:get).and_raise(RestClient::InternalServerError)
        expect(dividend_statement).to eq(nil)
      end
      it 'should return nil if there was a connection error' do
        expect_any_instance_of(RestClient::Resource).to receive(:get).and_raise(Errno::ECONNREFUSED)
        expect(dividend_statement).to eq(nil)
      end
    end
  end

  describe '`securities_services_statements_available` method' do
    let(:statement){ double('statement') }
    let(:statement2){ double('statement2') }
    it 'should return nil when get_json returns nil' do
      allow(subject).to receive(:get_json).and_return(nil)
      expect(subject.securities_services_statements_available).to eq(nil)
    end
    it 'should return apply fix_date to list items returned by get_json' do
      allow(subject).to receive(:get_json).and_return([statement])
      allow(subject).to receive(:fix_date).with(statement, 'report_end_date').and_return(statement2)
      expect(subject.securities_services_statements_available).to eq([statement2])
    end
  end

  describe '`securities_services_statement` method' do
    let(:date){ double('date') }
    let(:isodate){ double('isodate') }
    let(:statement){ double('statement') }
    let(:statement_with_debit_date){ double('statement_with_debit_date') }
    let(:statement_with_month_ending){ double('statement_with_month_ending') }
    before do
      allow(date).to receive_message_chain(:to_date,:iso8601).and_return(isodate)
    end
    it 'should return nil if get_hash returns nil' do
      allow(subject).to receive(:get_hash).and_return(nil)
      expect(subject.securities_services_statement(date)).to eq(nil)
    end
    it 'should fix_date on' do
      allow(subject).to receive(:get_hash).and_return(statement)
      allow(subject).to receive(:fix_date).with(statement,'debit_date').and_return(statement_with_debit_date)
      allow(subject).to receive(:fix_date).with(statement_with_debit_date,'month_ending').and_return(statement_with_month_ending)
      expect(subject.securities_services_statement(date)).to eq(statement_with_month_ending)
    end
  end

  describe '`letters_of_credit` method', :vcr do
    let(:letters_of_credit) { subject.letters_of_credit}
    let(:data) { JSON.parse(File.read(File.join(Rails.root, 'spec', 'fixtures', 'letters_of_credit.json'))).with_indifferent_access }

    it 'returns a date for its `as_of_date`' do
      expect(letters_of_credit[:as_of_date]).to be_kind_of(Date)
    end
    it 'returns a `total_current_par` that is the sum of all the current_par values' do
      allow(JSON).to receive(:parse).and_return(data)
      total_current_par = data[:credits].inject(0) {|sum, hash| sum + hash[:current_par]}
      expect(letters_of_credit[:total_current_par]).to eq(total_current_par)
    end
    describe '`credits` attribute' do
      [:settlement_date, :maturity_date, :trade_date].each do |attr|
        it "returns a date for its '#{attr}'" do
          letters_of_credit[:credits].each do |credit|
            expect(credit[attr]).to be_kind_of(Date)
          end
        end
      end
      [:current_par, :maintenance_charge].each do |attr|
        it "returns an integer for its '#{attr}'" do
          letters_of_credit[:credits].each do |credit|
            expect(credit[attr]).to be_kind_of(Integer)
          end
        end
      end
      [:lc_number, :description].each do |attr|
        it "returns a string for its '#{attr}'" do
          letters_of_credit[:credits].each do |credit|
            expect(credit[attr]).to be_kind_of(String)
          end
        end
      end
    end

    describe 'error states' do
      it 'should return nil if there is a JSON parsing error' do
        allow(JSON).to receive(:parse).and_raise(JSON::ParserError)
        expect(Rails.logger).to receive(:warn)
        expect(letters_of_credit).to be(nil)
      end
      it 'should return nil if there was an API error' do
        expect_any_instance_of(RestClient::Resource).to receive(:get).and_raise(RestClient::InternalServerError)
        expect(letters_of_credit).to eq(nil)
      end
      it 'should return nil if there was a connection error' do
        expect_any_instance_of(RestClient::Resource).to receive(:get).and_raise(Errno::ECONNREFUSED)
        expect(letters_of_credit).to eq(nil)
      end
    end
  end

  describe '`active_advances` method', :vcr do
    let(:active_advances) {subject.active_advances}
    it 'should return nil if there is a JSON parsing error' do
      allow(JSON).to receive(:parse).and_raise(JSON::ParserError)
      expect(Rails.logger).to receive(:warn)
      expect(active_advances).to be(nil)
    end
    it 'should return nil if there was an API error' do
      expect_any_instance_of(RestClient::Resource).to receive(:get).and_raise(RestClient::InternalServerError)
      expect(active_advances).to eq(nil)
    end
    it 'should return nil if there was a connection error' do
      expect_any_instance_of(RestClient::Resource).to receive(:get).and_raise(Errno::ECONNREFUSED)
      expect(active_advances).to eq(nil)
    end
    it 'should return an array of hashes containing active advances' do
      expect(active_advances).to be_kind_of(Array)
      expect(active_advances.length).to be >= 0
      active_advances.each do |rate|
        expect(rate['trade_date']).to be_kind_of(String)
        expect(rate['funding_date']).to be_kind_of(String)
        expect(rate['maturity_date']).to be_kind_of(String)
        expect(rate['advance_number']).to be_kind_of(String)
        expect(rate['advance_type']).to be_kind_of(String)
        expect(rate['status']).to be_kind_of(String)
        expect(rate['interest_rate']).to be_kind_of(Float)
        expect(rate['current_par']).to be_kind_of(Integer)
      end
    end
  end

  describe 'the `parallel_shift` method', :vcr do
    let(:parallel_shift) {subject.parallel_shift}
    let(:response_no_dates) { JSON.parse(File.read(File.join(Rails.root, 'spec', 'fixtures', 'parallel_shift_no_dates.json'))).with_indifferent_access }
    it 'returns a hash with an `as_of_date` that is a date' do
      expect(parallel_shift[:as_of_date]).to be_kind_of(Date)
    end
    it 'returns a hash with nil for an `as_of_date` if there is no as_of_date in the response' do
      allow(JSON).to receive(:parse).and_return(response_no_dates)
      expect(parallel_shift[:as_of_date]).to be_nil
    end
    it 'returns a hash with a `putable_advances` array' do
      expect(parallel_shift[:putable_advances]).to be_kind_of(Array)
    end
    describe 'the `putable_advances` array' do
      it 'contains objects representing putable advance data' do
        parallel_shift[:putable_advances].each do |advance|
          expect(advance[:advance_number]).to be_kind_of(String)
          expect(advance[:issue_date]).to be_kind_of(Date)
          expect(advance[:interest_rate]).to be_kind_of(Float)
          advance[:shift_neg_300].blank? ? (expect(advance[:shift_neg_300]).to be_nil) : (expect(advance[:shift_neg_300]).to be_kind_of(Float))
          advance[:shift_neg_200].blank? ? (expect(advance[:shift_neg_200]).to be_nil) : (expect(advance[:shift_neg_200]).to be_kind_of(Float))
          advance[:shift_neg_100].blank? ? (expect(advance[:shift_neg_100]).to be_nil) : (expect(advance[:shift_neg_100]).to be_kind_of(Float))
          advance[:shift_0].blank? ? (expect(advance[:shift_0]).to be_nil) : (expect(advance[:shift_0]).to be_kind_of(Float))
          advance[:shift_100].blank? ? (expect(advance[:shift_100]).to be_nil) : (expect(advance[:shift_100]).to be_kind_of(Float))
          advance[:shift_200].blank? ? (expect(advance[:shift_200]).to be_nil) : (expect(advance[:shift_200]).to be_kind_of(Float))
          advance[:shift_300].blank? ? (expect(advance[:shift_300]).to be_nil) : (expect(advance[:shift_300]).to be_kind_of(Float))
        end
      end
    end
    describe 'error states' do
      it 'should return nil if there is a JSON parsing error' do
        allow(JSON).to receive(:parse).and_raise(JSON::ParserError)
        expect(Rails.logger).to receive(:warn)
        expect(parallel_shift).to be(nil)
      end
      it 'should return nil if there was an API error' do
        expect_any_instance_of(RestClient::Resource).to receive(:get).and_raise(RestClient::InternalServerError)
        expect(parallel_shift).to eq(nil)
      end
      it 'should return nil if there was a connection error' do
        expect_any_instance_of(RestClient::Resource).to receive(:get).and_raise(Errno::ECONNREFUSED)
        expect(parallel_shift).to eq(nil)
      end
    end
    it 'fixes the date for the response' do
      expect(subject).to receive(:fix_date)
      parallel_shift
    end
    it 'fixes the :issue_date for each advance' do
      allow(subject).to receive(:fix_date).and_return(response_no_dates)
      expect(subject).to receive(:fix_date).with(anything, :issue_date).at_least(:once)
      parallel_shift
    end
  end

  describe 'the `current_securities_position` method', :vcr do
    let(:current_securities_position) {subject.current_securities_position('all')}
    it 'returns a hash with an `as_of_date` that is a date' do
      expect(current_securities_position[:as_of_date]).to be_kind_of(Date)
    end
    %w(total_original_par total_current_par total_market_value).each do |key|
      it "returns a hash with a `#{key}` that is a float" do
        expect(current_securities_position[key.to_sym]).to be_kind_of(Float)
      end
    end
    it 'returns a hash with a `securities` array' do
      expect(current_securities_position[:securities]).to be_kind_of(Array)
    end
    describe 'the `securities` array' do
      it 'contains objects representing securities data' do
        current_securities_position[:securities].each do |security|
          expect(security[:custody_account_number]).to be_kind_of(String)
          expect(security[:custody_account_type]).to be_kind_of(String)
          expect(security[:security_pledge_type]).to be_kind_of(String)
          expect(security[:cusip]).to be_kind_of(String)
          expect(security[:description]).to be_kind_of(String)
          expect(security[:reg_id]).to be_kind_of(String)
          expect(security[:pool_number]).to be_kind_of(String)
          expect(security[:coupon_rate]).to be_kind_of(Float)
          expect(security[:maturity_date]).to be_kind_of(String)
          expect(security[:original_par]).to be_kind_of(Float)
          expect(security[:factor]).to be_kind_of(Float)
          expect(security[:factor_date]).to be_kind_of(String)
          expect(security[:current_par]).to be_kind_of(Float)
          expect(security[:price]).to be_kind_of(Float)
          expect(security[:price_date]).to be_kind_of(String)
          expect(security[:market_value]).to be_kind_of(Float)
        end
      end
    end
    describe 'error states' do
      it 'should return nil if there is a JSON parsing error' do
        allow(JSON).to receive(:parse).and_raise(JSON::ParserError)
        expect(current_securities_position).to be(nil)
      end
      it 'should log an error if there is a JSON parsing error' do
        allow(JSON).to receive(:parse).and_raise(JSON::ParserError)
        expect(Rails.logger).to receive(:warn)
        current_securities_position
      end
      it 'should return nil if there was an API error' do
        allow_any_instance_of(RestClient::Resource).to receive(:get).and_raise(RestClient::InternalServerError)
        expect(current_securities_position).to eq(nil)
      end
      it 'should return nil if there was a connection error' do
        allow_any_instance_of(RestClient::Resource).to receive(:get).and_raise(Errno::ECONNREFUSED)
        expect(current_securities_position).to eq(nil)
      end
    end
  end

  describe 'the `monthly_securities_position` method', :vcr do
    let(:monthly_securities_position) {subject.monthly_securities_position('2015-01-31','all')}
    it 'returns a hash with an `as_of_date` that is a date' do
      expect(monthly_securities_position[:as_of_date]).to be_kind_of(Date)
    end
    %w(total_original_par total_current_par total_market_value).each do |key|
      it "returns a hash with a `#{key}` that is a float" do
        expect(monthly_securities_position[key.to_sym]).to be_kind_of(Float)
      end
    end
    it 'returns a hash with a `securities` array' do
      expect(monthly_securities_position[:securities]).to be_kind_of(Array)
    end
    describe 'the `securities` array' do
      it 'contains objects representing securities data' do
        monthly_securities_position[:securities].each do |security|
          expect(security[:custody_account_number]).to be_kind_of(String)
          expect(security[:custody_account_type]).to be_kind_of(String)
          expect(security[:security_pledge_type]).to be_kind_of(String)
          expect(security[:cusip]).to be_kind_of(String)
          expect(security[:description]).to be_kind_of(String)
          expect(security[:reg_id]).to be_kind_of(String)
          expect(security[:pool_number]).to be_kind_of(String)
          expect(security[:coupon_rate]).to be_kind_of(Float)
          expect(security[:maturity_date]).to be_kind_of(String)
          expect(security[:original_par]).to be_kind_of(Float)
          expect(security[:factor]).to be_kind_of(Float)
          expect(security[:factor_date]).to be_kind_of(String)
          expect(security[:current_par]).to be_kind_of(Float)
          expect(security[:price]).to be_kind_of(Float)
          expect(security[:price_date]).to be_kind_of(String)
          expect(security[:market_value]).to be_kind_of(Float)
        end
      end
    end
    describe 'error states' do
      it 'should return nil if there is a JSON parsing error' do
        allow(JSON).to receive(:parse).and_raise(JSON::ParserError)
        expect(monthly_securities_position).to be(nil)
      end
      it 'should log an error if there is a JSON parsing error' do
        allow(JSON).to receive(:parse).and_raise(JSON::ParserError)
        expect(Rails.logger).to receive(:warn)
        monthly_securities_position
      end
      it 'should return nil if there was an API error' do
        allow_any_instance_of(RestClient::Resource).to receive(:get).and_raise(RestClient::InternalServerError)
        expect(monthly_securities_position).to eq(nil)
      end
      it 'should return nil if there was a connection error' do
        allow_any_instance_of(RestClient::Resource).to receive(:get).and_raise(Errno::ECONNREFUSED)
        expect(monthly_securities_position).to eq(nil)
      end
    end
  end

  describe 'the `forward_commitments` method', :vcr do
    let(:forward_commitments) {subject.forward_commitments}
    it 'returns a hash with an `as_of_date` that is a date' do
      expect(forward_commitments[:as_of_date]).to be_kind_of(Date)
    end
    it "returns a hash with a `total_current_par` that is an integer" do
      expect(forward_commitments[:total_current_par]).to be_kind_of(Integer)
    end
    it 'returns a hash with an `advances` array' do
      expect(forward_commitments[:advances]).to be_kind_of(Array)
    end
    describe 'the `advances` array' do
      it 'contains objects representing securities data' do
        forward_commitments[:advances].each do |security|
          expect(security[:trade_date]).to be_kind_of(Date)
          expect(security[:funding_date]).to be_kind_of(Date)
          expect(security[:maturity_date]).to be_kind_of(Date)
          expect(security[:advance_number]).to be_kind_of(String)
          expect(security[:advance_type]).to be_kind_of(String)
          expect(security[:current_par]).to be_kind_of(Integer)
          expect(security[:interest_rate]).to be_kind_of(Float)
        end
      end
    end
    describe 'nil checks for dates' do
      before { allow(JSON).to receive(:parse).and_return(JSON.parse(File.read(File.join(Rails.root, 'spec', 'fixtures', 'forward_commitments_no_dates.json')))) }
      it 'should return nil for `as_of_date` if there is no as_of_date in the response' do
        expect(forward_commitments[:as_of_date]).to be_nil
      end
      %w(trade_date funding_date maturity_date).each do |attr|
        it "should return nil for an advance\'s #{attr} if there is no #{attr} in the response" do
          forward_commitments[:advances].each do |advance|
            expect(advance[attr.to_sym]).to be_nil
          end
        end
      end
    end
    describe 'error states' do
      it 'should return nil if there is a JSON parsing error' do
        allow(JSON).to receive(:parse).and_raise(JSON::ParserError)
        expect(forward_commitments).to be(nil)
      end
      it 'should log an error if there is a JSON parsing error' do
        allow(JSON).to receive(:parse).and_raise(JSON::ParserError)
        expect(Rails.logger).to receive(:warn)
        forward_commitments
      end
      it 'should return nil if there was an API error' do
        allow_any_instance_of(RestClient::Resource).to receive(:get).and_raise(RestClient::InternalServerError)
        expect(forward_commitments).to eq(nil)
      end
      it 'should return nil if there was a connection error' do
        allow_any_instance_of(RestClient::Resource).to receive(:get).and_raise(Errno::ECONNREFUSED)
        expect(forward_commitments).to eq(nil)
      end
    end
  end

  describe 'the `capital_stock_and_leverage` method', :vcr do
    let(:capital_stock_and_leverage) {subject.capital_stock_and_leverage}
    %i(stock_owned minimum_requirement excess_stock surplus_stock activity_based_requirement remaining_stock remaining_leverage).each do |key|
      it "returns a hash with an integer value for the #{key} key" do
        expect(capital_stock_and_leverage[key]).to be_kind_of(Integer)
      end
    end
    describe 'error states' do
      it 'should return nil if there is a JSON parsing error' do
        allow(JSON).to receive(:parse).and_raise(JSON::ParserError)
        expect(capital_stock_and_leverage).to be(nil)
      end
      it 'should log an error if there is a JSON parsing error' do
        allow(JSON).to receive(:parse).and_raise(JSON::ParserError)
        expect(Rails.logger).to receive(:warn)
        capital_stock_and_leverage
      end
      it 'should return nil if there was an API error' do
        allow_any_instance_of(RestClient::Resource).to receive(:get).and_raise(RestClient::InternalServerError)
        expect(capital_stock_and_leverage).to eq(nil)
      end
      it 'should return nil if there was a connection error' do
        allow_any_instance_of(RestClient::Resource).to receive(:get).and_raise(Errno::ECONNREFUSED)
        expect(capital_stock_and_leverage).to eq(nil)
      end
    end
  end

  describe 'the `capital_stock_trial_balance` method' do
    it_behaves_like 'a MAPI backed service object method', :capital_stock_trial_balance, Date.today
    let(:date){ double('date') }
    let(:isodate){ double('isodate') }
    let(:statement){ double('statement') }
    let(:certificate) { double('certificate') }
    let(:call_method) { subject.capital_stock_trial_balance(date) }
    before do
      allow(date).to receive(:iso8601).and_return(isodate)
      allow(statement).to receive(:[]).with(:certificates).and_return([])
    end
    it 'returns nil if get_hash returns nil' do
      allow(subject).to receive(:get_hash).and_return(nil)
      expect(call_method).to eq(nil)
    end
    context 'with a response' do
      before do
        allow(subject).to receive(:get_hash).and_return(statement)
      end

      it 'returns the result of `get_hash`' do
        expect(call_method).to eq(statement)
      end
      it 'fixes the :issue_date for each certificate' do
        allow(statement).to receive(:[]).with(:certificates).and_return([certificate])
        expect(subject).to receive(:fix_date).with(certificate, :issue_date)
        call_method
      end
      it 'handles the no results response' do
        allow(statement).to receive(:[]).and_return(nil)
        expect(call_method).to eq(statement)
      end
    end
  end

  describe 'the `interest_rate_resets` method', :vcr do
    let(:irr_rates) {subject.interest_rate_resets}
    let(:advances) { JSON.parse(File.read(File.join(Rails.root, 'spec', 'fixtures', 'interest_rate_resets.json'))).with_indifferent_access }
    describe 'error states' do
      it 'should return nil if there is a JSON parsing error' do
        allow(JSON).to receive(:parse).and_raise(JSON::ParserError)
        expect(irr_rates).to be(nil)
      end
      it 'should log an error if there is a JSON parsing error' do
        allow(JSON).to receive(:parse).and_raise(JSON::ParserError)
        expect(Rails.logger).to receive(:warn)
        irr_rates
      end
      it 'should return nil if there was an API error' do
        allow_any_instance_of(RestClient::Resource).to receive(:get).and_raise(RestClient::InternalServerError)
        expect(irr_rates).to eq(nil)
      end
      it 'should return nil if there was a connection error' do
        allow_any_instance_of(RestClient::Resource).to receive(:get).and_raise(Errno::ECONNREFUSED)
        expect(irr_rates).to eq(nil)
      end
    end
    it 'should return an array of hashes containing interest rate resets' do
      expect(irr_rates.length).to be >= 1
      irr_rates[:interest_rate_resets].each do |rate|
        expect(rate[:effective_date]).to be_kind_of(Date)
        expect(rate[:advance_number]).to be_kind_of(String)
        expect(rate[:prior_rate]).to be_kind_of(Float)
        expect(rate[:new_rate]).to be_kind_of(Float)
        expect(rate[:next_reset]).to be_kind_of(Date)
      end
    end
    it 'fixes the :date_processed for the response' do
      expect(subject).to receive(:fix_date).with(anything, :date_processed).exactly(:once)
      irr_rates
    end
    it 'fixes the :effective_date and :next_reset for each advance' do
      allow(subject).to receive(:fix_date).with(anything, :date_processed).and_return(advances)
      expect(subject).to receive(:fix_date).with(anything, [:effective_date, :next_reset]).at_least(:once)
      irr_rates
    end
  end

  describe 'the `todays_credit_activity` method' do
    it_behaves_like 'a MAPI backed service object method', :todays_credit_activity
    let(:todays_credit_activity) { subject.todays_credit_activity }
    let(:non_exercised_activity) { {instrument_type: double('instrument_type')} }
    let(:terminated_activity_without_status) { {instrument_type: double('some instrument'), termination_par: double('termination_par'), termination_full_partial: double('termination_full_partial')} }
    let(:terminated_lc) { {instrument_type: 'LC', termination_par: double('termination_par'), termination_full_partial: double('termination_full_partial')} }

    it 'should call `get_json` with the appropriate endpoint' do
      expect(subject).to receive(:get_json).with(:todays_credit_activity, "/member/#{member_id}/todays_credit_activity")
      todays_credit_activity
    end
    it 'fixes the :funding_date and :maturity_date for each activity' do
      allow(subject).to receive(:get_json).and_return([non_exercised_activity, terminated_activity_without_status, terminated_lc])
      expect(subject).to receive(:fix_date).with(anything, [:funding_date, :maturity_date, :termination_date]).exactly(3)
      todays_credit_activity
    end
  end

  describe 'the `mortgage_collateral_update` method' do
    let(:mortgage_collateral_update) { subject.mortgage_collateral_update }
    let(:response) { double('response') }
    it_should_behave_like 'a MAPI backed service object method', :mortgage_collateral_update
    it 'should call `get_hash` with the appropriate endpoint' do
      expect(subject).to receive(:get_hash).with(:mortgage_collateral_update, "/member/#{member_id}/mortgage_collateral_update")
      mortgage_collateral_update
    end
    it 'should call `fix_date` with the appropriate date field called out' do
      expect(subject).to receive(:fix_date).with(anything, :date_processed)
      mortgage_collateral_update
    end
    it 'should return the result of the `fix_date` call' do
      allow(subject).to receive(:fix_date).with(anything, :date_processed).and_return(response)
      expect(mortgage_collateral_update).to eq(response)
    end
  end

  describe 'the `managed_securities` method' do
    let(:managed_securities) { subject.managed_securities }
    let(:securities) { double('an array of securities') }
    before { allow(subject).to receive(:get_hash).and_return({}) }
    it_should_behave_like 'a MAPI backed service object method', :managed_securities
    it 'should call `get_hash` with the appropriate endpoint' do
      expect(subject).to receive(:get_hash).with(:managed_securities, "/member/#{member_id}/managed_securities").and_return({})
      managed_securities
    end
    it 'hands back only the array of securities objects' do
      allow(subject).to receive(:get_hash).and_return({securities: securities})
      expect(managed_securities).to eq(securities)
    end
  end

  # Helper Methods
  def expect_capital_stock_balance_to_receive(date)
    expect_any_instance_of(RestClient::Resource).to receive(:[]).with( "member/#{member_id}/capital_stock_balance/#{date}" )
  end

  def expect_capital_stock_activities_to_receive(start, finish)
    expect_any_instance_of(RestClient::Resource).to receive(:[]).with( "member/#{member_id}/capital_stock_activities/#{start}/#{finish}" )
  end

  def override_activities_endpoint(start_date, end_date, request_object)
    expect_capital_stock_balance_to_receive(start_date).and_call_original
    expect_capital_stock_balance_to_receive(end_date).and_call_original
    expect_capital_stock_activities_to_receive(start_date, end_date).and_return(request_object)
  end

end