require 'spec_helper'
require 'date'

describe MAPI::ServiceApp do
  subject { MAPI::Services::Member }

  describe 'capital_stock_trial_balance' do
    let(:result){ { "certificates" => [], "number_of_certificates" => 0, "number_of_shares" => 0 }}
    let(:id) { 750 }
    let(:date) { '2015-10-10' }
    let(:capital_stock_trial_balance) { get "/member/#{id}/capital_stock_trial_balance/#{date}"; JSON.parse(last_response.body) }
    it 'should call CapitalStockTrialBalance.capital_stock_trial_balance with appropriate types of arguments' do
      allow(MAPI::Services::Member::CapitalStockTrialBalance).to receive(:capital_stock_trial_balance).with(anything,kind_of(Numeric),kind_of(Date)).and_return(result)
      expect(capital_stock_trial_balance).to eq(result)
    end
  end

  describe 'GET `advances`' do
    let(:make_request) { get "/member/#{member_id}/advances" }
    let(:json_response) { make_request; JSON.parse(last_response.body) }

    it 'calls `MAPI::Services::Member::TradeActivity.historic_advances` with the `member_id`' do
      expect(MAPI::Services::Member::TradeActivity).to receive(:historic_advances).with(kind_of(app), member_id.to_s).and_return([])
      make_request
    end
    it 'calls `MAPI::Services::Member::TradeActivity.trade_activity` with the `member_id`' do
      expect(MAPI::Services::Member::TradeActivity).to receive(:trade_activity).with(kind_of(app), member_id.to_s, 'ADVANCE').and_return([])
      make_request
    end
    it 'sorts the combined set of trades' do
      historic = [double('A Trade'), double('A Trade')]
      active = [double('A Trade'), double('A Trade')]
      allow(MAPI::Services::Member::TradeActivity).to receive(:historic_advances).and_return(historic)
      allow(MAPI::Services::Member::TradeActivity).to receive(:trade_activity).and_return(active)
      expect(MAPI::Services::Member::TradeActivity).to receive(:sort_trades).with(match(historic + active))
      make_request
    end
    it 'converts the sorted array to JSON and returns it' do
      sorted_trades = double('Some Trades')
      allow(MAPI::Services::Member::TradeActivity).to receive(:historic_advances).and_return([])
      allow(MAPI::Services::Member::TradeActivity).to receive(:trade_activity).and_return([])
      allow(MAPI::Services::Member::TradeActivity).to receive(:sort_trades).and_return(sorted_trades)
      sentinel = SecureRandom.hex
      allow(sorted_trades).to receive(:to_json).and_return("[\"#{sentinel}\"]")
      expect(json_response).to eq([sentinel])
    end
    it 'doesnt raise an error' do
      expect{make_request}.to_not raise_error
    end
    describe 'if `MAPI::Services::Member::TradeActivity.trade_activity` raises a `Savon::Error`' do
      let(:error) { Savon::Error.new }
      before do
        allow(MAPI::Services::Member::TradeActivity).to receive(:trade_activity).and_raise(error)
      end
      it 'returns a 503' do
        make_request
        expect(last_response.status).to be(503)
      end
      it 'logs the error' do
        logger = instance_double(Logger)
        allow_any_instance_of(described_class).to receive(:logger).and_return(logger)
        expect(logger).to receive(:error).with(error)
        make_request
      end
    end
  end
end