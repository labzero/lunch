require 'spec_helper'
require 'rake'
require 'process_corp_com'

describe ProcessCorpCom do
  it { expect(subject).to respond_to(:prepend_style_tags) }

  describe 'prepend_style_tags method' do
    let(:email) {File.join(Rails.root + 'spec' + 'fixtures' + 'corp_com_fixture.txt')}
    it 'moves the `style` element from the email\'s `head` node into its `body` node' do
      expect(subject.prepend_style_tags(email)).to include('<style type=\"text/css\">')
    end
    it 'prepends the styles contained in the style node with `.corporate-communication-detail-reset`' do
      expect(subject.prepend_style_tags(email)).to include('.corporate-communication-detail-reset a')
      expect(subject.prepend_style_tags(email)).to include('.corporate-communication-detail-reset p')
    end
    it 'throws an error if it cannot find the file it was passed' do
      expect{subject.prepend_style_tags('some_nonexistant_file.txt')}.to raise_error(Errno::ENOENT)
    end
    it 'removes images that start with http://open.mkt1700.com/open/log/' do
      expect(subject.prepend_style_tags(email)).not_to include('http://open.mkt1700.com/open/log/')
    end
    it 'replaces html element links that start with http://links.mkt1700.com/' do
      expect(subject.prepend_style_tags(email)).not_to include('http://links.mkt1700.com/')
    end
  end
end

describe Rake do
  describe 'the process:corp_com task' do
    before do
      load 'lib/tasks/process_corp_com.rake'
      Rake::Task.define_task(:environment)
    end
    let(:email) {'some_email'}
    it 'calls the method `prepend_style_tags` on the `ProcessCorpCom` module with the given argument' do
      expect(ProcessCorpCom).to receive(:prepend_style_tags).with(email)
      ::Rake::Task["process:corp_com"].invoke(email)
    end
  end
end