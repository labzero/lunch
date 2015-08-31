require 'spec_helper'

module MAPISharedUtils
  include MAPI::Shared::Utils
end

describe MAPI::Shared::Utils::ClassMethods do
  subject { MAPISharedUtils }
  describe 'fetch_hashes' do
    let(:logger) { double('logger') }
    let(:sql)    { double('sql') }
    let(:cursor) { double('cursor') }
    let(:hash1)  { double('hash1') }
    let(:hash2)  { double('hash2') }
    let(:hash3)  { double('hash3') }

    it 'executes the SQL query for blackout dates query' do
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

    it 'executes the SQL query for blackout dates query' do
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
end