require 'spec_helper'

describe MAPI::ServiceApp do
  describe 'member profile' do
    let(:make_request) { get "/member/#{member_id}/member_profile" }
    let(:member_financial_position) { make_request; JSON.parse(last_response.body) }
    let(:capital_stock) { double('Capital Stock', as_json: SecureRandom.uuid) }
    before do
      allow(MAPI::Services::Member::CapitalStockAndLeverage).to receive(:capital_stock_and_leverage).with(anything, member_id).and_return(capital_stock)
    end
    it "should return json with expected elements type" do
      expect(member_financial_position.length).to be >= 1
      %w(total_financing_available remaining_financing_available mpf_credit_available collateral_market_value_sbc_agency collateral_market_value_sbc_aaa collateral_market_value_sbc_aa total_borrowing_capacity_standard total_borrowing_capacity_sbc_agency total_borrowing_capacity_sbc_aaa total_borrowing_capacity_sbc_aa maximum_term total_assets forward_commitments).each do |key|
        expect(member_financial_position[key]).to be_kind_of(Integer)
      end
      expect(member_financial_position['collateral_delivery_status']).to be_kind_of(String)
      %w(sta_balance financing_percentage approved_long_term_credit).each do |key|
        expect(member_financial_position[key]).to be_kind_of(Float)
      end
      credit_outstanding = member_financial_position['credit_outstanding']
      ['total', 'standard', 'sbc', 'swaps_credit', 'swaps_notational', 'mpf_credit', 'letters_of_credit', 'investments', 'total_advances_outstanding', 'total_credit_products_outstanding', 'total_advances_and_mpf'].each do |key|
        expect(credit_outstanding[key]).to be_kind_of(Integer)
      end
      collateral_borrowing_capacity = member_financial_position['collateral_borrowing_capacity']
      expect(collateral_borrowing_capacity['total']).to be_kind_of(Integer)
      expect(collateral_borrowing_capacity['remaining']).to be_kind_of(Integer)
      expect(collateral_borrowing_capacity['standard']['total']).to be_kind_of(Integer)
      expect(collateral_borrowing_capacity['standard']['remaining']).to be_kind_of(Integer)
      expect(collateral_borrowing_capacity['sbc']['total_borrowing']).to be_kind_of(Integer)
      expect(collateral_borrowing_capacity['sbc']['remaining_borrowing']).to be_kind_of(Integer)
      expect(collateral_borrowing_capacity['sbc']['total_market']).to be_kind_of(Integer)
      expect(collateral_borrowing_capacity['sbc']['remaining_market']).to be_kind_of(Integer)
    end

    it 'should call `MAPI::Services::Member::CapitalStockAndLeverage::capital_stock_and_leverage` method and return capital_stock' do
      capital_stock = double('Capital Stock', as_json: SecureRandom.uuid)
      allow(MAPI::Services::Member::CapitalStockAndLeverage).to receive(:capital_stock_and_leverage).with(anything, member_id).and_return(capital_stock)
      expect(member_financial_position['capital_stock']).to eq(capital_stock.as_json)
    end

    it 'should return a 404 if `MAPI::Services::Member::CapitalStockAndLeverage::capital_stock_and_leverage` returns nil'  do
      allow(MAPI::Services::Member::CapitalStockAndLeverage).to receive(:capital_stock_and_leverage).with(anything, member_id).and_return(nil)
      make_request
      expect(last_response.status).to be(404)
    end

    describe 'in the production environment' do
        let(:member_position_result) {double('Oracle Result Set', fetch: nil)}
        let(:member_sta_result) {double('Oracle Result Set', fetch: nil)}
        let(:some_financial_data) do
          data = {}
          %w(RECOM_EXPOSURE_PCT MAX_TERM TOTAL_ASSETS RHFA_ADVANCES_LIMIT REG_ADVANCES_OUTS SBC_ADVANCES_OUTS SWAP_MARKET_OUTS SWAP_NOTIONAL_PRINCIPAL UNSECURED_CREDIT LCS_OUTS MPF_CE_COLLATERAL_REQ STX_LEDGER_BALANCE CREDIT_OUTSTANDING COMMITTED_FUND_LESS_MPF AVAILABLE_CREDIT RECOM_EXPOSURE REG_BORR_CAP SBC_BORR_CAP EXCESS_REG_BORR_CAP EXCESS_SBC_BORR_CAP_AG EXCESS_SBC_BORR_CAP_AAA EXCESS_SBC_BORR_CAP_AA EXCESS_SBC_BORR_CAP SBC_MARKET_VALUE_AG SBC_MARKET_VALUE_AAA SBC_MARKET_VALUE_AA SBC_MARKET_VALUE EXCESS_SBC_MARKET_VALUE ADVANCES_OUTSTANDING MPF_UNPAID_BALANCE TOTAL_CAPITAL_STOCK MRTG_RELATED_ASSETS MRTG_RELATED_ASSETS_round100).each do |key|
            data[key] = rand(1..1000000)
          end
          data['DELIVERY_STATUS_FLAG'] = SecureRandom.uuid
          data
        end
        let(:some_sta_data) {{"STX_CURRENT_LEDGER_BALANCE"=> rand(1..1000000)}}
        before do
          allow(MAPI::ServiceApp).to receive(:environment).at_least(1).and_return(:production)
          allow(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(member_position_result, member_sta_result)
          allow(member_position_result).to receive(:fetch_hash).and_return(some_financial_data, nil)
          allow(member_sta_result).to receive(:fetch_hash).and_return(some_sta_data, nil)
        end

        it "should json with expected column (exclude stock leverage)" , vcr: {cassette_name: 'capital_stock_requirements_service'} do
          {
            'total_financing_available' => 'RECOM_EXPOSURE',
            'remaining_financing_available' => 'AVAILABLE_CREDIT',
            'collateral_market_value_sbc_agency' => 'SBC_MARKET_VALUE_AG',
            'collateral_market_value_sbc_aaa' => 'SBC_MARKET_VALUE_AAA',
            'collateral_market_value_sbc_aa' => 'SBC_MARKET_VALUE_AA',
            'total_borrowing_capacity_standard' => 'EXCESS_REG_BORR_CAP',
            'total_borrowing_capacity_sbc_agency' => 'EXCESS_SBC_BORR_CAP_AG',
            'total_borrowing_capacity_sbc_aaa' => 'EXCESS_SBC_BORR_CAP_AAA',
            'total_borrowing_capacity_sbc_aa' => 'EXCESS_SBC_BORR_CAP_AA',
            'collateral_delivery_status' => 'DELIVERY_STATUS_FLAG',
            'financing_percentage' => 'RECOM_EXPOSURE_PCT',
            'maximum_term' => 'MAX_TERM',
            'total_assets' => 'TOTAL_ASSETS',
            'approved_long_term_credit' => 'RHFA_ADVANCES_LIMIT'
          }.each do |key, value_key|
            expect(member_financial_position[key]).to eq(some_financial_data[value_key])
          end
          expect(member_financial_position['sta_balance']).to eq(some_sta_data['STX_CURRENT_LEDGER_BALANCE'])
          expect(member_financial_position['mpf_credit_available']).to eq(some_financial_data['RECOM_EXPOSURE'] - (some_financial_data['CREDIT_OUTSTANDING'] + some_financial_data['COMMITTED_FUND_LESS_MPF'] + some_financial_data['AVAILABLE_CREDIT']))
          expect(member_financial_position['collateral_borrowing_capacity']['total']).to eq(some_financial_data['REG_BORR_CAP'] + some_financial_data['SBC_BORR_CAP'])
          expect(member_financial_position['collateral_borrowing_capacity']['remaining']).to eq(some_financial_data['EXCESS_REG_BORR_CAP'] + some_financial_data['EXCESS_SBC_BORR_CAP'])
          expect(member_financial_position['collateral_borrowing_capacity']['standard']['total']).to eq(some_financial_data['REG_BORR_CAP'])
          expect(member_financial_position['collateral_borrowing_capacity']['standard']['remaining']).to eq(some_financial_data['EXCESS_REG_BORR_CAP'])
          expect(member_financial_position['collateral_borrowing_capacity']['sbc']['total_borrowing']).to eq(some_financial_data['SBC_BORR_CAP'])
          expect(member_financial_position['collateral_borrowing_capacity']['sbc']['remaining_borrowing']).to eq(some_financial_data['EXCESS_SBC_BORR_CAP'])
          expect(member_financial_position['collateral_borrowing_capacity']['sbc']['total_market']).to eq(some_financial_data['SBC_MARKET_VALUE'])
          expect(member_financial_position['collateral_borrowing_capacity']['sbc']['remaining_market']).to eq(some_financial_data['EXCESS_SBC_MARKET_VALUE'])
          {
            'total' => 'CREDIT_OUTSTANDING',
            'standard' => 'REG_ADVANCES_OUTS',
            'sbc' => 'SBC_ADVANCES_OUTS',
            'swaps_credit' => 'SWAP_MARKET_OUTS',
            'swaps_notational' => 'SWAP_NOTIONAL_PRINCIPAL',
            'mpf_credit' => 'MPF_CE_COLLATERAL_REQ',
            'letters_of_credit' => 'LCS_OUTS',
            'investments' => 'UNSECURED_CREDIT'
          }.each do |key, value_key|
            expect(member_financial_position['credit_outstanding'][key]).to eq(some_financial_data[value_key])
          end
        end

        it 'should return a 404 if no position data was found for the member' do
          allow(member_position_result).to receive(:fetch_hash).and_return(nil)
          make_request
          expect(last_response.status).to be(404)
        end

        it 'should return a 404 if no sta data was found for the member' do
          allow(member_sta_result).to receive(:fetch_hash).and_return(nil)
          make_request
          expect(last_response.status).to be(404)
        end

    end
  end

  describe 'member_details' do
    let(:make_request) { get "/member/#{member_id}/" }
    let(:member_details) { make_request; JSON.parse(last_response.body) }
    let(:member_name) {SecureRandom.uuid}
    let(:member_name_cursor) { double('Member Query', fetch: [member_name])}
    let(:sta_number) {SecureRandom.uuid}
    let(:sta_number_cursor) { double('STA Number Query', fetch: [sta_number])}
    let(:fhfa_number) {SecureRandom.uuid}
    let(:customer_signature_card_response) { {'CU_FHFB_ID' => fhfa_number } }
    let(:customer_signature_card_cursor) { double('customer_signature_card_cursor', fetch_hash: customer_signature_card_response)}
    let(:dual_signers_required) {SecureRandom.uuid}
    let(:development_json) {
      {
        member_id => {
          'name' => member_name,
          'sta_number' => sta_number,
          'fhfa_number' => fhfa_number,
          'dual_signers_required' => dual_signers_required
        }
      }
    }
    [:production, :development].each do |env|
      describe "in the `#{env}` environment" do
        before do
          allow(File).to receive(:read) do
            development_json.to_json
          end
          allow(MAPI::ServiceApp).to receive(:environment).at_least(1).and_return(env)
          allow(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(member_name_cursor, sta_number_cursor, customer_signature_card_cursor)
        end
        it 'returns a 404 if the member name isn\'t found' do
          allow(member_name_cursor).to receive(:fetch).and_return(nil)
          development_json[member_id]['name'] = nil
          make_request
          expect(last_response.status).to be(404)
        end
        it 'returns a 200 if the STA number isn\'t found' do
          allow(sta_number_cursor).to receive(:fetch).and_return(nil)
          development_json[member_id]['sta_number'] = nil
          make_request
          expect(last_response.status).to be(200)
        end
        it 'returns a 200 if the FHFB number isn\'t found' do
          allow(customer_signature_card_cursor).to receive(:fetch_hash).and_return(nil)
          development_json[member_id]['fhfa_number'] = nil
          make_request
          expect(last_response.status).to be(200)
        end
        it 'returns a 200 if the `dual_signers_required` value isn\'t found' do
          allow(customer_signature_card_cursor).to receive(:fetch_hash).and_return(nil)
          development_json[member_id]['dual_signers_required'] = nil
          make_request
          expect(last_response.status).to be(200)
        end
        if env == :development
          it 'returns a 404 if the member isn\'t found' do
            allow(File).to receive(:read).and_return({}.to_json)
            make_request
            expect(last_response.status).to be(404)
          end
          it 'returns the member `dual_signers_required` value' do
            expect(member_details['dual_signers_required']).to eq(dual_signers_required)
          end
        end
        if env == :production
          it 'returns `true` for `dual_signers_required` if the `NEEDSTWOSIGNERS` value is -1' do
            customer_signature_card_response = {'NEEDSTWOSIGNERS' => -1}
            allow(customer_signature_card_cursor).to receive(:fetch_hash).and_return(customer_signature_card_response)
            expect(member_details['dual_signers_required']).to eq(true)
          end
          [0, 1, :foo, nil, true, SecureRandom.uuid].each do |value|
            it "returns `false` for `dual_signers_required` if the `NEEDSTWOSIGNERS` value is #{value}" do
              customer_signature_card_response = {'NEEDSTWOSIGNERS' => value}
              allow(customer_signature_card_cursor).to receive(:fetch_hash).and_return(customer_signature_card_response)
              expect(member_details['dual_signers_required']).to eq(false)
            end
          end
        end
        it 'returns the member name' do
          expect(member_details['name']).to eq(member_name)
        end
        it 'returns the member STA number' do
          expect(member_details['sta_number']).to eq(sta_number)
        end
        it 'returns the member FHFB number' do
          expect(member_details['fhfa_number']).to eq(fhfa_number)
        end
      end
    end
  end

  describe 'list of all members' do
    let(:members) { get '/member/'; JSON.parse(last_response.body) }
    [:development, :test, :production].each do |env|
      describe "in #{env}" do
        let(:first_record) { {'FHLB_ID' => '1', 'CP_ASSOC' => 'Some Name'} }
        let(:second_record) { {'FHLB_ID' => '2', 'CP_ASSOC' => 'Another Name'} }
        before do
          expect(MAPI::ServiceApp).to receive(:environment).at_least(1).and_return(env)
          results = double('Oracle Result Set')
          allow(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(results)
          allow(results).to receive(:fetch_hash).and_return(first_record, second_record, nil)
        end
        it 'returns 200 on success' do
          get '/member/'
          expect(last_response.status).to be(200)
        end
        it 'returns an array of members on success' do
          expect(members).to be_kind_of(Array)
          expect(members.count).to be >= 1
          members.each do |member|
            expect(member).to be_kind_of(Hash)
            expect(member['id']).to be_kind_of(Numeric)
            expect(member['id']).to be > 0
            expect(member['name']).to be_kind_of(String)
            expect(member['name']).to be_present
          end
        end
        it 'sorts the members by name' do
          last_name = ''
          members.each do |member|
            expect(member['name']).to be > last_name
            last_name = member['name']
          end
        end
      end
    end
  end
end