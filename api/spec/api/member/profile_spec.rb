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
      %w(total_financing_available remaining_financing_available mpf_credit_available maximum_term total_assets forward_commitments).each do |key|
        expect(member_financial_position[key]).to be_kind_of(Integer)
      end
      expect(member_financial_position['collateral_delivery_status']).to be_kind_of(String)
      %w(sta_balance financing_percentage approved_long_term_credit).each do |key|
        expect(member_financial_position[key]).to be_kind_of(Float)
      end
      expect(member_financial_position['sta_update_date']).to be_kind_of(String)
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
      expect(member_financial_position['credit_exception']).to be_kind_of(String)
      expect(member_financial_position['disabled_reports']).to be_kind_of(Array)
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

    it 'includes the `member_id` of the member in question' do
      expect(member_financial_position['member_id']).to eq(member_id)
    end

    describe 'in the production environment' do
        let(:member_position_result) {double('Oracle Result Set', fetch: nil)}
        let(:member_sta_result) {double('Oracle Result Set', fetch: nil)}
        let(:member_credit_exception_hash) { double('Oracle Result Set', fetch: nil) }
        let(:disabled_reports_array) { double('Oracle Result Set', fetch: nil) }
        let(:credit_exception) { { 'EXCEPT_TEXT' => 'This is a credit exception' } }
        let(:disabled_reports) { [  { 'WEB_FLAG_ID' => 14,
                                      'WEB_FLAG_NAME' => 'Cash Projections Data' },
                                    { 'WEB_FLAG_ID' => 29,
                                      'WEB_FLAG_NAME' => 'Current Securities Position' } ] }
        let(:some_financial_data) do
          data = {}
          %w(RECOM_EXPOSURE_PCT MAX_TERM TOTAL_ASSETS RHFA_ADVANCES_LIMIT REG_ADVANCES_OUTS SBC_ADVANCES_OUTS SWAP_MARKET_OUTS SWAP_NOTIONAL_PRINCIPAL UNSECURED_CREDIT LCS_OUTS MPF_CE_COLLATERAL_REQ STX_LEDGER_BALANCE CREDIT_OUTSTANDING COMMITTED_FUND_LESS_MPF AVAILABLE_CREDIT RECOM_EXPOSURE REG_BORR_CAP SBC_BORR_CAP EXCESS_REG_BORR_CAP EXCESS_SBC_BORR_CAP_AG EXCESS_SBC_BORR_CAP_AAA EXCESS_SBC_BORR_CAP_AA EXCESS_SBC_BORR_CAP SBC_MARKET_VALUE_AG SBC_MARKET_VALUE_AAA SBC_MARKET_VALUE_AA SBC_MARKET_VALUE EXCESS_SBC_MARKET_VALUE ADVANCES_OUTSTANDING MPF_UNPAID_BALANCE TOTAL_CAPITAL_STOCK MRTG_RELATED_ASSETS MRTG_RELATED_ASSETS_round100
            SBC_BORR_CAP_AG EXCESS_SBC_BORR_CAP_AG SBC_MARKET_VALUE_AG EXCESS_SBC_MV_AG
            SBC_BORR_CAP_AA EXCESS_SBC_BORR_CAP_AA SBC_MARKET_VALUE_AA EXCESS_SBC_MV_AA
            SBC_BORR_CAP_AAA EXCESS_SBC_BORR_CAP_AAA SBC_MARKET_VALUE_AAA EXCESS_SBC_MV_AAA
          ).each do |key|
            data[key] = rand(1..1000000)
          end
          data['DELIVERY_STATUS_FLAG'] = SecureRandom.uuid
          data
        end
        let(:some_sta_data) {{ "STX_CURRENT_LEDGER_BALANCE"=> rand(1..1000000),
                               "STX_UPDATE_DATE"=> Time.zone.today.to_s }}
        before do
          allow(MAPI::ServiceApp).to receive(:environment).at_least(1).and_return(:production)
          allow(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(member_position_result, member_sta_result, member_credit_exception_hash, disabled_reports_array)
          allow(member_position_result).to receive(:fetch_hash).and_return(some_financial_data, nil)
          allow(member_sta_result).to receive(:fetch_hash).and_return(some_sta_data, nil)
          allow(member_credit_exception_hash).to receive(:fetch_hash).and_return(credit_exception)
          allow(MAPI::Services::Member::Profile).to receive(:fetch_hashes).and_return(disabled_reports)
        end

        it 'returns the `financing_percentage` from the `RECOM_EXPOSURE_PCT` field a percentage' do
          expect(member_financial_position['financing_percentage']).to eq(some_financial_data['RECOM_EXPOSURE_PCT'] * 100)
        end

        it "should json with expected column (exclude stock leverage)" , vcr: {cassette_name: 'capital_stock_requirements_service'} do
          {
            'total_financing_available' => 'RECOM_EXPOSURE',
            'remaining_financing_available' => 'AVAILABLE_CREDIT',
            'collateral_delivery_status' => 'DELIVERY_STATUS_FLAG',
            'maximum_term' => 'MAX_TERM',
            'total_assets' => 'TOTAL_ASSETS',
            'approved_long_term_credit' => 'RHFA_ADVANCES_LIMIT'
          }.each do |key, value_key|
            expect(member_financial_position[key]).to eq(some_financial_data[value_key])
          end
          expect(member_financial_position['sta_balance']).to eq(some_sta_data['STX_CURRENT_LEDGER_BALANCE'])
          expect(member_financial_position['sta_update_date']).to eq(some_sta_data['STX_UPDATE_DATE'])
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

        {
          'agency' => {
            'total' => 'SBC_BORR_CAP_AG',
            'remaining' => 'EXCESS_SBC_BORR_CAP_AG',
            'total_market' => 'SBC_MARKET_VALUE_AG',
            'remaining_market' => 'EXCESS_SBC_MV_AG'
          },
          'aa' => {
            'total' => 'SBC_BORR_CAP_AA',
            'remaining' => 'EXCESS_SBC_BORR_CAP_AA',
            'total_market' => 'SBC_MARKET_VALUE_AA',
            'remaining_market' => 'EXCESS_SBC_MV_AA'
          },
          'aaa' => {
            'total' => 'SBC_BORR_CAP_AAA',
            'remaining' => 'EXCESS_SBC_BORR_CAP_AAA',
            'total_market' => 'SBC_MARKET_VALUE_AAA',
            'remaining_market' => 'EXCESS_SBC_MV_AAA'
          }
        }.each do |collateral_type, keys|
          keys.each do |key, field|
            it "returns the field `#{field}` in the JSON response under `collateral_borrowing_capacity.sbc.#{collateral_type}.#{key}`" do
              expect(member_financial_position['collateral_borrowing_capacity']['sbc'][collateral_type][key]).to eq(some_financial_data[field])
            end
          end
        end

        it 'returns the credit exception' do
          expect(member_financial_position['credit_exception']).to eq(credit_exception['EXCEPT_TEXT'])
        end

        it 'returns disabled reports' do
          expect(member_financial_position['disabled_reports']).to eq(disabled_reports.map { |disabled_report| disabled_report['WEB_FLAG_NAME'] } )
        end

        it 'should return a 404 if no position data was found for the member' do
          allow(member_position_result).to receive(:fetch_hash).and_return(nil)
          make_request
          expect(last_response.status).to be(404)
        end

        it 'returns a 200 if no STA data was found for the member' do
          allow(member_sta_result).to receive(:fetch_hash).and_return(nil)
          make_request
          expect(last_response.status).to be(200)
        end

        it 'returns a nil for the `sta_balance` if no STA data was found ' do
          allow(member_sta_result).to receive(:fetch_hash).and_return(nil)
          expect(member_financial_position['sta_balance']).to be_nil
        end

        it 'returns a nil for the `sta_update_date` if no STA data was found ' do
          allow(member_sta_result).to receive(:fetch_hash).and_return(nil)
          expect(member_financial_position['sta_update_date']).to be_nil
        end

        it 'flips the sign of the MPF_UNPAID_BALANCE' do
          expect(member_financial_position['advances']['mpf_loan_balance']).to eq(some_financial_data['MPF_UNPAID_BALANCE'] * -1)
        end
        it 'calculates the advance total with MPF correctly' do
          expect(member_financial_position['advances']['total_advances_and_mpf']).to eq(some_financial_data['ADVANCES_OUTS'].to_i + some_financial_data['MPF_ACTIVITY'].to_i + (some_financial_data['MPF_UNPAID_BALANCE'].to_i * -1))
        end
    end

    context 'credit exceptions and disabled reports' do
      before do
        allow(MAPI::Services::Member::Profile).to receive(:quote).with(member_id).and_return(member_id)
      end

      it 'returns the credit exception query' do
        expect(MAPI::Services::Member::Profile.get_credit_exception_query(member_id)).to eq(
          <<-SQL
            SELECT EXCEPT_TEXT
            FROM CRED_APP.CRED_EXCEPT_REPORT
            WHERE VALID_FLAG = 'Y'
            AND EFFECT_DATE <= SYSDATE AND EXCEPT_TEXT IS NOT NULL AND FHLB_ID = #{member_id}
          SQL
        )
      end

      it 'returns the disabled reports query' do
        expect(MAPI::Services::Member::Profile.get_disabled_reports_query(member_id)).to eq(
          <<-SQL
            SELECT  C.WEB_FLAG_ID, P.WEB_FLAG_NAME
            FROM WEB_ADM.WEB_DATA_FLAGS P,  WEB_ADM.WEB_DATA_FLAGS_BY_INSTITUTIONS C
            WHERE P.WEB_FLAG_ID = C.WEB_FLAG_ID
            AND C.WEB_FHLB_ID = #{member_id}
          SQL
        )
      end
    end
  end
  
  context 'account numbers' do
    let(:account_numbers) { { 'P' => rand(999..9999), 'U' => rand(999..9999) } }
    let(:account_numbers_hash_array) { [ { 'ACCOUNT_TYPE' => 'P', 'ACCOUNT_NUMBER' => account_numbers['P'] },
                                         { 'ACCOUNT_TYPE' => 'U', 'ACCOUNT_NUMBER' => account_numbers['U'] } ] }
    let(:member_id) { rand(999..9999) }

    describe '`get_account_numbers_query`' do
      let(:sql) {
        <<-SQL
            SELECT UPPER(SUBSTR(BAT.BAT_ACCOUNT_TYPE,1,1)) AS ACCOUNT_TYPE, ADX.ADX_ID, ADX_BTC_ACCOUNT_NUMBER AS ACCOUNT_NUMBER
            FROM SAFEKEEPING.ACCOUNT_DOCKET_XREF ADX, SAFEKEEPING.BTC_ACCOUNT_TYPE BAT, SAFEKEEPING.CUSTOMER_PROFILE CP
            WHERE ADX.BAT_ID = BAT.BAT_ID
            AND ADX.CP_ID = CP.CP_ID
            AND CP.FHLB_ID = #{member_id}
            AND UPPER(SUBSTR(BAT.BAT_ACCOUNT_TYPE,1,1)) IN ('P', 'U')
            AND CONCAT(TRIM(TRANSLATE(ADX.ADX_BTC_ACCOUNT_NUMBER,' 0123456789',' ')), '*') = '*'
            AND (BAT.BAT_ACCOUNT_TYPE NOT LIKE '%DB%' AND BAT.BAT_ACCOUNT_TYPE NOT LIKE '%REIT%')
            ORDER BY TO_NUMBER(ADX.ADX_BTC_ACCOUNT_NUMBER) ASC
        SQL
      }

      it 'returns SQL with the member id' do
        expect(MAPI::Services::Member::Profile.get_account_numbers_query(member_id)).to eq(sql)
      end
    end

    describe '`get_account_numbers`' do
      let(:logger) { double('A Logger') }
      let(:account_numbers_query) { double('Account Numbers Query') }
      let(:call_method) { MAPI::Services::Member::Profile.get_account_numbers(logger, member_id) }

      before do
        allow(MAPI::Services::Member::Profile).to receive(:get_account_numbers_query).with(member_id).and_return(account_numbers_query)
        allow(MAPI::Services::Member::Profile).to receive(:fetch_hashes).and_return(account_numbers_hash_array)
      end

      it 'calls `fetch_hashes`' do
        expect(MAPI::Services::Member::Profile).to receive(:fetch_hashes).with(logger, account_numbers_query)
        call_method
      end

      it 'returns the `account_numbers` in a hash by account type' do
        expect(call_method).to eq(account_numbers)
      end
    end
  end

  describe 'member_details' do
    let(:make_request) { get "/member/#{member_id}/" }
    let(:member_details) { make_request; JSON.parse(last_response.body) }
    let(:member_name) { SecureRandom.uuid }
    let(:member_name_cursor) { double('Member Query', fetch: [member_name])}
    let(:sta_number) { SecureRandom.uuid }
    let(:sta_number_cursor) { double('STA Number Query', fetch: [sta_number])}
    let(:fhfa_number) { SecureRandom.uuid }
    let(:customer_signature_card_response) { {'CU_FHFB_ID' => fhfa_number } }
    let(:customer_signature_card_cursor) { double('customer_signature_card_cursor', fetch_hash: customer_signature_card_response)}
    let(:address_data_response) { {'CU_FHFB_ID' => fhfa_number } }
    let(:shippingstreetdata) { SecureRandom.uuid }
    let(:shippingstreet) { double('shippingstreet', read: shippingstreetdata) }
    let(:shippingcity) { SecureRandom.uuid }
    let(:shippingstate) { SecureRandom.uuid }
    let(:shippingpostalcode) { SecureRandom.uuid }
    let(:address_data_response) { {'SHIPPINGSTREET' => shippingstreet, 'SHIPPINGCITY'=> shippingcity, 'SHIPPINGSTATE'=> shippingstate, 'SHIPPINGPOSTALCODE' => shippingpostalcode} }
    let(:dual_signers_required) { SecureRandom.uuid }
    let(:account_numbers_query) { double('Account Numbers Query') }
    let(:account_numbers) { { "P" => rand(999..9999), "U" => rand(999..9999) } }
    let(:member_id) { rand(999..9999) }

    let(:development_json) {
      {
        member_id => {
          'name' => member_name,
          'sta_number' => sta_number,
          'fhfa_number' => fhfa_number,
          'dual_signers_required' => dual_signers_required,
          'street' => shippingstreetdata,
          'city' => shippingcity,
          'state' => shippingstate,
          'postal_code' => shippingpostalcode,
          'pledged_account_number' => account_numbers['P'],
          'unpledged_account_number' => account_numbers['U']
        }
      }
    }
    describe 'in the `production` environment' do
      before do
        allow(MAPI::ServiceApp).to receive(:environment).and_return(:production)
        allow(ActiveRecord::Base.connection).to receive(:execute).and_return(member_name_cursor, sta_number_cursor, customer_signature_card_cursor)
        allow(MAPI::Services::Member::Profile).to receive(:fetch_hash)
        allow(MAPI::Services::Member::Profile).to receive(:get_account_numbers)
        allow(MAPI::Services::Member::Profile).to receive(:execute_sql_single_result)
      end

      it 'succeeds' do
        expect{make_request}.not_to raise_error
      end
      describe 'the SQL query for the sta number' do
        let(:ensure_after_select_regexp) { '(?:\A\s*SELECT\s+sta.sta_account_number\s+)' }
        it 'SELECTs the `sta.sta_account_number`' do
          matcher = Regexp.new(/\A\s*SELECT\s+sta.sta_account_number\s+/i)
          expect(ActiveRecord::Base.connection).to receive(:execute).with(matcher).and_return(sta_number_cursor)
          make_request
        end
        it 'selects from `portfolios.sta` and `portfolios.sta_trans`' do
          matcher = Regexp.new(/#{ensure_after_select_regexp}FROM\s+portfolios.sta\s+sta\s*,\s+portfolios.sta_trans\s+st/i)
          expect(ActiveRecord::Base.connection).to receive(:execute).with(matcher).and_return(sta_number_cursor)
          make_request
        end
        describe 'the WHERE clause' do
          let(:ensure_position_regexp) { '\A\s*SELECT\s+sta.sta_account_number\s+FROM\s+.+\s+.+\s+WHERE.*' }
          before { allow(MAPI::Services::Member::Profile).to receive(:quote) }
          it 'quotes the member_id' do
            expect(MAPI::Services::Member::Profile).to receive(:quote).with(member_id.to_s)
            make_request
          end
          it 'ensures the fhlb_id is the member_id' do
            allow(MAPI::Services::Member::Profile).to receive(:quote).with(member_id.to_s).and_return(member_id)
            matcher = Regexp.new(/#{ensure_position_regexp}sta.fhlb_id\s+=\s+#{member_id}/im)
            expect(ActiveRecord::Base.connection).to receive(:execute).with(matcher).and_return(sta_number_cursor)
            make_request
          end
          it 'matches the `sta_id` between the two tables' do
            matcher = Regexp.new(/#{ensure_position_regexp}sta.sta_id\s+=\s+st.sta_id/im)
            expect(ActiveRecord::Base.connection).to receive(:execute).with(matcher).and_return(sta_number_cursor)
            make_request
          end
          it 'ensures the `sta_account_type` is `1`' do
            matcher = Regexp.new(/#{ensure_position_regexp}sta.sta_account_type\s+=\s+1/im)
            expect(ActiveRecord::Base.connection).to receive(:execute).with(matcher).and_return(sta_number_cursor)
            make_request
          end
          it 'ensures the `stx_update_date` is the latest available update date' do
            matcher = Regexp.new(/#{ensure_position_regexp}TRUNC\(st.stx_update_date\)\s+=\s+\(SELECT.*\)/im)
            expect(ActiveRecord::Base.connection).to receive(:execute).with(matcher).and_return(sta_number_cursor)
            make_request
          end
          describe 'fetching the latest available `stx_update_date`' do
            let(:ensure_position_regexp) { '\A\s*SELECT\s+sta.sta_account_number\s+FROM\s+.+\s+.+\s+WHERE.*TRUNC\(st.stx_update_date\)\s+=\s+\(.*' }
            it 'selects the truncated max `stx_update_date`' do
              matcher = Regexp.new(/#{ensure_position_regexp}SELECT\s+TRUNC\s*\(\s*MAX\s*\(\s*stx_update_date\s*\)\s*\).*\)/im)
              expect(ActiveRecord::Base.connection).to receive(:execute).with(matcher).and_return(sta_number_cursor)
              make_request
            end
            it 'selects from `portfolios.sta_trans`' do
              matcher = Regexp.new(/#{ensure_position_regexp}SELECT\s+.*FROM\s+portfolios.sta_trans.*\)/im)
              expect(ActiveRecord::Base.connection).to receive(:execute).with(matcher).and_return(sta_number_cursor)
              make_request
            end
            it 'ensures the stx_update_date is greater than the `SYSDATE` minus 10' do
              matcher = Regexp.new(/#{ensure_position_regexp}SELECT\s+.*FROM\s+.*WHERE\s+stx_update_date\s*>\s*SYSDATE\s*-\s*10.*\)/im)
              expect(ActiveRecord::Base.connection).to receive(:execute).with(matcher).and_return(sta_number_cursor)
              make_request
            end
          end
        end
      end
      describe 'the SQL query for the customer lc agreement flag' do
        it '`SELECT`s the `cu_lc_agreement_flag`' do
          matcher = Regexp.new(/\s+SELECT\s+cu_lc_agreement_flag\s+.*/i)
          expect(MAPI::Services::Member::Profile).to receive(:execute_sql_single_result).with(app, matcher, anything)
          make_request
        end
        it 'selects from `portfolios.customers`' do
          matcher = Regexp.new(/\s+SELECT\s+cu_lc_agreement_flag\s+FROM\s+portfolios.customers\s+.*/i)
          expect(MAPI::Services::Member::Profile).to receive(:execute_sql_single_result).with(app, matcher, anything)
          make_request
        end
        describe 'the WHERE clause' do
          before { allow(MAPI::Services::Member::Profile).to receive(:quote) }
          it 'quotes the member_id' do
            expect(MAPI::Services::Member::Profile).to receive(:quote).with(member_id.to_s)
            make_request
          end
          it 'ensures the fhlb_id is the member_id' do
            allow(MAPI::Services::Member::Profile).to receive(:quote).with(member_id.to_s).and_return(member_id)
            matcher = Regexp.new(/\s+SELECT\s+cu_lc_agreement_flag\s+FROM\s+portfolios.customers\s+WHERE\s+fhlb_id\s+=\s+#{member_id}/i)
            expect(MAPI::Services::Member::Profile).to receive(:execute_sql_single_result).with(app, matcher, anything)
            make_request
          end
        end
      end
    end
    [:production, :development].each do |env|
      describe "in the `#{env}` environment" do
        before do
          allow(File).to receive(:read) do
            development_json.to_json
          end
          allow(MAPI::ServiceApp).to receive(:environment).at_least(1).and_return(env)
          allow(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(member_name_cursor, sta_number_cursor, customer_signature_card_cursor)
          allow(MAPI::Services::Member::Profile).to receive(:fetch_hash).and_return(address_data_response)
          allow(MAPI::Services::Member::Profile).to receive(:get_account_numbers).and_return(account_numbers)
          allow(MAPI::Services::Member::Profile).to receive(:execute_sql_single_result).with(app, anything, anything).and_return(nil)
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
        it 'returns a 200 if the street isn\'t found' do
          allow(MAPI::Services::Member::Profile).to receive(:fetch_hash).and_return(nil)
          development_json[member_id]['street'] = nil
          make_request
          expect(last_response.status).to be(200)
        end
        it 'returns a 200 if the city isn\'t found' do
          allow(MAPI::Services::Member::Profile).to receive(:fetch_hash).and_return(nil)
          development_json[member_id]['city'] = nil
          make_request
          expect(last_response.status).to be(200)
        end
        it 'returns a 200 if the state isn\'t found' do
          allow(MAPI::Services::Member::Profile).to receive(:fetch_hash).and_return(nil)
          development_json[member_id]['state'] = nil
          make_request
          expect(last_response.status).to be(200)
        end
        it 'returns a 200 if the postal_code isn\'t found' do
          allow(MAPI::Services::Member::Profile).to receive(:fetch_hash).and_return(nil)
          development_json[member_id]['postal_code'] = nil
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
          it 'calls `get_account_numbers`' do
            expect(MAPI::Services::Member::Profile).to receive(:get_account_numbers).with(anything, member_id).and_return(account_numbers)
            make_request
          end
          it 'does not raise an error if `SHIPPINGSTREET` is nil' do
            address_data_response['SHIPPINGSTREET'] = nil
            make_request
            expect(last_response.status).to be(200)
          end
          it 'returns true for the `customer_lc_agreement_flag` value if the SQL query returns `[\'Y\']`' do
            allow(MAPI::Services::Member::Profile).to receive(:execute_sql_single_result).and_return('Y')
            expect(member_details['customer_lc_agreement_flag']).to eq(true)
          end
          it 'returns false for the `customer_lc_agreement_flag` value if the SQL query returns `[\'N\']`' do
            allow(MAPI::Services::Member::Profile).to receive(:execute_sql_single_result).and_return('N')
            expect(member_details['customer_lc_agreement_flag']).to eq(false)
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
        it 'returns the member street' do
          expect(member_details['street']).to eq(shippingstreetdata)
        end
        it 'returns the member city' do
          expect(member_details['city']).to eq(shippingcity)
        end
        it 'returns the member state' do
          expect(member_details['state']).to eq(shippingstate)
        end
        it 'returns the member postal code' do
          expect(member_details['postal_code']).to eq(shippingpostalcode)
        end
        it 'returns the pledged account number' do
          expect(member_details['pledged_account_number']).to eq(account_numbers['P'])
        end
        it 'returns the unpledged account number' do
          expect(member_details['unpledged_account_number']).to eq(account_numbers['U'])
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