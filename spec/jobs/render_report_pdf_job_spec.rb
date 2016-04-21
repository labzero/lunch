require 'rails_helper'

RSpec.describe RenderReportPDFJob, type: :job do
  let(:member_id) { double('A Member ID') }
  let(:member_name) { double('A Member Name') }
  let(:sta_number) { double('STA Number')}
  let(:member) { {id: member_id, name: member_name, sta_number: sta_number} }
  let(:start_date) { double('A Date', to_date: Date.today) }
  let(:report_name) { :advances_detail }
  let(:report_html) { double('Some Report HTML') }
  let(:footer_html) { double('Some Footer HTML') }
  let(:pdf) { double('A PDF') }
  let(:filename) { 'my_awesome_filename' }
  let(:params) { {start_date: start_date} }
  let(:run_job) { subject.perform(member_id, report_name, filename, params) }
  let(:reports_controller) { ReportsController.new }
  let(:wicked_pdf) { double('wicked pdf instance', pdf_from_string: pdf) }
  let(:user) { double(User) }
  let(:string_io_with_filename) { double('some StringIO instance', :'content_type=' => nil, :'original_filename=' => nil, :rewind => nil) }
  let(:job_status) { double('job status instance', canceled?: false, completed?: false, started!: nil, completed!: nil, failed!: nil, :'result=' => nil, :'status=' => nil, save!: nil, user: user) }

  before do
    allow(JobStatus).to receive(:find_or_create_by!).and_return(job_status)
    allow(ReportsController).to receive(:new).and_return(reports_controller)
    allow(reports_controller).to receive(report_name).and_return([report_html])
    allow(reports_controller).to receive(:render_to_string).with('reports/pdf_footer').and_return(footer_html)
    allow(reports_controller).to receive(:performed?).and_return(true)
    allow(reports_controller).to receive(:instance_variable_set)
    allow(ReportsController).to receive(:layout)
    allow(WickedPdf).to receive(:new).and_return(wicked_pdf)
    allow(StringIOWithFilename).to receive(:new).and_return(string_io_with_filename)
    allow_any_instance_of(MembersService).to receive(:member).with(member_id).and_return(member)
  end

  it 'should return nil if the job_status is `canceled`' do
    allow(job_status).to receive(:canceled?).and_return(true)
    expect(run_job).to be_nil
  end

  it 'should fetch the member details for the supplied member_id' do
    expect_any_instance_of(MembersService).to receive(:member).with(member_id).and_return(member)
    run_job
  end

  it 'should raise an exception if the member can\'t be found' do
    allow_any_instance_of(MembersService).to receive(:member).with(member_id).and_return(nil)
    expect {subject.perform_without_rescue(member_id, report_name, filename, params)}.to raise_error(/Member not found/)
  end

  it 'should render the report if the controller action didn\'t' do
    allow(reports_controller).to receive(:performed?).and_return(false)
    expect(reports_controller).to receive(:render_to_string).with("reports/#{report_name}").and_return(report_html)
    run_job
  end

  describe 'before calling the report action' do
    let(:run_job) do
      expect(reports_controller).to receive(report_name).and_return([report_html]).ordered
      subject.perform(member_id, report_name, filename, {start_date: start_date})
    end
    it 'should populate the session with the member details' do
      session = double('A Session', :[] => nil)
      allow(reports_controller).to receive(:session).and_return(session)
      expect(session).to receive(:[]=).with('member_id', member_id).ordered # technically we should let the order of these two vary, but RSpec doesn't have support for that
      expect(session).to receive(:[]=).with('member_name', member_name).ordered
      expect(session).to receive(:[]=).with('sta_number', sta_number).ordered
      run_job
    end
    it 'should set @inline_styles to `true`' do
      expect(reports_controller).to receive(:instance_variable_set).with(:@inline_styles, true).ordered
      run_job
    end
    it 'should set @skip_javascript to `true`' do
      expect(reports_controller).to receive(:instance_variable_set).with(:@skip_javascript, true).ordered
      run_job
    end
    it 'should set @print_layout to `true`' do
      expect(reports_controller).to receive(:instance_variable_set).with(:@print_layout, true).ordered
      run_job
    end
    it 'sets the `skip_deferred_load` controller attribute to `true`' do
      run_job
      expect(reports_controller.skip_deferred_load).to eq(true)
    end
    it 'should set the controller `params` to the params supplied to the job' do
      expect(reports_controller).to receive(:params=).with(params).ordered
      run_job
    end
    it 'should set the layout to `print`' do
      expect(ReportsController).to receive(:layout).with('print').ordered
      run_job
    end
    it 'creates a FhlbMember::WardenProxy for the job status user' do
      expect(FhlbMember::WardenProxy).to receive(:new).with(user)
      run_job
    end
    it 'adds a FhlbMember::WardenProxy to the request env' do
      request = ActionDispatch::TestRequest.new
      allow(ActionDispatch::TestRequest).to receive(:new).and_return(request)
      warden = double(FhlbMember::WardenProxy)
      allow(FhlbMember::WardenProxy).to receive(:new).with(user).and_return(warden)
      allow(request.env).to receive(:[]=).and_call_original
      expect(request.env).to receive(:[]=).with('warden', warden)
      run_job
    end
  end

  describe 'before rendering the report footer HTML' do
    let(:run_job) do
      expect(reports_controller).to receive(:render_to_string).with('reports/pdf_footer').and_return(footer_html).ordered
      subject.perform(member_id, report_name, {start_date: start_date})
    end
    it 'should set @member_name to the name of the member' do
      expect(reports_controller).to receive(:instance_variable_set).with(:@member_name, member_name).ordered
      run_job
    end
    it 'should set the layout to `print_footer`' do
      expect(ReportsController).to receive(:layout).with('print_footer').ordered
      run_job
    end
  end

  describe 'rendering the PDF' do
    it 'should use the generated report HTML' do
      expect(wicked_pdf).to receive(:pdf_from_string).with(report_html, any_args)
      run_job
    end
    it 'should use the generated footer HTML' do
      expect(wicked_pdf).to receive(:pdf_from_string).with(any_args, hash_including(footer: {content: footer_html}))
      run_job
    end
    it 'should set the margins' do
      expect(wicked_pdf).to receive(:pdf_from_string).with(any_args, hash_including(margin: {top: subject.class::MARGIN, left: subject.class::MARGIN, bottom: subject.class::MARGIN, right: subject.class::MARGIN}))
      run_job
    end
    it 'should use the `print` media type' do
      expect(wicked_pdf).to receive(:pdf_from_string).with(any_args, hash_including(print_media_type: true))
      run_job
    end
    it 'should disable external links' do
      expect(wicked_pdf).to receive(:pdf_from_string).with(any_args, hash_including(disable_external_links: true))
      run_job
    end
    it 'should enable smart shrinking' do
      expect(wicked_pdf).to receive(:pdf_from_string).with(any_args, hash_including(disable_smart_shrinking: false))
      run_job
    end
  end

  describe 'writing the PDF to file' do
    it 'should create an instance of StringIOWithFilename from the generated pdf' do
      expect(StringIOWithFilename).to receive(:new).with(pdf)
      run_job
    end
    it 'sets the `content_type` of the file' do
      expect(string_io_with_filename).to receive(:content_type=).with('application/pdf')
      run_job
    end
    it 'sets the `original_filename` of the file' do
      expect(string_io_with_filename).to receive(:original_filename=).with("#{filename}.pdf")
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
