require 'spec_helper'

describe MAPI::ServiceApp do
  describe 'capital stock balances' do
    let(:capital_stock_balance) { get "/member/#{member_id}/capital_stock_balance/2014-01-01"; JSON.parse(last_response.body) }

    RSpec.shared_examples 'a capital stock balance endpoint' do
      it 'should return a number for the balance' do
        expect(capital_stock_balance['open_balance']).to be_kind_of(Numeric)
        expect(capital_stock_balance['close_balance']).to be_kind_of(Numeric)
      end
      it 'should return a date for the balance_date' do
        expect(capital_stock_balance['balance_date']).to match(MAPI::Shared::Constants::REPORT_PARAM_DATE_FORMAT)
      end
    end
    describe 'in the production environment' do
      let!(:some_balance) {123.4}
      let!(:close_balance) {456.4}
      let(:result_set) {double('Oracle Result Set', fetch: nil)}
      let(:result_set2) {double('Oracle Result Set', fetch: nil)}
      before do
        expect(MAPI::ServiceApp).to receive(:environment).at_least(1).times.and_return(:production)
        expect(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(result_set)
        expect(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(result_set2)
        allow(result_set).to receive(:fetch).and_return([some_balance], nil)
        allow(result_set2).to receive(:fetch).and_return([close_balance], nil)
      end
      it 'should return zero for balance if no balance was found' do
        expect(result_set).to receive(:fetch).and_return(nil)
        expect(result_set2).to receive(:fetch).and_return(nil)
        expect(capital_stock_balance['open_balance']).to eq(0)
        expect(capital_stock_balance['close_balance']).to eq(0)
      end
      it 'should return the first balance found (first column of first row)' do
        expect(capital_stock_balance['open_balance']).to eq(some_balance)
        expect(capital_stock_balance['close_balance']).to eq(close_balance)
      end
      it 'should not return the second column found' do
        expect(result_set).to receive(:fetch).and_return([124.5, some_balance], nil).at_least(1).times
        expect(result_set2).to receive(:fetch).and_return([224.5, close_balance], nil).at_least(1).times
        expect(capital_stock_balance['open_balance']).not_to eq(some_balance)
        expect(capital_stock_balance['close_balance']).not_to eq(close_balance)
      end
      it 'should not return the second row found' do
        expect(result_set).to receive(:fetch).and_return([124.5], [some_balance], nil).at_least(1).times
        expect(result_set2).to receive(:fetch).and_return([224.5], [close_balance], nil).at_least(1).times
        expect(capital_stock_balance['open_balance']).not_to eq(some_balance)
        expect(capital_stock_balance['close_balance']).not_to eq(close_balance)
      end
      it_behaves_like 'a capital stock balance endpoint'
    end
    describe 'in the development environment' do
      it_behaves_like 'a capital stock balance endpoint'
    end
    it 'invalid param result in 400 error message' do
      get "/member/#{member_id}/capital_stock_balance/12-12-2014"
      expect(last_response.status).to eq(400)
    end
  end
  describe 'capital stock Activities' do
    let(:from_date) {'2014-01-01'}
    let(:to_date) {'2014-12-31'}
    let(:capital_stock_activities) { get "/member/#{member_id}/capital_stock_activities/#{from_date}/#{to_date}"; JSON.parse(last_response.body) }
    it 'should return expected hash and data type in development' do
      capital_stock_activities['activities'].each do |activity|
        expect(activity['cert_id']).to be_kind_of(String)
        expect(activity['share_number']).to be_kind_of(Numeric)
        expect(activity['trans_date'].to_s).to match(MAPI::Shared::Constants::REPORT_PARAM_DATE_FORMAT)
        expect(activity['trans_type']).to be_kind_of(String)
        expect(activity['dr_cr']) == ('C' || 'D')
      end
    end
    it 'invalid param result in 400 error message' do
      get "/member/#{member_id}/capital_stock_activities/12-12-2014/#{to_date}"
      expect(last_response.status).to eq(400)
      get "/member/#{member_id}/capital_stock_activities/#{from_date}/12-12-2014"
      expect(last_response.status).to eq(400)
    end
    describe 'in the production environment' do
      let!(:some_activity) {['12345','549','2014-12-24 12:00:00','-','D']}
      let(:result_set) {double('Oracle Result Set', fetch: nil)}
      before do
        expect(MAPI::ServiceApp).to receive(:environment).at_least(1).and_return(:production)
        expect(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(result_set)
        allow(result_set).to receive(:fetch).and_return(some_activity, nil)
      end
      it 'should return empty activities array if no activity record found' do
        expect(result_set).to receive(:fetch).and_return(nil)
        expect(capital_stock_activities['activities']).to eq([])
      end
      it 'should return expected hash and data type' do
        capital_stock_activities['activities'].each do |activity|
          expect(activity['cert_id']).to be_kind_of(String)
          expect(activity['share_number']).to be_kind_of(Numeric)
          expect(activity['trans_date'].to_s).to match(MAPI::Shared::Constants::REPORT_PARAM_DATE_FORMAT)
          expect(activity['trans_type']).to be_kind_of(String)
          expect(activity['dr_cr']) == ('C' || 'D')
        end
      end
      it 'should return only 5 column hash even when fetch returns more than 5 columns' do
        expect(result_set).to receive(:fetch).and_return(['12345','549','2014-11-11 12:00:00','-','D','2222'], nil).at_least(1).times
        expect(capital_stock_activities['activities']).to eq([{"cert_id"=>"12345", "share_number"=>549.0, "trans_date"=>"2014-11-11", "trans_type"=>"-", "dr_cr"=>"D"}])
      end
      it 'should return both hash in the activities' do
        expect(result_set).to receive(:fetch).and_return(some_activity, ['22345','2549','24-Nov-2014 12:00:00 AM','-','C'], nil).at_least(1).times
        expect(capital_stock_activities['activities'].count()).to eq(2)
      end
    end
  end
end