require 'spec_helper'

describe MemberBalanceService do
  MEMBER_ID = 750
  subject { MemberBalanceService.new(MEMBER_ID) }
  it { expect(subject).to respond_to(:pledged_collateral) }
  it { expect(subject).to respond_to(:total_securities) }
  it { expect(subject).to respond_to(:effective_borrowing_capacity) }
  it { expect(subject).to respond_to(:capital_stock_activity) }
  describe "`pledged_collateral` method", :vcr do
    let(:pledged_collateral) {subject.pledged_collateral}
    it "should return a hash of hashes containing pledged collateral values" do
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
    it "should return nil if there was an API error" do
      expect_any_instance_of(RestClient::Resource).to receive(:get).and_raise(RestClient::InternalServerError)
      expect(pledged_collateral).to eq(nil)
    end
    it "should return nil if there was a connection error" do
      expect_any_instance_of(RestClient::Resource).to receive(:get).and_raise(Errno::ECONNREFUSED)
      expect(pledged_collateral).to eq(nil)
    end
  end
  describe "`total_securities` method", :vcr do
    let(:total_securities) {subject.total_securities}
    it "should return a hash of hashes containing total security values" do
      expect(total_securities.length).to be >= 1
      expect(total_securities[:pledged_securities][:absolute]).to be_kind_of(Integer)
      expect(total_securities[:pledged_securities][:percentage]).to be_kind_of(Float)
      expect(total_securities[:safekept_securities][:absolute]).to be_kind_of(Integer)
      expect(total_securities[:safekept_securities][:percentage]).to be_kind_of(Float)
    end
    it "should return nil if there was an API error" do
      expect_any_instance_of(RestClient::Resource).to receive(:get).and_raise(RestClient::InternalServerError)
      expect(total_securities).to eq(nil)
    end
    it "should return nil if there was a connection error" do
      expect_any_instance_of(RestClient::Resource).to receive(:get).and_raise(Errno::ECONNREFUSED)
      expect(total_securities).to eq(nil)
    end
  end
  describe "`effective_borrowing_capacity` method", :vcr do
    let(:effective_borrowing_capacity) {subject.effective_borrowing_capacity}
    it "should return a hash of hashes containing effective borrowing capacity values" do
      expect(effective_borrowing_capacity.length).to be >= 1
      expect(effective_borrowing_capacity[:used_capacity]).to be_kind_of(Hash)
      expect(effective_borrowing_capacity[:used_capacity][:absolute]).to be_kind_of(Integer)
      expect(effective_borrowing_capacity[:used_capacity][:percentage]).to be_kind_of(Float)
      expect(effective_borrowing_capacity[:unused_capacity]).to be_kind_of(Hash)
      expect(effective_borrowing_capacity[:unused_capacity][:absolute]).to be_kind_of(Integer)
      expect(effective_borrowing_capacity[:unused_capacity][:percentage]).to be_kind_of(Float)
    end
    it "should return nil if there was an API error" do
      expect_any_instance_of(RestClient::Resource).to receive(:get).and_raise(RestClient::InternalServerError)
      expect(effective_borrowing_capacity).to eq(nil)
    end
    it "should return nil if there was a connection error" do
      expect_any_instance_of(RestClient::Resource).to receive(:get).and_raise(Errno::ECONNREFUSED)
      expect(effective_borrowing_capacity).to eq(nil)
    end
  end

  describe "`capital_stock_activity` method", :vcr do
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
      it "should return nil if there was an API error for the start_date capital_stock_balance endpoint" do
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
      it "should return nil if there was an API error for the capital_stock_activities endpoint" do
        expect(request_object).to receive(:get).and_raise(RestClient::InternalServerError)
        override_activities_endpoint(start_date, end_date, request_object)
        expect(capital_stock_activity).to eq(nil)
      end
      it "should return nil if there was a connection error for the capital_stock_activities endpoint" do
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