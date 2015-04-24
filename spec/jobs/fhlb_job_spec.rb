require 'rails_helper'

RSpec.describe FhlbJob, type: :job do
  let(:base_instance) { FhlbJob.new}
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
      it 'logs the error' do
        expect(Rails.logger).to receive(:warn)
        base_instance.perform_with_rescue
      end
      it 'sets the job_status equal to `failed`' do
        expect(job_status).to receive(:failed!)
        base_instance.perform_with_rescue
      end
    end
  end
end