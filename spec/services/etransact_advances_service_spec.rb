require 'rails_helper'

describe EtransactAdvancesService do
  let(:request) { instance_double(ActionDispatch::Request, uuid: '12345', session: double('A Session', :[] => nil), member_id: nil, member_name: nil) }
  subject { EtransactAdvancesService.new(request) }
  it { expect(subject).to respond_to(:etransact_active?) }
  describe '`etransact_active?` method', :vcr do
    let(:call_method) {subject.etransact_active?(status_object)}
    let(:status_object) { {etransact_advances_status: 'my_status'} }
    it 'returns the value of `etransact_advances_status` from the status object' do
      expect(call_method).to eq('my_status')
    end
    it 'should call EtransactAdvancesService#status if no status object is provided' do
      expect(subject).to receive(:status)
      subject.etransact_active?
    end
    it 'should return false if EtransactAdvancesService#status returns nil' do
      allow(subject).to receive(:status).and_return(nil)
      expect(subject.etransact_active?).to be(false)
    end
    it 'should not call EtransactAdvancesService#status if a status object is provided' do
      expect(subject).to_not receive(:status)
      call_method
    end
    it 'should use the supplied status object' do
      expect(status_object).to receive(:[]).with(:etransact_advances_status).and_return(status_object[:etransact_advances_status])
      call_method
    end
    it 'should use the returned status object if none is passed' do
      expect(status_object).to receive(:[]).with(:etransact_advances_status).and_return(status_object[:etransact_advances_status])
      allow(subject).to receive(:status).and_return(status_object)
      subject.etransact_active?
    end
  end
  describe '`signer_full_name` method', :vcr do
    let(:signer) {'signer'}
    let(:signer_full_name) {subject.signer_full_name(signer)}
    it 'should return signer full name' do
      expect(signer_full_name).to be_kind_of(String)
    end
    it 'should return nil if there was an API error' do
      expect_any_instance_of(RestClient::Resource).to receive(:get).and_raise(RestClient::InternalServerError)
      expect(signer_full_name).to eq(nil)
    end
    it 'should return nil if there was a connection error' do
      expect_any_instance_of(RestClient::Resource).to receive(:get).and_raise(Errno::ECONNREFUSED)
      expect(signer_full_name).to eq(nil)
    end
  end

  describe '`quick_advance_validate` method', :vcr do
    let(:signer) {'signer'}
    let(:member_id) {750}
    let(:advance_term) {'someterm'}
    let(:advance_type) {'sometype'}
    let(:advance_rate) {'0.17'}
    let(:check_capstock) {true}
    let(:amount) { 100 }
    let(:maturity_date) { "2016-03-11".to_date }
    let(:funding_date) { Time.zone.today + rand(1..2).days }
    let(:allow_grace_period) { true }
    let(:call_method) { subject.quick_advance_validate(member_id, amount, advance_type, advance_term, advance_rate, check_capstock, signer, maturity_date, allow_grace_period, nil) }
    let(:call_method_funding_date) { subject.quick_advance_validate(member_id, amount, advance_type, advance_term, advance_rate, check_capstock, signer, maturity_date, allow_grace_period, funding_date) }
    before do
      allow(subject).to receive(:calypso_error_handler).and_return(nil)
    end

    it 'should return a hash back' do
      expect(call_method).to be_kind_of(Hash)
    end
    it 'calls `get_hash`' do
      expect(subject).to receive(:get_hash).with(:quick_advance_validate, "etransact_advances/validate_advance/#{member_id}/#{amount}/#{advance_type}/#{advance_term}/#{advance_rate}/#{check_capstock}/#{signer}/#{maturity_date.iso8601}", allow_grace_period: allow_grace_period, funding_date: nil)
      call_method
    end
    it 'calls `get_hash` with funding_date' do
      expect(subject).to receive(:get_hash).with(:quick_advance_validate, "etransact_advances/validate_advance/#{member_id}/#{amount}/#{advance_type}/#{advance_term}/#{advance_rate}/#{check_capstock}/#{signer}/#{maturity_date.iso8601}", allow_grace_period: allow_grace_period, funding_date: funding_date.iso8601)
      call_method_funding_date
    end
    it 'defaults `allow_grace_period` to false' do
      expect(subject).to receive(:get_hash).with(:quick_advance_validate, anything, allow_grace_period: false, funding_date: nil)
      subject.quick_advance_validate(member_id, amount, advance_type, advance_term, advance_rate, check_capstock, signer, maturity_date, false, nil)
    end
    it 'returns the results of `get_hash`' do
      result = double('A Result')
      allow(subject).to receive(:get_hash).and_return(result)
      expect(call_method).to be(result)
    end
    it 'should URL encode the signer' do
      allow(subject).to receive(:get_hash)
      expect(URI).to receive(:escape).with(signer)
      call_method
    end
    it 'passes a `calypso_error_handler` to the `get_hash` method' do
      error_handler = -> (n, m, e) {}
      allow(subject).to receive(:calypso_error_handler).with(member_id).and_return(error_handler)
      allow(subject).to receive(:get_hash).with(anything, anything, anything) do |*args, &block|
        expect(block).to be(error_handler)
      end
      call_method
    end
  end

  describe '`quick_advance_execute` method' do
    let(:signer) { double('signer') }
    let(:member_id) { double('member id') }
    let(:advance_term) { double('term') }
    let(:advance_type) { double('type') }
    let(:advance_rate) { double('rate') }
    let(:amount) { double('amount') }
    let(:iso_date) { double('iso8601 date') }
    let(:maturity_date) { double('date string', to_date: double('date', iso8601: iso_date)) }
    let(:allow_grace_period) { double('Allow Grace Period') }
    let(:error_handler) { double('error handler') }
    let(:post_body) {
      {
        amount: amount,
        advance_type: advance_type,
        advance_term: advance_term,
        rate: advance_rate,
        signer: signer,
        maturity_date: iso_date,
        allow_grace_period: allow_grace_period,
        funding_date: nil
      }
    }
    let(:post_response) { double('response from post_hash', :[]= => nil) }
    let(:now) { double('now') }
    let(:call_method) { subject.quick_advance_execute(member_id, amount, advance_type, advance_term, advance_rate, signer, maturity_date, allow_grace_period, nil) }

    before do
      allow(subject).to receive(:calypso_error_handler)
    end

    describe 'calling the `post_hash` method' do
      it 'passes :quick_advance_execute as the method name' do
        expect(subject).to receive(:post_hash).with(:quick_advance_execute, anything, anything)
        call_method
      end
      it 'passes the correct MAPI endpoint' do
        expect(subject).to receive(:post_hash).with(anything, "etransact_advances/execute_advance/#{member_id}", anything)
        call_method
      end
      it 'passes the body of the post request' do
        expect(subject).to receive(:post_hash).with(anything, anything, post_body)
        call_method
      end
      it 'defaults `allow_grace_period` to false' do
        post_body[:allow_grace_period] = false
        post_body[:funding_date] = nil
        expect(subject).to receive(:post_hash).with(anything, anything, post_body)
        subject.quick_advance_execute(member_id, amount, advance_type, advance_term, advance_rate, signer, maturity_date, false, nil)
      end
    end
    it 'returns the result of the `post_hash` call' do
      allow(subject).to receive(:post_hash).and_return(post_response)
      expect(call_method).to eq(post_response)
    end
    it 'should set initiated_at' do
      allow(subject).to receive(:post_hash).and_return({})
      allow(Time.zone).to receive(:now).and_return(double('now', to_datetime: now))
      expect(call_method[:initiated_at]).to eq(now)
    end
    it 'passes a `calypso_error_handler` to the `post_hash` method' do
      error_handler = -> (n, m, e) {}
      allow(subject).to receive(:calypso_error_handler).with(member_id).and_return(error_handler)
      allow(subject).to receive(:post_hash).with(anything, anything, anything) do |*args, &block|
        expect(block).to be(error_handler)
        nil
      end
      call_method
    end
  end

  describe '`check_limits` method' do
    m_id = 750
    l_amount =  Random.rand(0..10000)
    let(:low_days) { rand(0..9999) }
    let(:high_days) { low_days + rand(1..9999) }
    let(:member_id) {m_id}
    let(:advance_term) {'someterm'}
    let(:low_amount) { l_amount }
    let(:amount) { Random.rand(100000..1000000) }
    let(:high_amount) { Random.rand(10000000..99999999) }
    let(:cumulative_amount) { Random.rand(1000000..9999998) }
    let(:low_check_limits) {subject.check_limits(member_id, low_amount, advance_term)}
    let(:check_limits) {subject.check_limits(member_id, amount, advance_term)}
    let(:high_check_limits) {subject.check_limits(member_id, high_amount, advance_term)}
    let(:cumulative_check_limits) {subject.check_limits(member_id, cumulative_amount, advance_term)}
    let(:low_check)  {{:status=>'low', :low=>amount, :high=>high_amount}}
    let(:pass_result) {{:status => 'pass', :low => amount, :high => high_amount}}
    let(:high_result) {{:status => 'high', :low => amount, :high => high_amount}}
    let(:limits_response) {[{"WHOLE_LOAN_ENABLED" => "N","SBC_AGENCY_ENABLED" => "Y", "SBC_AAA_ENABLED" => "Y", "SBC_AA_ENABLED" => "Y", "LOW_DAYS_TO_MATURITY" => low_days,
                             "HIGH_DAYS_TO_MATURITY" => high_days, "MIN_ONLINE_ADVANCE" => amount, "TERM_DAILY_LIMIT" => high_amount, "PRODUCT_TYPE" => "VRC",
                             "END_TIME" => "1700", "OVERRIDE_END_DATE" => "2006-01-01", "OVERRIDE_END_TIME" => "1700"}]}
    let(:settings_response) {{"shareholder_total_daily_limit" => cumulative_amount}}
    let(:todays_advances_amount_response) {rand(1..9)}
    let(:todays_cumulative_advances_amount_response) {rand(1..9)}
    it_should_behave_like 'a MAPI backed service object method', :check_limits, [m_id, l_amount, '1Week']
    describe 'without service exceptions' do
      before do
        allow(subject).to receive(:get_days_to_maturity).with(advance_term, nil).and_return(low_days)
        allow(subject).to receive(:get_days_to_maturity).with(nil, nil).and_return(nil)
        allow(subject).to receive(:todays_advances_amount).with(member_id, anything, anything).and_return(todays_advances_amount_response)
        allow(subject).to receive(:settings).and_return(settings_response)
        allow(subject).to receive(:todays_cumulative_advances_amount).with(member_id).and_return(todays_cumulative_advances_amount_response)
        allow(subject).to receive(:get_json).with(:check_limits, anything).and_return(limits_response)
      end
      it 'should return a hash back' do
        expect(check_limits).to be_kind_of(Hash)
      end
      it 'should call EtransactAdvancesService#todays_advances_amount' do
        expect(subject).to receive(:todays_advances_amount)
        check_limits
      end
      it 'should call EtransactAdvancesService#todays_cumulative_advances_amount' do
        expect(subject).to receive(:todays_cumulative_advances_amount)
        check_limits
      end
      it 'should return low if limits are not passing min tests' do
        expect(low_check_limits).to eq(low_check)
      end
      it 'should return pass if limits are passing tests' do
        expect(check_limits).to eq(pass_result)
      end
      it 'should return high if limits are not passing max tests' do
        expect(high_check_limits).to eq(high_result)
      end
      it 'should return high if limits are not passing cumulative tests' do
        expect(cumulative_check_limits).to eq(high_result)
      end
      it 'should return nil if todays_cumulative_advances_amount returns nil' do
        allow(subject).to receive(:todays_cumulative_advances_amount).with(member_id).and_return(nil)
        expect(check_limits).to eq(nil)
      end
      it 'returns nil if passed a nil term' do
        expect(subject.check_limits(member_id, amount, nil)).to be_nil
      end
      it 'returns nil if passed a nil amount' do
        expect(subject.check_limits(member_id, nil, advance_term)).to be_nil
      end
    end
  end

  describe '`limits` method' do
    let(:limit_data) {[
      {'FOO' => double('foo')},
      {'BAR' => double('bar')}
    ]}
    let(:call_method) { subject.limits }
    before { allow(subject).to receive(:get_json).and_return(limit_data) }

    it 'calls `get_json` with the proper name and endpoint' do
      expect(subject).to receive(:get_json).with(:check_limits, 'etransact_advances/limits').and_return([])
      call_method
    end
    it 'downcases all of the keys from the returned hash' do
      results = call_method
      limit_data.each do |bucket|
        expect(bucket.length).to be > 0
        bucket.each do |k,v|
          expect(results).to include(hash_including(k.downcase => v))
        end
      end
    end
    it 'returns buckets that have indifferent access' do
      results = call_method
      limit_data.each_with_index do |bucket, i|
        expect(bucket.length).to be > 0
        bucket.each do |k,v|
          expect(results[i][k.downcase.to_sym]).to eq(v)
        end
      end
    end
  end

  describe '`todays_advances_amount` method' do
    l_days = 0
    h_days = 1
    m_id = 750
    let(:member_id) {m_id}
    let(:low_days) {l_days}
    let(:high_days) {h_days}
    let(:current_part1) {rand(0..10000)}
    let(:current_part2) {rand(0..10000)}
    let(:maturity_date) {double('Maturity Date')}
    let(:todays_advances_amount) {subject.todays_advances_amount(member_id, low_days, high_days)}
    let(:todays_advances_amount_response) {[{"maturity_date"=> maturity_date, "current_par"=> current_part1}, {"maturity_date"=> maturity_date, "current_par"=> current_part2 }]}
    it_should_behave_like 'a MAPI backed service object method', :todays_advances_amount, [m_id, l_days, h_days]
    describe 'without service exceptions' do
      before do
        allow(subject).to receive(:get_json).with(:todays_advances_amount, anything).and_return(todays_advances_amount_response)
      end
      it 'should return a number' do
        allow(subject).to receive(:get_days_to_maturity_date).with(maturity_date).and_return(low_days)
        expect(todays_advances_amount).to eq(current_part1+current_part2)
      end
      it 'should return zero' do
        allow(subject).to receive(:get_days_to_maturity_date).with(maturity_date).and_return(10)
        expect(todays_advances_amount).to eq(0)
      end
    end
  end

  describe '`todays_cumulative_advances_amount` method' do
    m_id = 750
    let(:member_id) {m_id}
    let(:current_part1) {rand(0..10000)}
    let(:current_part2) {rand(0..10000)}
    let(:maturity_date) {double('Maturity Date')}
    let(:todays_cumulative_advances_amount) {subject.todays_cumulative_advances_amount(member_id)}
    let(:todays_advances_amount_response) {[{"maturity_date"=> maturity_date, "current_par"=> current_part1}, {"maturity_date"=> maturity_date, "current_par"=> current_part2 }]}
    it_should_behave_like 'a MAPI backed service object method', :todays_cumulative_advances_amount, [m_id]
    describe 'without service exceptions' do
      before do
        allow(subject).to receive(:get_json).with(:todays_advances_amount, anything).and_return(todays_advances_amount_response)
      end
      it 'should return a number' do
        expect(todays_cumulative_advances_amount).to eq(current_part1+current_part2)
      end
      it 'should return zero' do
        allow(subject).to receive(:get_json).with(:todays_advances_amount, anything).and_return([])
        expect(todays_cumulative_advances_amount).to eq(0)
      end
    end
  end

  describe '`status` method', :vcr do
    let(:call_method) {subject.status}
    it_should_behave_like 'a MAPI backed service object method', :status
    it 'should return the MAPI response object' do
      response_object = double('A MAPI Response Object')
      allow(response_object).to receive(:with_indifferent_access).and_return(response_object)
      allow(JSON).to receive(:parse).and_return(response_object)
      expect(call_method).to be(response_object)
    end
  end

  describe '`blackout_dates` method', :vcr do
    let(:call_method) {subject.blackout_dates}
    it_should_behave_like 'a MAPI backed service object method', :blackout_dates
    it 'should return the MAPI response object' do
      response_object = double('A MAPI Response Object')
      allow(JSON).to receive(:parse).and_return(response_object)
      expect(call_method).to be(response_object)
    end
  end

  describe '`settings` method' do
    let(:settings) { double('some settings') }
    let(:call_method) { subject.settings }

    it_behaves_like 'a MAPI backed service object method', :settings
    it 'calls `get_hash` with the proper endpoint name' do
      expect(subject).to receive(:get_hash).with(:settings, any_args)
      call_method
    end
    it 'calls `get_hash` with `etransact_advances/settings` as the endpoint' do
      expect(subject).to receive(:get_hash).with(anything, 'etransact_advances/settings')
      call_method
    end
    it 'returns the result of calling `get_hash`' do
      allow(subject).to receive(:get_hash).and_return(settings)
      expect(call_method).to eq(settings)
    end
    it 'caches its settings for the lifecycle of the object' do
      expect(subject).to receive(:get_hash)
      call_method
      expect(subject).to_not receive(:get_hash)
      call_method
      new_subject = described_class.new(request)
      expect(new_subject).to receive(:get_hash)
      new_subject.settings
    end
  end

  describe '`update_settings` method' do
    let(:settings) { double('some settings') }
    let(:results) { double('some results') }
    let(:call_method) { subject.update_settings(settings) }

    it_behaves_like 'a MAPI backed service object method', :update_settings, nil, :put, nil, true do
      let(:call_method) { subject.update_settings(settings) }
    end
    it 'calls `put_hash` with the proper endpoint name' do
      expect(subject).to receive(:put_hash).with(:update_settings, any_args)
      call_method
    end
    it 'calls `put_hash` with `etransact_advances/settings` as the endpoint' do
      expect(subject).to receive(:put_hash).with(anything, 'etransact_advances/settings', anything)
      call_method
    end
    it 'calls `put_hash` with the provided settings' do
      expect(subject).to receive(:put_hash).with(anything, anything, settings)
      call_method
    end
    it 'returns the result of calling `put_hash`' do
      allow(subject).to receive(:put_hash).and_return(results)
      expect(call_method).to eq(results)
    end
  end

  describe '`update_term_limits` method' do
    let(:limits) { double('some settings') }
    let(:results) { double('some results') }
    let(:call_method) { subject.update_term_limits(limits) }

    it_behaves_like 'a MAPI backed service object method', :update_term_limits, nil, :put, nil, true do
      let(:call_method) { subject.update_term_limits(limits) }
    end
    it 'calls `put_hash` with the proper endpoint name' do
      expect(subject).to receive(:put_hash).with(:update_term_limits, any_args)
      call_method
    end
    it 'calls `put_hash` with `etransact_advances/limits` as the endpoint' do
      expect(subject).to receive(:put_hash).with(anything, 'etransact_advances/limits', anything)
      call_method
    end
    it 'calls `put_hash` with the provided limits' do
      expect(subject).to receive(:put_hash).with(anything, anything, limits)
      call_method
    end
    it 'returns the result of calling `put_hash`' do
      allow(subject).to receive(:put_hash).and_return(results)
      expect(call_method).to eq(results)
    end
  end

  describe '`enable_etransact_service` method' do
    let(:results) { double('some results') }
    let(:call_method) { subject.enable_etransact_service }

    it_behaves_like 'a MAPI backed service object method', :enable_etransact_service, nil, :put, nil, true
    it 'calls `put_hash` with the proper endpoint name' do
      expect(subject).to receive(:put_hash).with(:enable_etransact_service, any_args)
      call_method
    end
    it 'calls `put_hash` with `etransact_advances/settings/enable_service` as the endpoint' do
      expect(subject).to receive(:put_hash).with(anything, 'etransact_advances/settings/enable_service', anything)
      call_method
    end
    it 'calls `put_hash` with an empty hash' do
      expect(subject).to receive(:put_hash).with(anything, anything, {})
      call_method
    end
    it 'returns the result of calling `put_hash`' do
      allow(subject).to receive(:put_hash).and_return(results)
      expect(call_method).to eq(results)
    end
  end

  describe '`disable_etransact_service` method' do
    let(:results) { double('some results') }
    let(:call_method) { subject.disable_etransact_service }

    it_behaves_like 'a MAPI backed service object method', :disable_etransact_service, nil, :put, nil, true
    it 'calls `put_hash` with the proper endpoint name' do
      expect(subject).to receive(:put_hash).with(:disable_etransact_service, any_args)
      call_method
    end
    it 'calls `put_hash` with `etransact_advances/settings/disable_service` as the endpoint' do
      expect(subject).to receive(:put_hash).with(anything, 'etransact_advances/settings/disable_service', anything)
      call_method
    end
    it 'calls `put_hash` with an empty hash' do
      expect(subject).to receive(:put_hash).with(anything, anything, {})
      call_method
    end
    it 'returns the result of calling `put_hash`' do
      allow(subject).to receive(:put_hash).and_return(results)
      expect(call_method).to eq(results)
    end
  end

  describe '`has_terms?` method', :vcr do
    let(:call_method) {subject.has_terms?(status_object)}
    let(:status_object) { {all_loan_status: {foo: {bar: {trade_status: true, display_status: true}}}} }
    it 'should return true if at least one term is found, displayable, and tradeable' do
      expect(call_method).to be(true)
    end
    it 'should return false if none of the terms are found' do
      status_object[:all_loan_status] = {}
      expect(call_method).to be(false)
    end
    it 'should return false if none of the terms are displayable' do
      status_object[:all_loan_status] = {foo: {bar: {trade_status: true, display_status: false}}}
      expect(call_method).to be(false)
    end
    it 'should return false if none of the terms are tradeable' do
      status_object[:all_loan_status] = {foo: {bar: {trade_status: false, display_status: true}}}
      expect(call_method).to be(false)
    end
    it 'should call EtransactAdvancesService#status if no status object is provided' do
      expect(subject).to receive(:status)
      subject.has_terms?
    end
    it 'should return false if EtransactAdvancesService#status returns nil' do
      allow(subject).to receive(:status).and_return(nil)
      expect(subject.has_terms?).to be(false)
    end
    it 'should not call EtransactAdvancesService#status if a status object is provided' do
      expect(subject).to_not receive(:status)
      call_method
    end
    it 'should use the supplied status object' do
      expect(status_object).to receive(:[]).with(:all_loan_status).and_return(status_object[:all_loan_status])
      call_method
    end
    it 'should use the returned status object if none is passed' do
      expect(status_object).to receive(:[]).with(:all_loan_status).and_return(status_object[:all_loan_status])
      allow(subject).to receive(:status).and_return(status_object)
      subject.has_terms?
    end
  end

  describe 'get_days_to_maturity' do
    let(:today) { Time.zone.today }
    let(:custom_maturity_date) { today + rand(3..1095).days }
    it 'should map overnight to 1' do
      expect(subject.send(:get_days_to_maturity,'Overnight')).to eq( 1 )
      expect(subject.send(:get_days_to_maturity,'overnight')).to eq( 1 )
    end
    it 'should map open to 1' do
      expect(subject.send(:get_days_to_maturity,'Open')).to eq( 1 )
      expect(subject.send(:get_days_to_maturity,'open')).to eq( 1 )
    end
    (1..4).each do |i|
      it "should map #{i}w to #{7*i}" do
        expect(subject.send(:get_days_to_maturity,"#{i}w")).to eq( ((today + 7*i) - today).to_i )
      end
    end
    (1..12).each do |i|
      it "should map #{i}m" do
        expect(subject.send(:get_days_to_maturity,"#{i}m")).to eq( ((today + i.month) - today).to_i )
      end
    end
    (1..10).each do |i|
      it "should map #{i}y" do
        expect(subject.send(:get_days_to_maturity,"#{i}y")).to eq( ((today + i.year) - today).to_i )
      end
    end
    it 'returns nil if passed nil' do
      expect(subject.send(:get_days_to_maturity, nil)).to be_nil
    end
    it 'should map custom to custom_maturity_date - today' do
      result = (custom_maturity_date.to_date - today.to_date).to_i
      expect(subject.send(:get_days_to_maturity, '10day', custom_maturity_date)).to eq(result)
    end
  end

  describe 'get_days_to_maturity_date' do
    let(:today) { Time.zone.today }
    it 'should map overnight to 1' do
      expect(subject.send(:get_days_to_maturity_date,'Overnight')).to eq( 1 )
      expect(subject.send(:get_days_to_maturity_date,'overnight')).to eq( 1 )
    end
    it 'should map open to 1' do
      expect(subject.send(:get_days_to_maturity_date,'Open')).to eq( 1 )
      expect(subject.send(:get_days_to_maturity_date,'open')).to eq( 1 )
    end
    it 'should map a future date to the correct number of dates' do
      r = rand(1..100).round
      expect(subject.send(:get_days_to_maturity_date, (today + r.days).to_s)).to eq( r )
    end
  end

  describe '`etransact_status`' do
    let(:status_object) { double('status object') }
    let(:member_id) { SecureRandom.uuid }
    let(:call_method) {subject.etransact_status(member_id, status_object)}
    let(:members_service) { double('members service instance', quick_advance_enabled_for_member?: false) }

    before do
      allow(subject).to receive(:etransact_active?)
      allow(subject).to receive(:has_terms?)
      allow(MembersService).to receive(:new).and_return(members_service)
    end

    it 'should call EtransactAdvancesService#status if no status object is provided' do
      expect(subject).to receive(:status)
      subject.etransact_status(false)
    end
    it 'should not call EtransactAdvancesService#status if a status object is provided' do
      expect(subject).to_not receive(:status)
      call_method
    end
    it 'should use the supplied status object when calling `etransact_active?`' do
      expect(subject).to receive(:etransact_active?).with(status_object)
      call_method
    end
    it 'should use the supplied status object when calling `has_terms?`' do
      expect(subject).to receive(:has_terms?).with(status_object)
      call_method
    end
    it 'calls `quick_advance_enabled_for_member?` on the MembersService instance with the supplied member_id' do
      expect(members_service).to receive(:quick_advance_enabled_for_member?).with(member_id)
      call_method
    end

    describe 'when etransact is active' do
      before { allow(subject).to receive(:etransact_active?).and_return(true) }
      describe 'when etransact has terms' do
        before { allow(subject).to receive(:has_terms?).and_return(true) }
        describe 'when etransact is enabled for a member' do
          it 'returns :open' do
            allow(members_service).to receive(:quick_advance_enabled_for_member?).and_return(true)
            expect(call_method).to eq(:open)
          end
        end
        describe 'when etransact is disabled for a member' do
          it 'returns :disabled_for_member' do
            expect(call_method).to eq(:disabled_for_member)
          end
        end
      end
      describe 'when etransact does not have terms' do
        it 'returns :no_terms' do
          expect(call_method).to eq(:no_terms)
        end
      end
    end
    describe 'when etransact is not active' do
      it 'returns a value of `:closed` after desk closing time' do
        allow(subject).to receive(:etransact_active?).and_return(false)
        allow(Time).to receive_message_chain(:zone, :now, :hour).and_return(rand(14..23))
        expect(call_method).to eq(:closed)
      end
      it 'returns a value of `:closed` before desk opening time' do
        allow(subject).to receive(:etransact_active?).and_return(false)
        allow(Time).to receive_message_chain(:zone, :now, :hour).and_return(rand(0..7))
        expect(call_method).to eq(:closed)
      end
      it 'returns a value of `:unavailable` during normal desk hours' do
        allow(subject).to receive(:etransact_active?).and_return(false)
        allow(Time).to receive_message_chain(:zone, :now, :hour).and_return(rand(8..13))
        expect(call_method).to eq(:unavailable)
      end
    end
  end

  describe '`shutoff_times_by_type`' do
    let(:shutoff_times) {{
      'frc' => double('end time'),
      'vrc' => double('end time')
    }}
    let(:vrc_sentinel) { double('processed vrc end time') }
    let(:frc_sentinel) { double('processed frc end time') }
    let(:call_method) { subject.shutoff_times_by_type }
    before do
      allow(subject).to receive(:get_hash).and_return(shutoff_times)
      allow(subject).to receive(:parse_24_hour_time)
    end

    it 'calls `get_hash` with the proper name and endpoint' do
      expect(subject).to receive(:get_hash).with(:shutoff_times_by_type, 'etransact_advances/shutoff_times_by_type').and_return({})
      call_method
    end
    it 'returns nil if `get_hash` returns nil' do
      allow(subject).to receive(:get_hash).and_return(nil)
      expect(call_method).to be nil
    end
    it 'returns an empty hash if `get_hash` returns an empty hash' do
      allow(subject).to receive(:get_hash).and_return({})
      expect(call_method).to eq({})
    end
    describe 'processing the end times' do
      let(:end_time) { double('end time') }
      it 'passes the values from the returned hash to the `parse_24_hour_time` method' do
        shutoff_times_results = {}
        n = rand(2..5)
        n.times do |i|
          shutoff_times_results[i] = end_time
        end
        allow(subject).to receive(:get_hash).and_return(shutoff_times_results)
        expect(subject).to receive(:parse_24_hour_time).exactly(n).times.with(end_time)
        call_method
      end
      it 'sets the value of each key to the result of `parse_24_hour_time`' do
        allow(subject).to receive(:parse_24_hour_time).with(shutoff_times['frc']).and_return(frc_sentinel)
        allow(subject).to receive(:parse_24_hour_time).with(shutoff_times['vrc']).and_return(vrc_sentinel)
        expect(call_method).to eq({
          'frc' => frc_sentinel,
          'vrc' => vrc_sentinel
        })
      end
    end
  end

  describe '`early_shutoffs`' do
    let(:early_shutoff) { {} }
    let(:processed_early_shutoff) {{
      early_shutoff_date: early_shutoff_date
    }}
    let(:early_shutoff_date) { instance_double(Date) }
    let(:call_method) { subject.early_shutoffs }
    before do
      allow(subject).to receive(:get_hashes).and_return([early_shutoff])
      allow(subject).to receive(:fix_date)
    end

    it 'calls `get_hashes` with the proper name and endpoint' do
      expect(subject).to receive(:get_hashes).with(:early_shutoffs, 'etransact_advances/early_shutoffs').and_return([])
      call_method
    end
    it 'returns nil if `get_hashes` returns nil' do
      allow(subject).to receive(:get_hashes).and_return(nil)
      expect(call_method).to be nil
    end
    it 'returns an empty hash if `get_hashes` returns an empty hash' do
      allow(subject).to receive(:get_hashes).and_return([])
      expect(call_method).to eq([])
    end
    describe 'processing the scheduled shutoff times' do
      describe 'per row' do
        let(:n) { rand(2..5) }
        let(:scheduled_shutoffs) do
          shutoffs = []
          n.times do |i|
            shutoffs << early_shutoff
          end
          shutoffs
        end
        before do
          allow(subject).to receive(:get_hashes).and_return(scheduled_shutoffs)
        end

        it 'calls `fix_date` once for each scheduled shutoff' do
          expect(subject).to receive(:fix_date).exactly(n).times
          call_method
        end
      end
      it 'calls `fix_date` with the early shutoff hash' do
        expect(subject).to receive(:fix_date).with(early_shutoff, anything)
        call_method
      end
      it 'calls `fix_date` with the key name `early_shutoff_date`' do
        expect(subject).to receive(:fix_date).with(anything, :early_shutoff_date)
        call_method
      end
      it 'returns the processed early shutoff times' do
        allow(subject).to receive(:fix_date) do |shutoff_hash|
          shutoff_hash[:early_shutoff_date] = early_shutoff_date
        end
        expect(call_method).to eq([processed_early_shutoff])
      end
    end
  end

  shared_examples 'an EtransactAdvancesService endpoint that calls to `etransact_advances/early_shutoff`' do |http_method, endpoint_name|
    let(:early_shutoff) { instance_double(EarlyShutoffRequest) }
    let(:shutoff_hash) { instance_double(Hash) }
    let(:result) { double('some result') }
    before { allow(subject).to receive(:shutoff_hash) }

    it "calls `#{http_method}` with the endpoint name" do
      expect(subject).to receive(http_method).with(endpoint_name, any_args)
      call_method
    end
    it "calls `#{http_method}` with the proper endpoint" do
      expect(subject).to receive(http_method).with(anything, 'etransact_advances/early_shutoff', anything)
      call_method
    end
    it 'calls `shutoff_hash` with the passed early shutoff arg' do
      expect(subject).to receive(:shutoff_hash).with(early_shutoff)
      call_method
    end
    it "calls `#{http_method}` with the result of `shutoff_hash`" do
      allow(subject).to receive(:shutoff_hash).and_return(shutoff_hash)
      expect(subject).to receive(http_method).with(anything, anything, shutoff_hash)
      call_method
    end
    it "returns the result of calling `#{http_method}`" do
      allow(subject).to receive(http_method).and_return(result)
      expect(call_method).to eq(result)
    end
  end

  describe '`schedule_early_shutoff`' do
    let(:call_method) { subject.schedule_early_shutoff(early_shutoff) }
    it_behaves_like 'an EtransactAdvancesService endpoint that calls to `etransact_advances/early_shutoff`', :post_hash, :schedule_early_shutoff
  end

  describe '`update_early_shutoff`' do
    let(:call_method) { subject.update_early_shutoff(early_shutoff) }
    it_behaves_like 'an EtransactAdvancesService endpoint that calls to `etransact_advances/early_shutoff`', :put_hash, :update_early_shutoff
  end

  describe 'days_until' do
    let(:today) { Time.zone.today }
    it 'should map today to 0' do
      expect(subject.send(:days_until, today)).to eq( 0 )
    end
    it 'should map tomorrow to 1' do
      expect(subject.send(:days_until, today.tomorrow)).to eq( 1 )
    end
    it 'should map next week to 7' do
      expect(subject.send(:days_until, today + 1.week)).to eq( 7 )
    end
  end

  describe '`calypso_error_handler` protected method' do
    let(:member_id) { double('A Member ID') }
    let(:error_handler) { subject.send(:calypso_error_handler, member_id) }
    let(:call_error_handler) { error_handler.call(:some_name, 'a message', error) }
    let(:error) { double('An Error') }
    let(:request_user) { double('A User') }
    let(:request_uuid) { double('A UUID') }
    let(:member_name) { double('A Member Name') }
    let(:mail) { double('An Email', deliver_now: nil)}

    before do
      allow(subject).to receive(:connection_request_uuid).and_return(request_uuid)
      allow(subject).to receive(:connection_user).and_return(request_user)
      allow(subject).to receive(:member_id_to_name).with(member_id).and_return(member_name)
    end

    it 'returns a Proc' do
      expect(error_handler).to be_kind_of(Proc)
    end
    it 'builds a `calypso_error` email when the Proc is called' do
      expect(InternalMailer).to receive(:calypso_error).with(error, request_uuid, request_user, member_name).and_return(mail)
      call_error_handler
    end
    it 'sends the email immediately' do
      allow(InternalMailer).to receive(:calypso_error).and_return(mail)
      expect(mail).to receive(:deliver_now)
      call_error_handler
    end
  end

  describe '`member_id_to_name` protected method' do
    let(:member_id) { double('Member ID') }
    let(:call_method) { subject.send(:member_id_to_name, member_id) }
    let(:member_name) { double('A Member Name') }

    before do
      allow(request).to receive(:member_name).and_return(member_name)
    end

    it 'returns the member name assocaited with the supplied member ID' do
      allow(request).to receive(:member_id).and_return(member_id)
      expect(call_method).to be(member_name)
    end
    it 'returns the member ID if the name cant be found' do
      expect(call_method).to be(member_id)
    end
  end

  describe 'the `shutoff_hash` protected method' do
    let(:early_shutoff) { instance_double(EarlyShutoffRequest, original_early_shutoff_date: instance_double(String), early_shutoff_date: instance_double(String), vrc_shutoff_time: instance_double(String), frc_shutoff_time: instance_double(String), day_of_message_simple_format: instance_double(String), day_before_message_simple_format: instance_double(String)) }
    let(:call_method) { subject.send(:shutoff_hash, early_shutoff) }
    [:original_early_shutoff_date, :early_shutoff_date, :vrc_shutoff_time, :frc_shutoff_time].each do |attr|
      it "returns a hash that includes the `#{attr}` of the early_shutoff_request" do
        expect(call_method).to include(attr => early_shutoff.send(attr))
      end
    end
    [:day_of_message, :day_before_message].each do |attr|
      it "returns a hash that includes the `#{attr}_simple_format` of the early_shutoff_request" do
        expect(call_method).to include(attr => early_shutoff.send(:"#{attr}_simple_format"))
      end
    end
  end
end