require 'rails_helper'

RSpec.describe MemberBalanceTodaysCreditActivityJob, type: :job do
  let(:member_id) { double('A Member ID') }
  let(:run_job) { subject.perform(member_id) }
  let(:json_results) { double('JSON Serialized Results')}
  let(:results) { double('Some Results', to_json: json_results) }
  let(:string_io_with_filename) { double('some StringIO instance', :'content_type=' => nil, :'original_filename=' => nil) }
  let(:job_status) { double('job status instance', canceled?: false, completed?: false, started!: nil, completed!: nil, :'result=' => nil, :'status=' => nil, save!: nil, failed!: nil, :'no_download=' => nil) }

  before do
    allow(JobStatus).to receive(:find_or_create_by!).and_return(job_status)
    allow_any_instance_of(MemberBalanceService).to receive(:todays_credit_activity).and_return(results)
    allow(StringIOWithFilename).to receive(:new).and_return(string_io_with_filename)
  end

  it 'should call `MemberBalanceService#todays_credit_activity`' do
    expect_any_instance_of(MemberBalanceService).to receive(:todays_credit_activity)
    run_job
  end

  it 'should fail the job if the MembersService call fails' do
    allow_any_instance_of(MemberBalanceService).to receive(:todays_credit_activity).and_return(nil)
    expect(job_status).to receive(:failed!)
    run_job
  end

  it 'should create a `StringIOWithFilename` with the JSON serialized results of the service call' do
    expect(StringIOWithFilename).to receive(:new).with(json_results)
    run_job
  end

  it 'should set the StringIOWithFilename.content_type to `application/json`' do
    expect(string_io_with_filename).to receive(:content_type=).with('application/json')
    run_job
  end

  it 'should set the StringIOWithFilename.original_filename to `results.json`' do
    expect(string_io_with_filename).to receive(:original_filename=).with('results.json')
    run_job
  end

  it 'should set the `result` on the JobStatus to the StringIOWithFilename' do
    expect(job_status).to receive(:result=).with(string_io_with_filename).ordered
    expect(job_status).to receive(:save!).once.ordered
    run_job
  end

  it 'should flag the JobStatus as completed on success' do
    expect(job_status).to receive(:status=).with(:completed).ordered
    expect(job_status).to receive(:save!).once.ordered
    run_job
  end

  it 'should flag the JobStatus as no_download' do
    expect(job_status).to receive(:no_download=).with(true).ordered
    expect(job_status).to receive(:save!).once.ordered
    run_job
  end

  it 'should return the results' do
    expect(run_job).to be(results)
  end
end
