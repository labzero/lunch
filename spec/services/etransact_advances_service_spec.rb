require 'rails_helper'

describe EtransactAdvancesService do
  subject { EtransactAdvancesService.new(double('request', uuid: '12345')) }
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
    let(:quick_advance_validate) {subject.quick_advance_validate(member_id, amount, advance_type, advance_term, advance_rate, check_capstock, signer)}
    it 'should return a hash back' do
      expect(quick_advance_validate).to be_kind_of(Hash)
    end
    it 'should return nil if there was an API error' do
      allow_any_instance_of(RestClient::Resource).to receive(:get).and_raise(RestClient::InternalServerError)
      expect(quick_advance_validate).to eq(nil)
    end
    it 'should return nil if there was a connection error' do
      allow_any_instance_of(RestClient::Resource).to receive(:get).and_raise(Errno::ECONNREFUSED)
      expect(quick_advance_validate).to eq(nil)
    end
    it 'returns nil if there is a JSON parsing error' do
      allow(JSON).to receive(:parse).and_raise(JSON::ParserError)
      allow(Rails.logger).to receive(:warn)
      expect(quick_advance_validate).to be(nil)
    end
    it 'should URL encode the signer' do
      expect(URI).to receive(:escape).with(signer)
      quick_advance_validate
    end
  end
  describe '`quick_advance_execute` method', :vcr do
    let(:signer) {'signer'}
    let(:member_id) {750}
    let(:advance_term) {'someterm'}
    let(:advance_type) {'sometype'}
    let(:advance_rate) {'0.17'}
    let(:amount) { 100 }
    let(:quick_advance_execute) {subject.quick_advance_execute(member_id, amount, advance_type, advance_term, advance_rate, signer)}
    it 'should return a hash back' do
      expect(quick_advance_execute).to be_kind_of(Hash)
    end
    it 'should set initiated_at' do
      expect(quick_advance_execute[:initiated_at]).to be_kind_of(DateTime)
    end
    it 'returns nil if there is a JSON parsing error' do
      allow(JSON).to receive(:parse).and_raise(JSON::ParserError)
      allow(Rails.logger).to receive(:warn)
      expect(quick_advance_execute).to be(nil)
    end
    it 'should return nil if there was an API error' do
      allow_any_instance_of(RestClient::Resource).to receive(:post).and_raise(RestClient::InternalServerError)
      expect(quick_advance_execute).to eq(nil)
    end
    it 'should return nil if there was a connection error' do
      allow_any_instance_of(RestClient::Resource).to receive(:post).and_raise(Errno::ECONNREFUSED)
      expect(quick_advance_execute).to eq(nil)
    end
    it 'should URL encode the signer' do
      expect(URI).to receive(:escape).with(signer)
      quick_advance_execute
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
    let(:low_check_limits) {subject.check_limits(member_id, low_amount, advance_term)}
    let(:check_limits) {subject.check_limits(member_id, amount, advance_term)}
    let(:high_check_limits) {subject.check_limits(member_id, high_amount, advance_term)}
    let(:low_check)  {{:status=>'low', :low=>amount, :high=>high_amount}}
    let(:pass_result) {{:status => 'pass', :low => amount, :high => high_amount}}
    let(:high_result) {{:status => 'high', :low => amount, :high => high_amount}}
    let(:limits_response) {[{"WHOLE_LOAN_ENABLED" => "N","SBC_AGENCY_ENABLED" => "Y", "SBC_AAA_ENABLED" => "Y", "SBC_AA_ENABLED" => "Y", "LOW_DAYS_TO_MATURITY" => low_days,
                             "HIGH_DAYS_TO_MATURITY" => high_days, "MIN_ONLINE_ADVANCE" => amount, "TERM_DAILY_LIMIT" => high_amount, "PRODUCT_TYPE" => "VRC",
                             "END_TIME" => "1700", "OVERRIDE_END_DATE" => "01-JAN-2006 12:00 AM", "OVERRIDE_END_TIME" => "1700"}]}
    let(:todays_advances_amount_response) {rand(1..9)}
    it_should_behave_like 'a MAPI backed service object method', :check_limits, [m_id, l_amount, '1Week']
    describe 'without service exceptions' do
      before do
        allow(subject).to receive(:get_days_to_maturity).with(advance_term).and_return(low_days)
        allow(subject).to receive(:todays_advances_amount).with(member_id, anything, anything).and_return(todays_advances_amount_response)
        allow(subject).to receive(:get_json).with(:check_limits, anything).and_return(limits_response)
      end
      it 'should return a hash back' do
        expect(check_limits).to be_kind_of(Hash)
      end
      it 'should call EtransactAdvancesService#todays_advances_amount' do
        expect(subject).to receive(:todays_advances_amount)
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
        expect(subject.send(:get_days_to_maturity,"#{i}w")).to eq( ((Date.today + 7*i) - Date.today).to_i )
      end
    end
    (1..12).each do |i|
      it "should map #{i}m" do
        expect(subject.send(:get_days_to_maturity,"#{i}m")).to eq( ((Date.today + i.month) - Date.today).to_i )
      end
    end
    (1..10).each do |i|
      it "should map #{i}y" do
        expect(subject.send(:get_days_to_maturity,"#{i}y")).to eq( ((Date.today + i.year) - Date.today).to_i )
      end
    end
  end

  describe 'get_days_to_maturity_date' do
    it 'should map overnight to 1' do
      expect(subject.send(:get_days_to_maturity_date,'Overnight')).to eq( 1 )
      expect(subject.send(:get_days_to_maturity_date,'overnight')).to eq( 1 )
    end
    it 'should map open to 1' do
      expect(subject.send(:get_days_to_maturity_date,'Open')).to eq( 1 )
      expect(subject.send(:get_days_to_maturity_date,'open')).to eq( 1 )
    end
    it 'should map a future date to the correct number of dates' do
      r = (rand*100).round
      expect(subject.send(:get_days_to_maturity_date, (Date.today + r.days).to_s)).to eq( r )
    end
  end

  describe 'days_until' do
    it 'should map today to 0' do
      expect(subject.send(:days_until, Date.today)).to eq( 0 )
    end
    it 'should map tomorrow to 1' do
      expect(subject.send(:days_until, Date.tomorrow)).to eq( 1 )
    end
    it 'should map next week to 7' do
      expect(subject.send(:days_until, Date.today + 1.week)).to eq( 7 )
    end
  end
end