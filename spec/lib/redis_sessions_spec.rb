require 'rails_helper'
require_relative Rails.root.join('lib', 'redis-sessions', 'store')
require_relative Rails.root.join('lib', 'redis-sessions', 'marshalling')
require_relative Rails.root.join('lib', 'redis-sessions', 'namespace')

RSpec.describe Rack::Session::Redis do
  subject { described_class.new({}) }
  let(:redis) { double(Redis::Store) }
  let(:sid) { SecureRandom.hex }
  let(:options) { subject.instance_variable_get(:@default_options) }

  before do
    allow(Redis::Store::Factory).to receive(:create).and_return(redis)
  end
  describe 'public methods' do
    describe '`generate_sid`' do
      let(:call_method) { subject.generate_sid }
      class Rack::Session::Abstract::ID
        def super_method
        end

        def generate_sid(*args)
          super_method(*args)
        end
      end
      before do
        allow(redis).to receive(:exists).with(sid).and_return(false)
        allow(subject).to receive(:super_method).and_return(sid)
      end
      it 'calls `super` to get a SID' do
        expect(subject).to receive(:super_method).and_return(sid)
        call_method
      end
      it 'checks if the SID already exists' do
        expect(redis).to receive(:exists).with(sid).and_return(false)
        call_method
      end
      it 'returns the SID if it does not exist already' do
        expect(call_method).to eq(sid)
      end
      it 'loops until it generated a valid SID' do
        allow(redis).to receive(:exists).with(sid).and_return(true, true, false)
        expect(subject).to receive(:super_method).and_return(sid).exactly(3)
        call_method
      end
    end
    describe '`get_session`' do
      let(:env) { {} }
      let(:new_sid) { SecureRandom.hex }
      let(:session) { double('A Session') }
      let(:new_session) { {} }
      let(:call_method) { subject.get_session(env, sid) }
      before do
        allow(subject).to receive(:generate_sid).and_return(new_sid)
        allow(subject).to receive(:persist_session).and_return('OK')
        allow(subject).to receive(:fetch_session).and_return(session)
      end
      it 'respects the session mutation mutex' do
        expect(subject).to receive(:with_lock).with(env, [nil, {}])
        call_method
      end
      it 'wraps the work in the session mutex' do
        allow(subject).to receive(:with_lock) # don't call the block to ensure our work is inside
        expect(subject).to_not receive(:fetch_session)
        expect(subject).to_not receive(:persist_session)
        call_method
      end
      it 'fetches the session using the SID' do
        expect(subject).to receive(:fetch_session).with(redis, sid, options).and_return(session)
        call_method
      end
      it 'returns the SID and session' do
        expect(call_method).to eq([sid, session])
      end

      shared_examples 'generate session and SID' do
        it 'generates a new SID' do
          expect(subject).to receive(:generate_sid)
          call_method
        end
        it 'persists the new SID and session' do
          expect(subject).to receive(:persist_session).with(redis, new_sid, new_session, options, new_session).and_return('OK')
          call_method
        end
        it 'raise an error if the persistance fails' do
          allow(subject).to receive(:persist_session).and_return('ERR')
          expect{call_method}.to raise_error
        end
        it 'returns the new SID and session' do
          expect(call_method).to eq([new_sid, new_session])
        end
      end

      describe 'if the session cant be found' do
        before do
          allow(subject).to receive(:fetch_session).and_return(nil)
        end
        include_examples 'generate session and SID'
      end
      describe 'if the provided SID is nil' do
        let(:call_method) { subject.get_session(env, nil) }
        include_examples 'generate session and SID'
      end
    end
    describe '`set_session`' do
      let(:env) { {} }
      let(:session) { double('A Session') }
      let(:call_method) { subject.set_session(env, sid, session, options) }

      before do
        allow(subject).to receive(:persist_session)
      end

      it 'respects the session mutation mutex' do
        expect(subject).to receive(:with_lock).with(env, false)
        call_method
      end
      it 'wraps the work in the session mutex' do
        allow(subject).to receive(:with_lock) # don't call the block to ensure our work is inside
        expect(subject).to_not receive(:persist_session)
        call_method
      end
      it 'persists the session' do
        expect(subject).to receive(:persist_session).with(redis, sid, session, options)
        call_method
      end
      it 'returns the SID' do
        expect(call_method).to eq(sid)
      end
    end
  end
  describe 'protected methods' do
    describe '`persist_session`' do
      let(:session) { double('A Session') }
      let(:old_session) { double('An Old Session')}
      let(:call_method) { subject.send(:persist_session, redis, sid, session, options) }
      let(:redis_transaction) { double('A Redis Transaction', hdel: nil, hmset: nil)}
      let(:updated_hash) { {SecureRandom.hex => [double('Some Value'), double('Some Value')], SecureRandom.hex => double('Some Value')} }
      let(:deleted_hash) { {SecureRandom.hex => false, SecureRandom.hex => false} }

      before do
        allow(subject).to receive(:fetch_session).and_return(old_session)
        allow(subject).to receive(:changed_keys).and_return([updated_hash, deleted_hash])
        allow(redis).to receive(:multi).and_yield(redis_transaction).and_return([])
      end

      it 'fetches the old session if one is not provided' do
        expect(subject).to receive(:fetch_session).with(redis, sid, options)
        call_method
      end
      it 'does not fetch the old session if one is provided' do
        expect(subject).to_not receive(:fetch_session)
        subject.send(:persist_session, redis, sid, session, options, {})
      end
      it 'calculates the delta between the old and new session' do
        expect(subject).to receive(:changed_keys).with(old_session, session)
        call_method
      end
      it 'starts a redis transaction' do
        expect(redis).to receive(:multi)
        call_method
      end
      describe 'inside the redis transaction' do
        it 'deletes the keys found in the old session but not the new' do
          expect(redis_transaction).to receive(:hdel).with(sid, deleted_hash.keys)
          call_method
        end
        it 'does not call delete if there is nothing to delete' do
          deleted_hash.clear
          expect(redis_transaction).to_not receive(:hdel)
          call_method
        end
        it 'sets the values of the new/changed keys found in the new session' do
          expect(redis_transaction).to receive(:hmset) do |*args|
            expect(args.first).to eq(sid)
            expect(args.last).to eq(options)
            expect(args).to include_slice(updated_hash.to_a.flatten(1))
          end
          call_method
        end
        it 'sets the SID_KEY in the updates' do
          expect(redis_transaction).to receive(:hmset) do |*args|
            expect(args).to include_slice([described_class::SID_KEY, sid])
          end
          call_method
        end
      end
      it 'returns the success code from the transaction' do
        response_code = double('A Response Code')
        allow(redis).to receive(:multi).and_return([response_code])
        expect(call_method).to eq(response_code)
      end
    end
    describe '`fetch_session`' do
      let(:flat_session) do 
        {
          described_class::SID_KEY => sid,
          "foo#{described_class::SEPARATOR}bar" => [1,2],
          "foo#{described_class::SEPARATOR}woo" => {},
          "car#{described_class::SEPARATOR}war#{described_class::SEPARATOR}nar" => 7.078,
          'boo' => {}
        }
      end
      let(:session) { {'foo' => {'bar' => [1, 2], 'woo' => {}}, 'car' => {'war' => {'nar' => 7.078}}, 'boo' => {}} }
      let(:call_method) { subject.send(:fetch_session, redis, sid, options) }
      before do
        allow(redis).to receive(:hgetall).and_return(flat_session)
      end
      it 'fetches all keys and values for the session' do
        expect(redis).to receive(:hgetall).with(sid, options).and_return({})
        call_method
      end
      it 'does not include the SID_KEY in the session' do
        expect(call_method).to_not include(described_class::SID_KEY)
      end
      it 'splits the flat keys into their segements' do
        (flat_session.keys - [described_class::SID_KEY]).each do |key|
          expect(subject).to receive(:split_prefixed_key).with(key).and_return([key])
        end
        call_method
      end
      it 'recreates the multi level session from the flat session and returns it' do
        expect(call_method).to eq(session)
      end
    end
    describe '`flatten_session`' do
      let(:session) { {'foo' => {'bar' => [1, 2], 'woo' => {}}, 'car' => {'war' => {'nar' => 7.078}}, 'boo' => {}} }
      let(:flat_session) do
        {
          "foo#{described_class::SEPARATOR}bar" => [1,2],
          "foo#{described_class::SEPARATOR}woo" => {},
          "car#{described_class::SEPARATOR}war#{described_class::SEPARATOR}nar" => 7.078,
          'boo' => {}
        }
      end
      let(:call_method) { subject.send(:flatten_session, session) }
      it 'converts nested hashes into a single flat hash and returns it' do
        expect(call_method).to eq(flat_session)
      end
      it 'includes empty hashes' do
        session.clear
        session['foo'] = {}
        session['bar'] = {'foo' => {}}
        session['car'] = {'foo' => {'bar' => {}}}
        expect(call_method).to eq({
          "foo" => {},
          "bar#{described_class::SEPARATOR}foo" => {},
          "car#{described_class::SEPARATOR}foo#{described_class::SEPARATOR}bar" => {}
        })
      end
      it 'handles the vales for some keys being nested arrays' do
        session.clear
        session['foo'] = [1, [2, 3, [4, 5]]]
        session['bar'] = { 'foo' => [5, 4, [3, 2, [1]]] }
        expect(call_method).to eq({
          'foo' => [1, [2, 3, [4, 5]]],
          "bar#{described_class::SEPARATOR}foo" => [5, 4, [3, 2, [1]]]
        })
      end
    end
    describe '`changed_keys`' do
      let(:old_session) { {'foo' => 'bar', 'war' => 'gar'} }
      let(:new_session) { {'bar' => 'foo', 'foo' => 'car'} }
      let(:call_method) { subject.send(:changed_keys, old_session, new_session) }
      before do
        allow(subject).to receive(:flatten_session).and_call_original
      end
      it 'flattens the new session' do
        expect(subject).to receive(:flatten_session).with(old_session).and_return({})
        call_method
      end
      it 'flattens the old session' do
        expect(subject).to receive(:flatten_session).with(new_session).and_return({})
        call_method
      end
      it 'returns two values' do
        expect(call_method.length).to be(2)
      end
      it 'returns all added or changed keys and their values as the first value' do
        expect(call_method.first).to eq({'bar' => 'foo', 'foo' => 'car'})
      end
      it 'returns all removed keys and their values as the second value' do
        expect(call_method.last).to eq({'war' => 'gar'})
      end
      it 'handles the vales for some keys being nested arrays in the updates' do
        old_session['nested'] = [1, 2, [3, 4]]
        new_session['nested'] = [2, 3, [4, 5]]
        expect(call_method.first['nested']).to eq([2, 3, [4, 5]])
      end
      it 'handles the vales for some keys being nested arrays in the removes' do
        old_session['nested'] = [1, 2, [3, 4]]
        expect(call_method.last['nested']).to eq([1, 2, [3, 4]])
      end
    end
    describe '`prefix_key`' do
      let(:key) { SecureRandom.hex }
      let(:prefix) { SecureRandom.hex }
      let(:call_method) { subject.send(:prefix_key, prefix, key) }
      it 'escapes SEPARATOR characters found in the key' do
        key = "123#{described_class::SEPARATOR}#{described_class::SEPARATOR_ESCAPED}456"
        expect(subject.send(:prefix_key, prefix, key)).to eq("#{prefix}#{described_class::SEPARATOR}123#{described_class::SEPARATOR_ESCAPED}#{described_class::SEPARATOR_ESCAPE}#{described_class::SEPARATOR_ESCAPED}456")
      end
      it 'addes the supplied prefix to the key seprated by the SEPARATOR and returns it' do
        expect(call_method).to eq("#{prefix}#{described_class::SEPARATOR}#{key}")
      end
      it 'does not add the prefix if its nil' do
        expect(subject.send(:prefix_key, nil, key)).to eq(key)
      end
      it 'does not escape SEPARATOR characters in the prefix' do
        prefix = "123#{described_class::SEPARATOR}456"
        expect(subject.send(:prefix_key, prefix, key)).to eq("#{prefix}#{described_class::SEPARATOR}#{key}")
      end
    end
    describe '`split_prefixed_key`' do
      it 'splits the key into segments by the SEPARATOR' do
        key = "123#{described_class::SEPARATOR}456#{described_class::SEPARATOR}789"
        expect(subject.send(:split_prefixed_key, key)).to eq(['123', '456', '789'])
      end
      it 'does not split along escaped SEPARATOR characters' do
        key = "123#{described_class::SEPARATOR_ESCAPED}456#{described_class::SEPARATOR}789"
        expect(subject.send(:split_prefixed_key, key).length).to be(2)
      end
      it 'converts escaped SEPARATOR characters into SEPARATOR characters' do
        key = "123#{described_class::SEPARATOR_ESCAPED}456#{described_class::SEPARATOR}#{described_class::SEPARATOR_ESCAPE}789"
        expect(subject.send(:split_prefixed_key, key)).to eq(["123#{described_class::SEPARATOR}456", "#{described_class::SEPARATOR_ESCAPE}789"])
      end
    end
  end
end

dummy_class = Class.new do
  def super_method(*args)
  end

  def hmset(*args)
    super_method(*args)
  end

  def hgetall(*args)
    super_method(*args)
  end

  def hdel(*args)
    super_method(*args)
  end
end

RSpec.describe Redis::Store::Namespace do
  subject { Class.new(dummy_class) { include Redis::Store::Namespace }.new }
  let(:key) { double('A Key') }
  let(:namespaced_key) { double('A Namespaced Key') }
  let(:options) { double('Some Options').as_null_object }

  describe '`hmset` method' do
    let(:attrs) { [double('An Attr Key'), double('An Attr Value'), double('An Attr Key'), double('An Attr Value')] }
    let(:args) { attrs + [options] }
    let(:call_method) { subject.hmset(key, *args) }

    it 'calls `namespace` with the key' do
      expect(subject).to receive(:namespace).with(key)
      call_method
    end

    it 'calls `super` with the yielded key and the original arguments' do
      allow(subject).to receive(:namespace).and_yield(namespaced_key)
      expect(subject).to receive(:super_method).with(namespaced_key, *args)
      call_method
    end
  end

  describe '`hgetall` method' do
    let(:call_method) { subject.hgetall(key, options) }

    it 'calls `namespace` with the key' do
      expect(subject).to receive(:namespace).with(key)
      call_method
    end

    it 'calls `super` with the yielded key and the original arguments' do
      allow(subject).to receive(:namespace).and_yield(namespaced_key)
      expect(subject).to receive(:super_method).with(namespaced_key, options)
      call_method
    end
  end

  describe '`hdel` method' do
    let(:attrs) { [double('An Attr Key'), double('An Attr Key')] }
    let(:args) { attrs + [options] }
    let(:call_method) { subject.hdel(key, *args) }

    it 'calls `namespace` with the key' do
      expect(subject).to receive(:namespace).with(key)
      call_method
    end

    it 'calls `super` with the yielded key and the original arguments' do
      allow(subject).to receive(:namespace).and_yield(namespaced_key)
      expect(subject).to receive(:super_method).with(namespaced_key, *args)
      call_method
    end
  end
  
end

RSpec.describe Redis::Store::Marshalling do
  subject { Class.new(dummy_class) { include Redis::Store::Marshalling }.new }
  let(:key) { double('A Key') }
  let(:options) { double('Some Options') }

  describe '`hmset` method' do
    let(:keys) { [double('An Attr Key'), double('An Attr Key')] }
    let(:values) { [double('An Attr Value'), double('An Attr Value')] }
    let(:attrs) { [keys.first, values.first, keys.last, values.last] }
    let(:call_method) { subject.hmset(key, *(attrs + [options])) }

    before do
      allow(subject).to receive(:_marshal)
    end

    it 'passes options to `_marshal` if found at the end of the attributes list' do
      expect(subject).to receive(:_marshal).with(anything, options).at_least(:once)
      call_method
    end
    it 'passes nil to `_marshal` if no options are found' do
      expect(subject).to receive(:_marshal).with(anything, nil).at_least(:once)
      subject.hmset(key, *attrs)
    end
    it 'calls `_marshal` on each value in the attributes array' do
      values.each do |value|
        expect(subject).to receive(:_marshal).with(value, anything)
      end
      call_method
    end
    it 'calls `encode` on each marshalled value' do
      allow(subject).to receive(:encode)
      values.each do |value|
        marshalled_value = double('A Marshalled Value')
        allow(subject).to receive(:_marshal).with(value, anything).and_yield(marshalled_value)
        expect(subject).to receive(:encode).with(marshalled_value)
      end
      call_method
    end
    it 'calls `encode` on each attribute key' do
      keys.each do |key|
        expect(subject).to receive(:encode).with(key)
      end
      call_method
    end
    it 'calls `super` with the supplied key and marshalled and encoded attributes' do
      encoded_values = []
      values.each do |value|
        marshalled_value = double('A Marshalled Value')
        encoded_value = double('An Encoded Value')
        allow(subject).to receive(:_marshal).with(value, anything).and_yield(marshalled_value)
        allow(subject).to receive(:encode).with(marshalled_value).and_return(encoded_value)
        encoded_values << encoded_value
      end
      encoded_keys = []
      keys.each do |key|
        encoded_key = double('An Encoded Key')
        allow(subject).to receive(:encode).with(key).and_return(encoded_key)
        encoded_keys << encoded_key
      end
      expect(subject).to receive(:super_method).with(key, encoded_keys.first, encoded_values.first, encoded_keys.last, encoded_values.last)
      call_method
    end

    it 'returns the result of super' do
      results = double('Some Results')
      allow(subject).to receive(:super_method).and_return(results)
      expect(call_method).to eq(results)
    end

  end

  describe '`hgetall` method' do
    let(:marshalled_hash) { {double('A Key') => double('A Marshalled Value'), double('A Key') => double('A Marshalled Value')} }
    let(:call_method) { subject.hgetall(key, options) }

    before do
      allow(subject).to receive(:super_method).and_return(marshalled_hash)
    end

    it 'calls `super` with the supplied key' do
      expect(subject).to receive(:super_method).with(key).and_return({})
      call_method
    end

    it 'calls `_unmarshal` on each of the returned values' do
      marshalled_hash.each do |key, value|
        expect(subject).to receive(:_unmarshal).with(value, options)
      end
      call_method
    end

    it 'returns a hash with the regular keys and unmarshalled values' do
      unmarshalled_hash = {}
      marshalled_hash.each do |key, value|
        unmarshalled_value = double('An Unmarshalled Value')
        allow(subject).to receive(:_unmarshal).with(value, options).and_return(unmarshalled_value)
        unmarshalled_hash[key] = unmarshalled_value
      end
      expect(call_method).to eq(unmarshalled_hash)
    end

  end
  
end