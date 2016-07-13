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
  describe 'POST `securities/release`' do
    let(:security) { {  'cusip' => SecureRandom.hex,
                        'description' => SecureRandom.hex,
                        'original_par' => rand(1..100000) + rand.round(2),
                        'payment_amount' => rand(1..100000) + rand.round(2) } }
    let(:delivery_type) { MAPI::Services::Member::SecuritiesRequests::DELIVERY_TYPE.keys[rand(0..3)] }
    let(:delivery_instructions) { { 'delivery_type' => delivery_type } }
    let(:post_body) { {
      'broker_instructions' => { 'transaction_code' => MAPI::Services::Member::SecuritiesRequests::TRANSACTION_CODE.keys[rand(0..1)],
        'settlement_type' => MAPI::Services::Member::SecuritiesRequests::SETTLEMENT_TYPE.keys[rand(0..1)],
        'trade_date' => "2016-06-20T16:28:55-07:00",
        'settlement_date' => "2016-06-20T16:28:55-07:00" },
      'delivery_instructions' => delivery_instructions,
      'securities' => rand(1..5).times.map { security },
      'user' => {
          'username' => SecureRandom.hex,
          'full_name' => SecureRandom.hex,
          'session_id' => SecureRandom.hex }
      } }
    let(:make_request) { post("/member/#{member_id}/securities/release", post_body.to_json) }
    let(:exception_message) { SecureRandom.hex }

    before do
      MAPI::Services::Member::SecuritiesRequests.delivery_keys_for_delivery_type(delivery_type).each do |key|
        delivery_instructions[key] = SecureRandom.hex
      end
    end

    it 'calls `MAPI::Services::Member::SecuritiesRequests.create_release`' do
      allow(MAPI::Services::Member::SecuritiesRequests).to receive(:create_release).with(
        kind_of(app),
        member_id.to_i,
        post_body['user']['username'],
        post_body['user']['full_name'],
        post_body['user']['session_id'],
        post_body['broker_instructions'],
        post_body['delivery_instructions'],
        post_body['securities']).and_return(true)
      make_request
      expect(last_response.status).to be(200)
      expect(last_response.body).to eq("")
     end

    it 'doesn\'t raise an error' do
      expect { make_request }.to_not raise_error
    end

    it 'returns a status of 400 on error' do
      allow(MAPI::Services::Member::SecuritiesRequests).to receive(:create_release).and_raise(ArgumentError, exception_message)
      make_request
      expect(last_response.status).to be(400)
    end
  end
  describe 'PUT `securities/authorize`' do
    let(:username) { SecureRandom.hex }
    let(:full_name) { SecureRandom.hex }
    let(:session_id) { SecureRandom.hex }
    let(:request_id) { rand(100000..999999) }
    let(:make_request) { put "/member/#{member_id}/securities/authorize", {user: {username: username, full_name: full_name, session_id: session_id}, request_id: request_id}.to_json }

    before do
      allow(MAPI::Services::Member::SecuritiesRequests).to receive(:authorize_request).and_return(true)
    end

    it 'calls `authorize_request` with the `request_id`' do
      expect(MAPI::Services::Member::SecuritiesRequests).to receive(:authorize_request).with(app, anything, request_id, anything, anything, anything)
      make_request
    end
    it 'calls `authorize_request` with the `username`' do
      expect(MAPI::Services::Member::SecuritiesRequests).to receive(:authorize_request).with(app, anything, anything, username, anything, anything)
      make_request
    end
    it 'calls `authorize_request` with the `full_name`' do
      expect(MAPI::Services::Member::SecuritiesRequests).to receive(:authorize_request).with(app, anything, anything, anything, full_name, anything)
      make_request
    end
    it 'calls `authorize_request` with the `session_id`' do
      expect(MAPI::Services::Member::SecuritiesRequests).to receive(:authorize_request).with(app, anything, anything, anything, anything, session_id)
      make_request
    end
    it 'calls `authorize_request` with the `member_id`' do
      expect(MAPI::Services::Member::SecuritiesRequests).to receive(:authorize_request).with(app, member_id, anything, anything, anything, anything)
      make_request
    end
    it 'returns a 200 if `authorize_request` returns true' do
      make_request
      expect(last_response.status).to be(200)
    end
    it 'returns a 404 if `authorize_request` returns false' do
      allow(MAPI::Services::Member::SecuritiesRequests).to receive(:authorize_request).and_return(false)
      make_request
      expect(last_response.status).to be(404)
    end
    it 'returns a 400 if `authorize_request` raises an error' do
      allow(MAPI::Services::Member::SecuritiesRequests).to receive(:authorize_request).and_raise(ArgumentError.new('some error'))
      make_request
      expect(last_response.status).to be(400)
    end
    it 'returns a 400 if no `user` is provided' do
      put "/member/#{member_id}/securities/authorize", {request_id: request_id}.to_json
      expect(last_response.status).to be(400)
    end
  end
end