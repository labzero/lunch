require 'rails_helper'

describe RedisHelper do
  describe '`add_url_namespace` class method' do
    let(:url) { double('A URL') }
    let(:namespace) { SecureRandom.hex }
    let(:parsed_url) { URI('redis://localhost:6379/') }
    let(:call_method) {subject.add_url_namespace(url, namespace) }

    before do
      allow(subject).to receive(:URI).with(url).and_return(parsed_url)
    end
    
    it 'responds to `add_url_namespace`' do
      expect(subject).to respond_to(:add_url_namespace)
    end
    
    it 'parses the supplied URL' do
      expect(subject).to receive(:URI).with(url).and_return(parsed_url)
      call_method
    end

    it 'converts the parsed URL back to a string and returns it' do
      modified_url = double('A Modified URL')
      allow(parsed_url).to receive(:to_s).and_return(modified_url)
      expect(call_method).to be(modified_url)
    end

    it 'converts the parsed URL to a string after modifying it' do
      expect(parsed_url).to receive(:path=).ordered
      expect(parsed_url).to receive(:to_s).ordered
      call_method
    end

    it 'adds the namespace if there is no current namesapce' do
      expect(parsed_url).to receive(:path=).with('/' + namespace)
      call_method
    end

    it 'modifies the namespace if there is one already' do
      current_namespace = SecureRandom.hex
      allow(parsed_url).to receive(:path).and_return('/' + current_namespace)
      expect(parsed_url).to receive(:path=).with(parsed_url.path + '-' + namespace)
      call_method
    end

    describe 'if there is a DB number' do
      let(:db_number) { rand(0..16).to_s }

      it 'adds the namespace' do
        allow(parsed_url).to receive(:path).and_return('/' + db_number)
        expect(parsed_url).to receive(:path=).with(parsed_url.path + '/' + namespace)
        call_method
      end

      it 'handles a trailing slash on the DB number' do
        allow(parsed_url).to receive(:path).and_return('/' + db_number + '/')
        expect(parsed_url).to receive(:path=).with(parsed_url.path + namespace)
        call_method
      end

      it 'modfies the namespace if there is one' do
        current_namespace = SecureRandom.hex
        allow(parsed_url).to receive(:path).and_return('/' + db_number + '/' + current_namespace)
        expect(parsed_url).to receive(:path=).with(parsed_url.path + '-' + namespace)
        call_method
      end
    end
  end

  describe '`namespace_from_url` class method' do
    let(:url) { double('A URL') }
    let(:namespace) { SecureRandom.hex }
    let(:parsed_url) { URI('redis://localhost:6379/') }
    let(:call_method) {subject.namespace_from_url(url) }
    let(:db_number) { rand(0..16).to_s }

    before do
      allow(subject).to receive(:URI).with(url).and_return(parsed_url)
    end

    it 'responds to `namespace_from_url`' do
      expect(subject).to respond_to(:namespace_from_url)
    end

    it 'parses the supplied URL' do
      expect(subject).to receive(:URI).with(url).and_return(parsed_url)
      call_method
    end

    it 'returns nil if there was no namespace and no DB' do
      expect(call_method).to be_nil
    end

    it 'returns nil if there was a DB but no namespace' do
      allow(parsed_url).to receive(:path).and_return('/' + db_number)
      expect(call_method).to be_nil
    end

    it 'returns the namespace if there was a namespace but no DB' do
      allow(parsed_url).to receive(:path).and_return('/' + namespace)
      expect(call_method).to eq(namespace)
    end

    it 'returns the namespace if the namespace looks like a DB' do
      allow(parsed_url).to receive(:path).and_return('/' + db_number + namespace)
      expect(call_method).to eq(db_number + namespace)
    end

    it 'returns the namespace if there was a namespace and a DB' do
      allow(parsed_url).to receive(:path).and_return('/' + db_number + '/' + namespace)
      expect(call_method).to eq(namespace)
    end
  end
end