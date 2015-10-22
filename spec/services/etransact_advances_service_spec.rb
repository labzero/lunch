require 'rails_helper'

describe EtransactAdvancesService do
  let(:request) { double('request', uuid: '12345', session: double('A Session', :[] => nil)) }
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
    let(:call_method) {subject.quick_advance_validate(member_id, amount, advance_type, advance_term, advance_rate, check_capstock, signer)}
    
    before do
      allow(subject).to receive(:calypso_error_handler).and_return(nil)
    end

    it 'should return a hash back' do
      expect(call_method).to be_kind_of(Hash)
    end
    it 'calls `get_hash`' do
      expect(subject).to receive(:get_hash).with(:quick_advance_validate, "etransact_advances/validate_advance/#{member_id}/#{amount}/#{advance_type}/#{advance_term}/#{advance_rate}/#{check_capstock}/#{signer}")
      call_method
    end
    it 'returns the results of `get_hash`' do
      result = double('A Result')
      allow(subject).to receive(:get_hash).and_return(result)
      expect(call_method).to be(result)
    end
    it 'should URL encode the signer' do
      expect(URI).to receive(:escape).with(signer)
      call_method
    end
    it 'passes a `calypso_error_handler` to the `get_hash` method' do
      error_handler = -> (n, m, e) {}
      allow(subject).to receive(:calypso_error_handler).with(member_id).and_return(error_handler)
      allow(subject).to receive(:get_hash).with(anything, anything) do |*args, &block|
        expect(block).to be(error_handler)
      end
      call_method
    end
  end

  describe '`quick_advance_execute` method', :vcr do
    let(:signer) {'signer'}
    let(:member_id) {750}
    let(:advance_term) {'someterm'}
    let(:advance_type) {'sometype'}
    let(:advance_rate) {'0.17'}
    let(:amount) { 100 }
    let(:call_method) {subject.quick_advance_execute(member_id, amount, advance_type, advance_term, advance_rate, signer)}
    
    before do
      allow(subject).to receive(:calypso_error_handler).and_return(nil)
    end

    it 'should return a hash back' do
      expect(call_method).to be_kind_of(Hash)
    end
    it 'should set initiated_at' do
      expect(call_method[:initiated_at]).to be_kind_of(DateTime)
    end
    it 'calls `post_hash`' do
      expect(subject).to receive(:post_hash).with(:quick_advance_execute, "etransact_advances/execute_advance/#{member_id}/#{amount}/#{advance_type}/#{advance_term}/#{advance_rate}/#{signer}", '')
      call_method
    end
    it 'returns the result of `post_hash`' do
      result = double('A Result', :[]= => nil)
      allow(subject).to receive(:post_hash).and_return(result)
      expect(call_method).to be(result)
    end
    it 'should URL encode the signer' do
      expect(URI).to receive(:escape).with(signer)
      call_method
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
        allow(subject).to receive(:get_days_to_maturity).with(advance_term).and_return(low_days)
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
    it_should_behave_like 'a MAPI backed service object method', :status
    it 'should return the MAPI response object' do
      response_object = double('A MAPI Response Object')
      allow(JSON).to receive(:parse).and_return(response_object)
      expect(call_method).to be(response_object)
    end
  end

  describe '`settings` method', :vcr do
    let(:call_method) {subject.settings}
    it_should_behave_like 'a MAPI backed service object method', :settings
    it 'should return the MAPI response object' do
      response_object = double('A MAPI Response Object')
      allow(response_object).to receive(:with_indifferent_access).and_return(response_object)
      allow(JSON).to receive(:parse).and_return(response_object)
      expect(call_method).to be(response_object)
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

    it 'returns a Proc' do
      expect(error_handler).to be_kind_of(Proc)
    end
    it 'builds a `calypso_error` email when the Proc is called' do
      allow(subject).to receive(:request_uuid).and_return(request_uuid)
      allow(subject).to receive(:request_user).and_return(request_user)
      allow(subject).to receive(:member_id_to_name).with(member_id).and_return(member_name)
      expect(InternalMailer).to receive(:calypso_error).with(error, request_uuid, request_user, member_name).and_return(mail)
      call_error_handler
    end
    it 'sends the email immediately' do
      allow(InternalMailer).to receive(:calypso_error).and_return(mail)
      expect(mail).to receive(:deliver_now)
      call_error_handler
    end
  end
end