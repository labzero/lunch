require 'rails_helper'

RSpec.describe RenderReportExcelJob, type: :job do
  let(:member_id) { double('A Member ID') }
  let(:member_name) { double('A Member Name') }
  let(:member) { {id: member_id, name: member_name} }
  let(:start_date) { double('A Date', to_date: Date.today) }
  let(:report_name) { :advances_detail }
  let(:xlsx) { double('An XLSX File') }
  let(:filename) { 'my_awesome_filename' }
  let(:params) { {start_date: start_date} }
  let(:run_job) { subject.perform(member_id, report_name, filename, params) }
  let(:reports_controller) { ReportsController.new }
  let(:string_io_with_filename) { double('some StringIO instance', :'content_type=' => nil, :'original_filename=' => nil, :rewind => nil) }
  let(:job_status) { double('job status instance', canceled?: false, completed?: false, started!: nil, completed!: nil, :'result=' => nil, :'status=' => nil, save!: nil) }

  before do
    allow(JobStatus).to receive(:find_or_create_by!).and_return(job_status)
    allow(ReportsController).to receive(:new).and_return(reports_controller)
    allow(reports_controller).to receive(report_name)
    allow(reports_controller).to receive(:render_to_string).and_return(xlsx)
    allow_any_instance_of(MembersService).to receive(:member).with(member_id).and_return(member)
    allow(StringIOWithFilename).to receive(:new).and_return(string_io_with_filename)
  end

  it 'should fetch the member details for the supplied member_id' do
    expect_any_instance_of(MembersService).to receive(:member).with(member_id).and_return(member)
    run_job
  end

  it 'should raise an exception if the member can\'t be found' do
    allow_any_instance_of(MembersService).to receive(:member).with(member_id).and_return(nil)
    expect {run_job}.to raise_error
  end

  describe 'before calling the report action' do
    let(:run_job) do
      expect(reports_controller).to receive(report_name).ordered
      subject.perform(member_id, report_name, filename, {start_date: start_date})
    end
    it 'should populate the session with the member details' do
      session = double('A Session', :[] => nil)
      allow(reports_controller).to receive(:session).and_return(session)
      expect(session).to receive(:[]=).with('member_id', member_id).ordered # technically we should let the order of these two vary, but RSpec doesn't have support for that
      expect(session).to receive(:[]=).with('member_name', member_name).ordered
      run_job
    end
    it 'should set the controller `params` to the params supplied to the job' do
      expect(reports_controller).to receive(:params=).with(params).ordered
      run_job
    end
  end

  describe 'rendering the XLSX file' do
    it 'should the render the report template' do
      expect(reports_controller).to receive(:render_to_string).with(hash_including(template: "reports/#{report_name}"))
      run_job
    end
    it 'should use the `axlsx` view handler' do
      expect(reports_controller).to receive(:render_to_string).with(hash_including(handlers: [:axlsx]))
      run_job
    end
    it 'should use the `xlsx` view format' do
      expect(reports_controller).to receive(:render_to_string).with(hash_including(formats: [:xlsx]))
      run_job
    end
  end

  describe 'writing the XLSX to file' do
    it 'should create an instance of StringIOWithFilename from the generated pdf' do
      expect(StringIOWithFilename).to receive(:new).with(xlsx)
      run_job
    end
    it 'sets the `content_type` of the file' do
      expect(string_io_with_filename).to receive(:content_type=).with('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
      run_job
    end
    it 'sets the `original_filename` of the file using the start_date param' do
      start_date = Time.zone.now.to_date.to_s
      expect(string_io_with_filename).to receive(:original_filename=).with("#{filename}.xlsx")
      run_job
    end
    it 'sets the file as the `result` attribute of the job_status object' do
      expect(job_status).to receive(:result=).with(string_io_with_filename)
      run_job
    end
    it 'flags the JobStatus as completed on success' do
      expect(job_status).to receive(:save!).once.ordered
      expect(job_status).to receive(:completed!).ordered
      run_job
    end
    it 'saves the job_status' do
      expect(job_status).to receive(:save!)
      run_job
    end
    it 'rewinds the file' do
      expect(string_io_with_filename).to receive(:rewind)
      run_job
    end
    it 'returns the file' do
      expect(run_job).to eq(string_io_with_filename)
    end
  end
end
