require 'rails_helper'

RSpec.describe AssetHelper do
  describe '`find_asset`' do
    let(:name) { double('An Asset Name') }
    let(:call_method) { helper.find_asset(name) }
    describe 'when a Sprockets::Environment is present' do
      let(:sprockets_asset) { double(Sprockets::Asset) }
      let(:sprockets_environment) { double(Sprockets::Environment) }
      before do
        allow(sprockets_environment).to receive(:find_asset).and_return(sprockets_asset)
        allow(Rails.application).to receive(:assets).and_return(sprockets_environment)
      end
      it 'finds the asset via Sprockets' do
        expect(sprockets_environment).to receive(:find_asset).with(name)
        call_method
      end
      it 'returns the sprocket asset' do
        expect(call_method).to be(sprockets_asset)
      end
    end

    describe 'when a Sprockets::Environment is not present' do
      let(:asset) { double('An Asset') }
      let(:asset_catalog) { {name => asset} }
      let(:manifest) { double(Sprockets::Manifest, assets: asset_catalog) }
      before do
        allow(Rails.application).to receive(:assets).and_return(nil)
        allow(Rails.application).to receive(:assets_manifest).and_return(manifest)
      end
      it 'finds the asset in the asset manifest' do
        expect(asset_catalog).to receive(:[]).with(name)
        call_method
      end
      it 'returns the asset name from the manifest' do
        expect(call_method).to be(asset)
      end
    end
  end
  describe '`asset_source`' do
    let(:name) { double('An Asset Name') }
    let(:call_method) { helper.asset_source(name) }
    let(:asset) { double('An Asset') }
    before do
      allow(helper).to receive(:find_asset).and_return(asset)
    end
    it 'finds the asset via `find_asset`' do
      expect(helper).to receive(:find_asset).with(name).and_return(nil)
      call_method
    end
    it 'returns nil when the asset can not be found' do
      allow(helper).to receive(:find_asset).and_return(nil)
      expect(call_method).to be_nil
    end
    describe 'when `find_asset` returns a Sprockets::Asset' do
      let(:asset) { double(Sprockets::Asset) }
      let(:asset_source) { double('An Asset Source') }
      before do
        allow(asset).to receive(:is_a?).with(Sprockets::Asset).and_return(true)
        allow(asset).to receive(:source).and_return(asset_source)
      end
      it 'returns the asset source' do
        expect(call_method).to be(asset_source)
      end
    end
    describe 'when `find_asset` does not return a Sprockets::Asset' do
      let(:asset) { SecureRandom.hex }
      let(:contents) { double('File Contents') }
      let(:path) { double('A Path') }
      before do
        allow(File).to receive(:join).and_return(path)
        allow(File).to receive(:read).and_return(contents)
      end
      it 'builds a path for the asset' do
        expect(File).to receive(:join).with(Rails.root, 'public', Rails.application.config.assets.prefix, asset).and_return(path)
        call_method
      end
      it 'returns the contents of the file found at that path' do
        expect(call_method).to eq(contents)
      end
    end
  end
end