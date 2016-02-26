require 'rails_helper'

describe HeaderHelper, type: :helper do
  describe '`header_report_nav_item` method' do
    let(:title) { SecureRandom.hex }
    let(:path) { SecureRandom.hex }
    let(:link) { SecureRandom.hex }
    let(:call_method) { helper.header_report_nav_item(title, path, true) }
    before do
      allow(helper).to receive(:link_to).with(title, path).and_return(link)
    end
    it 'creates a `li`' do
      expect(helper).to receive(:content_tag).with(:li, anything, anything)
      call_method
    end
    it 'returns the header nav item HTML' do
      result = double('Some HTML')
      allow(helper).to receive(:content_tag).and_return(result)
      expect(call_method).to be(result)
    end
    describe 'when enabled' do
      it 'defaults to enabled' do
        expect(helper).to receive(:link_to)
        helper.header_report_nav_item(title, path)
      end
      it 'wraps the `title` in a link to `path`' do
        expect(helper).to receive(:link_to).with(title, path)
        call_method
      end
      it 'puts the link as the item content' do
        expect(helper).to receive(:content_tag).with(anything, link, anything)
        call_method
      end
      it 'does not include the class `disabled`' do
        expect(helper).to receive(:content_tag).with(anything, anything, hash_excluding(class: :disabled))
        call_method
      end
    end
    describe 'when disabled' do
      let(:call_method) { helper.header_report_nav_item(title, path, false) }
      it 'does not include a link' do
        expect(helper).to_not receive(:link_to)
        call_method
      end
      it 'puts the class `disabled` on the returned node' do
        expect(helper).to receive(:content_tag).with(anything, anything, include(class: :disabled))
        call_method
      end
      it 'puts the title as the item content' do
        expect(helper).to receive(:content_tag).with(anything, title, anything)
        call_method
      end
    end
  end
end