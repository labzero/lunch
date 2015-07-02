require 'spec_helper'
require 'date'

describe MAPI::ServiceApp do

  let(:member_id) {750}
  let(:amount)  {'100'}
  let(:advance_type)  {'agency'}
  let(:advance_term)  {'1week'}
  let(:rate)  {0.17}
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
    let(:overnight_response) {{:payment_at=>'Overnight', :advance_payment_frequency=>{'v13:frequency'=>1, 'v13:frequencyUnit'=>'T'}, :advance_payment_day_of_month=>0}}
    let(:open_response) {{:payment_at=>'End Of Month', :advance_payment_frequency=>{'v13:frequency'=>1, 'v13:frequencyUnit'=>'M'}, :advance_payment_day_of_month=>31}}
    let(:whole_1_week_response) {{:payment_at=>'Maturity', :advance_payment_frequency=>{'v13:frequency'=>1, 'v13:frequencyUnit'=>'T'}, :advance_payment_day_of_month=>0}}
    let(:next_month_response) {{:payment_at=>'Maturity', :advance_payment_frequency=>{'v13:frequency'=>1, 'v13:frequencyUnit'=>'M'}, :advance_payment_day_of_month=>0}}
    it 'should return overnight payment info' do
      expect(MAPI::Services::EtransactAdvances::ExecuteTrade.get_payment_info('overnight', 'whole', Date.today, Date.today)).to eq(overnight_response)
    end
    it 'should return open payment info' do
      expect(MAPI::Services::EtransactAdvances::ExecuteTrade.get_payment_info('open', 'whole', Date.today, Date.today)).to eq(open_response)
    end
    it 'should return whole loan 1 week payment info' do
      expect(MAPI::Services::EtransactAdvances::ExecuteTrade.get_payment_info('1week', 'whole', Date.new(2015,6,7), Date.new(2015,6,7))).to eq(whole_1_week_response)
    end
    it 'should return a next month payment info if a whole loan is excuted on the last day of the month' do
      expect(MAPI::Services::EtransactAdvances::ExecuteTrade.get_payment_info('1week', 'whole', Date.new(2015,6,30), Date.new(2015,6,30))).to eq(next_month_response)
    end
    it 'should return next month payment info' do
      expect(MAPI::Services::EtransactAdvances::ExecuteTrade.get_payment_info('1week', 'whole', Date.today, Date.today+32.days)).to eq(next_month_response)
    end
  end

  describe 'get_advance_rate_schedule' do
    let(:rate) { double('rate') }
    let(:day_count) { double('day_count') }
    let(:overnight_response) {
      {
        'v13:initialRate'=>rate,
        'v13:floatingRateSchedule'=>{
          'v13:floatingPeriod'=>{
            'v13:startDate'=>Date.today,
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
        'v13:initialRate'=>rate,
        'v13:fixedRateSchedule'=>{
          'v13:step'=>{
            'v13:startDate'=>Date.today,
            'v13:endDate'=>Date.today,
            'v13:rate'=>rate,
            'v13:dayCountBasis'=>day_count
          }
        },
        'v13:roundingConvention'=>'NEAREST'
      }
    }
    it 'should return overnight advance rate schedule' do
      expect(MAPI::Services::EtransactAdvances::ExecuteTrade.get_advance_rate_schedule('overnight', rate, day_count, Date.today, Date.today)).to eq(overnight_response)
    end
    it 'should return week advance rate schedule' do
      expect(MAPI::Services::EtransactAdvances::ExecuteTrade.get_advance_rate_schedule('1week', rate, day_count, Date.today, Date.today)).to eq(week_response)
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
      expect(execute_trade['status']).to be_kind_of(String)
      expect(execute_trade['confirmation_number']).to be_kind_of(String)
      expect(execute_trade['advance_rate']).to be_kind_of(Numeric)
      expect(execute_trade['advance_amount']).to be_kind_of(Numeric)
      expect(execute_trade['advance_term']).to be_kind_of(String)
      expect(execute_trade['advance_type']).to be_kind_of(String)
      expect(execute_trade['interest_day_count']).to be_kind_of(String)
      expect(execute_trade['payment_on']).to be_kind_of(String)
      expect(execute_trade['funding_date']).to be_kind_of(String)
      expect(execute_trade['maturity_date']).to be_kind_of(String)
    end
  end
  describe 'Validate Trade' do
    let(:execute_trade) { get "/etransact_advances/validate_advance/#{member_id}/#{amount}/#{advance_type}/#{advance_term}/#{rate}/#{signer}"; JSON.parse(last_response.body) }
    it 'should return expected result of validate trade' do
      expect(execute_trade['status']).to be_kind_of(String)
      expect(execute_trade['confirmation_number']).to be_kind_of(String)
      expect(execute_trade['advance_rate']).to be_kind_of(Numeric)
      expect(execute_trade['advance_amount']).to be_kind_of(Numeric)
      expect(execute_trade['advance_term']).to be_kind_of(String)
      expect(execute_trade['advance_type']).to be_kind_of(String)
      expect(execute_trade['interest_day_count']).to be_kind_of(String)
      expect(execute_trade['payment_on']).to be_kind_of(String)
      expect(execute_trade['funding_date']).to be_kind_of(String)
      expect(execute_trade['maturity_date']).to be_kind_of(String)
    end
  end
  describe 'in the production environment' do
    before do
      expect(MAPI::ServiceApp).to receive(:environment).at_least(1).and_return(:production)
    end
    describe 'agency for 1 week' do
      let(:advance_type)  {'agency'}
      let(:advance_term)  {'1week'}
      let(:execute_trade) { post "/etransact_advances/execute_advance/#{member_id}/#{amount}/#{advance_type}/#{advance_term}/#{rate}/#{signer}"; JSON.parse(last_response.body) }
      it 'should return result of execute trade', vcr: {cassette_name: 'execute_trade_service_agency_1week'} do
        expect(execute_trade['status']).to be_kind_of(String)
        expect(execute_trade['confirmation_number']).to be_kind_of(String)
        expect(execute_trade['advance_rate']).to be_kind_of(Numeric)
        expect(execute_trade['advance_amount']).to be_kind_of(Numeric)
        expect(execute_trade['advance_term']).to be_kind_of(String)
        expect(execute_trade['advance_type']).to be_kind_of(String)
        expect(execute_trade['interest_day_count']).to be_kind_of(String)
        expect(execute_trade['payment_on']).to be_kind_of(String)
        expect(execute_trade['funding_date']).to be_kind_of(String)
        expect(execute_trade['maturity_date']).to be_kind_of(String)
      end
    end
    describe 'agency for 1 year' do
      let(:advance_type)  {'agency'}
      let(:advance_term)  {'1year'}
      let(:execute_trade) { post "/etransact_advances/execute_advance/#{member_id}/#{amount}/#{advance_type}/#{advance_term}/#{rate}/#{signer}"; JSON.parse(last_response.body) }
      it 'should return result of execute trade', vcr: {cassette_name: 'execute_trade_service_agency_1year'} do
        expect(execute_trade['status']).to be_kind_of(String)
        expect(execute_trade['confirmation_number']).to be_kind_of(String)
        expect(execute_trade['advance_rate']).to be_kind_of(Numeric)
        expect(execute_trade['advance_amount']).to be_kind_of(Numeric)
        expect(execute_trade['advance_term']).to be_kind_of(String)
        expect(execute_trade['advance_type']).to be_kind_of(String)
        expect(execute_trade['interest_day_count']).to be_kind_of(String)
        expect(execute_trade['payment_on']).to be_kind_of(String)
        expect(execute_trade['funding_date']).to be_kind_of(String)
        expect(execute_trade['maturity_date']).to be_kind_of(String)
      end
    end
    describe 'whole overnight' do
      let(:advance_type)  {'whole'}
      let(:advance_term)  {'overnight'}
      let(:execute_trade) { post "/etransact_advances/execute_advance/#{member_id}/#{amount}/#{advance_type}/#{advance_term}/#{rate}/#{signer}"; JSON.parse(last_response.body) }
      it 'should return result of execute trade', vcr: {cassette_name: 'execute_trade_service_whole_overnight'} do
        expect(execute_trade['status']).to be_kind_of(String)
        expect(execute_trade['confirmation_number']).to be_kind_of(String)
        expect(execute_trade['advance_rate']).to be_kind_of(Numeric)
        expect(execute_trade['advance_amount']).to be_kind_of(Numeric)
        expect(execute_trade['advance_term']).to be_kind_of(String)
        expect(execute_trade['advance_type']).to be_kind_of(String)
        expect(execute_trade['interest_day_count']).to be_kind_of(String)
        expect(execute_trade['payment_on']).to be_kind_of(String)
        expect(execute_trade['funding_date']).to be_kind_of(String)
        expect(execute_trade['maturity_date']).to be_kind_of(String)
      end
    end
    it 'should return Internal Service Error, if execute trade service is unavailable', vcr: {cassette_name: 'execute_trade_service_unavailable'} do
      post "/etransact_advances/execute_advance/#{member_id}/#{amount}/#{advance_type}/#{advance_term}/#{rate}/#{signer}"
      expect(last_response.status).to eq(503)
    end
  end
end