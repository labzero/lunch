require 'rails_helper'
require 'rake'

RSpec.describe RakeTaskJob, type: :job do
  let(:task_name) { SecureRandom.hex }
  let(:sentinel) { double(Object, some_method: nil) }
  let(:arguments) { [double(Object), double(Object)] }
  let(:run_job) { described_class.perform_now(task_name, *arguments) }
  before do
    allow(::Rake.application).to receive(:init)
    allow(::Rake.application).to receive(:load_rakefile)
    ::Rake::Task.clear
    ::Rake::Task.define_task(task_name) do |t, args|
      sentinel.some_method(*args)
    end
  end
  it 'initializes the Rake::Application' do
    expect(Rake.application).to receive(:init)
    run_job
  end
  it 'loads the Rakefile' do
    expect(Rake.application).to receive(:load_rakefile)
    run_job
  end
  it 'executes the supplied task with the passed arguments' do
    expect(sentinel).to receive(:some_method).with(*arguments)
    run_job
  end
  it 'executes the task each time perform is called' do
    expect(sentinel).to receive(:some_method).with(*arguments).twice
    described_class.perform_now(task_name, *arguments)
    described_class.perform_now(task_name, *arguments)
  end
end