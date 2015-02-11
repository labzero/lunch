require 'spec_helper'
require 'rake'

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