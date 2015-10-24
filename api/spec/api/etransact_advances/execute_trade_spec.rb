require 'spec_helper'
require 'date'

def mk_payment_info(payment_at, freq_count, freq_unit, day_of_month=0)
  {
    payment_at: payment_at,
    advance_payment_frequency: {'v13:frequency'=>freq_count, 'v13:frequencyUnit'=>freq_unit},
    advance_payment_day_of_month: day_of_month
  }
end

describe MAPI::ServiceApp do

  let(:member_id) {750}
  let(:amount)  {'100'}
  let(:advance_type)  {'agency'}
  let(:advance_term)  {'1week'}
  let(:rate)  {0.17}
  let(:check_capstock)  {true}
  let(:signer)  {'local'}

  before do
    header 'Authorization', "Token token=\"#{ENV['MAPI_SECRET_TOKEN']}\""
  end

  describe 'get_maturity_date' do
    it 'should add one day if overnight' do
      expect(MAPI::Services::EtransactAdvances::ExecuteTrade.get_maturity_date(Time.zone.parse('2015-02-03').to_date, 'overnight')).to eq(Time.zone.parse('2015-02-04').to_date)
    end
    it 'should add 7 days if 1week' do
      expect(MAPI::Services::EtransactAdvances::ExecuteTrade.get_maturity_date(Time.zone.parse('2015-02-03').to_date, '1week')).to eq(Time.zone.parse('2015-02-10').to_date)
    end
    it 'should add 1 months if 1month' do
      expect(MAPI::Services::EtransactAdvances::ExecuteTrade.get_maturity_date(Time.zone.parse('2015-02-03').to_date, '1month')).to eq(Time.zone.parse('2015-03-03').to_date)
    end
    it 'should add 1 year if 1year' do
      expect(MAPI::Services::EtransactAdvances::ExecuteTrade.get_maturity_date(Time.zone.parse('2015-02-03').to_date, '1year')).to eq(Time.zone.parse('2016-02-03').to_date)
    end
  end

  describe 'get_signer_full_name' do
    let(:signer_full_name) { get "/etransact_advances/signer_full_name/#{signer}"; last_response.body }
    it 'should return signer full name' do
      expect(signer_full_name).to eq('Test User')
    end
    describe 'in the production environment' do
      let(:result_set) {double('Oracle Result Set', fetch: nil)}
      let(:full_name) {['full_name']}
      before do
        allow(MAPI::ServiceApp).to receive(:environment).at_least(1).times.and_return(:production)
        allow(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(result_set)
        allow(result_set).to receive(:fetch).and_return(full_name)
      end
      it 'should return signer full name' do
        expect(signer_full_name).to eq(full_name[0])
      end
    end
  end

  describe 'get_payment_info' do
    let(:overnight_response)    { mk_payment_info('Overnight',    1, 'T') }
    let(:open_response)         { mk_payment_info('End Of Month', 1, 'M', 31)}
    let(:whole_1_week_response) { mk_payment_info('End Of Month', 1, 'T') }
    let(:next_month_response)   { mk_payment_info('End Of Month', 1, 'M') }
    let(:maturity_response)     { mk_payment_info('Maturity',     1, 'T') }
    let(:semiannual_response)   { mk_payment_info('Semiannual',   6, 'M') }
    it 'should return overnight payment info' do
      expect(MAPI::Services::EtransactAdvances::ExecuteTrade.get_payment_info('overnight', 'whole', Time.zone.today, Time.zone.today)).to eq(overnight_response)
    end
    it 'should return open payment info' do
      expect(MAPI::Services::EtransactAdvances::ExecuteTrade.get_payment_info('open', 'whole', Time.zone.today, Time.zone.today)).to eq(open_response)
    end
    it 'should return whole loan 1 week payment info' do
      expect(MAPI::Services::EtransactAdvances::ExecuteTrade.get_payment_info('1week', 'whole', Date.new(2015,6,7), Date.new(2015,6,7))).to eq(whole_1_week_response)
    end
    it 'should return a next month payment info if a whole loan is excuted on the last day of the month' do
      expect(MAPI::Services::EtransactAdvances::ExecuteTrade.get_payment_info('1week', 'whole', Date.new(2015,6,30), Date.new(2015,6,30))).to eq(next_month_response)
    end
    it 'should return next month payment info' do
      expect(MAPI::Services::EtransactAdvances::ExecuteTrade.get_payment_info('1week', 'whole', Time.zone.today, Time.zone.today+32.days)).to eq(next_month_response)
    end
    it 'should return maturity for SBC loans under six months' do
      expect(MAPI::Services::EtransactAdvances::ExecuteTrade.get_payment_info('1week', 'aa', Time.zone.today, Time.zone.today+7.days)).to eq(maturity_response)
    end
    it 'should return semiannual for SBC loans longer than six months' do
      expect(MAPI::Services::EtransactAdvances::ExecuteTrade.get_payment_info('1year', 'aaa', Time.zone.today, Time.zone.today+365.days)).to eq(semiannual_response)
    end
  end

  describe 'get_advance_rate_schedule' do
    let(:rate) { double('rate') }
    let(:transformed_rate) { double('transformed rate') }
    let(:day_count) { double('day_count') }
    let(:overnight_response) {
      {
        'v13:initialRate'=>transformed_rate,
        'v13:floatingRateSchedule'=>{
          'v13:floatingPeriod'=>{
            'v13:startDate'=>Time.zone.today,
            'v13:rateIndices'=>{
              'v13:rateIndex'=>{
                'v13:index'=>'',
                'v13:tenor'=>{
                  'v13:frequency'=>1,
                  'v13:frequencyUnit'=>'D'
                },
                'v13:weight'=>1
              }
            },
            'v13:periodicCap'=>100,
            'v13:periodicFloor'=>0,
            'v13:dayCountBasis'=>day_count,
            'v13:maximumRate'=>100,
            'v13:minimumRate'=>0}},
        'v13:roundingConvention'=>'NEAREST'
      }
    }
    let(:week_response) {
      {
        'v13:initialRate'=>transformed_rate,
        'v13:fixedRateSchedule'=>{
          'v13:step'=>{
            'v13:startDate'=>Time.zone.today,
            'v13:endDate'=>Time.zone.today,
            'v13:rate'=>transformed_rate,
            'v13:dayCountBasis'=>day_count
          }
        },
        'v13:roundingConvention'=>'NEAREST'
      }
    }

    before do
      allow(MAPI::Services::EtransactAdvances::ExecuteTrade).to receive(:percentage_to_decimal_rate).and_return(transformed_rate)
    end

    it 'should return overnight advance rate schedule' do
      expect(MAPI::Services::EtransactAdvances::ExecuteTrade.get_advance_rate_schedule('overnight', rate, day_count, Time.zone.today, Time.zone.today)).to eq(overnight_response)
    end
    it 'should return week advance rate schedule' do
      expect(MAPI::Services::EtransactAdvances::ExecuteTrade.get_advance_rate_schedule('1week', rate, day_count, Time.zone.today, Time.zone.today)).to eq(week_response)
    end
    it 'transforms the rate' do
      expect(MAPI::Services::EtransactAdvances::ExecuteTrade).to receive(:percentage_to_decimal_rate)
      MAPI::Services::EtransactAdvances::ExecuteTrade.get_advance_rate_schedule('foo', rate, day_count, Time.zone.today, Time.zone.today)
    end
  end

  describe 'get_advance_product_info' do
    let(:overnight_response) {{'v14:product'=>'O/N VRC', 'v14:subProduct'=>'VRC', 'v14:term'=>{'v13:frequency'=>1, 'v13:frequencyUnit'=>'D'}}}
    let(:week_response) {{'v14:product'=>'FX CONSTANT', 'v14:subProduct'=>'FRC', 'v14:term'=>{'v13:frequency'=>1, 'v13:frequencyUnit'=>'W'}}}
    it 'should return overnight advance product info' do
      expect(MAPI::Services::EtransactAdvances::ExecuteTrade.get_advance_product_info('overnight')).to eq(overnight_response)
    end
    it 'should return week advance product info' do
      expect(MAPI::Services::EtransactAdvances::ExecuteTrade.get_advance_product_info('1week')).to eq(week_response)
    end
  end

  describe 'Execute Trade' do
    let(:execute_trade) { post "/etransact_advances/execute_advance/#{member_id}/#{amount}/#{advance_type}/#{advance_term}/#{rate}/#{signer}"; JSON.parse(last_response.body) }
    it 'should return expected result of execute trade' do
      expect(execute_trade['status']).to be_kind_of(Array)
      expect(execute_trade['confirmation_number']).to be_kind_of(String)
      expect(execute_trade['advance_rate']).to be_kind_of(Numeric)
      expect(execute_trade['advance_amount']).to be_kind_of(Numeric)
      expect(execute_trade['advance_term']).to be_kind_of(String)
      expect(execute_trade['advance_type']).to be_kind_of(String)
      expect(execute_trade['interest_day_count']).to be_kind_of(String)
      expect(execute_trade['payment_on']).to be_kind_of(String)
      expect(execute_trade['trade_date']).to be_kind_of(String)
      expect(execute_trade['funding_date']).to be_kind_of(String)
      expect(execute_trade['maturity_date']).to be_kind_of(String)
    end
  end
  describe 'Validate Trade' do
    let(:execute_trade) { get "/etransact_advances/validate_advance/#{member_id}/#{amount}/#{advance_type}/#{advance_term}/#{rate}/#{check_capstock}/#{signer}"; JSON.parse(last_response.body) }
    it 'should return expected result of validate trade' do
      expect(execute_trade['status']).to be_kind_of(Array)
      expect(execute_trade['confirmation_number']).to be_kind_of(String)
      expect(execute_trade['advance_rate']).to be_kind_of(Numeric)
      expect(execute_trade['advance_amount']).to be_kind_of(Numeric)
      expect(execute_trade['advance_term']).to be_kind_of(String)
      expect(execute_trade['advance_type']).to be_kind_of(String)
      expect(execute_trade['interest_day_count']).to be_kind_of(String)
      expect(execute_trade['payment_on']).to be_kind_of(String)
      expect(execute_trade['trade_date']).to be_kind_of(String)
      expect(execute_trade['funding_date']).to be_kind_of(String)
      expect(execute_trade['maturity_date']).to be_kind_of(String)
    end
  end

  describe 'Validate Trade With Capital Stock Exception' do
    let(:amount)  {'1000000'}
    let(:execute_trade) { get "/etransact_advances/validate_advance/#{member_id}/#{amount}/#{advance_type}/#{advance_term}/#{rate}/#{check_capstock}/#{signer}"; JSON.parse(last_response.body) }
    it 'should return expected result of validate trade' do
      expect(execute_trade['status']).to eq(['CapitalStockError'])
      expect(execute_trade['authorized_amount']).to be_kind_of(Numeric)
      expect(execute_trade['exception_message']).to be_kind_of(String)
      expect(execute_trade['cumulative_stock_required']).to be_kind_of(Numeric)
      expect(execute_trade['current_trade_stock_required']).to be_kind_of(Numeric)
      expect(execute_trade['net_stock_required']).to be_kind_of(Numeric)
      expect(execute_trade['pre_trade_stock_required']).to be_kind_of(Numeric)
      expect(execute_trade['gross_amount']).to be_kind_of(Numeric)
      expect(execute_trade['gross_cumulative_stock_required']).to be_kind_of(Numeric)
      expect(execute_trade['gross_current_trade_stock_required']).to be_kind_of(Numeric)
      expect(execute_trade['gross_pre_trade_stock_required']).to be_kind_of(Numeric)
      expect(execute_trade['gross_net_stock_required']).to be_kind_of(Numeric)
    end
  end

  describe 'Validate Trade With Credit Error Exception' do
    let(:amount)  {'100001'}
    let(:execute_trade) { get "/etransact_advances/validate_advance/#{member_id}/#{amount}/#{advance_type}/#{advance_term}/#{rate}/#{check_capstock}/#{signer}"; JSON.parse(last_response.body) }
    it 'should return a credit error response' do
      expect(execute_trade['status']).to eq(['CreditError'])
      expect(execute_trade['credit_max_amount']).to be_kind_of(Numeric)
    end
  end

  describe 'Validate Trade With Collateral Error Exception' do
    let(:amount)  {'100002'}
    let(:execute_trade) { get "/etransact_advances/validate_advance/#{member_id}/#{amount}/#{advance_type}/#{advance_term}/#{rate}/#{check_capstock}/#{signer}"; JSON.parse(last_response.body) }
    it 'should return a collateral exception response' do
      expect(execute_trade['status']).to eq(['CollateralError'])
      expect(execute_trade['collateral_max_amount']).to be_kind_of(Numeric)
      expect(execute_trade['collateral_authorized_amount']).to be_kind_of(Numeric)
    end
  end

  describe 'Validate Trade With Total Daily Limit Error Exception' do
    let(:amount)  {'100003'}
    let(:execute_trade) { get "/etransact_advances/validate_advance/#{member_id}/#{amount}/#{advance_type}/#{advance_term}/#{rate}/#{check_capstock}/#{signer}"; JSON.parse(last_response.body) }
    it 'should return expected result of validate trade' do
      expect(execute_trade['status']).to eq(['ExceedsTotalDailyLimitError'])
    end
  end

  describe 'Validate Trade With Capital Stock Gross Up Exception' do
    let(:amount)  {'2000000'}
    let(:execute_trade) { get "/etransact_advances/validate_advance/#{member_id}/#{amount}/#{advance_type}/#{advance_term}/#{rate}/#{check_capstock}/#{signer}"; JSON.parse(last_response.body) }
    it 'should return expected result of validate trade' do
      expect(execute_trade['status']).to eq(['GrossUpError'])
      expect(execute_trade['authorized_amount']).to be_kind_of(Numeric)
      expect(execute_trade['exception_message']).to be_kind_of(String)
      expect(execute_trade['cumulative_stock_required']).to be_kind_of(Numeric)
      expect(execute_trade['current_trade_stock_required']).to be_kind_of(Numeric)
      expect(execute_trade['net_stock_required']).to be_kind_of(Numeric)
      expect(execute_trade['pre_trade_stock_required']).to be_kind_of(Numeric)
      expect(execute_trade['gross_amount']).to be_kind_of(Numeric)
      expect(execute_trade['gross_cumulative_stock_required']).to be_kind_of(Numeric)
      expect(execute_trade['gross_current_trade_stock_required']).to be_kind_of(Numeric)
      expect(execute_trade['gross_pre_trade_stock_required']).to be_kind_of(Numeric)
      expect(execute_trade['gross_net_stock_required']).to be_kind_of(Numeric)
    end
  end

  describe 'Validate Trade With Capital Stock Missing Exception' do
    let(:amount)  {'3000000'}
    let(:execute_trade) { get "/etransact_advances/validate_advance/#{member_id}/#{amount}/#{advance_type}/#{advance_term}/#{rate}/#{check_capstock}/#{signer}"; JSON.parse(last_response.body) }
    it 'should return expected result of validate trade' do
      expect(execute_trade['status']).to eq(['ExceptionError'])
      expect(execute_trade['authorized_amount']).to be_kind_of(Numeric)
      expect(execute_trade['exception_message']).to be_kind_of(String)
      expect(execute_trade['cumulative_stock_required']).to be_kind_of(Numeric)
      expect(execute_trade['current_trade_stock_required']).to be_kind_of(Numeric)
      expect(execute_trade['net_stock_required']).to be_kind_of(Numeric)
      expect(execute_trade['pre_trade_stock_required']).to be_kind_of(Numeric)
      expect(execute_trade['gross_amount']).to be_kind_of(Numeric)
      expect(execute_trade['gross_cumulative_stock_required']).to be_kind_of(Numeric)
      expect(execute_trade['gross_current_trade_stock_required']).to be_kind_of(Numeric)
      expect(execute_trade['gross_pre_trade_stock_required']).to be_kind_of(Numeric)
      expect(execute_trade['gross_net_stock_required']).to be_kind_of(Numeric)
    end
  end

  describe 'in the production environment' do
    let(:execute_trade) { post "/etransact_advances/execute_advance/#{member_id}/#{amount}/#{advance_type}/#{advance_term}/#{rate}/#{signer}"; JSON.parse(last_response.body) }
    before do
      allow(MAPI::ServiceApp).to receive(:environment).and_return(:production)
      allow(MAPI::Services::EtransactAdvances::ExecuteTrade).to receive(:check_total_daily_limit) {|env, amount, hash| hash }
    end
    describe 'agency for 1 week' do
      let(:advance_type)  {'agency'}
      let(:advance_term)  {'1week'}
      it 'should return result of execute trade', vcr: {cassette_name: 'execute_trade_service_agency_1week'} do
        expect(execute_trade['status']).to be_kind_of(Array)
        expect(execute_trade['confirmation_number']).to be_kind_of(String)
        expect(execute_trade['advance_rate']).to be_kind_of(Numeric)
        expect(execute_trade['advance_amount']).to be_kind_of(Numeric)
        expect(execute_trade['advance_term']).to be_kind_of(String)
        expect(execute_trade['advance_type']).to be_kind_of(String)
        expect(execute_trade['interest_day_count']).to be_kind_of(String)
        expect(execute_trade['payment_on']).to be_kind_of(String)
        expect(execute_trade['trade_date']).to be_kind_of(String)
        expect(execute_trade['funding_date']).to be_kind_of(String)
        expect(execute_trade['maturity_date']).to be_kind_of(String)
      end
    end
    describe 'agency for 1 year' do
      let(:advance_type)  {'agency'}
      let(:advance_term)  {'1year'}
      it 'should return result of execute trade', vcr: {cassette_name: 'execute_trade_service_agency_1year'} do
        expect(execute_trade['status']).to be_kind_of(Array)
        expect(execute_trade['confirmation_number']).to be_kind_of(String)
        expect(execute_trade['advance_rate']).to be_kind_of(Numeric)
        expect(execute_trade['advance_amount']).to be_kind_of(Numeric)
        expect(execute_trade['advance_term']).to be_kind_of(String)
        expect(execute_trade['advance_type']).to be_kind_of(String)
        expect(execute_trade['interest_day_count']).to be_kind_of(String)
        expect(execute_trade['payment_on']).to be_kind_of(String)
        expect(execute_trade['trade_date']).to be_kind_of(String)
        expect(execute_trade['funding_date']).to be_kind_of(String)
        expect(execute_trade['maturity_date']).to be_kind_of(String)
      end
    end
    describe 'whole overnight' do
      let(:advance_type)  {'whole'}
      let(:advance_term)  {'overnight'}
      it 'should return result of execute trade', vcr: {cassette_name: 'execute_trade_service_whole_overnight'} do
        expect(execute_trade['status']).to be_kind_of(Array)
        expect(execute_trade['confirmation_number']).to be_kind_of(String)
        expect(execute_trade['advance_rate']).to be_kind_of(Numeric)
        expect(execute_trade['advance_amount']).to be_kind_of(Numeric)
        expect(execute_trade['advance_term']).to be_kind_of(String)
        expect(execute_trade['advance_type']).to be_kind_of(String)
        expect(execute_trade['interest_day_count']).to be_kind_of(String)
        expect(execute_trade['payment_on']).to be_kind_of(String)
        expect(execute_trade['trade_date']).to be_kind_of(String)
        expect(execute_trade['funding_date']).to be_kind_of(String)
        expect(execute_trade['maturity_date']).to be_kind_of(String)
      end
    end
    describe 'capital stock exception' do
      let(:advance_type)  {'agency'}
      let(:advance_term)  {'1year'}
      let(:amount)  {'1000000'}
      let(:execute_trade) { get "/etransact_advances/validate_advance/#{member_id}/#{amount}/#{advance_type}/#{advance_term}/#{rate}/#{check_capstock}/#{signer}"; JSON.parse(last_response.body) }
      it 'should return result of execute trade', vcr: {cassette_name: 'execute_trade_service_capital_stock_purchase'} do
        expect(execute_trade['status']).to be_kind_of(Array)
        expect(execute_trade['authorized_amount']).to be_kind_of(Numeric)
        expect(execute_trade['exception_message']).to be_kind_of(String)
        expect(execute_trade['cumulative_stock_required']).to be_kind_of(Numeric)
        expect(execute_trade['current_trade_stock_required']).to be_kind_of(Numeric)
        expect(execute_trade['pre_trade_stock_required']).to be_kind_of(Numeric)
        expect(execute_trade['gross_amount']).to be_kind_of(Numeric)
        expect(execute_trade['gross_cumulative_stock_required']).to be_kind_of(Numeric)
        expect(execute_trade['gross_current_trade_stock_required']).to be_kind_of(Numeric)
        expect(execute_trade['gross_pre_trade_stock_required']).to be_kind_of(Numeric)
      end
    end
    it 'should return Internal Service Error, if execute trade service is unavailable', vcr: {cassette_name: 'execute_trade_service_unavailable'} do
      post "/etransact_advances/execute_advance/#{member_id}/#{amount}/#{advance_type}/#{advance_term}/#{rate}/#{signer}"
      expect(last_response.status).to eq(503)
    end
    it 'should return Internal Service Error, if execute mds service is unavailable', vcr: {cassette_name: 'execute_trade_market_data_service_unavailable'} do
      post "/etransact_advances/execute_advance/#{member_id}/#{amount}/#{advance_type}/#{advance_term}/#{rate}/#{signer}"
      expect(last_response.status).to eq(503)
    end
  end

  describe 'execute trade checks' do
    let(:fhlbsfresponse) { double('fhlbsfresponse', at_css: nil) }
    let(:response) { double('response', doc: nil) }
    let(:response_hash) { {foo: 'bar'} }

    describe 'the `check_capital_stock` method' do
      let(:check_capital_stock) { MAPI::Services::EtransactAdvances::ExecuteTrade::check_capital_stock(fhlbsfresponse, response, response_hash) }
      let(:capital_stock_exceptions) { double('exceptions', at_css: nil)}
      it 'returns the response_hash it was passed if the `fhlbsfresponse` has no content at `advanceValidation capitalStockValidations capitalStockValid`' do
        allow(fhlbsfresponse).to receive(:at_css).and_return(nil)
        expect(check_capital_stock).to eq(response_hash)
      end
      it 'returns the response_hash it was passed if the `fhlbsfresponse` is `true` at `advanceValidation capitalStockValidations capitalStockValid`' do
        allow(fhlbsfresponse).to receive(:at_css).with('advanceValidation capitalStockValidations capitalStockValid').and_return(double('some xml', content: 'true'))
        expect(check_capital_stock).to eq(response_hash)
      end
      describe 'when the credit is not valid' do
        before do
          allow(fhlbsfresponse).to receive(:at_css).and_return(double('some xml', content: 'false'))
          allow(response).to receive(:doc).and_return(double('doc', xpath: capital_stock_exceptions))
        end
        it 'returns a hash that still has the same key-value pairs as the response_hash it was passed' do
          expect(check_capital_stock[:foo]).to eq(response_hash[:foo])
        end
        it 'returns a hash with a `status` array that includes whatever was in the `status` array for the response_hash' do
          response_hash = {'status' => ['foo']}
          check_capital_stock = MAPI::Services::EtransactAdvances::ExecuteTrade::check_capital_stock(fhlbsfresponse, response, response_hash)
          expect(check_capital_stock['status']).to include('foo')
        end
        it 'returns a hash with a `status` array that includes \'GrossUpError\' when the capital_stock_exceptions do not include a `exception GrossUp` node' do
          allow(capital_stock_exceptions).to receive(:at_css).with('exception GrossUp').and_return(false)
          expect(check_capital_stock['status']).to include('GrossUpError')
        end
        it 'returns a hash with a `status` array that includes \'ExceptionError\' when the capital_stock_exceptions includes a `exception GrossUp` node but not an `exception` node' do
          allow(capital_stock_exceptions).to receive(:at_css).with('exception GrossUp').and_return(true)
          allow(capital_stock_exceptions).to receive(:at_css).with('exception').and_return(false)
          expect(check_capital_stock['status']).to include('ExceptionError')
        end
        it 'returns a hash with a `status` array that includes \'CapitalStockError\' when the capital_stock_exceptions includes a `exception GrossUp` node znd an `exception` node' do
          allow(capital_stock_exceptions).to receive(:at_css).with('exception GrossUp').and_return(true)
          allow(capital_stock_exceptions).to receive(:at_css).with('exception').and_return(true)
          expect(check_capital_stock['status']).to include('CapitalStockError')
        end
        describe 'current stock attributes' do
          let(:cumulative_stock) { double('cumulative stock', :+ => 0) }
          let(:cumulative_stock_arg) { double('cumulative_stock arg', to_i: cumulative_stock) }
          let(:current_trade_stock) { double('current_trade_stock') }
          let(:pre_trade_stock) { double('pre_trade_stock', :> => true) }
          let(:pre_trade_stock_arg) { double('pre_trade_stock arg', to_i: pre_trade_stock) }

          before do
            allow(capital_stock_exceptions).to receive(:at_css).with('exception cumulativeStockRequired').and_return(double('xml node', content: cumulative_stock_arg))
            allow(MAPI::Services::EtransactAdvances::ExecuteTrade).to receive(:round_up_stock).with(cumulative_stock).ordered.and_return(cumulative_stock)
            allow(MAPI::Services::EtransactAdvances::ExecuteTrade).to receive(:round_up_stock).with(0).ordered.and_return(0)
            allow(capital_stock_exceptions).to receive(:at_css).with('exception currentTradeStockRequired').and_return(double('xml node', content: double('another node', to_i: current_trade_stock)))
            allow(capital_stock_exceptions).to receive(:at_css).with('exception preTradeStockRequired').and_return(double('xml node', content: pre_trade_stock_arg))
            allow(MAPI::Services::EtransactAdvances::ExecuteTrade).to receive(:round_down_stock).with(pre_trade_stock).ordered.and_return(pre_trade_stock)
            allow(MAPI::Services::EtransactAdvances::ExecuteTrade).to receive(:round_down_stock).with(0).ordered.and_return(0)
          end
          it 'returns a hash with an `authorized_amount`' do
            authorized_amount = double('authorized amount')
            allow(capital_stock_exceptions).to receive(:at_css).with('authorizedAmount').and_return(double('xml node', content: double('another node', to_i: authorized_amount)))
            expect(check_capital_stock['authorized_amount']).to eq(authorized_amount)
          end
          it 'returns a hash with a `authorized_amount` set to 0 if there is no `authorizedAmount`' do
            expect(check_capital_stock['authorized_amount']).to eq(0)
          end
          it 'returns a hash with an `exception_message`' do
            exception_message = double('exception_message')
            allow(capital_stock_exceptions).to receive(:at_css).with('exception exceptionMessage').and_return(double('xml node', content: exception_message))
            expect(check_capital_stock['exception_message']).to eq(exception_message)
          end
          it 'returns a hash with an empty string for `exception_message` if there is no `exceptionMessage`' do
            expect(check_capital_stock['exception_message']).to eq('')
          end
          it 'returns a hash with `cumulative_stock_required`' do
            expect(check_capital_stock['cumulative_stock_required']).to eq(cumulative_stock)
          end
          it 'returns a hash with `cumulative_stock_required` set to 0 if there is no `exception cumulativeStockRequired`' do
            allow(capital_stock_exceptions).to receive(:at_css).with('exception cumulativeStockRequired').and_return(nil)
            expect(check_capital_stock['cumulative_stock_required']).to eq(0)
          end
          it 'returns a hash with `current_trade_stock_required`' do
            expect(check_capital_stock['current_trade_stock_required']).to eq(current_trade_stock)
          end
          it 'returns a hash with `current_trade_stock_required` set to 0 if there is no `exception currentTradeStockRequired`' do
            allow(capital_stock_exceptions).to receive(:at_css).with('exception currentTradeStockRequired').and_return(nil)
            expect(check_capital_stock['current_trade_stock_required']).to eq(0)
          end
          it 'returns a hash with `pre_trade_stock_required`' do
            expect(check_capital_stock['pre_trade_stock_required']).to eq(pre_trade_stock)
          end
          it 'returns a hash with `pre_trade_stock_required` set to 0 if there is no `exception preTradeStockRequired`' do
            allow(capital_stock_exceptions).to receive(:at_css).with('exception preTradeStockRequired').and_return(nil)
            expect(check_capital_stock['pre_trade_stock_required']).to eq(0)
          end
          it 'returns a hash with a `net_stock_required` that is equal to `cumulative_stock_required` if `pre_trade_stock_required` is greater than 0' do
            expect(check_capital_stock['net_stock_required']).to eq(cumulative_stock)
          end
          it 'returns a hash with a `net_stock_required` that is equal to `cumulative_stock_required` plus `pre_trade_stock_required` if `pre_trade_stock_required` is less than 0' do
            net_stock = double('net stock')
            allow(pre_trade_stock).to receive(:>).and_return(false)
            allow(cumulative_stock).to receive(:+).with(pre_trade_stock).and_return(net_stock)
            expect(check_capital_stock['net_stock_required']).to eq(net_stock)
          end
        end
        describe 'gross up stock attributes' do
          let(:gross_amount) { double('gross amount') }
          let(:gross_cumulative_stock) { double('gross cumulative stock', :+ => 0) }
          let(:gross_cumulative_stock_arg) { double('gross_cumulative_stock arg', to_i: gross_cumulative_stock) }
          let(:gross_current_trade_stock) { double('gross_current_trade_stock') }
          let(:gross_pre_trade_stock) { double('gross_pre_trade_stock', :> => true) }
          let(:gross_pre_trade_stock_arg) { double('gross_pre_trade_stock arg', to_i: gross_pre_trade_stock) }

          before do
            allow(capital_stock_exceptions).to receive(:at_css).with('exception GrossUp grossAmount').and_return(double('xml node', content: double('another node', to_i: gross_amount)))
            allow(capital_stock_exceptions).to receive(:at_css).with('exception GrossUp cumulativeStockRequired').and_return(double('xml node', content: gross_cumulative_stock_arg))
            allow(MAPI::Services::EtransactAdvances::ExecuteTrade).to receive(:round_up_stock).with(gross_cumulative_stock).ordered.and_return(gross_cumulative_stock)
            allow(MAPI::Services::EtransactAdvances::ExecuteTrade).to receive(:round_up_stock).with(0).ordered.and_return(0)
            allow(capital_stock_exceptions).to receive(:at_css).with('exception GrossUp currentTradeStockRequired').and_return(double('xml node', content: double('another node', to_i: gross_current_trade_stock)))
            allow(capital_stock_exceptions).to receive(:at_css).with('exception GrossUp preTradeStockRequired').and_return(double('xml node', content: gross_pre_trade_stock_arg))
            allow(MAPI::Services::EtransactAdvances::ExecuteTrade).to receive(:round_down_stock).with(gross_pre_trade_stock).ordered.and_return(gross_pre_trade_stock)
            allow(MAPI::Services::EtransactAdvances::ExecuteTrade).to receive(:round_down_stock).with(0).ordered.and_return(0)
          end

          it 'returns a hash with a `gross_amount`' do
            expect(check_capital_stock['gross_amount']).to eq(gross_amount)
          end
          it 'returns a hash with a `gross_amount` set to 0 if there is no `exception GrossUp grossAmount`' do
            allow(capital_stock_exceptions).to receive(:at_css).with('exception GrossUp grossAmount').and_return(nil)
            expect(check_capital_stock['gross_amount']).to eq(0)
          end
          it 'returns a hash with `gross_cumulative_stock_required`' do
            expect(check_capital_stock['gross_cumulative_stock_required']).to eq(gross_cumulative_stock)
          end
          it 'returns a hash with `cumulative_stock_required` set to 0 if there is no `exception GrossUp cumulativeStockRequired`' do
            allow(capital_stock_exceptions).to receive(:at_css).with('exception GrossUp cumulativeStockRequired').and_return(nil)
            expect(check_capital_stock['cumulative_stock_required']).to eq(0)
          end
          it 'returns a hash with `gross_pre_trade_stock_required`' do
            expect(check_capital_stock['gross_pre_trade_stock_required']).to eq(gross_pre_trade_stock)
          end
          it 'returns a hash with `gross_pre_trade_stock_required` set to 0 if there is no `exception GrossUp preTradeStockRequired`' do
            allow(capital_stock_exceptions).to receive(:at_css).with('exception GrossUp preTradeStockRequired').and_return(nil)
            expect(check_capital_stock['cumulative_stock_required']).to eq(0)
          end
          it 'returns a hash with a `gross_net_stock_required` that is equal to `gross_cumulative_stock_required` if `gross_pre_trade_stock_required` is greater than 0' do
            expect(check_capital_stock['gross_net_stock_required']).to eq(gross_cumulative_stock)
          end
          it 'returns a hash with a `gross_net_stock_required` that is equal to `gross_cumulative_stock_required` plus `gross_pre_trade_stock_required` if `gross_pre_trade_stock_required` is less than 0' do
            gross_net_stock = double('net stock')
            allow(gross_pre_trade_stock).to receive(:>).and_return(false)
            allow(gross_cumulative_stock).to receive(:+).with(gross_pre_trade_stock).and_return(gross_net_stock)
            expect(check_capital_stock['gross_net_stock_required']).to eq(gross_net_stock)
          end
        end
      end
    end

    describe 'the `check_credit` method' do
      let(:check_credit) { MAPI::Services::EtransactAdvances::ExecuteTrade::check_credit(fhlbsfresponse, response, response_hash) }
      let(:credit_exceptions) { double('exceptions', at_css: nil)}
      it 'returns the response_hash it was passed if the `fhlbsfresponse` has no content at `advanceValidation creditValidations creditValid`' do
        allow(fhlbsfresponse).to receive(:at_css).and_return(nil)
        expect(check_credit).to eq(response_hash)
      end
      it 'returns the response_hash it was passed if the `fhlbsfresponse` is `true` at `advanceValidation creditValidations creditValid`' do
        allow(fhlbsfresponse).to receive(:at_css).with('advanceValidation creditValidations creditValid').and_return(double('some xml', content: 'true'))
        expect(check_credit).to eq(response_hash)
      end
      describe 'when the credit is not valid' do
        before do
          allow(fhlbsfresponse).to receive(:at_css).and_return(double('some xml', content: 'false'))
          allow(response).to receive(:doc).and_return(double('doc', xpath: credit_exceptions))
        end
        it 'returns a hash that still has the same key-value pairs as the response_hash it was passed' do
          expect(check_credit[:foo]).to eq(response_hash[:foo])
        end
        it 'returns a hash with a `status` array that includes \'CreditError\'' do
          expect(check_credit['status']).to include('CreditError')
        end
        it 'returns a hash with a `status` array that includes whatever was in the `status` array for the response_hash' do
          response_hash = {'status' => ['foo']}
          check_credit = MAPI::Services::EtransactAdvances::ExecuteTrade::check_credit(fhlbsfresponse, response, response_hash)
          expect(check_credit['status']).to include('foo')
        end
        it 'returns a hash with a `credit_max_amount`' do
          max_amount = double('max amount')
          allow(credit_exceptions).to receive(:at_css).with('maxAmount').and_return(double('xml node', content: max_amount))
          expect(check_credit['credit_max_amount']).to eq(max_amount)
        end
      end
    end

    describe 'the `check_collateral` method' do
      let(:check_collateral) { MAPI::Services::EtransactAdvances::ExecuteTrade::check_collateral(fhlbsfresponse, response, response_hash) }
      let(:collateral_exceptions) { double('exceptions', at_css: nil)}
      it 'returns the response_hash it was passed if the `fhlbsfresponse` has no content at `advanceValidation collateralValidations collateralValid`' do
        allow(fhlbsfresponse).to receive(:at_css).and_return(nil)
        expect(check_collateral).to eq(response_hash)
      end
      it 'returns the response_hash it was passed if the `fhlbsfresponse` is `true` at `advanceValidation collateralValidations collateralValid`' do
        allow(fhlbsfresponse).to receive(:at_css).with('advanceValidation collateralValidations collateralValid').and_return(double('some xml', content: 'true'))
        expect(check_collateral).to eq(response_hash)
      end
      describe 'when the collateral is not valid' do
        before do
          allow(fhlbsfresponse).to receive(:at_css).and_return(double('some xml', content: 'false'))
          allow(response).to receive(:doc).and_return(double('doc', xpath: collateral_exceptions))
        end
        it 'returns a hash that still has the same key-value pairs as the response_hash it was passed' do
          expect(check_collateral[:foo]).to eq(response_hash[:foo])
        end
        it 'returns a hash with a `status` array that includes \'CollateralError\'' do
          expect(check_collateral['status']).to include('CollateralError')
        end
        it 'returns a hash with a `status` array that includes whatever was in the `status` array for the response_hash' do
          response_hash = {'status' => ['foo']}
          check_collateral = MAPI::Services::EtransactAdvances::ExecuteTrade::check_collateral(fhlbsfresponse, response, response_hash)
          expect(check_collateral['status']).to include('foo')
        end
        it 'returns a hash with a `collateral_max_amount`' do
          max_amount = double('max amount')
          allow(collateral_exceptions).to receive(:at_css).with('maxAmount').and_return(double('xml node', content: max_amount))
          expect(check_collateral['collateral_max_amount']).to eq(max_amount)
        end
        it 'returns a hash with a `collateral_authorized_amount`' do
          collateral_authorized_amount = double('collateral authorized amount')
          allow(collateral_exceptions).to receive(:at_css).with('authorizedAmount').and_return(double('xml node', content: collateral_authorized_amount))
          expect(check_collateral['collateral_authorized_amount']).to eq(collateral_authorized_amount)
        end
      end
    end

    [:development, :test, :production].each do |env|
      describe "the `check_total_daily_limit` method in the #{env} environment" do
        let(:advance_amount) { rand(100000..9999999)}
        let(:total_daily_limit) { double('total daily limit')}
        let(:settings) { double('settings', :'[]' => nil) }
        let(:local_total_daily_limit) { MAPI::Services::EtransactAdvances::ExecuteTrade::LOCAL_TOTAL_DAILY_LIMIT }
        let(:check_advance) { MAPI::Services::EtransactAdvances::ExecuteTrade.check_total_daily_limit(env, advance_amount, response_hash)}
        before do
          allow(MAPI::Services::Member::TradeActivity).to receive(:current_daily_total).and_return( advance_amount )
          allow(settings).to receive(:'[]').with('shareholder_web_daily_limit').and_return(total_daily_limit)
          allow(MAPI::Services::EtransactAdvances::Settings).to receive(:settings).and_return(settings)
        end
        it 'returns a hash with a `status` array that includes whatever was in the `status` array for the response_hash' do
          response_hash = {'status' => ['foo']}
          allow(total_daily_limit).to receive(:to_f).and_return(advance_amount.to_f)
          check_advance = MAPI::Services::EtransactAdvances::ExecuteTrade.check_total_daily_limit(app, advance_amount, response_hash)
          expect(check_advance['status']).to include('foo')
        end
        it 'returns a hash with a `status` array that includes \'ExceedsTotalDailyLimitError\' if the requested advance plus the current daily total exceeds the limit set by FHLB' do
          daily_limit = 2 * advance_amount - 100
          allow(total_daily_limit).to receive(:to_f).and_return(daily_limit.to_f)
          expect(check_advance['status']).to include('ExceedsTotalDailyLimitError')
        end
        it 'returns the response_hash it was passed if the requested advance plus the current daily total does not exceed the limit set by FHLB' do
          daily_limit = 2 * advance_amount + 100
          allow(total_daily_limit).to receive(:to_f).and_return(daily_limit.to_f)
          expect(check_advance).to eq(response_hash)
        end
        it 'raises an error if the settings endpoint returns nil' do
          allow(MAPI::Services::EtransactAdvances::Settings).to receive(:settings).and_return(nil)
          expect{check_advance}.to raise_error
        end
      end
    end
  end
  
  describe 'the `execute_trade` method' do
    let(:app) { double('app', settings: double('settings', environment: nil)) }
    let(:today) { Time.zone.today }
    let(:built_message) { [double('message'), {}] }
    let(:execute_trade) { MAPI::Services::EtransactAdvances::ExecuteTrade.execute_trade(app, member_id, double('instrument'), 'EXECUTE', 234234, advance_term, advance_type, rate, false, double('signer'), double('markup'), double('blended_cost_of_funds'), double('cost_of_funds'), double('benchmark_rate')) }
    before do
      allow(MAPI::Services::EtransactAdvances::ExecuteTrade).to receive(:get_maturity_date)
      allow(MAPI::Services::EtransactAdvances::ExecuteTrade).to receive(:init_execute_trade_connection)
      allow(MAPI::Services::EtransactAdvances::ExecuteTrade).to receive(:build_message).and_return(built_message)
    end
    
    it 'returns today\'s date as a string for `trade_date`' do
      expect(execute_trade['trade_date']).to eq(today)
    end
    it 'returns today\'s date as a string for `funding_date`' do
      expect(execute_trade['funding_date']).to eq(today)
    end
  end
end