require 'spec_helper'

module MAPISharedUtils
  include MAPI::Shared::Utils
end

describe MAPI::Shared::Utils::ClassMethods do
  subject { MAPISharedUtils }
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
      allow(sql_response).to receive(:fetch_hash).and_raise(:exception)
      expect(logger).to receive(:error)
      call_method
    end
  end
  
  describe 'fetch_hashes' do
    let(:logger) { double('logger') }
    let(:sql)    { double('sql') }
    let(:cursor) { double('cursor') }
    let(:hash1)  { double('hash1') }
    let(:hash2)  { double('hash2') }
    let(:hash3)  { double('hash3') }
    let(:hash4)  { { "A" =>  1,    "B" => "2",   "C" => "3.0" } }
    let(:hash5)  { { "A" => "1",   "B" => "2.0", "C" =>  3    } }
    let(:hash6)  { { "A" => "1.0", "B" =>  2,    "C" => "3"   } }
    let(:hash7)  { { "A" =>  1,    "B" =>  2,    "C" =>  3    } }
    let(:hash8)  { { "a" =>  1,    "b" =>  2,    "c" =>  3    } }

    before do
      allow(ActiveRecord::Base.connection).to receive(:execute).with(sql).and_return(cursor)
    end

    it 'executes a SQL query and performs fetch_hash on the resulting cursor' do
      allow(cursor).to receive(:fetch_hash).and_return(hash1, hash2, hash3, nil)
      expect(subject.fetch_hashes(logger, sql)).to eq( [hash1, hash2, hash3] )
    end
    it 'handles the map_values parameter properly' do
      allow(cursor).to receive(:fetch_hash).and_return(hash4, hash5, hash6, nil)
      expect(subject.fetch_hashes(logger, sql, {to_i: %w(A B C)})).to eq( [hash7, hash7, hash7] )
    end
    it 'should honour the downcase_keys argument' do
      allow(cursor).to receive(:fetch_hash).and_return({ 'A' => hash1}, { 'B' => hash2}, {'C' => hash3}, nil)
      expect(subject.fetch_hashes(logger, sql, {}, true)).to eq([{'a' => hash1}, {'b' => hash2}, {'c' => hash3}])
    end
    it 'should handle both the map_keys and downcase_keys arguments properly' do
      allow(cursor).to receive(:fetch_hash).and_return(hash4, hash5, hash6, nil)
      expect(subject.fetch_hashes(logger, sql, {to_i: %w(A B C)}, true)).to eq([hash8, hash8, hash8])
    end
    it 'returns an empty array if the SQL query yields no results' do
      allow(cursor).to receive(:fetch_hash).and_return(nil)
      expect(subject.fetch_hashes(logger, sql, {}, true)).to eq([])
    end
    it 'logs an error for exceptions' do
      allow(cursor).to receive(:fetch_hash).and_raise(:exception)
      expect(logger).to receive(:error)
      subject.fetch_hashes(logger, sql)
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
      allow(cursor).to receive(:fetch).and_raise(:exception)
      expect(logger).to receive(:error)
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
end