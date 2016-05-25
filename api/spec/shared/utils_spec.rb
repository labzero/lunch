require 'spec_helper'

module MAPISharedUtils
  include MAPI::Shared::Utils
end

describe MAPI::Shared::Utils::ClassMethods do
  subject { MAPISharedUtils }
  let(:exception_message) { SecureRandom.hex }
  let(:exception) { RuntimeError.new(exception_message) }
  describe 'fetch_hash' do
    let(:logger)        { double('logger') }
    let(:sql)           { double('sql') }
    let(:sql_response)  { double('result of sql query') }
    let(:response_hash) { double('a hash of results') }
    let(:call_method)   { subject.fetch_hash(logger, sql) }
    before { allow(ActiveRecord::Base.connection).to receive(:execute).and_return(sql_response) }

    it 'executes a SQL query on the ActiveRecord::Base.connection' do
      expect(ActiveRecord::Base.connection).to receive(:execute).with(sql)
      call_method
    end
    it 'returns a fetched hash of the results of the SQL query' do
      allow(sql_response).to receive(:fetch_hash).and_return(response_hash)
      expect(call_method).to eq(response_hash)
    end
    it 'returns an empty hash if the SQL query yields no results' do
      expect(call_method).to eq({})
    end
    it 'logs an error for exceptions' do
      allow(sql_response).to receive(:fetch_hash).and_raise(exception)
      expect(logger).to receive(:error).with(exception_message)
      call_method
    end
  end
  
  describe 'fetch_hashes' do
    let(:logger) { double(Logger) }
    let(:sql)    { double('sql') }
    let(:cursor) { double(OCI8::Cursor) }
    let(:mapping) { double(Hash) }
    let(:downcase) { double('Should Downcase') }
    let(:hashes) { [double(Hash), double(Hash), double(Hash)]}
    let!(:mapped_hashes) do
      hashes.collect do |hash|
        mapped = double(Hash)
        allow(subject).to receive(:map_hash_values).with(hash, anything, anything).and_return(mapped)
        mapped
      end
    end
    let(:call_method) { subject.fetch_hashes(logger, sql, mapping, downcase)}

    before do
      allow(ActiveRecord::Base.connection).to receive(:execute).with(sql).and_return(cursor)
      allow(cursor).to receive(:fetch_hash).and_return(*([*hashes, nil]))
    end

    it 'executes a SQL query' do
      expect(ActiveRecord::Base.connection).to receive(:execute).with(sql).and_return(cursor)
      call_method
    end
    it 'calls `fetch_hash` on the results cursor until nil is receieved' do
      expect(cursor).to receive(:fetch_hash).and_return(*([*hashes, nil])).exactly(hashes.length + 1)
      call_method
    end
    it 'calls `map_hash_values` on each returned row' do
      hashes.each do |hash|
        expect(subject).to receive(:map_hash_values).with(hash, mapping, downcase)
      end
      call_method
    end
    it 'returns the mapped results' do
      expect(call_method).to eq(mapped_hashes)
    end
    it 'returns an empty array if the SQL query yields no results' do
      allow(cursor).to receive(:fetch_hash).and_return(nil)
      expect(call_method).to eq([])
    end
    it 'logs an error for exceptions' do
      allow(cursor).to receive(:fetch_hash).and_raise(exception)
      expect(logger).to receive(:error).with(exception_message)
      call_method
    end
  end

  describe 'dateify' do
    let(:date){ Date.parse('2015-11-30') }
    it 'should map an Oracle formatted date to this century' do
      expect(subject.dateify('30-NOV-15')).to eq(date)
    end
    it 'should be idempotent on a Date' do
      expect(subject.dateify(date)).to eq(date)
    end
    it 'should handle an iso8661 string' do
      expect(subject.dateify(date.iso8601)).to eq(date)
    end
  end

  describe 'fetch_objects' do
    let(:logger) { double('logger')  }
    let(:sql)    { double('sql')     }
    let(:cursor) { double('cursor')  }
    let(:object1){ double('object1') }
    let(:object2){ double('object2') }
    let(:object3){ double('object3') }

    it 'executes a SQL query and performs fetch on the resulting cursor' do
      allow(ActiveRecord::Base.connection).to receive(:execute).with(sql).and_return(cursor)
      allow(cursor).to receive(:fetch).and_return([object1], [object2, object3], nil)
      expect(subject.fetch_objects(logger, sql)).to be == [object1, object2, object3]
    end

    it 'logs an error for exceptions' do
      allow(ActiveRecord::Base.connection).to receive(:execute).with(sql).and_return(cursor)
      allow(cursor).to receive(:fetch).and_raise(exception)
      expect(logger).to receive(:error).with(exception_message)
      subject.fetch_objects(logger, sql)
    end
  end

  describe '`decimal_to_percentage_rate` method' do
    it 'converts a decimal rate to a percentage rate' do
      rate = double('A Rate')
      allow(rate).to receive(:to_f).and_return(rate)
      expect(rate).to receive(:round).with(7).and_return(rate).ordered
      expect(rate).to receive(:*).with(100.0).ordered
      subject.decimal_to_percentage_rate(rate)
    end

    {
      nil => nil,
      0 => 0,
      1.0 => 0.01,
      20.0 => 0.2,
      5 => 0.05,
      4.36 => 0.0436,
      4.37 => 0.043700001
    }.each do |transformed_rate, rate|
      it "converts `#{rate}` to `#{transformed_rate}`" do
        expect(subject.decimal_to_percentage_rate(rate)).to eq(transformed_rate)
      end
    end
  end

  describe '`percentage_to_decimal_rate` method' do
    it 'converts the rate to a decimal rate' do
      rate = double('A Rate')
      allow(rate).to receive(:to_f).and_return(rate)
      expect(rate).to receive(:/).with(100.0)
      subject.percentage_to_decimal_rate(rate)
    end

    {
      nil => nil,
      0 => 0,
      1.0 => 0.01,
      20.0 => 0.2,
      5 => 0.05,
      4.36 => 0.0436
    }.each do |rate, transformed_rate|
      it "converts `#{rate}` to `#{transformed_rate}`" do
        expect(subject.percentage_to_decimal_rate(rate)).to eq(transformed_rate)
      end
    end
  end

  describe '`request_cache` method' do
    let(:environment) { {} }
    let(:request) { double(Sinatra::Request, env: environment) }
    let(:key) { SecureRandom.hex }
    let(:full_key) { [MAPI::Shared::Utils::CACHE_KEY_BASE, key].join(MAPI::Shared::Utils::CACHE_KEY_SEPARATOR) }
    let(:block_value) { double('A Value') }
    let(:block) { Proc.new { block_value } }
    let(:call_method) { subject.request_cache(request, key, &block) }

    it 'joins the key with the CACHE_KEY_BASE' do
      expect(environment).to receive(:[]=).with(full_key, anything)
      call_method
    end
    it 'handles an array of key segments being passed for the key' do
      other_key = SecureRandom.hex
      full_other_key = [MAPI::Shared::Utils::CACHE_KEY_BASE, key, other_key].join(MAPI::Shared::Utils::CACHE_KEY_SEPARATOR)
      expect(environment).to receive(:[]=).with(full_other_key, anything)
      subject.request_cache(request, [key, other_key], &block)
    end
    it 'returns the value for the supplied key if found in the request environment' do
      cached_value = double('A Value')
      environment[full_key] = cached_value
      expect(call_method).to be(cached_value)
    end
    it 'does not call the supplied block if the supplied key is found in the request environment' do
      environment[full_key] = true
      expect{ |b| subject.request_cache(request, key, &b) }.to_not yield_control
    end
    it 'does not call the supplied block if the supplied key is found in the request environment and its value is false' do
      environment[full_key] = false
      expect{ |b| subject.request_cache(request, key, &b) }.to_not yield_control
    end
    describe 'if the key does not exist in the cache' do
      it 'yields to the provided block' do
        expect{ |b| subject.request_cache(request, key, &b) }.to yield_control
      end
      it 'stores the blocks result in the request environment under the supplied key' do
        expect(environment).to receive(:[]=).with(full_key, block_value)
        call_method
      end
      it 'returns the blocks result' do
        expect(call_method).to be(block_value)
      end
    end
  end

  describe '`fake_hashes` method' do
    let(:filename) { double('A Filename') }
    let(:call_method) { subject.fake_hashes(filename) }
    let(:hashes) { [double(Hash), double(Hash)] }
    let!(:indifferent_hashes) do
      hashes.collect do |hash|
        indifferent = double(Hash)
        allow(hash).to receive(:with_indifferent_access).and_return(indifferent)
        indifferent
      end
    end
    before do
      allow(subject).to receive(:fake).with(filename).and_return(hashes)
    end

    it 'calls `fake` with the supplied filename' do
      expect(subject).to receive(:fake).with(filename)
      call_method
    end
    it 'calls `with_indifferent_access` on each hash returned from `fake`' do
      hashes.each do |hash|
        expect(hash).to receive(:with_indifferent_access)
      end
      call_method
    end
    it 'returns the converted hashes' do
      expect(call_method).to eq(indifferent_hashes)
    end
  end

  describe '`should_fake?` method' do
    let(:settings) { double('settings', environment: SecureRandom.hex()) }
    let(:app) { double(MAPI::ServiceApp, settings: settings) }
    let(:call_method) { subject.should_fake?(app) }
    it 'returns true if the `environment` is not production' do
      expect(call_method).to be(true)
    end
    it 'returns false if the `environment` is production' do
      allow(settings).to receive(:environment).and_return(:production)
      expect(call_method).to be(false)
    end
  end

  describe '`map_hash_values` method' do
    let(:mapping_proc) { Proc.new() {} }
    let(:operation) { :an_operation }
    let(:missing_key) { SecureRandom.hex }
    let(:unmapped_key) { SecureRandom.hex }
    let(:procd_key) { SecureRandom.hex }
    let(:operation_keys) { [SecureRandom.hex, SecureRandom.hex] }
    let(:mapping) { {
      operation => [*operation_keys, missing_key],
      mapping_proc => [procd_key]
    } }
    let(:hash) { {
      operation_keys.first => double('A Value'),
      operation_keys.last => double('A Value'),
      procd_key => double('A Value'),
      unmapped_key => double('A Value')
    } }
    let(:upcased_hash) { {
      SecureRandom.hex.upcase => double('A Value'),
      SecureRandom.hex.upcase => double('A Value')
    } }
    let(:call_method) { subject.map_hash_values(hash, mapping, true) }
    
    it 'returns a new hash with the keys downcased if `downcase` is true' do
      downcased_keys = upcased_hash.keys.collect{|x| x.downcase}
      expect(subject.map_hash_values(upcased_hash, [], true).keys).to eq(downcased_keys)
    end
    it 'does not downcase the keys if `downcase` is false' do
      expect(subject.map_hash_values(upcased_hash, [], false).keys).to eq(upcased_hash.keys)
    end
    it 'calls the method named in the keys of `mapping` on each key of the `hash` that is found in the mapping value for that key' do
      operation_keys.each do |key|
        expect(hash[key]).to receive(operation).and_return(double('A Mapped Value'))
      end
      call_method
    end
    it 'does nothing to hash keys not found in the `mapping`' do
      expect(call_method[unmapped_key]).to be(hash[unmapped_key])
    end
    it 'calls `call` on any operation in the `mapping` that responds, passing in the current value of the hash for the key' do
      expect(mapping_proc).to receive(:call).with(hash[procd_key])
      call_method
    end
    it 'handles nil values in the hash' do
      hash = {foo: nil}
      expect{subject.map_hash_values(hash, mapping, false)}.not_to raise_error
    end
    it 'assigns missing keys a value of nil in the hash' do
      operation_keys.each do |key|
        allow(hash[key]).to receive(operation).and_return(double('A Mapped Value'))
      end
      expect(call_method[missing_key]).to eq(nil)
    end
    it 'returns the mapped hash' do
      mapped_values = [double('A Mapped Value'), double('A Mapped Value'), double('A Mapped Value')]
      operation_keys.each_with_index do |key, i|
        allow(hash[key]).to receive(operation).and_return(mapped_values[i])
      end
      expect(mapping_proc).to receive(:call).with(hash[procd_key]).and_return(mapped_values[2])
      expect(call_method).to eq({
                                  operation_keys.first => mapped_values[0],
                                  operation_keys.last => mapped_values[1],
                                  procd_key => mapped_values[2],
                                  unmapped_key => hash[unmapped_key],
                                  missing_key => nil
                                })
    end
  end
end