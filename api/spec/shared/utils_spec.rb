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

    it 'executes a SQL query and performs fetch_hash on the resulting cursor' do
      allow(ActiveRecord::Base.connection).to receive(:execute).with(sql).and_return(cursor)
      allow(cursor).to receive(:fetch_hash).and_return(hash1, hash2, hash3, nil)
      expect(subject.fetch_hashes(logger, sql)).to be == [hash1, hash2, hash3]
    end

    it 'logs an error for exceptions' do
      allow(ActiveRecord::Base.connection).to receive(:execute).with(sql).and_return(cursor)
      allow(cursor).to receive(:fetch_hash).and_raise(:exception)
      expect(logger).to receive(:error)
      subject.fetch_hashes(logger, sql)
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
      expect(rate).to receive(:round).with(5).and_return(rate).ordered
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
end