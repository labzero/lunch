require 'rails_helper'

describe ResourceHelper do
  describe 'link_to_download_resource' do
    let(:text) { double('some text') }
    let(:url) { double('a url') }
    let(:target) { double('a target')}
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
    it 'calls `link_to with the given target`' do
      expect(helper).to receive(:link_to).with(anything, anything, {target: target})
      helper.link_to_download_resource(text, url, target)
    end
  end
end