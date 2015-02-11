require 'spec_helper'
require 'process_corp_com'

describe ProcessCorpCom do
  it { expect(subject).to respond_to(:prepend_style_tags) }

  describe 'prepend_style_tags method' do
    let(:email) {File.join(Rails.root + 'spec' + 'fixtures' + 'corp_com_fixture.txt')}
    it 'moves the `style` element from the email\'s `head` node into its `body` node' do
      expect(subject.prepend_style_tags(email)).to include('<style type="text/css">')
    end
    it 'prepends the styles contained in the style node with `.corporate-communication-detail-reset`' do
      expect(subject.prepend_style_tags(email)).to include('.corporate-communication-detail-reset a')
      expect(subject.prepend_style_tags(email)).to include('.corporate-communication-detail-reset p')
    end
    it 'throws an error if it cannot find the file it was passed' do
      expect{subject.prepend_style_tags('some_nonexistant_file.txt')}.to raise_error(Errno::ENOENT)
    end
  end
end
