RSpec.shared_examples 'a MemberBalanceServiceJob backed report' do |service_job_method, job_call, deferred_job = false|
  let(:job_response) {deferred_job ? response_hash : member_balance_service_job_instance}
  describe "calling `#{job_call}` on the MemberBalanceServiceJob" do
    it 'passes the member id' do
      allow(controller).to receive(:report_disabled?).and_return(false) if controller.respond_to? :report_disabled?
      allow(controller).to receive(:current_member_id).and_return(member_id)
      expect(MemberBalanceServiceJob).to receive(job_call).with(member_id, any_args).and_return(job_response)
      call_action
    end
    it "passes `#{service_job_method}`" do
      expect(MemberBalanceServiceJob).to receive(job_call).with(anything, service_job_method, any_args).and_return(job_response)
      call_action
    end
    it 'passes the proper uuid' do
      expect(MemberBalanceServiceJob).to receive(job_call).with(anything, anything, request.uuid, any_args).and_return(job_response)
      call_action
    end
  end
  if job_call == :perform_later
    it 'updates the job status with the user\'s id' do
      allow(controller).to receive(:current_user).and_return(user)
      expect(job_status).to receive(:update_attributes!).with({user_id: user_id})
      call_action
    end
    it 'sets the @job_status_url' do
      call_action
      expect(assigns[:job_status_url]).to eq(job_status_url(job_status))
    end
  end
end

RSpec.shared_examples 'a JobStatus backed report' do
  let(:parsed_response_hash) { double('parsed hash', with_indifferent_access: response_hash, collect!: response_hash) }
  before do
    allow(JobStatus).to receive(:find_by).and_return(job_status)
    allow(JSON).to receive(:parse).and_return(parsed_response_hash)
  end
  it 'finds the JobStatus by id, user_id, and status' do
    allow(controller).to receive(:current_user).and_return(user)
    expect(JobStatus).to receive(:find_by).with(id: job_id.to_s, user_id: user_id, status: JobStatus.statuses[:completed]).and_return(job_status)
    call_action_with_job_id
  end
  it 'raises an error if there is no job status found' do
    allow(JobStatus).to receive(:find_by)
    expect{call_action_with_job_id}.to raise_error(ActiveRecord::RecordNotFound)
  end
  it 'parses the job_status string' do
    job_status_string = double('job status string')
    allow(job_status).to receive(:result_as_string).and_return(job_status_string)
    expect(JSON).to receive(:parse).with(job_status_string).and_return(parsed_response_hash)
    call_action_with_job_id
  end
  it 'destroys the job status' do
    expect(job_status).to receive(:destroy)
    call_action_with_job_id
  end
end