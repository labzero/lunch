require 'rails_helper'

RSpec.describe RenderReportExcelJob, type: :job do
  let(:member_id) { double('A Member ID') }
  let(:member_name) { double('A Member Name') }
  let(:member) { {id: member_id, name: member_name} }
  let(:start_date) { double('A Date', to_date: Date.today) }
  let(:action_name) { :advances_detail }
  let(:xlsx) { double('An XLSX File') }
  let(:filename) { 'my_awesome_filename' }
  let(:action_name) { SecureRandom.hex }
  let(:params) { {start_date: start_date} }
  let(:call_method) { subject.perform(member_id, action_name, filename, params) }
  let(:request) { instance_double(ActionDispatch::TestRequest, env: {}) }
  let(:controller) { double('controller', report_download_name: nil, :request= => nil, :response= => nil, request: request, session: {}, :action_name= => nil, :params= => nil, action_name: nil, :skip_deferred_load= => nil, action_name => nil) }
  let(:user) { double(User) }
  let(:file) { double('some StringIO instance', :'content_type=' => nil, :'original_filename=' => nil, :rewind => nil) }
  let(:warden_proxy) { instance_double(FhlbMember::WardenProxy) }
  let(:job_status) { double('job status instance', canceled?: false, completed?: false, started!: nil, completed!: nil, failed!: nil, :'result=' => nil, :'status=' => nil, save!: nil, user: user) }

  before do
    allow(JobStatus).to receive(:find_or_create_by!).and_return(job_status)
    allow(ReportsController).to receive(:new).and_return(controller)
    allow(controller).to receive(action_name)
    allow(controller).to receive(:render_to_string).and_return(xlsx)
    allow_any_instance_of(MembersService).to receive(:member).with(member_id).and_return(member)
    allow(StringIOWithFilename).to receive(:new).and_return(file)
    allow(FhlbMember::WardenProxy).to receive(:new).and_return(warden_proxy)
  end

  it_behaves_like 'a job that has a filename', :xlsx

  it 'should fetch the member details for the supplied member_id' do
    expect_any_instance_of(MembersService).to receive(:member).with(member_id).and_return(member)
    call_method
  end

  it 'should raise an exception if the member can\'t be found' do
    allow_any_instance_of(MembersService).to receive(:member).with(member_id).and_return(nil)
    expect {subject.perform_without_rescue(member_id, action_name, filename, params)}.to raise_error(/Member not found/)
  end

  describe 'before calling the report action' do
    let(:call_method) do
      expect(controller).to receive(action_name).ordered
      subject.perform(member_id, action_name, filename, {start_date: start_date})
    end
    it 'populates the session with the member details' do
      session = double('A Session', :[] => nil)
      allow(controller).to receive(:session).and_return(session)
      expect(session).to receive(:[]=).with('member_id', member_id).ordered # technically we should let the order of these two vary, but RSpec doesn't have support for that
      expect(session).to receive(:[]=).with('member_name', member_name).ordered
      call_method
    end
    it 'sets the controller `params` to the params supplied to the job' do
      expect(controller).to receive(:params=).with(params).ordered
      call_method
    end
    it 'sets the `skip_deferred_load` controller attribute to `true`' do
      expect(controller).to receive(:skip_deferred_load=).with(true)
      call_method
    end
    it 'creates a FhlbMember::WardenProxy for the job status user' do
      expect(FhlbMember::WardenProxy).to receive(:new).with(user)
      call_method
    end
    it 'creates a new instance of FhlbMember::WardenProxy with the user from the job_status' do
      expect(FhlbMember::WardenProxy).to receive(:new).with(user).and_return(warden_proxy)
      call_method
    end
    it 'sets the `warden` value in the request env hash to the instance of FhlbMember::WardenProxy' do
      call_method
      expect(controller.request.env['warden']).to eq(warden_proxy)
    end
  end

  describe 'rendering the XLSX file' do
    it 'should the render the report template' do
      expect(controller).to receive(:render_to_string).with(hash_including(template: "reports/#{action_name}"))
      call_method
    end
    it 'should use the `axlsx` view handler' do
      expect(controller).to receive(:render_to_string).with(hash_including(handlers: [:axlsx]))
      call_method
    end
    it 'should use the `xlsx` view format' do
      expect(controller).to receive(:render_to_string).with(hash_including(formats: [:xlsx]))
      call_method
    end
  end

  describe 'writing the XLSX to file' do
    it 'should create an instance of StringIOWithFilename from the generated Excel file' do
      expect(StringIOWithFilename).to receive(:new).with(xlsx)
      call_method
    end
    it 'sets the `content_type` of the file' do
      expect(file).to receive(:content_type=).with('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
      call_method
    end
    it 'sets the file as the `result` attribute of the job_status object' do
      expect(job_status).to receive(:result=).with(file)
      call_method
    end
    it 'flags the JobStatus as completed on success' do
      expect(job_status).to receive(:save!).once.ordered
      expect(job_status).to receive(:completed!).ordered
      call_method
    end
    it 'saves the job_status' do
      expect(job_status).to receive(:save!)
      call_method
    end
    it 'rewinds the file' do
      expect(file).to receive(:rewind)
      call_method
    end
    it 'returns the file' do
      expect(call_method).to eq(file)
    end
  end
end
