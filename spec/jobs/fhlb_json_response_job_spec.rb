require 'rails_helper'

RSpec.describe FhlbJsonResponseJob, type: :job do

  describe '`perform_with_json_result`' do
    let(:job_status) { double(JobStatus, canceled?: false, :result= => nil, :status= => nil, :no_download= => nil, save!: nil, started!: nil, completed?: nil, completed!: nil) }
    let(:args) { double('arguments') }
    let(:block) { double('a block of code') }
    let(:run_job) { subject.perform(args, block) }
    let(:results) { double('result of the perform_without_json_result call') }
    let(:file) { double('instance of StringIOWithFilename', :content_type= => nil, :original_filename= => nil, ) }
    before do
      allow(subject).to receive(:job_status).and_return(job_status)
      allow(subject).to receive(:perform_without_json_result).and_return(results)
      allow(results).to receive(:to_json).and_return(results)
      allow(StringIOWithFilename).to receive(:new).and_return(file)
    end

    it 'returns nil if the job has been canceled' do
      allow(job_status).to receive(:canceled?).and_return(true)
      expect(run_job).to be_nil
    end

    it 'calls `perform_without_json_result` to get the results' do
      expect(subject).to receive(:perform_without_json_result).and_return(results)
      run_job
    end

    it 'raises an error if `perform_without_json_result` returns nil' do
      allow(subject).to receive(:perform_without_json_result).and_return(nil)
      expect{run_job}.to raise_error
    end

    it 'creates a `StringIOWithFilename` with the JSON serialized results of the service call' do
      expect(StringIOWithFilename).to receive(:new).with(results).and_return(file)
      run_job
    end

    it 'sets the StringIOWithFilename.content_type to `application/json`' do
      expect(file).to receive(:content_type=).with('application/json')
      run_job
    end

    it 'sets the StringIOWithFilename.original_filename to `results.json`' do
      expect(file).to receive(:original_filename=).with('results.json')
      run_job
    end

    it 'sets the `result` on the JobStatus to the StringIOWithFilename' do
      expect(job_status).to receive(:result=).with(file).ordered
      expect(job_status).to receive(:save!).once.ordered
      run_job
    end

    it 'flags the JobStatus as completed on success' do
      expect(job_status).to receive(:save!).once.ordered
      expect(job_status).to receive(:completed!).ordered
      run_job
    end

    it 'flags the JobStatus as no_download' do
      expect(job_status).to receive(:no_download=).with(true).ordered
      expect(job_status).to receive(:save!).once.ordered
      run_job
    end

    it 'returns the results' do
      expect(run_job).to be(results)
    end
  end
end