require 'rails_helper'

RSpec.describe EarlyShutoffRequest, :type => :model do
  let(:today) { Time.zone.today }

  before do
    allow(Time.zone).to receive(:today).and_return(today)
  end

  subject { described_class.new }

  describe 'initialization' do
    describe 'setting the `request` attribute' do
      let(:request) { double('request') }
      context 'when a request arg is passed' do
        let(:early_shutoff) { described_class.new(request) }
        it 'sets `request` to the passed arg' do
          expect(early_shutoff.request).to eq(request)
        end
      end
      context 'when a request arg is not passed' do
        let(:early_shutoff) { described_class.new }
        before { allow(ActionDispatch::TestRequest).to receive(:new).and_return(request) }
        it 'creates a new instance of ActionDispatch::TestRequest' do
          expect(ActionDispatch::TestRequest).to receive(:new)
          early_shutoff
        end
        it 'sets `request` to the test arg' do
          expect(early_shutoff.request).to eq(request)
        end
      end
    end
    it 'sets the `early_shutoff_date` attribute to today' do
      expect(subject.early_shutoff_date).to eq(today)
    end
    it 'sets the `early_shutoff_date` attribute to today' do
      expect(subject.early_shutoff_date).to eq(today)
    end
    it "sets the `frc_shutoff_time` attribute to `#{described_class::DEFAULT_FRC_SHUTOFF_TIME}`" do
      expect(subject.frc_shutoff_time).to eq(described_class::DEFAULT_FRC_SHUTOFF_TIME)
    end
    it "sets the `vrc_shutoff_time` attribute to `#{described_class::DEFAULT_VRC_SHUTOFF_TIME}`" do
      expect(subject.vrc_shutoff_time).to eq(described_class::DEFAULT_VRC_SHUTOFF_TIME)
    end
  end

  describe 'class methods' do
    describe '`policy_class`' do
      it 'returns the WebAdminPolicy class' do
        expect(described_class.policy_class).to eq(WebAdminPolicy)
      end
    end

    describe '`from_json`' do
      let(:json) { double('some JSON') }
      let(:request) { double('request') }
      let(:early_shutoff) { instance_double(EarlyShutoffRequest, from_json: nil) }
      let(:call_method) { EarlyShutoffRequest.from_json(json, request) }

      before { allow(EarlyShutoffRequest).to receive(:new).and_return(early_shutoff) }

      it 'creates a new `EarlyShutoffRequest`' do
        expect(EarlyShutoffRequest).to receive(:new).and_return(early_shutoff)
        call_method
      end
      it 'calls `from_json` with the passed json' do
        expect(early_shutoff).to receive(:from_json).with(json)
        call_method
      end
      it 'returns the `EarlyShutoffRequest`' do
        allow(early_shutoff).to receive(:from_json).and_return(early_shutoff)
        expect(call_method).to eq(early_shutoff)
      end
    end
  end

  describe 'instance methods' do
    describe 'the `id` getter' do
      let(:id) { SecureRandom.hex }
      context 'when the attribute already exists' do
        before { subject.instance_variable_set(:@id, id) }
        it 'returns the attribute' do
          expect(subject.id).to eq(id)
        end
      end
      context 'when the attribute does not yet exist' do
        it 'sets the attribute to the result of calling `SecureRandom.uuid`' do
          allow(SecureRandom).to receive(:uuid).and_return(id)
          expect(subject.id).to be(id)
        end
      end
    end

    describe '`attributes`' do
      let(:call_method) { subject.attributes }
      persisted_attributes = described_class::READ_ONLY_ATTRS + described_class::ACCESSIBLE_ATTRS - described_class::SERIALIZATION_EXCLUDE_ATTRS

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

      described_class::SERIALIZATION_EXCLUDE_ATTRS.each do |attr|
        it "does not include `#{attr}`" do
          allow(subject).to receive(attr).and_return(double('A Value'))
          expect(call_method).to_not have_key(attr)
        end
      end
    end

    describe '`attributes=`' do
      read_only_attrs = [:id, :request]
      serialization_exclude_attrs = [:request]
      time_attrs = [:frc_shutoff_time, :vrc_shutoff_time]
      let(:hash) { {} }
      let(:value) { double('some value') }
      let(:time_value) { (sprintf '%02d', rand(0..23)) + (sprintf '%02d', rand(0..59)) }
      let(:call_method) { subject.send(:attributes=, hash) }

      (described_class::ACCESSIBLE_ATTRS + read_only_attrs - time_attrs - serialization_exclude_attrs).each do |key|
        it "assigns the value found under `#{key}` to the attribute `#{key}`" do
          hash[key.to_s] = value
          call_method
          expect(subject.send(key)).to be(value)
        end
      end
      time_attrs.each do |key|
        it "assigns the value found under `#{key}` to the attribute `#{key}`" do
          hash[key.to_s] = time_value
          call_method
          expect(subject.send(key)).to be(time_value)
        end
      end
      serialization_exclude_attrs.each do |attr|
        it 'raises an error if it encounters an excluded attribute' do
          hash[attr] = double('A Value')
          expect{call_method}.to raise_error(ArgumentError, "illegal attribute: #{attr}")
        end
      end
      it 'assigns the `owners` attribute after calling `to_set` on the value' do
        expected_value = double('Set of Owners')
        value = double('A Value', to_set: expected_value)
        hash[:owners] = value
        call_method
        expect(subject.owners).to eq(expected_value)
      end
      it 'raises an exception if the hash contains keys that are not `EarlyShutoffRequest` attributes' do
        hash[:foo] = 'bar'
        expect{call_method}.to raise_error(ArgumentError, "unknown attribute: foo")
      end
    end

    [:frc_shutoff_time, :vrc_shutoff_time].each do |time_attr|
      describe "the `#{time_attr}` setter" do
        let(:time_string) { instance_double(String, match: true) }
        let(:time) { double('time', to_s: time_string) }
        let(:call_method) { subject.send(:"#{time_attr}=", time)}
        it 'converts the time into a string' do
          expect(time).to receive(:to_s).and_return(time_string)
          call_method
        end
        it 'checks to make sure the time string matches the `TIME_24_HOUR_FORMAT`' do
          expect(time_string).to receive(:match).with(described_class::TIME_24_HOUR_FORMAT)
          call_method
        end
        context 'when the time string matches the `TIME_24_HOUR_FORMAT`' do
          before { allow(time_string).to receive(:match).and_return(true) }
          it "sets `frc_shutoff_time` to the passed time" do
            call_method
            expect(subject.send(time_attr)).to eq(time_string)
          end
        end
        context 'when the time string does not match the `TIME_24_HOUR_FORMAT`' do
          before { allow(time_string).to receive(:match).and_return(false) }
          it 'raises an error' do
            expect{call_method}.to raise_error(ArgumentError) do |error|
              expect(error.message).to eq("#{time_attr} must be a 4-digit, 24-hour time representation with values between `0000` and `2359`")
            end
          end
        end
        describe 'the `TIME_24_HOUR_FORMAT` regex' do
          valid_times = ['0000', '2359', '1234', '0900', '1200', '2100']
          invalid_times = ['2400', '900', '3100', '2160', '2512']
          valid_times.each do |time|
            it "succeeds when the time is `#{time}`" do
              expect{subject.send(:"#{time_attr}=", time)}.not_to raise_error
            end
          end
          invalid_times.each do |time|
            it "fails when the time is `#{time}`" do
              expect{subject.send(:"#{time_attr}=", time)}.to raise_error(ArgumentError) do |error|
                expect(error.message).to eq("#{time_attr} must be a 4-digit, 24-hour time representation with values between `0000` and `2359`")
              end
            end
          end
        end
      end

      describe 'methods retrieving hours and minutes' do
        hour_getter_method = :"#{time_attr}_hour"
        minute_getter_method = :"#{time_attr}_minute"
        let(:hour_value) { sprintf '%02d', rand(0..23) }
        let(:minute_value) { sprintf '%02d', rand(0..59) }
        before { subject.send(:"#{time_attr}=", hour_value + minute_value) }

        describe "the `#{hour_getter_method}` method" do
          it "returns the first two digits of the `#{time_attr}`" do
            expect(subject.send(hour_getter_method)).to eq(hour_value)
          end
        end
        describe "the `#{minute_getter_method}` method" do
          it "returns the last two digits of the `#{time_attr}`" do
            expect(subject.send(minute_getter_method)).to eq(minute_value)
          end
        end
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

    [:day_of_message, :day_before_message].each do |message_attr|
      message_getter = :"#{message_attr}_simple_format"
      describe "`#{message_getter}`" do
        let(:message) { instance_double(String) }
        let(:formatted_message) { instance_double(String) }
        let(:call_method) { subject.send(message_getter) }
        before { subject.send(:"#{message_attr}=", message) }

        it "calls `simple_format_for` with the `#{message_attr}`" do
          expect(subject).to receive(:simple_format_for).with(message)
          call_method
        end
        it 'returns the result of calling `simple_format_for`' do
          allow(subject).to receive(:simple_format_for).with(message).and_return(formatted_message)
          expect(call_method).to eq(formatted_message)
        end
      end
    end
  end

  describe 'private methods' do
    describe '`simple_format_for`' do
      let(:part_1) { SecureRandom.hex }
      let(:part_2) { SecureRandom.hex }
      let(:formatted_string) { "#{part_1}\n\n#{part_2}" }
      it 'substitutes `\n\n` for any `\r\n` characters it finds' do
        text = "#{part_1}\r\n#{part_2}"
        expect(subject.send(:simple_format_for, text)).to eq(formatted_string)
      end
      it 'only replaces once, regardless of how many times the `\r\n` pattern repeats' do
        text = "#{part_1}\r\n\r\n\r\n\r\n\r\n\r\n#{part_2}"
        expect(subject.send(:simple_format_for, text)).to eq(formatted_string)
      end
      it 'strips out leading and trailing whitespace' do
        text = "   #{part_1}\r\n#{part_2}     "
        expect(subject.send(:simple_format_for, text)).to eq(formatted_string)
      end
      it 'returns the string unchanged if there is no pattern found, or trailing/leading whitespace' do
        expect(subject.send(:simple_format_for, formatted_string)).to eq(formatted_string)
      end
    end
  end

end