require 'rails_helper'
require 'rake'

describe Rake do
  describe 'the process:maintenance task' do
    before :each do
      Rake::Task.clear
      load 'lib/tasks/maintenance.rake'
      Rake::Task.define_task(:environment)
      allow(STDOUT).to receive(:print) # just to suppress output
    end
    it 'calls the `maintenance` action on the ErrorController' do
      expect_any_instance_of(ErrorController).to receive(:maintenance).and_return([''])
      ::Rake::Task['process:maintenance'].invoke()
    end
    it 'does not raise an error' do
      expect{::Rake::Task['process:maintenance'].invoke()}.to_not raise_error
    end
    it 'prints its results to STDOUT with no arguments' do
      some_html = double('HTML')
      allow_any_instance_of(ErrorController).to receive(:maintenance).and_return([some_html])
      expect(STDOUT).to receive(:print).with(some_html)
      ::Rake::Task['process:maintenance'].invoke()
    end
    it 'dumps its results to a File when supplied with a path' do
      some_html = double('HTML')
      some_path = double('Path')
      allow_any_instance_of(ErrorController).to receive(:maintenance).and_return([some_html])
      expect(File).to receive(:write).with(some_path, some_html)
      ::Rake::Task['process:maintenance'].invoke(some_path)
    end
    it 'handles a missing Sprockets::Environment' do
      allow(Rails.application).to receive(:assets).and_return(nil)
      expect{::Rake::Task['process:maintenance'].invoke()}.to_not raise_error
    end
  end
end