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

  it 'should set @report_name' do
    call_method
    expect(assigns[:report_name]).to be_kind_of(String)
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
      end

      it "should enqueue a report #{format.first} job when the requested `export_format` is `#{format.first}`" do
        expect(format.last).to receive(:perform_later).with(member_id, method.to_s, any_args).and_return(active_job)
        get method.to_sym, export_format: format.first
      end
      it 'should update the job_status instance with the user_id of the current user' do
        expect(job_status).to receive(:update_attributes!).with({user_id: user_id})
        get method.to_sym, export_format: format.first
      end
      it 'should return a json response with a `job_status_url`' do
        get method.to_sym, export_format: format.first
        expect(JSON.parse(response.body).with_indifferent_access[:job_status_url]).to eq(job_status_url(job_status))
      end
      it 'should return a json response with a `job_cancel_url`' do
        get method.to_sym, export_format: format.first
        expect(JSON.parse(response.body).with_indifferent_access[:job_cancel_url]).to eq(job_cancel_url(job_status))
      end
    end
  end
end