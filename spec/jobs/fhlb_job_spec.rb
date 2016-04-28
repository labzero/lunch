require 'rails_helper'

RSpec.describe FhlbJob, type: :job do
  let(:base_instance) { FhlbJob.new }
  describe '`job_status` method' do
    it 'find or creates an instance of JobStatus using its job_id' do
      expect(JobStatus).to receive(:find_or_create_by!).with(job_id: base_instance.job_id)
      base_instance.job_status
    end
  end

  describe 'enqueuing' do
    it 'calls `job_status`' do
      expect_any_instance_of(FhlbJob).to receive(:job_status)
      FhlbJob.perform_later
    end
  end

  describe '`perform_with_rescue` method' do
    let(:job_status) { double('job status instance', canceled?: false, completed?: false, completed!: nil, started!: nil, failed!: nil) }
    let(:args) { double('arguments') }
    let(:block) { double('a block of code') }
    let(:job_result) { double('result of the job') }
    before do
      allow(base_instance).to receive(:job_status).and_return(job_status)
    end
    it 'returns nil if job has a status of canceled' do
      allow(job_status).to receive(:canceled?).and_return(true)
      expect(base_instance.perform_with_rescue).to be_nil
    end
    describe 'job not canceled' do
      before do
        allow(base_instance).to receive(:perform_without_rescue)
      end
      it 'sets the job_status to `started`' do
        expect(job_status).to receive(:started!)
        base_instance.perform_with_rescue
      end
      it 'calls `perform_without_rescue` with the same args and block it was given' do
        expect(base_instance).to receive(:perform_without_rescue).with(args, block)
        base_instance.perform_with_rescue(args, block)
      end
      it 'sets the job_status status equal to completed if the status is not canceled' do
        expect(job_status).to receive(:completed!)
        base_instance.perform_with_rescue
      end
      it 'returns the result of perform_without_rescue' do
        allow(base_instance).to receive(:perform_without_rescue).and_return(job_result)
        expect(base_instance.perform_with_rescue).to eq(job_result)
      end
    end
    describe 'error handling' do
      before do
        allow(job_status).to receive(:canceled?).and_raise('some error!')
      end
      it 'logs the error at the `warn` level' do
        expect(Rails.logger).to receive(:warn)
        base_instance.perform_with_rescue
      end
      it 'provides a backtrace of the error at the `debug` level' do
        expect(Rails.logger).to receive(:debug)
        base_instance.perform_with_rescue
      end
      it 'sets the job_status equal to `failed`' do
        expect(job_status).to receive(:failed!)
        base_instance.perform_with_rescue
      end
      it 'returns nil' do
        allow(job_status).to receive(:failed!).and_return(double('Status Change Result'))
        expect(base_instance.perform_with_rescue).to be(nil)
      end
    end
  end

  describe '`queue` class method' do
    it 'returns the value provided by the `queue_name` method' do
      name = double('A Queue Name')
      allow(described_class).to receive(:queue_name).and_return(name)
      expect(described_class.queue).to eq(name)
    end
  end

  describe '`scheduled` class method' do
    let(:klass) { double('A Class', constantize: described_class) }
    let(:queue) { double('A Queue') }
    let(:args) { [double('An Arg'), double('An Arg')] }
    let(:call_method) { described_class.scheduled(queue, klass, *args) }

    before do
      allow(described_class).to receive(:perform_later)
      allow(described_class).to receive(:set).and_return(described_class)
    end

    it 'constantizes the class' do
      expect(klass).to receive(:constantize).and_return(described_class)
      call_method
    end
    it 'sets the queue' do
      expect(described_class).to receive(:set).with(include(queue: queue)).and_return(described_class)
      call_method
    end
    it 'calls `perform_later`' do
      expect(described_class).to receive(:perform_later).with(*args)
      call_method
    end
  end
end