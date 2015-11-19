require 'rails_helper'

describe ResourceHelper do
  describe 'link_to_download_resource' do
    let(:text) { double('some text') }
    let(:url) { double('a url') }
    let(:target) { double('a target')}
    let(:options) { {foo: :bar, target: :car} }
    let(:call_method) { helper.link_to_download_resource(text, url) }
    
    it 'calls `link_to` with the given text' do
      expect(helper).to receive(:link_to).with(text, anything, anything)
      call_method
    end
    it 'calls `link_to` with the given url' do
      expect(helper).to receive(:link_to).with(anything, url, anything)
      call_method
    end
    it 'calls `link_to` with a target of \'_blank\' by default' do
      expect(helper).to receive(:link_to).with(anything, anything, {target: '_blank'})
      call_method
    end
    it 'calls `link_to` with the given options' do
      expect(helper).to receive(:link_to).with(anything, anything, options)
      helper.link_to_download_resource(text, url, options)
    end
    it 'calls `link_to` adding a default target to the options' do
      expect(helper).to receive(:link_to).with(anything, anything, {foo: :car, target: '_blank'})
      helper.link_to_download_resource(text, url, {foo: :car})
    end
  end
end