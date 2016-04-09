require 'rails_helper'

describe AdvanceRequest do
  describe AdvanceRequest::Error do
    let(:type) { double('A Type') }
    let(:code) { double('A Code') }
    let(:value) { double('A Value') }

    subject { described_class.new(type, code, value) }

    describe 'initializer' do
      let(:call_method) { described_class.new(type, code, value) }
      it 'assigns the `type` parameter to the `type` attribute' do
        expect(call_method.type).to be(type)
      end
      it 'assigns the `code` parameter to the `code` attribute' do
        expect(call_method.code).to be(code)
      end
      it 'assigns the `value` parameter to the `value` attribute' do
        expect(call_method.value).to be(value)
      end
      it 'sets `value` to nil if none is provided' do
        expect(described_class.new(type, code).value).to be_nil
      end
    end

    describe 'inspect' do
      let(:call_method) { subject.inspect }

      it 'returns a String' do
        expect(call_method).to be_kind_of(String)
      end
      [:type, :code, :value, :object_id, :class].each do |attr|
        it "includes the `#{attr}`" do
          expect(call_method).to include(subject.send(attr).to_s)
        end
      end
    end
  end

  let(:member_id) { double('A Member ID') }
  let(:signer) { double('A Signer', display_name: nil, username: nil) }
  let(:request) { double('A Request') }
  let(:maturity_date) { double('A Maturity Date') }
  subject { described_class.new(member_id, signer, request) }

  describe 'initializer' do
    it 'assigns the `member_id` parameter to the `member_id` attribute' do
      expect(subject.member_id).to be(member_id)
    end
    it 'assigns the `signer` parameter to the `signer` attribute' do
      expect(subject.signer).to be(signer)
    end
    it 'assigns the `request` parameter to `@request`' do
      expect(subject.instance_variable_get(:@request)).to be(request)
    end
    it 'sets `@request` to nil if none is provided' do
      obj = described_class.new(member_id, signer)
      expect(obj.instance_variable_get(:@request)).to be_nil
    end
  end

  describe '`id` method' do
    let(:call_method) { subject.id }
    it 'returns a UUID' do
      uuid = double('A UUID')
      allow(SecureRandom).to receive(:uuid).and_return(uuid)
      expect(call_method).to be(uuid)
    end
    it 'returns the same ID each time' do
      id = call_method
      expect(call_method).to be(id)
    end
    it 'returns a different ID per instance' do
      other_instance = subject.dup
      expect(call_method).to_not eq(other_instance.id)
    end
  end

  describe '`timestamp!` method' do
    it 'assigns the current time to the `timestamp` attribute' do
      now = double('Now')
      allow(Time).to receive_message_chain(:zone, :now).and_return(now)
      subject.timestamp!
      expect(subject.timestamp).to be(now)
    end
  end

  describe '`expired?` method' do
    let(:timeout) { double('A Timeout') }
    let(:now) { Time.zone.now }
    before do
      allow(Time).to receive_message_chain(:zone, :now).and_return(now)
      allow(subject).to receive(:perform_rate_check)
      allow(subject).to receive(:rate_changed?)
    end

    shared_examples 'a rate that has expired' do
      before { allow(subject).to receive(:rate_changed?).and_return(true) }
      it 'checks the rate' do
        expect(subject).to receive(:perform_rate_check)
        call_method
      end
      it 'returns true' do
        expect(call_method).to be(true)
      end
    end

    shared_examples 'a rate that has not expired' do
      before { allow(subject).to receive(:rate_changed?).and_return(false) }
      it 'resets the timestamp on the advance' do
        expect(subject).to receive(:timestamp!)
        call_method
      end
      it 'returns false' do
        expect(call_method).to be(false)
      end
    end

    shared_examples 'check the timestamp' do
      let(:timeout) { rand(1..20) }
      describe 'when the timestamp + the timeout < now' do
        before { subject.attributes = {'timestamp' => now - (timeout + 0.1).seconds} }
        describe 'when the rate has changed' do
          include_examples 'a rate that has expired'
        end
        describe 'when the rate has not changed' do
          include_examples 'a rate that has not expired'
        end
      end
      describe 'returns true if the timestamp + the timeout == now' do
        before { subject.attributes = {'timestamp' => now - timeout.seconds} }
        describe 'when the rate has changed' do
          include_examples 'a rate that has expired'
        end
        describe 'when the rate has not changed' do
          include_examples 'a rate that has not expired'
        end
      end
      it 'returns false if the timestamp + the timeout > now' do
        subject.attributes = {'timestamp' => now - (timeout - 0.1).seconds}
        expect(call_method).to be(false)
      end
      it 'returns false if the request has no timestamp' do
        expect(call_method).to be(false)
      end
    end

    describe 'with supplied timeout' do
      let(:call_method) { subject.expired?(timeout) }
      it 'does not fetch settings' do
        expect(subject).to_not receive(:etransact_service)
        call_method
      end
      include_examples 'check the timestamp'
    end
    describe 'without supplied timeout' do
      let(:call_method) { subject.expired? }
      let(:settings) { {rate_timeout: timeout} }
      before do
        allow(subject).to receive_message_chain(:etransact_service, :settings).and_return(settings)
      end
      it 'fetches the eTransact settings' do
        expect(subject).to receive_message_chain(:etransact_service, :settings).and_return(settings)
        call_method
      end
      it 'raises an error if fetching the settings fails' do
        allow(subject).to receive_message_chain(:etransact_service, :settings).and_return(nil)
        expect{call_method}.to raise_error
      end
      it 'raises an error if no timeout is found in the settings' do
        allow(settings).to receive(:[]).with(:rate_timeout).and_return(nil)
        expect{call_method}.to raise_error
      end
      it 'retrives the timeout setting from the settings hash' do
        expect(settings).to receive(:[]).with(:rate_timeout).and_return(timeout).at_least(1)
        call_method
      end
      include_examples 'check the timestamp'
    end
  end

  describe '`rate_for` method' do
    let(:term) { double('A Term') }
    let(:type) { double('A Type') }
    let(:rate) { double('A Rate') }
    let(:rate_details) { {rate: rate} }
    let(:term_table) { {term => rate_details} }
    let(:rate_table) { {type => term_table} }
    let(:call_method) { subject.rate_for(term, type) }
    before do
      allow(term).to receive(:to_sym).and_return(term)
      allow(type).to receive(:to_sym).and_return(type)
      allow(rate).to receive(:to_f).and_return(rate)
      allow(subject).to receive(:rates).and_return(rate_table)
    end
    it 'fetches the rate table from the `rates` attribute' do
      expect(subject).to receive(:rates).and_return(rate_table)
      call_method
    end
    it 'looks up the term/type pair in the rate table' do
      allow(rate_table).to receive(:[]).with(type).and_return(term_table)
      expect(term_table).to receive(:[]).with(term).and_return(rate_details)
      call_method
    end
    it 'converts the found rate to a float and returns it' do
      floated_rate = double('A Float Rate')
      allow(rate).to receive(:to_f).and_return(floated_rate)
      expect(call_method).to be(floated_rate)
    end
    it 'raises an error if the rate is not found' do
      expect{subject.rate_for(double('A Bad Term'), double('A Bad Type'))}.to raise_error
    end
  end

  describe '`rate_for!` method' do
    let(:term) { double('A Term') }
    let(:type) { double('A Type') }
    let(:rate) { double('A Rate', to_f: nil) }
    let(:call_method) { subject.rate_for!(term, type) }
    before do
      allow(subject).to receive(:rate_for).with(term, type).and_return(rate)
    end
    it 'fetches the rate via `rate_for`' do
      expect(subject).to receive(:rate_for).with(term, type)
      call_method
    end
    it 'assigns the rate to the `rate` attribute' do
      expect(subject).to receive(:rate=).with(rate)
      call_method
    end
    it 'returns the rate' do
      expect(call_method).to be(rate)
    end
  end

  describe '`rate!` method' do
    let(:rate) { double('A Rate') }
    let(:term) { double('A Term') }
    let(:type) { double('A Type') }
    let(:call_method) { subject.rate! }
    before do
      allow(subject).to receive(:term).and_return(term)
      allow(subject).to receive(:type).and_return(type)
    end
    describe 'if the `rate` attribute is present' do
      before do
        allow(subject).to receive(:rate).and_return(rate)
      end
      it 'returns the `rate` attribute' do
        expect(call_method).to be(rate)
      end
      it 'does not change the rate' do
        expect(subject).to_not receive(:rate=)
        call_method
      end
    end
    describe 'if the rate is not present' do
      it 'calls `rate_for!` with the `term` and `type` attribute' do
        expect(subject).to receive(:rate_for!).with(term, type)
        call_method
      end
      it 'returns the updated rate attribute' do
        expect(subject).to receive(:rate).and_return(nil).ordered
        expect(subject).to receive(:rate_for!).ordered
        expect(subject).to receive(:rate).and_return(rate).ordered
        expect(call_method).to be(rate)
      end
    end
  end

  describe '`rate=` method' do
    let(:rate) { double('A Rate') }
    let(:floated_rate) { double('A Float Rate') }
    let(:call_method) { subject.rate = rate }
    it 'calls `to_f` on the rate' do
      expect(rate).to receive(:to_f)
      call_method
    end
    it 'stores the transformed rate in the `rate` attribute' do
      allow(rate).to receive(:to_f).and_return(floated_rate)
      call_method
      expect(subject.rate).to be(floated_rate)
    end
  end

  describe '`maturity_date_for` method' do
    let(:term) { double('A Term') }
    let(:type) { double('A Type') }
    let(:maturity_date) { double('A Date') }
    let(:details) { {maturity_date: maturity_date} }
    let(:term_table) { {term => details} }
    let(:rate_table) { {type => term_table} }
    let(:call_method) { subject.maturity_date_for(term, type) }
    before do
      allow(term).to receive(:to_sym).and_return(term)
      allow(type).to receive(:to_sym).and_return(type)
      allow(maturity_date).to receive(:to_date).and_return(maturity_date)
      allow(subject).to receive(:rates).and_return(rate_table)
    end
    it 'fetches the rate table from the `rates` attribute' do
      expect(subject).to receive(:rates).and_return(rate_table)
      call_method
    end
    it 'looks up the term/type pair in the rate table' do
      allow(rate_table).to receive(:[]).with(type).and_return(term_table)
      expect(term_table).to receive(:[]).with(term).and_return(details)
      call_method
    end
    it 'converts the found date string to a date and returns it' do
      maturity_date_to_date = double('A Maturity Date')
      allow(maturity_date).to receive(:to_date).and_return(maturity_date_to_date)
      expect(call_method).to be(maturity_date_to_date)
    end
    it 'raises an error if the rate is not found' do
      expect{subject.maturity_date_for(double('A Bad Term'), double('A Bad Type'))}.to raise_error
    end
  end

  describe '`maturity_date_for!` method' do
    let(:term) { double('A Term') }
    let(:type) { double('A Type') }
    let(:maturity_date) { double('A Maturity date', to_date: nil) }
    let(:call_method) { subject.maturity_date_for!(term, type) }
    before do
      allow(subject).to receive(:maturity_date_for).with(term, type).and_return(maturity_date)
    end
    it 'fetches the maturity_date via `maturity_date_for`' do
      expect(subject).to receive(:maturity_date_for).with(term, type)
      call_method
    end
    it 'assigns the maturity_date to the `maturity_date` attribute' do
      expect(subject).to receive(:maturity_date=).with(maturity_date)
      call_method
    end
    it 'returns the maturity_date' do
      expect(call_method).to be(maturity_date)
    end
  end

  describe '`maturity_date=` method' do
    let(:maturity_date) { double('maturity_date') }
    let(:maturity_date_to_date) { double('maturity_date_to_date') }
    let(:call_method) { subject.maturity_date = maturity_date }
    it 'calls `to_date` on the maturity_date' do
      expect(maturity_date).to receive(:to_date)
      call_method
    end
    it 'stores the transformed maturity_date in the `maturity_date` attribute' do
      allow(maturity_date).to receive(:to_date).and_return(maturity_date_to_date)
      call_method
      expect(subject.maturity_date).to be(maturity_date_to_date)
    end
    it 'stores the transformed maturity_date in the `maturity_date` attribute even if nil' do
      subject.maturity_date = nil
      expect(subject.maturity_date).to be(nil)
    end
  end


  describe '`rates` method' do
    let(:rate_table) { double('A Rate Table') }
    let(:rate_service) { double('A RatesService', quick_advance_rates: rate_table) }
    let(:call_method) { subject.rates }
    describe 'with no stored rates' do
      before do
        allow(subject).to receive(:rate_service).and_return(rate_service)
        allow(subject).to receive(:notify_if_rate_bands_exceeded)
      end
      it 'fetches the rates from the RatesService' do
        expect(rate_service).to receive(:quick_advance_rates).with(member_id)
        call_method
      end
      it 'returns the rates' do
        expect(call_method).to be(rate_table)
      end
      it 'stores the rates' do
        expect(rate_service).to receive(:quick_advance_rates).once
        call_method
        call_method
      end
      it 'passes the rates to `notify_if_rate_bands_exceeded`' do
        expect(subject).to receive(:notify_if_rate_bands_exceeded)
        call_method
      end
    end
    it 'returns the stored rates if present' do
      subject.rates = rate_table
      expect(call_method).to be(rate_table)
    end
  end

  {:term => :ADVANCE_TERMS, :type => :ADVANCE_TYPES}.each do |attr, allowed_values_const_name|
    describe "`#{attr}=` method" do
      let(:sym_value) { double('Symbolic Value') }
      let(:value) { double("A #{attr.to_s.titlecase}", to_sym: sym_value) }
      let(:call_method) { subject.send("#{attr}=", value)}
      let(:allowed_values) { double('Allowed Values') }
      let(:maturity_date) { double('Maturity date') }
      let(:term){double('A Term')}
      let(:type){double('A Type')}

      before do
        stub_const("#{described_class.name}::#{allowed_values_const_name}", allowed_values)
        allow(allowed_values).to receive(:include?).with(sym_value).and_return(true)
        allow(subject).to receive(:maturity_date_for!).with(term, type)
        allow(subject).to receive(:rate_for!).with(term, type)
      end

      it "converts the supplied `#{attr}` to a symbol" do
        expect(value).to receive(:to_sym).and_return(sym_value)
        call_method
      end
      it "checks that the `#{attr}` is an allowed #{attr}" do
        stub_const("#{described_class.name}::#{allowed_values_const_name}", allowed_values)
        allow(allowed_values).to receive(:include?).with(sym_value).and_return(false)
        expect{call_method}.to raise_error
      end
      it 'raises an error if passed `nil`' do
        expect{subject.send("#{attr}=", nil)}.to raise_error
      end
      it "stores the #{attr}" do
        call_method
        expect(subject.send(attr)).to be(sym_value)
      end
      it 'updates the rate if both `term` and `type` are present' do
        allow(subject).to receive(:term).and_return(term)
        allow(subject).to receive(:type).and_return(type)
        expect(subject).to receive(:rate_for!).with(term, type)
        call_method
      end
      it 'updates the maturity_date if both `term` and `type` are present' do
        allow(subject).to receive(:term).and_return(term)
        allow(subject).to receive(:type).and_return(type)
        expect(subject).to receive(:maturity_date_for!).with(term, type)
        call_method
      end
      it "does not update the rate if the `#{attr}` has not changed" do
        call_method
        expect(subject).to_not receive(:rate_for!)
        call_method
      end
      describe 'when both `term` and `type` are present' do
        let(:term) { double('A Term') }
        let(:type) { double('A Tyoe') }
        before do
          allow(subject).to receive(:term).and_return(term)
          allow(subject).to receive(:type).and_return(type)
          allow(subject).to receive(:rate_for!)
        end
        it 'resets the `stock_choice` if the value has changed' do
          expect(subject).to receive(:reset_stock_choice!)
          call_method
        end
        it 'does not reset the `stock_choice` attr if the value has not changed' do
          call_method
          expect(subject).to_not receive(:reset_stock_choice!)
          call_method
        end
        it 'updates the rate' do
          expect(subject).to receive(:rate_for!).with(term, type)
          call_method
        end
      end
      it 'does not reset the `stock_choice` attr if type or term is not present' do
        call_method
        expect(subject).to_not receive(:reset_stock_choice!)
        call_method
      end
      it "does not update the maturity_date if the `#{attr}` has not changed" do
        call_method
        expect(subject).to_not receive(:maturity_date_for!)
        call_method
      end
    end
  end

  [:gross_amount, :amount].each do |attr|
    describe "`#{attr}=` method" do
      let(:transformed_amount) { double('A Transformed Amount') }
      let(:amount) { double('An Amount') }
      let(:call_method) { subject.send("#{attr}=", amount)}

      before do
        allow(subject).to receive(:transform_amount).with(amount, attr).and_return(transformed_amount)
        allow(subject).to receive(:transform_amount).with(nil, attr).and_return(nil)
      end

      if attr == :amount
        it 'resets the `stock_choice` attr via the `reset_stock_choice!` method if the new amount differs from the old amount' do
          expect(subject).to receive(:reset_stock_choice!)
          call_method
        end
        it 'does not reset the `stock_choice` attr if the new amount is the same as the old amount' do
          call_method
          expect(subject).to_not receive(:reset_stock_choice!)
          call_method
        end
      end

      it 'passes the amount through `transform_amount`' do
        expect(subject).to receive(:transform_amount).with(amount, attr)
        call_method
      end
      it 'allows errors raised by `transform_amount` to bubble up' do
        error = Exception.new('Some Error')
        allow(subject).to receive(:transform_amount).and_raise(error)
        expect{call_method}.to raise_error(error)
      end
      it "updates the `#{attr}` attribute" do
        call_method
        expect(subject.send(attr)).to be(transformed_amount)
      end
      it 'handles being passed `nil`' do
        subject.send("#{attr}=", nil)
        expect(subject.send(attr)).to be_nil
      end
    end
  end

  describe '`total_amount` method' do
    let(:call_method) { subject.send(:total_amount) }
    let(:gross_amount) { double('A Gross Amount') }
    let(:amount) { double('An Amount') }
    before do
      allow(subject).to receive(:amount).and_return(amount)
      allow(subject).to receive(:gross_amount).and_return(gross_amount)
    end
    it 'returns the `gross_amount` if a stock purchase was requested' do
      allow(subject).to receive(:purchase_stock?).and_return(true)
      expect(call_method).to be(gross_amount)
    end
    it 'returns the `amount` if a stock purchase was not requested' do
      allow(subject).to receive(:purchase_stock?).and_return(false)
      expect(call_method).to be(amount)
    end
  end

  describe '`stock_choice=` method' do
    let(:sym_value) { double('Symbolic Value') }
    let(:value) { double("A Stock Choice", to_sym: sym_value) }
    let(:call_method) { subject.stock_choice = value}
    let(:allowed_values) { double('Allowed Values') }

    before do
      stub_const("#{described_class.name}::STOCK_CHOICES", allowed_values)
      allow(allowed_values).to receive(:include?).with(sym_value).and_return(true)
    end

    it 'converts the supplied `stock_choice` to a symbol' do
      expect(value).to receive(:to_sym).and_return(sym_value)
      call_method
    end
    it 'checks that the `stock_choice` is an allowed stock_choice}' do
      stub_const("#{described_class.name}::STOCK_CHOICES", allowed_values)
      allow(allowed_values).to receive(:include?).with(sym_value).and_return(false)
      expect{call_method}.to raise_error
    end
    it 'supports being set to `nil`' do
      subject.stock_choice = nil
      expect(subject.stock_choice).to be_nil
    end
    it 'stores the stock_choice' do
      call_method
      expect(subject.stock_choice).to be(sym_value)
    end
  end

  describe '`allow_grace_period=` method' do
    {
      nil => false,
      false => false,
      true => true,
      SecureRandom.hex => true,
      '' => true,
      rand(0..100) => true
    }.each do |assigned, expected|
      it "stores #{expected} if assigned `#{assigned}`" do
        subject.allow_grace_period = assigned
        expect(subject.allow_grace_period).to be(expected)
      end
    end
  end

  describe '`initiated_at=` method' do
    let(:value) { double('A Value') }
    let(:call_method) { subject.initiated_at = value}
    it 'tries to convert the value to a DateTime' do
      expect(value).to receive(:try).with(:to_datetime)
      call_method
    end
    it 'updates the `initiated_at` attribute' do
      allow(value).to receive(:to_datetime).and_return(value)
      call_method
      expect(subject.initiated_at).to be(value)
    end
  end

  describe '`sta_debit_amount` method' do
    let(:gross_stock) { double('A Gross Stock Amount').as_null_object }
    let(:cumulative_stock) { double('A Cumulative Stock Amount').as_null_object }
    let(:call_method) { subject.sta_debit_amount }

    before do
      allow(subject).to receive(:gross_cumulative_stock_required).and_return(gross_stock)
      allow(subject).to receive(:cumulative_stock_required).and_return(cumulative_stock)
    end

    it 'returns the `gross_cumulative_stock_required` if `purchase_stock?` is true' do
      allow(subject).to receive(:purchase_stock?).and_return(true)
      expect(call_method).to be(gross_stock)
    end
    it 'returns the `cumulative_stock_required` if `purchase_stock?` is false' do
      allow(subject).to receive(:purchase_stock?).and_return(false)
      expect(call_method).to be(cumulative_stock)
    end
    it 'returns a float if the stock cost is present' do
      allow(subject).to receive(:purchase_stock?).and_return(false)
      expect(cumulative_stock).to receive(:to_f)
      call_method
    end
    it 'returns nil if the stock cost is nil' do
      allow(subject).to receive(:gross_cumulative_stock_required).and_return(nil)
      allow(subject).to receive(:cumulative_stock_required).and_return(nil)
      expect(call_method).to be_nil
    end
  end

  describe '`validate_advance` method' do
    let(:call_method) { subject.validate_advance }

    before do
      allow(subject).to receive(:perform_limit_check)
      allow(subject).to receive(:perform_rate_check)
      allow(subject).to receive(:perform_preview)
    end

    it 'calls `clear_errors` first' do
      expect(subject).to receive(:clear_errors)
      call_method
    end
    it 'calls `perform_limit_check`' do
      expect(subject).to receive(:clear_errors).ordered
      expect(subject).to receive(:perform_limit_check).ordered
      call_method
    end
    it 'calls `perform_preview`' do
      expect(subject).to receive(:clear_errors).ordered
      expect(subject).to receive(:perform_preview).ordered
      call_method
    end
    it 'calls `perform_rate_check`' do
      expect(subject).to receive(:clear_errors).ordered
      expect(subject).to receive(:perform_rate_check).ordered
      call_method
    end
    it 'returns true if no errors were found' do
      allow(subject).to receive(:no_errors_present?).and_return(true)
      expect(call_method).to be(true)
    end
    it 'returns false if errors were found' do
      allow(subject).to receive(:no_errors_present?).and_return(false)
      expect(call_method).to be(false)
    end
  end

  describe '`rate_changed?` method' do
    let(:old_rate) { double('An Old Rate') }
    let(:rate) { double('An Rate') }
    let(:call_method) { subject.rate_changed? }

    it 'returns true if the `old_rate` is present and does not match the `rate`' do
      allow(subject).to receive(:old_rate).and_return(old_rate)
      allow(subject).to receive(:rate).and_return(rate)
      expect(call_method).to be(true)
    end
    it 'returns false if the `old_rate` is not present' do
      expect(call_method).to be(false)
    end
    it 'returns false if the `old_rate` matches the `rate`' do
      allow(subject).to receive(:old_rate).and_return(rate)
      allow(subject).to receive(:rate).and_return(rate)
      expect(call_method).to be(false)
    end
  end

  describe '`errors` method' do
    let(:call_method) { subject.errors }
    let(:error) { double('An Error') }
    it 'returns an empty array if there are no errors' do
      expect(call_method).to eq([])
    end
    it 'returns an array of errors if there are errors' do
      subject.instance_variable_set(:@errors, [error])
      expect(call_method).to eq([error])
    end
  end

  describe '`program_name` method' do
    let(:call_method) { subject.program_name }
    describe 'when `type` is `:whole`' do
      it 'returns a string for standard loans' do
        allow(subject).to receive(:type).and_return(:whole)
        expect(call_method).to eq(I18n.t('dashboard.quick_advance.table.axes_labels.standard'))
      end
    end
    [:aa, :aaa, :agency].each do |type|
      describe "when `type` is `#{type}`" do
        it 'returns a string for securities backed loans' do
          allow(subject).to receive(:type).and_return(type)
          expect(call_method).to eq(I18n.t('dashboard.quick_advance.table.axes_labels.securities_backed'))
        end
      end
    end
    describe 'when `type` is anything else' do
      it 'returns the `type` value directly' do
        type = double('A Type')
        allow(subject).to receive(:type).and_return(type)
        expect(call_method).to be(type)
      end
    end
  end

  describe '`term_description` method' do
    let(:call_method) { subject.term_description }
    [:open, :overnight].each do |term|
      it "returns VRC when the `term` is `#{term}`" do
        allow(subject).to receive(:term).and_return(term)
        expect(call_method).to eq(I18n.t('dashboard.quick_advance.vrc_title'))
      end
    end
    it 'returns nil when `term` is nil' do
      expect(call_method).to be_nil
    end
    it 'returns FRC when the `term` is anything else' do
      allow(subject).to receive(:term).and_return(double('A Term'))
      expect(call_method).to eq(I18n.t('dashboard.quick_advance.frc_title'))
    end
  end

  describe '`human_type` method' do
    let(:call_method) { subject.human_type }
    {
      whole: I18n.t('dashboard.quick_advance.table.whole_loan'),
      agency: I18n.t('dashboard.quick_advance.table.agency'),
      aa: I18n.t('dashboard.quick_advance.table.aa'),
      aaa: I18n.t('dashboard.quick_advance.table.aaa')
    }.each do |type, human_type|
      it "returns `#{human_type}` when the `type` is `#{type}`" do
        allow(subject).to receive(:type).and_return(type)
        expect(call_method).to eq(human_type)
      end
    end
    it 'returns the `type` when its anything else' do
      type = double('A Type')
      allow(subject).to receive(:type).and_return(type)
      expect(call_method).to be(type)
    end
  end

  describe '`human_term` method' do
    let(:call_method) { subject.human_term }
    described_class::ADVANCE_TERMS.each do |term|
      human_term = I18n.t("dashboard.quick_advance.table.axes_labels.#{term}")
      it "returns `#{human_term}` when the `term` is `#{term}`" do
        allow(subject).to receive(:term).and_return(term)
        expect(call_method).to eq(human_term)
      end
    end
    it 'returns the `term` when its anything else' do
      term = double('A Term')
      allow(subject).to receive(:term).and_return(term)
      expect(call_method).to be(term)
    end
  end

  describe '`collateral_type` method' do
    let(:call_method) { subject.collateral_type }
    {
      whole: I18n.t('dashboard.quick_advance.table.mortgage'),
      agency: I18n.t('dashboard.quick_advance.table.agency'),
      aa: I18n.t('dashboard.quick_advance.table.aa'),
      aaa: I18n.t('dashboard.quick_advance.table.aaa')
    }.each do |type, collateral_type|
      it "returns `#{collateral_type}` when the `type` is `#{type}`" do
        allow(subject).to receive(:type).and_return(type)
        expect(call_method).to eq(collateral_type)
      end
    end
    it 'returns the `type` when its anything else' do
      type = double('A Type')
      allow(subject).to receive(:type).and_return(type)
      expect(call_method).to be(type)
    end
  end

  describe '`current_state` method' do
    it 'returns the current state of the state machine' do
      state = double('A State')
      allow(subject).to receive_message_chain(:aasm, :current_state).and_return(state)
      expect(subject.current_state).to be(state)
    end
  end

  describe '`attributes` method' do
    let(:call_method) { subject.attributes }
    persisted_attributes = described_class::READONLY_ATTRS + described_class::REQUEST_PARAMETERS + described_class::CORE_PARAMETERS + [:id] - described_class::SERIALIZATION_EXCLUDE_ATTRS

    before do
      persisted_attributes.each { |attr| allow(subject).to receive(attr) }
    end

    it 'returns a hash of attribute values' do
      expect(call_method).to be_kind_of(Hash)
    end

    (persisted_attributes).each do |attr|
      it "includes the key `#{attr}` with a value of nil if the attribute is present" do
        value = double('A Value')
        allow(subject).to receive(attr).and_return(value)
        expect(call_method).to have_key(attr)
      end
      it "does not include `#{attr}` if the attribute is nil" do
        allow(subject).to receive(attr).and_return(nil)
        expect(call_method).to_not have_key(attr)
      end
    end

    it 'returns the `current_state` under the key `current_state`' do
      current_state = double('The Current State')
      allow(subject).to receive(:current_state).and_return(current_state)
      expect(call_method[:current_state]).to be(current_state)
    end

    described_class::SERIALIZATION_EXCLUDE_ATTRS.each do |attr|
      it "does not include `#{attr}`" do
        allow(subject).to receive(attr).and_return(double('A Value'))
        expect(call_method).to_not have_key(attr)
      end
    end
  end

  describe '`attributes=` method' do
    let(:hash) { {} }
    let(:call_method) { subject.attributes = hash}
    it 'assigns the value found under `current_state` in the attribute hash to the state machine `current_state`' do
      hash[:current_state] = double('Some State')
      symbol_state = double('Some State Symbol')
      allow(hash[:current_state]).to receive(:to_sym).and_return(symbol_state)
      call_method
      expect(subject.current_state).to be(symbol_state)
    end
    it 'processes the keys in the order: rates, term, type, amount, and then the remaining keys' do
      other_key = described_class::REQUEST_PARAMETERS.sample
      hash[:type] = :aa
      hash[:rates] = double('Some Rates', with_indifferent_access: nil)
      hash[:term] = :open
      hash[:amount] = rand(100000..999999)
      hash[other_key] = 'some value'
      expect(subject).to receive(:rates=).ordered
      expect(subject).to receive(:term=).ordered
      expect(subject).to receive(:type=).ordered
      expect(subject).to receive(:amount=).ordered
      expect(subject).to receive("#{other_key}=").ordered
      call_method
    end
    (described_class::READONLY_ATTRS + described_class::REQUEST_PARAMETERS + described_class::CORE_PARAMETERS + [:id] - described_class::SERIALIZATION_EXCLUDE_ATTRS).each do |key|
      it "assigns the value found under `#{key}` to the attribute `#{key}`" do
        case key
        when :type
          value = :aa
        when :term
          value = :open
        when :stock_choice
          value = :continue
        when :gross_amount, :amount
          value = double('A Value').as_null_object
          allow(value).to receive(:dup).and_return(value)
        when :timestamp
          expected_value = double('A Converted Value')
          value = double('A Value', to_datetime: expected_value)
        when :rates
          expected_value = double('A Converted Value')
          value = double('A Value', with_indifferent_access: expected_value)
        when :owners
          expected_value = double('Set of Owners')
          value = double('A Value', to_set: expected_value)
        when :allow_grace_period
          value = true
        else
          value = double('A Value').as_null_object
        end
        expected_value ||= value
        hash[key.to_s] = value
        call_method
        expect(subject.send(key)).to be(expected_value)
      end
    end
    it 'raises an error if it encounters an unknown attribute' do
      hash[double('An Unknown Key').as_null_object] = double('A Value')
      expect{call_method}.to raise_error
    end
    described_class::SERIALIZATION_EXCLUDE_ATTRS.each do |attr|
      it 'raises an error if it encounters an excluded attribute' do
        hash[attr] = double('A Value')
        expect{call_method}.to raise_error
      end
    end
    it 'converts the rates to an indifferent access hash' do
      rates = double('Rates')
      hash[:rates] = rates
      allow(subject).to receive(:rates).and_return(rates)
      expect(rates).to receive(:with_indifferent_access)
      call_method
    end
  end

  describe '`save` method' do
    let(:redis_value) { double(Redis::Value, :set => true, :expire => true) }
    let(:json) { double('Some JSON') }
    let(:call_method) { subject.save }
    before do
      allow(subject).to receive(:redis_value).and_return(redis_value)
      allow(subject).to receive(:to_json).and_return(json)
    end
    it 'calls `set` on the `redis_value` with the JSON repersentation' do
      expect(redis_value).to receive(:set).with(json)
      call_method
    end
    it 'sets an expiration on the `redis_value`' do
      expect(redis_value).to receive(:expire).with(Rails.configuration.x.advance_request.key_expiration)
      call_method
    end
    it 'logs the save' do
      expect(subject).to receive(:log)
      call_method
    end
    it 'does not set the expiration if the save fails' do
      allow(redis_value).to receive(:set).and_return(false)
      expect(redis_value).to_not receive(:expire)
      call_method
    end
    it 'returns true on success' do
      expect(call_method).to be(true)
    end
    it 'returns false if the save fails' do
      allow(redis_value).to receive(:set).and_return(false)
      expect(call_method).to be(false)
    end
    it 'returns false if the expiration update fails' do
      allow(redis_value).to receive(:expire).and_return(false)
      expect(call_method).to be(false)
    end
  end

  describe '`ttl` method' do
    let(:redis_value) { double(Redis::Value) }
    it 'returns the `ttl` value from Redis' do
      ttl = double('A TTL')
      allow(subject).to receive(:redis_value).and_return(redis_value)
      allow(redis_value).to receive(:ttl).and_return(ttl)
      expect(subject.ttl).to be(ttl)
    end
  end

  describe '`inspect` method' do
    let(:call_method) { subject.inspect }

    it 'returns a String' do
      expect(call_method).to be_kind_of(String)
    end
    [:type, :term, :amount, :id, :current_state, :rate, :stock_choice].each do |attr|
      it "includes the `#{attr}`" do
        expect(call_method).to include(subject.send(attr).to_s)
      end
    end

    it 'includes the `errors`' do
      expect(call_method).to include(subject.errors.inspect)
    end
  end

  describe '`owners` method' do
    let(:call_method) { subject.owners }
    it 'returns a Set' do
      expect(call_method).to be_kind_of(Set)
    end
    it 'returns the same object on each call' do
      set = call_method
      expect(call_method).to be(set)
    end
  end

  {from_json: :from_json, from_hash: :attributes=}.each do |class_method, instance_method|
    describe "`#{class_method}` class method" do
      let(:input) { double('Some Input') }
      let(:call_method) { described_class.send(class_method, input) }

      before do
        allow_any_instance_of(described_class).to receive(instance_method)
      end

      it 'creates a new blank instance' do
        expect(described_class).to receive(:new).with(nil, nil, nil).and_call_original
        call_method
      end
      it 'passes along the supplied `request` parameter to the new instance' do
        expect(described_class).to receive(:new).with(nil, nil, request).and_call_original
        described_class.send(class_method, input, request)
      end
      it "calls `#{instance_method}` on the new instance" do
        expect_any_instance_of(described_class).to receive(instance_method).with(input)
        call_method
      end
      it 'returns the new instance' do
        instance = double(described_class).as_null_object
        allow(described_class).to receive(:new).and_return(instance)
        expect(call_method).to be(instance)
      end
    end
  end

  describe '`find` class method' do
    let(:id) { double('An ID') }
    let(:value) { subject.to_json }
    let(:redis_value) { double(Redis::Value, nil?: false, value: value, expire: true) }
    let(:call_method) { described_class.find(id, request) }

    before do
      allow(described_class).to receive(:redis_value).with(id).and_return(redis_value)
    end

    it 'call `redis_value`' do
      expect(described_class).to receive(:redis_value).with(id)
      call_method
    end
    it 'raises an `ActiveRecord::RecordNotFound` if the key is not found' do
      allow(redis_value).to receive(:nil?).and_return(true)
      expect{call_method}.to raise_error(ActiveRecord::RecordNotFound)
    end
    describe 'with a found key' do
      it "converts the JSON to an `#{described_class}` instance" do
        expect(described_class).to receive(:from_json).with(value, anything)
        call_method
      end
      it 'gives the new instance the supplied request if one is present' do
        expect(described_class).to receive(:from_json).with(anything, request)
        call_method
      end
      it 'updates the expiration on the key in Redis' do
        expect(redis_value).to receive(:expire).with(Rails.configuration.x.advance_request.key_expiration)
        call_method
      end
      it 'logs the find' do
        expect(described_class).to receive(:log)
        call_method
      end
      it 'returns the new instance' do
        instance = double(described_class)
        allow(described_class).to receive(:from_json).and_return(instance)
        expect(call_method).to be(instance)
      end
    end
  end

  describe '`redis_key` class method' do
    it 'joins the class name and the supplied `id`' do
      id = SecureRandom.uuid
      expect(described_class.redis_key(id)).to eq(described_class.name + ':' + id)
    end
  end

  describe '`redis_value` class method' do
    let(:id) { SecureRandom.uuid }
    let(:call_method) { described_class.redis_value(id) }
    it 'contrcuts a new `Redis::Value` using the key from `redis_key`' do
      key = double('A Redis Key')
      allow(described_class).to receive(:redis_key).and_return(key)
      expect(Redis::Value).to receive(:new).with(key)
      call_method
    end
    it 'returns the new instance' do
      value = double(Redis::Value)
      allow(Redis::Value).to receive(:new).and_return(value)
      expect(call_method).to be(value)
    end
  end

  describe '`log` class method' do
    let(:level) { double('A Log Level') }
    let(:message)  { double('A Message', to_s: SecureRandom.hex) }
    let(:block) { Proc.new { message } }
    let(:call_method) { described_class.log(level, &block) }

    it 'calls the Rails logger with the supplied level' do
      expect(Rails.logger).to receive(:send).with(level)
      call_method
    end
    it 'uses level `info` if none is provided' do
      expect(Rails.logger).to receive(:info)
      described_class.log
    end
    it 'the Rails logger block calls the supplied block and prepends the `LOG_PREFIX` to its results' do
      allow(Rails.logger).to receive(:send).with(level) do |*args, &block|
        expect(block.call).to eq(described_class::LOG_PREFIX + message.to_s)
      end
      call_method
    end
  end

  describe '`policy_class` class method' do
    it 'returns the AdvancePolicy class' do
      expect(described_class.policy_class).to eq(AdvancePolicy)
    end
  end

  describe '`log` protected method' do
    let(:level) { double('A Log Level') }
    let(:block) { Proc.new {} }
    it 'calls `log` on the class with the supplied level and block' do
      expect(described_class).to receive(:log).with(level) do |*args, &proc|
        expect(proc).to be(block)
      end
      subject.send(:log, level, &block)
    end
    it 'uses `info` if no level has been provided' do
      expect(described_class).to receive(:log).with(:info)
      subject.send(:log)
    end
  end

  describe '`redis_value` protected method' do
    let(:value) { double(Redis::Value) }
    let(:call_method) { subject.send(:redis_value) }

    it 'returns the result of calling `redis_value` on the class' do
      allow(described_class).to receive(:redis_value).with(subject.id).and_return(value)
      expect(call_method).to be(value)
    end
    it 'returns the same instance on subsequent calls' do
      value = call_method
      expect(call_method).to be(value)
    end
  end


  describe '`notify_if_rate_bands_exceeded` protected method' do
    let(:request_uuid) { double('Some UUID') }
    let(:mail_message) { double('A Mail Message', deliver_now: nil) }
    let(:rate_band_info) { double('rate band info', :[] => nil) }
    let(:rate_data) { double('rate_data', :[]= => nil, :[] => nil) }
    let(:rates) { double('rates', :[] => double('term rates', :[] => rate_data)) }
    let(:call_method) { subject.send(:notify_if_rate_bands_exceeded) }

    before do
      allow(request).to receive(:uuid).and_return(request_uuid)
      allow(InternalMailer).to receive(:exceeds_rate_band).and_return(mail_message)
      subject.instance_variable_set(:@rates, rates)
      allow(rate_data).to receive(:dup).and_return(rate_data)
    end
    describe 'when a rate is disabled' do
      before do
        allow(rate_data).to receive(:[]).with(:disabled).and_return(true)
        allow(rate_data).to receive(:[]).with(:rate_band_info).and_return(rate_band_info)
        allow(rate_data).to receive(:[]).with(:end_of_day).and_return(false)
      end
      it 'sends the `exceeds_rate_band` email if a rate is disabled and has exceeded its minimum threshold' do
        allow(rate_band_info).to receive(:[]).with(:min_threshold_exceeded).and_return(true)
        allow(InternalMailer).to receive(:exceeds_rate_band).with(rate_data, request_uuid, signer).and_return(mail_message)
        expect(mail_message).to receive(:deliver_now)
        call_method
      end
      it 'sends the `exceeds_rate_band` email if a rate is disabled and has exceeded its maximum threshold' do
        allow(rate_band_info).to receive(:[]).with(:max_threshold_exceeded).and_return(true)
        allow(InternalMailer).to receive(:exceeds_rate_band).with(rate_data, request_uuid, signer).and_return(mail_message)
        expect(mail_message).to receive(:deliver_now)
        call_method
      end
      it 'does not send an email if a rate has not exceeded its thresholds' do
        expect(InternalMailer).to_not receive(:exceeds_rate_band)
        call_method
      end
      it 'does not send an email if a rate is disabled due to end of day' do
        allow(rate_band_info).to receive(:[]).with(:min_threshold_exceeded).and_return(true)
        allow(rate_data).to receive(:[]).with(:end_of_day).and_return(true)
        expect(InternalMailer).to_not receive(:exceeds_rate_band)
        call_method
      end
    end
    it 'does not send an email if a rate is not disabled' do
      expect(InternalMailer).to_not receive(:exceeds_rate_band)
      call_method
    end
    it 'does not raise an error if `rates` is nil' do
      allow(subject).to receive(:rates).and_return(nil)
      expect{call_method}.to_not raise_error
    end
  end

  describe '`terms_present?` protected method' do
    let(:call_method) { subject.send(:terms_present?) }
    let(:present_value) { double('A Value', present?: true) }
    attributes = [:term, :type, :rate!, :amount]
    before do
      attributes.each do |attr|
        allow(subject).to receive(attr).and_return(present_value)
      end
    end
    it 'returns true if term, type, rate! and amount are present' do
      expect(call_method).to be(true)
    end
    attributes.each do |attr|
      it "returns false if `#{attr}` is not present" do
        allow(subject).to receive(attr).and_return(nil)
        expect(call_method).to be(false)
      end
    end
  end

  describe '`stock_choice_present?` protected method' do
    it 'returns the result of calling `present?` on the `stock_choice` attribute' do
      stock_choice = double('A Stock Choice', present?: double('A Boolean'))
      allow(subject).to receive(:stock_choice).and_return(stock_choice)
      expect(subject.send(:stock_choice_present?)).to be(stock_choice.present?)
    end
  end

  describe '`purchase_stock?` protected method' do
    let(:call_method) { subject.send(:purchase_stock?) }
    it 'returns true if `stock_choice` is not `nil` or `:continue`' do
      allow(subject).to receive(:stock_choice).and_return(double('A Stock Choice'))
      expect(call_method).to be(true)
    end
    it 'returns false if `stock_choice` is `nil`' do
      allow(subject).to receive(:stock_choice).and_return(nil)
      expect(call_method).to be(false)
    end
    it 'returns false if `stock_choice` is `:continue`' do
      allow(subject).to receive(:stock_choice).and_return(:continue)
      expect(call_method).to be(false)
    end
  end

  describe '`clear_errors` protected method' do
    it 'zeros out the errors array' do
      subject.instance_variable_set(:@errors, [double('An Error')])
      subject.send(:clear_errors)
      expect(subject.errors).to eq([])
    end
  end

  describe '`add_error` protected method' do
    let(:type) { double('An Error Type') }
    let(:code) { double('An Error Code') }
    let(:error) { double(described_class::Error) }

    it 'adds a new error to the errors array' do
      value = double('An Error Value')
      allow(described_class::Error).to receive(:new).with(type, code, value).and_return(error)
      subject.send(:add_error, type, code, value)
      expect(subject.errors).to include(error)
    end

    it 'defaults the value to nil if not supplied' do
      allow(described_class::Error).to receive(:new).with(type, code, nil).and_return(error)
      subject.send(:add_error, type, code)
      expect(subject.errors).to include(error)
    end
  end

  describe '`no_errors_present?` protected method' do
    let(:errors) { double('An Error Array') }
    let(:call_method) { subject.send(:no_errors_present?) }

    before do
      subject.instance_variable_set(:@errors, errors)
    end

    it 'returns false if there are errors' do
      allow(errors).to receive(:present?).and_return(true)
      expect(call_method).to be(false)
    end

    it 'returns true if there are no errors' do
      allow(errors).to receive(:present?).and_return(false)
      expect(call_method).to be(true)
    end
  end

  {etransact_service: EtransactAdvancesService, rate_service: RatesService}.each do |method, service_class|
    describe "`#{method}` protected method" do
      let(:call_method) { subject.send(method) }
      let(:service_object) { double(service_class) }
      it "constructs a new #{service_class} instance and returns it" do
        allow(service_class).to receive(:new).with(request).and_return(service_object)
        expect(call_method).to be(service_object)
      end
      it "stores the #{service_class} instance for subsequent calls" do
        expect(service_class).to receive(:new).with(request).and_return(service_object).once
        call_method
        call_method
      end
    end
  end

  describe '`populate_attributes_from_response` protected method' do
    let(:response_hash) { {} }
    let(:value) { double('A Value') }
    let(:call_method) { subject.send(:populate_attributes_from_response, response_hash) }
    described_class::REQUEST_PARAMETERS.each do |attr|
      it "assigns the attribute `#{attr}` the value found in the response hash for the key `#{attr}`" do
        response_hash[attr] = value
        expect(subject).to receive("#{attr}=").with(value)
        call_method
      end
    end

    described_class::PREVIEW_EXCLUDE_KEYS.each do |excluded_attr|
      it "does not assign `#{excluded_attr}` even if found in the response hash" do
        response_hash[excluded_attr] = value
        expect(subject).to_not receive(:send).with("#{excluded_attr}=", value)
        call_method
      end
    end
    it 'handles being passed `nil`' do
      expect{subject.send(:populate_attributes_from_response, nil)}.to_not raise_error
    end
  end

  describe '`perform_limit_check` protected method' do
    let(:service_object) { double(EtransactAdvancesService) }
    let(:amount) { double('An Amount') }
    let(:term) { double('A Term') }
    let(:call_method) { subject.send(:perform_limit_check) }

    before do
      allow(subject).to receive(:term).and_return(term)
      allow(subject).to receive(:amount).and_return(amount)
      allow(subject).to receive(:etransact_service).and_return(service_object)
      allow(service_object).to receive(:check_limits)
    end

    it 'calls `check_limits` on the `etransact_service` object' do
      expect(service_object).to receive(:check_limits).with(member_id, amount, term)
      call_method
    end
    it 'adds an error of type `:limits` and code `:unknown` if the limit check fails' do
      expect(subject).to receive(:add_error).with(:limits, :unknown)
      call_method
    end
    it 'if the check status is not pass, adds an error of type `:limits`, a code of the status value and a value of the related response key' do
      sym_status = double('A Symbolic Status')
      status = double('A Status', to_sym: sym_status)
      value = double('A Value')
      allow(service_object).to receive(:check_limits).and_return(status: status, sym_status => value)
      expect(subject).to receive(:add_error).with(:limits, sym_status, value)
      call_method
    end
    it 'does not add an error if the limit check returns a status of `pass`' do
      allow(service_object).to receive(:check_limits).and_return(status: 'pass')
      expect(subject).to_not receive(:add_error)
      call_method
    end
  end

  describe '`perform_preview` protected method' do
    let(:service_object) { double(EtransactAdvancesService) }
    let(:amount) { double('An Amount') }
    let(:term) { double('A Term') }
    let(:type) { double('A Type') }
    let(:rate) { double('A Rate') }
    let(:maturity_date) { double('maturity_date') }
    let(:call_method) { subject.send(:perform_preview) }
    let(:allow_grace_period) { double('Allow Grace Period') }
    let(:response) { double('A Quick Advance Validate Response', each: nil, :[] => []) }

    before do
      allow(subject).to receive(:type).and_return(type)
      allow(subject).to receive(:rate).and_return(rate)
      allow(subject).to receive(:term).and_return(term)
      allow(subject).to receive(:maturity_date).and_return(maturity_date)
      allow(subject).to receive(:amount).and_return(amount)
      allow(subject).to receive(:etransact_service).and_return(service_object)
      allow(subject).to receive(:stock_choice_present?).and_return(false)
      allow(subject).to receive(:allow_grace_period).and_return(allow_grace_period)
      allow(service_object).to receive(:quick_advance_validate).and_return(response)
    end

    it 'calls `quick_advance_validate`' do
      expect(service_object).to receive(:quick_advance_validate).with(member_id, amount, type, term, rate, anything, signer, maturity_date, allow_grace_period)
      call_method
    end
    it 'calls `quick_advance_validate` with a check stock value of `true` if `stock_choice_present?` returns false' do
      expect(service_object).to receive(:quick_advance_validate).with(anything, anything, anything, anything, anything, true, anything, anything, anything)
      call_method
    end
    it 'calls `quick_advance_validate` with a check stock value of `false` if `stock_choice_present?` returns true' do
      allow(subject).to receive(:stock_choice_present?).and_return(true)
      expect(service_object).to receive(:quick_advance_validate).with(anything, anything, anything, anything, anything, false, anything, anything, anything)
      call_method
    end
    it 'calls `process_trade_errors` with the `quick_advance_validate` response' do
      expect(subject).to receive(:process_trade_errors).with(:preview, response)
      call_method
    end
    it 'calls `populate_attributes_from_response` with the `quick_advance_validate` response' do
      expect(subject).to receive(:populate_attributes_from_response).with(response)
      call_method
    end
  end

  describe '`perform_rate_check` protected method' do
    let(:term) { double('A Term') }
    let(:type) { double('A Type') }
    let(:rate) { double('A Rate') }
    let(:rate_service_object) { double(RatesService, rate: rate_details) }
    let(:etransact_service_object) { double(EtransactAdvancesService, settings: settings) }
    let(:rate_timeout) { rand(5..20) }
    let(:settings) { {rate_stale_check: rate_timeout} }
    let(:rate_details) { {updated_at: Time.zone.now, rate: rate} }
    let(:call_method) { subject.send(:perform_rate_check) }

    before do
      allow(rate).to receive(:to_f).and_return(rate)
      subject.rate = rate
      allow(subject).to receive(:rate_service).and_return(rate_service_object)
      allow(subject).to receive(:etransact_service).and_return(etransact_service_object)
    end

    it 'fetches the eTransact settings' do
      expect(etransact_service_object).to receive(:settings)
      call_method
    end
    it 'fetches the current rate information' do
      expect(rate_service_object).to receive(:rate)
      call_method
    end
    it 'adds an error if the rate check fails' do
      allow(rate_service_object).to receive(:rate).and_return(nil)
      expect(subject).to receive(:add_error).with(:rate, :unknown)
      call_method
    end
    it 'adds an error if the settings fetch fails' do
      allow(etransact_service_object).to receive(:settings).and_return(nil)
      expect(subject).to receive(:add_error).with(:rate, :settings)
      call_method
    end
    it 'has no errors when everything works' do
      expect(subject).to_not receive(:add_error)
      call_method
    end

    describe 'when the rate is stale' do
      let(:request_uuid) { double('Some UUID') }
      let(:mail_message) { double('A Mail Message', deliver_now: nil) }
      before do
        allow(request).to receive(:request_uuid).and_return(request_uuid)
        rate_details[:updated_at] = Time.zone.now.to_datetime - 30.seconds
        allow(InternalMailer).to receive(:stale_rate).and_return(mail_message)
      end
      it 'sends a stale rate warning email' do
        allow(InternalMailer).to receive(:stale_rate).with(rate_timeout, request_uuid, signer).and_return(mail_message)
        expect(mail_message).to receive(:deliver_now)
        call_method
      end
      it 'adds a stale rate error' do
        expect(subject).to receive(:add_error).with(:rate, :stale)
        call_method
      end
      describe 'and the advance is being executed' do
        before do
          allow(subject).to receive_message_chain(:aasm, :current_event).and_return(:execute)
        end
        it 'does not add an error' do
          expect(subject).to_not receive(:add_error).with(:rate, :stale)
          call_method
        end
        it 'does not send a stale rate warning email' do
          expect(InternalMailer).to_not receive(:stale_rate)
          call_method
        end
      end
    end

    describe 'when the rate is not stale' do
      it 'does not add a stale rate error' do
        expect(subject).to_not receive(:add_error).with(:rate, :stale)
        call_method
      end
    end

    describe 'when the rate has changed' do
      let(:new_rate) { double('A New Rate') }
      before do
        allow(new_rate).to receive(:to_f).and_return(new_rate)
        rate_details[:rate] = new_rate
      end
      it 'sets the `old_rate` to the current `rate`' do
        call_method
        expect(subject.old_rate).to be(rate)
      end
      it 'sets the `rate` to be the new rate' do
        call_method
        expect(subject.rate).to be(new_rate)
      end
      it 'does not update the rate if the advance is being executed' do
        allow(subject).to receive_message_chain(:aasm, :current_event).and_return(:execute)
        call_method
        expect(subject.rate).to be(rate)
      end
    end
  end

  describe '`perform_execute` protected method' do
    let(:service_object) { double(EtransactAdvancesService) }
    let(:amount) { double('An Amount') }
    let(:gross_amount) { double('A Gross Amount') }
    let(:term) { double('A Term') }
    let(:type) { double('A Type') }
    let(:rate) { double('A Rate') }
    let(:allow_grace_period) { double('Allow Grace Period') }
    let(:call_method) { subject.send(:perform_execute) }
    let(:response) { double('A Quick Advance Execute Response', each: nil, :[] => []) }
    let(:mail_message) { double(Mail::Message, deliver_now: nil) }

    before do
      allow(subject).to receive(:type).and_return(type)
      allow(subject).to receive(:rate).and_return(rate)
      allow(subject).to receive(:term).and_return(term)
      allow(subject).to receive(:amount).and_return(amount)
      allow(subject).to receive(:maturity_date).and_return(maturity_date)
      allow(subject).to receive(:gross_amount).and_return(gross_amount)
      allow(subject).to receive(:etransact_service).and_return(service_object)
      allow(subject).to receive(:allow_grace_period).and_return(allow_grace_period)
      allow(service_object).to receive(:quick_advance_execute).and_return(response)
      allow(InternalMailer).to receive(:long_term_advance).and_return(mail_message)
    end

    it 'calls `quick_advance_execute`' do
      expect(service_object).to receive(:quick_advance_execute).with(member_id, anything, type, term, rate, signer, maturity_date, allow_grace_period)
      call_method
    end
    it 'calls `quick_advance_execute` with the `amount` if no stock purchase is requested' do
      allow(subject).to receive(:purchase_stock?).and_return(false)
      expect(service_object).to receive(:quick_advance_execute).with(anything, amount, anything, anything, anything, anything, anything, anything)
      call_method
    end
    it 'calls `quick_advance_execute` with the `gross_amount` if stock purchase is requested' do
      allow(subject).to receive(:purchase_stock?).and_return(true)
      expect(service_object).to receive(:quick_advance_execute).with(anything, gross_amount, anything, anything, anything, anything, anything, anything)
      call_method
    end
    it 'calls `process_trade_errors` with the `quick_advance_execute` response' do
      expect(subject).to receive(:process_trade_errors).with(:execute, response)
      call_method
    end
    it 'calls `populate_attributes_from_response` with the `quick_advance_execute` response' do
      expect(subject).to receive(:populate_attributes_from_response).with(response)
      call_method
    end
    describe 'when the advance is successfully executed' do
      it 'sends a long term advance email if the term was > 3 months' do
        term = described_class::LONG_ADVANCE_TERMS.sample
        allow(subject).to receive(:term).and_return(term)
        expect(InternalMailer).to receive(:long_term_advance).with(subject).and_return(mail_message)
        call_method
      end
      it 'does not send a long term advance email if the term was <= 3 months' do
        term = (described_class::ADVANCE_TERMS - described_class::LONG_ADVANCE_TERMS).sample
        allow(subject).to receive(:term).and_return(term)
        expect(InternalMailer).to_not receive(:long_term_advance).with(subject)
        call_method
      end
    end
    describe 'when the advance is not successfully executed' do
      before do
        subject.send(:add_error, 'foo', 'bar')
      end
      it 'does not send a long term advance email' do
        term = described_class::LONG_ADVANCE_TERMS.sample
        allow(subject).to receive(:term).and_return(term)
        expect(InternalMailer).to_not receive(:long_term_advance).with(subject)
        call_method
      end
    end
  end

  describe '`process_trade_errors` protected method' do
    let(:error_type) { double('An Error Type') }
    let(:response) { double('A Response', :[] => nil) }
    let(:call_method) { subject.send(:process_trade_errors, error_type, response) }

    it 'adds an error with a code of `:unknown` if nil is passed for the response' do
      expect(subject).to receive(:add_error).with(error_type, :unknown)
      subject.send(:process_trade_errors, error_type, nil)
    end

    it 'adds an error with a code of `:unknown` if the response has no `status` key' do
      expect(subject).to receive(:add_error).with(error_type, :unknown)
      call_method
    end

    it 'adds an error with a code of `:unknown` if status key does not contain an Array' do
      allow(response).to receive(:[]).with(:status).and_return('Succces')
      expect(subject).to receive(:add_error).with(error_type, :unknown)
      call_method
    end

    describe 'with a valid response' do
      let(:random_status) { double('An Unknown Status')}

      it 'adds no errors if the response status contains `Success`' do
        allow(response).to receive(:[]).with(:status).and_return(['Success', random_status])
        expect(subject).to_not receive(:add_error)
      end
      {
        'CapitalStockError' => :capital_stock,
        'CreditError' => :credit,
        'CollateralError' => :collateral,
        'ExceedsTotalDailyLimitError' => :total_daily_limit,
        'DisabledProductError' => :disabled_product
      }.each do |status, code|
        it "adds an error with a code of `#{code}` if the status contains `#{status}`" do
          allow(response).to receive(:[]).with(:status).and_return([status])
          expect(subject).to receive(:add_error).with(error_type, code)
          call_method
        end
      end
      {
        'GrossUpError' => :capital_stock_offline,
        'ExceptionError' => :capital_stock_offline
      }.each do |status, code|
        it "adds an error with a code of `#{code}` and a value of `#{status}` if the status contains `#{status}`" do
          allow(response).to receive(:[]).with(:status).and_return([status])
          expect(subject).to receive(:add_error).with(error_type, code, status)
          call_method
        end
      end
      it 'adds an error with a code of `:unknown` and a value of the unknown status when an unknown status is encountered' do
        allow(response).to receive(:[]).with(:status).and_return([random_status])
        expect(subject).to receive(:add_error).with(error_type, :unknown, random_status)
        call_method
      end
      it 'adds multiple errors if multiple status are found' do
        another_status = double('Another Status')
        allow(response).to receive(:[]).with(:status).and_return([random_status, another_status, 'GrossUpError'])
        expect(subject).to receive(:add_error).exactly(3)
        call_method
      end
    end
  end

  describe '`human_interest_day_count`' do
    shared_examples 'human_interest_day_count' do |input,output|
      it "should return #{output} for #{input}" do
        allow(subject).to receive(:interest_day_count).and_return(input)
        expect(subject.human_interest_day_count).to eq(output)
      end
    end
    include_examples 'human_interest_day_count', nil,       nil
    include_examples 'human_interest_day_count', 'ACT/ACT',  I18n.t('dashboard.quick_advance.table.ACTACT')
    include_examples 'human_interest_day_count', 'ACT/360', I18n.t('dashboard.quick_advance.table.ACT360')
    it 'should raise an ArgumentError for other values' do
      allow(subject).to receive(:interest_day_count).and_return('other values')
      expect{subject.human_interest_day_count}.to raise_error(ArgumentError)
    end
  end

  describe '`human_payment_on`' do
    shared_examples 'human_payment_on' do |input,output|
      it "should return #{output} for #{input}" do
        allow(subject).to receive(:payment_on).and_return(input)
        expect(subject.human_payment_on).to eq(output)
      end
    end
    include_examples 'human_payment_on', 'Maturity',               I18n.t('dashboard.quick_advance.table.maturity')
    include_examples 'human_payment_on', 'MonthEndOrRepayment',    I18n.t('dashboard.quick_advance.table.monthendorrepayment')
    include_examples 'human_payment_on', 'Repayment',              I18n.t('dashboard.quick_advance.table.repayment')
    include_examples 'human_payment_on', 'SemiannualAndRepayment', I18n.t('dashboard.quick_advance.table.semiannualandrepayment')
    it 'should raise an ArgumentError for other values' do
      allow(subject).to receive(:payment_on).and_return('other values')
      expect{subject.human_payment_on}.to raise_error(ArgumentError)
    end
  end

  describe '`transform_amount` protected method' do
    let(:floated_amount) { double('A Float Amount') }
    let(:duped_amount) { double('A Duplicated Amount', to_f: floated_amount) }
    let(:amount) { double('An Amount', dup: duped_amount ) }
    let(:field_name) { double('A Field Name', titleize: SecureRandom.hex) }
    let(:call_method) { subject.send(:transform_amount, amount, field_name) }

    it 'duplicates the amount before transforming it' do
      expect(amount).to receive(:dup).ordered
      expect(duped_amount).to receive(:gsub!).ordered
      call_method
    end
    it 'doed not dup the amount if its not duplicable' do
      allow(amount).to receive(:duplicable?).and_return(false)
      allow(amount).to receive(:to_f)
      expect(amount).to_not receive(:dup)
      call_method
    end
    it 'strips out commas if the `amount` is a string' do
      base_amount = rand(10000000..99999999).to_s
      amount = base_amount.dup
      rand(3..7).times { amount.insert(rand(amount.length), ',') }
      expect(subject.send(:transform_amount, amount, field_name)).to eq(base_amount.to_f)
    end
    it 'raises an error if the amount is an unsupported string format' do
      allow(amount).to receive(:match).with(described_class::VALID_AMOUNT).and_return(false)
      expect{call_method}.to raise_error(/#{field_name.titleize}/)
    end
    it 'raises an error if the amount contains fractional dollars' do
      allow(amount).to receive(:floor).and_return(floated_amount)
      expect{call_method}.to raise_error(/#{field_name.titleize}/)
    end
    ['-1000.0', '123abc.0', '123abc123', '000000.11', '#$#11,,0231', 100.01].each do |bad_amount|
      it "handles a real world invalid amount: #{bad_amount}" do
        expect{subject.send(:transform_amount, bad_amount, field_name)}.to raise_error
      end
    end
    it 'converts the value to a float' do
      expect(duped_amount).to receive(:to_f)
      call_method
    end
    it 'handles being passed `nil`' do
      expect(subject.send(:transform_amount, nil, field_name)).to be_nil
    end
    {
      '1000.0' => 1000.0,
      '123,321.00' => 123321.0,
      '1234' => 1234.0,
      345.0 => 345.0,
      123 => 123.0
    }.each do |input, output|
      it "properly transforms `#{input}` into `#{output}`" do
        expect(subject.send(:transform_amount, input, :a_field)).to eq(output)
      end
    end
  end

  describe '`execute` state transition' do
    let(:call_method) { subject.execute }
    let(:call_method_ignoring_errors) { ignoring_errors(AASM::InvalidTransition) { call_method } }

    shared_examples 'no service requests' do
      it 'raises an error' do
        expect{call_method}.to raise_error
      end
      it 'does not call `perform_execute`' do
        expect(subject).to_not receive(:perform_execute)
        call_method_ignoring_errors
      end
      it 'does not call `validate_advance`' do
        expect(subject).to_not receive(:validate_advance)
        call_method_ignoring_errors
      end
    end

    shared_examples 'no state change' do
      it 'does not change the `current_state`' do
        call_method_ignoring_errors
        expect(subject.current_state).to be(:preview)
      end
    end

    shared_examples 'no service requests or state change' do
      include_examples 'no service requests'
      include_examples 'no state change'
    end

    before do
      allow(subject).to receive(:terms_present?).and_return(true)
      allow(subject).to receive(:no_errors_present?).and_return(true)
      allow(subject).to receive(:validate_advance).and_return(true)
      allow(subject).to receive(:perform_execute)
    end

    describe 'if `terms_present?` returns false' do
      before do
        allow(subject).to receive(:terms_present?).and_return(false)
      end
      include_examples 'no service requests or state change'
    end
    describe 'if `no_errors_present?` returns false' do
      before do
        allow(subject).to receive(:no_errors_present?).and_return(false)
      end
      include_examples 'no service requests or state change'
    end
    describe 'if `current_state` is not `preview`' do
      before do
        subject.aasm.current_state = :executed
      end
      include_examples 'no service requests'
    end
    describe 'if `validate_advance` sets errors' do
      before do
        allow(subject).to receive(:no_errors_present?).and_call_original
        allow(subject).to receive(:validate_advance) do
          subject.send(:add_error, :preview, :unknown)
        end
      end
      include_examples 'no state change'
    end
    describe 'if `perform_execute` sets errors' do
      before do
        allow(subject).to receive(:no_errors_present?).and_call_original
        allow(subject).to receive(:perform_execute) do
          subject.send(:add_error, :execute, :unknown)
        end
      end
      include_examples 'no state change'
    end
    it 'calls `validate_advance`' do
      expect(subject).to receive(:validate_advance)
      call_method
    end
    it 'calls `perform_execute` if `validate_advance` returns true' do
      expect(subject).to receive(:perform_execute)
      call_method
    end
    it 'does not call `perform_execute` if `validate_advance` returns false' do
      allow(subject).to receive(:validate_advance).and_return(false)
      expect(subject).to_not receive(:perform_execute)
      call_method
    end
    it 'changes the `current_state` to `executed`' do
      call_method
      expect(subject.current_state).to be(:executed)
    end
  end
end