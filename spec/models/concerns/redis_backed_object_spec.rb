require 'rails_helper'

describe RedisBackedObject do
  subject { mock_context(RedisBackedObject, instance_methods: [:id], class_methods: [:from_json, :name]) }
  let(:described_class) { subject.class }
  let(:id) { SecureRandom.hex }
  let(:key_path) { SecureRandom.hex }

  before do
    allow(subject).to receive(:id).and_return(id)
    described_class.const_set('REDIS_EXPIRATION_KEY_PATH', key_path)
  end

  describe 'instance methods' do
    describe '`save`' do
      let(:redis_value) { double(Redis::Value, :set => true, :expire => true) }
      let(:expiration) { double('expiration') }
      let(:json) { double('Some JSON') }
      let(:call_method) { subject.save }
      before do
        allow(described_class).to receive(:redis_expiration).and_return(expiration)
        allow(subject).to receive(:id)
        allow(subject).to receive(:redis_value).and_return(redis_value)
        allow(subject).to receive(:to_json).and_return(json)
      end
      it 'calls `to_json` to turn the instance into json' do
        expect(subject).to receive(:to_json).and_return(json)
        call_method
      end
      it 'calls `redis_value` to fetch the value in the redis store' do
        expect(subject).to receive(:redis_value).and_return(redis_value)
        call_method
      end
      it 'calls `set` on the `redis_value` with the JSON representation' do
        expect(redis_value).to receive(:set).with(json)
        call_method
      end
      it 'calls `redis_expiration` to retrieve the expiration configuration' do
        expect(described_class).to receive(:redis_expiration)
        call_method
      end
      it 'sets an expiration on the `redis_value`' do
        expect(redis_value).to receive(:expire).with(expiration)
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
      it 'returns false if the save fails' do
        allow(redis_value).to receive(:set).and_return(false)
        expect(call_method).to be(false)
      end
      it 'returns false if the expiration update fails' do
        allow(redis_value).to receive(:expire).and_return(false)
        expect(call_method).to be(false)
      end
      it 'returns true on success' do
        expect(call_method).to be(true)
      end
    end

    describe 'protected methods' do
      describe '`redis_value`' do
        let(:value) { double('some value') }
        let(:call_method) { subject.send(:redis_value) }
        describe 'when @redis_value is already set' do
          before { subject.instance_variable_set(:@redis_value, value) }
          it 'returns `@redis_value`' do
            expect(call_method).to eq(value)
          end
          it 'does not call the `redis_value` class method' do
            expect(described_class).not_to receive(:redis_value)
            call_method
          end
        end
        describe 'when the @redis_value has not been set' do
          before { allow(described_class).to receive(:redis_value).and_return(value) }
          it 'calls the `redis_value` class method with the id of the instance' do
            expect(described_class).to receive(:redis_value).with(id)
            call_method
          end
          it 'returns the result of the `redis_value` class method' do
            expect(call_method).to eq(value)
          end
          it 'sets @redis_value to the result of the `redis_value` class method' do
            call_method
            expect(subject.instance_variable_get(:@redis_value)).to eq(value)
          end
        end
      end
    end
  end

  describe 'class methods' do
    describe '`find`' do
      let(:request) { double('request') }
      let(:value) { double('some value') }
      let(:instance_from_json) { instance_double(described_class) }
      let(:redis_value) { instance_double(Redis::Value, nil?: false, value: value, expire: true) }
      let(:expiration) { double('expiration') }
      let(:call_method) { described_class.find(id, request) }

      before do
        allow(described_class).to receive(:redis_expiration).and_return(expiration)
        allow(described_class).to receive(:redis_value).with(id).and_return(redis_value)
        allow(described_class).to receive(:from_json).and_return(instance_from_json)
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
        it 'calls `redis_expiration` to retrieve the expiration configuration' do
          expect(described_class).to receive(:redis_expiration)
          call_method
        end
        it 'updates the expiration on the `redis_value`' do
          expect(redis_value).to receive(:expire).with(expiration)
          call_method
        end
        it 'logs the find' do
          expect(described_class).to receive(:log)
          call_method
        end
        it 'returns the new instance' do
          expect(call_method).to be(instance_from_json)
        end
      end
    end

    describe '`redis_value`' do
      let(:id) { double('a passed ID value') }
      let(:key) { double('A Redis Key') }
      let(:call_method) { described_class.redis_value(id) }

      before { allow(described_class).to receive(:redis_key).and_return(key) }
      it 'calls `redis_key` to fetch the redis key' do
        expect(described_class).to receive(:redis_key).and_return(key)
        call_method
      end
      it 'constructs a new `Redis::Value` using the key from `redis_key`' do
        expect(Redis::Value).to receive(:new).with(key)
        call_method
      end
      it 'returns the new instance of `Redis::Value`' do
        value = double(Redis::Value)
        allow(Redis::Value).to receive(:new).and_return(value)
        expect(call_method).to be(value)
      end
    end

    describe '`redis_expiration`' do
      let(:expiration) { double('expiration') }
      let(:call_method) { described_class.redis_expiration }
      it 'fetches the appropriate expiration configuration from Rails.configuration' do
        expect(Rails.configuration.x).to receive(:instance_eval).with(key_path)
        call_method
      end
      it 'returns the expiration configuration' do
        expect(Rails.configuration.x).to receive(:instance_eval).and_return(expiration)
        expect(call_method).to eq(expiration)
      end
    end

    describe '`redis_key`' do
      it 'joins the class name and the supplied `id`' do
        id = SecureRandom.uuid
        name = SecureRandom.hex
        allow(described_class).to receive(:name).and_return(name)
        expect(described_class.redis_key(id)).to eq(described_class.name + ':' + id)
      end
    end
  end
end