require 'rails_helper'

RSpec.describe CacheConfiguration do
  subject { CacheConfiguration }

  let(:cache_context) { double('cache context') }

  describe '`config` method' do
    let(:defaults_config) { double('defaults config') }
    let(:cache_context_config)  { double('cache context config') }
    let(:unknown_context) { double('unknown context') }
    let(:config_hash) { { default: defaults_config, cache_context => cache_context_config } }

    before do
      stub_const("CacheConfiguration::CONFIG", config_hash)
    end

    it 'returns the appropriate `config` based on default `context`' do
      expect(subject.config(unknown_context)).to eq(defaults_config)
    end
    it 'returns the appropriate `config` based on matched `context`' do
      expect(subject.config(cache_context)).to eq(cache_context_config)
    end
  end

  describe 'other methods' do
    let(:expiry) { double('cache context config expiry') }
    let(:key_prefix) { SecureRandom.hex }
    let(:context_config) { {
        expiry: expiry,
        key_prefix: key_prefix
      } }
    before do
      allow(subject).to receive(:config).with(cache_context).and_return(context_config)
    end

    describe '`key` method' do
      it 'returns cache context key prefix if no additional arguments provided' do
        expect(subject.key(cache_context)).to eq(key_prefix)
      end
      it 'splats additional arguments into the cache key' do
        splat_args = [ SecureRandom.hex, SecureRandom.hex, SecureRandom.hex ]
        expect(subject.key(cache_context, splat_args)).to eq([key_prefix, *splat_args].join(CacheConfiguration::SEPARATOR))
      end
    end

    describe '`expiry` method' do
      it 'return the `:expiry` assocaited with the cache context configuration' do
        expect(subject.expiry(cache_context)).to be(expiry)
      end
    end
  end
end