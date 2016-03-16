RSpec.shared_examples 'a report that can be downloaded' do |method, download_options|
  jobs = download_options.collect do |option|
    case option
    when :xlsx
      ['xlsx', RenderReportExcelJob]
    when :pdf
      ['pdf', RenderReportPDFJob]
    end
  end

  let(:call_method) {subject.send(method.to_sym)}

  it 'sets @report_name' do
    call_method
    expect(assigns[:report_name]).to be_kind_of(String)
  end
  it 'calls `downloadable_report` with the supported formats' do
    formats = download_options.count == 1 ? download_options.first : nil
    expect(subject).to receive(:downloadable_report) do |*args|
      if args.present?
        passed_formats = Array.wrap(args.first)
        expect(passed_formats).to match(download_options)
      else
        expect(download_options).to match(described_class::DOWNLOAD_FORMATS)
      end
    end
    call_method
  end
  jobs.each do |format|
    describe "downloading a #{format.first.upcase}" do
      let(:member_id) { double('A Member ID') }
      let(:job_status) { double('JobStatus', update_attributes!: nil)}
      let(:active_job) { double('Active Job Instance', job_status: job_status) }
      let(:user_id) { rand(1000) }
      let(:current_user) { double('User', id: user_id, :accepted_terms? => true)}

      before do
        allow_any_instance_of(MembersService).to receive(:report_disabled?).and_return(false)
        allow_any_instance_of(MembersService).to receive(:member).with(anything).and_return({id: member_id, name: 'Foo'})
        allow_any_instance_of(subject.class).to receive(:current_member_id).and_return(member_id)
        allow(format.last).to receive(:perform_later).and_return(active_job)
        allow(controller).to receive(:current_user).and_return(current_user)
        allow(controller).to receive(:fhlb_report_date_numeric)
      end

      it "enqueues a report #{format.first} job when the requested `export_format` is `#{format.first}`" do
        expect(format.last).to receive(:perform_later).with(member_id, method.to_s, any_args).and_return(active_job)
        get method.to_sym, export_format: format.first
      end
      it 'updates the job_status instance with the user_id of the current user' do
        expect(job_status).to receive(:update_attributes!).with({user_id: user_id})
        get method.to_sym, export_format: format.first
      end
      it 'returns a json response with a `job_status_url`' do
        get method.to_sym, export_format: format.first
        expect(JSON.parse(response.body).with_indifferent_access[:job_status_url]).to eq(job_status_url(job_status))
      end
      it 'returns a json response with a `job_cancel_url`' do
        get method.to_sym, export_format: format.first
        expect(JSON.parse(response.body).with_indifferent_access[:job_cancel_url]).to eq(job_cancel_url(job_status))
      end
    end
  end
end

RSpec.shared_examples 'a job that makes service calls' do |service, method|
  let(:member_id) { double('A Member ID') }
  let(:run_job) { subject.perform(member_id) }
  let(:results) { double('results') }
  let(:uuid) { double('uuid') }

  it "calls `#{service.to_s}##{method.to_s}`" do
    expect_any_instance_of(service).to receive(method).and_return(results)
    run_job
  end
  it "creates a new instance of #{service} with the proper member_id" do
    expect(service).to receive(:new).with(member_id, anything)
    run_job
  end
  it "creates a new instance of #{service} with an instance of ActionDispatch::TestRequest" do
    expect(service).to receive(:new).with(anything, instance_of(ActionDispatch::TestRequest))
    run_job
  end
  it 'creates an instance of TestRequest using the uuid if one is provided' do
    expect(ActionDispatch::TestRequest).to receive(:new).with({'action_dispatch.request_id' => uuid})
    subject.perform(member_id, uuid)
  end
  it 'creates an instance of TestRequest with a nil uuid if one is not provided' do
    expect(ActionDispatch::TestRequest).to receive(:new).with({'action_dispatch.request_id' => nil})
    run_job
  end
end