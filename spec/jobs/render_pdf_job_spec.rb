require 'rails_helper'

RSpec.describe RenderPDFJob, type: :job do
  describe 'public methods' do
    let(:member_id) { double('A Member ID') }
    let(:action_name) { SecureRandom.hex }
    let(:view) { double('view') }
    let(:user) { double('user') }
    let(:member) {{
      name: double('name'),
      fhfa_number: double('fhfa number'),
      sta_number: double('sta_number')
    }}
    let(:request) { instance_double(ActionDispatch::TestRequest, env: {}) }
    let(:params) { double('params hash') }
    let(:job_status) { double('job status instance', canceled?: false, completed?: false, started!: nil, completed!: nil, failed!: nil, :result= => nil, :status= => nil, save!: nil, user: user) }
    let(:controller) { double('controller', report_download_name: nil, :request= => nil, :response= => nil, request: request, session: {}, :action_name= => nil, :params= => nil, action_name: nil) }
    before do
      allow(subject).to receive(:job_status).and_return(job_status)
      allow(subject).to receive(:initialize_controller) { subject.instance_variable_set(:@controller, controller) }
      allow(subject).to receive(:pdf_orientation)
    end
    describe '`perform`' do
      let(:file) { instance_double(StringIOWithFilename, :content_type= => nil, :original_filename= => nil, rewind: nil) }
      let(:filename) { SecureRandom.hex }
      let(:report_download_name) { SecureRandom.hex }
      let(:rendered_pdf) { double('a rendered pdf') }
      let(:call_method) { subject.perform(member_id, action_name, nil, params) }
      before do
        allow(subject).to receive(:configure_controller)
        allow(subject).to receive(:set_controller_instance_vars)
        allow(subject).to receive(:render_pdf)
        allow(StringIOWithFilename).to receive(:new).and_return(file)
      end
      it 'initializes the controller' do
        expect(subject).to receive(:initialize_controller)
        call_method
      end
      it 'configures the controller with the appropriate args' do
        expect(subject).to receive(:configure_controller).with(member_id, action_name, params)
        call_method
      end
      it 'configures the controller with an empty hash for params if no params hash is provided' do
        expect(subject).to receive(:configure_controller).with(anything, anything, {})
        subject.perform(member_id, action_name)
      end
      it 'returns nil if the job_status is canceled' do
        allow(job_status).to receive(:canceled?).and_return(true)
        expect(call_method).to be nil
      end
      it 'calls `set_controller_instance_vars`' do
        expect(subject).to receive(:set_controller_instance_vars)
        call_method
      end
      it 'calls `render_pdf` with the view if one is provided' do
        expect(subject).to receive(:render_pdf).with(view)
        subject.perform(member_id, action_name, nil, nil, view)
      end
      it 'calls `render_pdf` with nil if no view is provided' do
        expect(subject).to receive(:render_pdf).with(nil)
        call_method
      end
      it 'creates a new instance of StringIOWithFilename with the result of `render_pdf`' do
        allow(subject).to receive(:render_pdf).and_return(rendered_pdf)
        expect(StringIOWithFilename).to receive(:new).with(rendered_pdf).and_return(file)
        call_method
      end
      it 'sets the file\'s content_type to `application/pdf`' do
        expect(file).to receive(:content_type=).with('application/pdf')
        call_method
      end
      it 'sets the file\'s original_filename to the passed filename if one is provided' do
        expect(file).to receive(:original_filename=).with("#{filename}.pdf")
        subject.perform(member_id, action_name, filename)
      end
      it 'sets the file\'s original_filename to the controller\'s report_download_name if a filename is not provided' do
        allow(controller).to receive(:report_download_name).and_return(report_download_name)
        expect(file).to receive(:original_filename=).with("#{report_download_name}.pdf")
        call_method
      end
      it 'sets the job_status result to the file' do
        expect(job_status).to receive(:result=).with(file)
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

    describe '`render_html`' do
      let(:response) { double('response', first: nil)}
      let(:controller) { mock_context(Module.new, instance_methods: [:action_name, action_name.to_sym, :performed?, :render_to_string], class_methods: [:layout])}
      let(:call_method) { subject.render_html(view) }
      before do
        subject.instance_variable_set(:@controller, controller)
        allow(controller).to receive(:action_name).and_return(action_name)
      end
      it 'sets the layout to print' do
        expect(controller.class).to receive(:layout).with('print')
        call_method
      end
      it 'calls the symbolized `action_name` method on the controller' do
        expect(controller).to receive(action_name.to_sym)
        call_method
      end
      describe 'when the controller returns true for `performed?`' do
        before { allow(controller).to receive(:performed?).and_return(true) }
        it 'returns the first response from sending the action name to the controller' do
          allow(controller).to receive(action_name.to_sym).and_return([response])
          expect(call_method).to eq(response)
        end
      end
      describe 'when the controller returns false for `performed?`' do
        before { allow(controller).to receive(:performed?).and_return(false) }
        it 'renders the view to a string if a view is provided' do
          expect(controller).to receive(:render_to_string).with(view)
          call_method
        end
        it 'renders the controller action to a string if no view is provided' do
          expect(controller).to receive(:render_to_string).with(action_name)
          subject.render_html(nil)
        end
      end
    end

    describe '`render_footer_html`' do
      let(:call_method) { subject.render_footer_html }
      before { subject.instance_variable_set(:@controller, controller) }
      it 'calls `render_to_string` with `pdf_footer`' do
        expect(controller).to receive(:render_to_string).with('pdf_footer', anything)
        call_method
      end
      it 'calls `render_to_string` with the `print_footer` layout' do
        expect(controller).to receive(:render_to_string).with(anything, {layout: 'print_footer'})
        call_method
      end
    end

    describe '`configure_controller`' do
      let(:warden_proxy) { instance_double(FhlbMember::WardenProxy) }
      let(:members_service) { instance_double(MembersService, member: member) }
      let(:member_id_session_key) { SecureRandom.hex }
      let(:member_name_session_key) { SecureRandom.hex }
      let(:call_method) { subject.configure_controller(member_id, action_name, params) }
      before do
        subject.instance_variable_set(:@controller, controller)
        allow(controller.class).to receive(:const_get)
        allow(controller).to receive(:request).and_return(request)
        allow(FhlbMember::WardenProxy).to receive(:new).and_return(warden_proxy)
        allow(MembersService).to receive(:new).and_return(members_service)
        allow(controller).to receive(:session).and_return({})
      end
      it 'sets the controller\'s request to an instance of ActionDispatch::TestRequest' do
        expect(controller).to receive(:request=).with(an_instance_of(ActionDispatch::TestRequest))
        call_method
      end
      it 'sets the controller\'s response to an instance of ActionDispatch::TestResponse' do
        expect(controller).to receive(:response=).with(an_instance_of(ActionDispatch::TestResponse))
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
      it 'creates a new instance of the MembersService with the request from the controller' do
        expect(MembersService).to receive(:new).with(request).and_return(members_service)
        call_method
      end
      it 'calls `member` on the MembersService instance with the member_id' do
        expect(members_service).to receive(:member).with(member_id)
        call_method
      end
      it 'sets the `@member` attribute to the result of `MembersService#member`' do
        allow(members_service).to receive(:member).and_return(member)
        call_method
        expect(subject.member).to eq(member)
      end
      it 'raises an error if there is no member found' do
        allow(members_service).to receive(:member)
        expect{call_method}.to raise_error('Member not found!')
      end
      it 'gets the `SessionKeys::MEMBER_ID` constant from the controller class' do
        expect(controller.class).to receive(:const_get).with('SessionKeys::MEMBER_ID')
        call_method
      end
      it 'gets the `SessionKeys::MEMBER_NAME` constant from the controller class' do
        expect(controller.class).to receive(:const_get).with('SessionKeys::MEMBER_NAME')
        call_method
      end
      it 'sets the session value for `SessionKeys::MEMBER_ID` to the member_id' do
        allow(controller.class).to receive(:const_get).with('SessionKeys::MEMBER_ID').and_return(member_id_session_key)
        call_method
        expect(controller.session[member_id_session_key]).to eq(member_id)
      end
      it 'sets the session value for `SessionKeys::MEMBER_NAME` to the member name' do
        allow(controller.class).to receive(:const_get).with('SessionKeys::MEMBER_NAME').and_return(member_name_session_key)
        call_method
        expect(controller.session[member_name_session_key]).to eq(member[:name])
      end
      it 'sets `skip_deferred_load` to true if possible' do
        expect(controller).to receive(:skip_deferred_load=).with(true)
        call_method
      end
      it 'sets the controller\'s action_name to the action_name' do
        expect(controller).to receive(:action_name=).with(action_name)
        call_method
      end
      it 'sets the controller\'s params to the passed params hash' do
        expect(controller).to receive(:params=).with(params)
        call_method
      end
    end

    describe '`set_controller_instance_vars`' do
      let(:call_method) { subject.set_controller_instance_vars }
      before do
        subject.instance_variable_set(:@controller, controller)
        subject.instance_variable_set(:@member, member)
        allow(controller).to receive(:instance_variable_set)
      end
      describe 'setting member-specific instance variables' do
        [
          ['@member_name', :name],
          ['@member_fhfa', :fhfa_number],
          ['@sta_number', :sta_number]
        ].each do |instance_var|
          it "sets the controller's `#{instance_var.first}` instance variable to `#{instance_var.last}` value from the member hash" do
            expect(controller).to receive(:instance_variable_set).with(:"#{instance_var.first}", member[instance_var.last])
            call_method
          end
        end
      end
      describe 'setting other instance variables' do
        [
          ['@inline_styles', true],
          ['@skip_javascript', true],
          ['@print_layout', true]
        ].each do |instance_var|
          it "sets the controller's `#{instance_var.first}` instance variable to `#{instance_var.last}`" do
            expect(controller).to receive(:instance_variable_set).with(:"#{instance_var.first}", instance_var.last)
            call_method
          end
        end
      end
    end

    describe '`render_pdf`' do
      let(:wicked_pdf) { instance_double(WickedPdf, pdf_from_string: nil) }
      let(:call_method) { subject.render_pdf(view) }

      before do
        subject.instance_variable_set(:@controller, controller)
        allow(WickedPdf).to receive(:new).and_return(wicked_pdf)
        allow(subject).to receive(:render_html)
        allow(subject).to receive(:render_footer_html)
      end

      it 'creates a new instance of `WickedPdf`' do
        expect(WickedPdf).to receive(:new)
        call_method
      end
      it 'calls `pdf_from_string` on the instance of `WickedPdf`' do
        expect(wicked_pdf).to receive(:pdf_from_string)
        call_method
      end
      it 'returns the results of calling `pdf_from_string` on the instance of `WickedPdf`' do
        pdf = double('pdf')
        allow(wicked_pdf).to receive(:pdf_from_string).and_return(pdf)
        expect(call_method).to eq(pdf)
      end
      describe 'the `pdf_from_string` args' do
        it 'calls `render_html` with the view' do
          expect(subject).to receive(:render_html).with(view)
          call_method
        end
        it 'calls `pdf_from_string` with the rendered html' do
          rendered_html = double('html')
          allow(subject).to receive(:render_html).and_return(rendered_html)
          expect(wicked_pdf).to receive(:pdf_from_string).with(rendered_html, any_args)
          call_method
        end
        describe 'the options hash' do
          {
            page_size: 'Letter',
            print_media_type: true,
            disable_external_links: true,
            margin: {
              top: described_class::MARGIN,
              left: described_class::MARGIN,
              right: described_class::MARGIN,
              bottom: described_class::MARGIN
            },
            disable_smart_shrinking: false
          }.each do |key, value|
            it "calls `pdf_from_string` with the `#{key}`` option set to `#{value}`" do
              expect(wicked_pdf).to receive(:pdf_from_string).with(anything, hash_including(key => value))
              call_method
            end
          end
          it 'calls `render_footer_html`' do
            expect(subject).to receive(:render_footer_html)
            call_method
          end
          it 'calls `pdf_from_string` with a `footer` option that includes the rendered footer' do
            rendered_footer = double('footer html')
            allow(subject).to receive(:render_footer_html).and_return(rendered_footer)
            expect(wicked_pdf).to receive(:pdf_from_string).with(anything, hash_including(footer: {content: rendered_footer}))
            call_method
          end
          it 'calls `pdf_orientation`' do
            expect(subject).to receive(:pdf_orientation)
            call_method
          end
          it 'calls `pdf_from_string` with the `orientation` option that is the result of calling `pdf_orientation`' do
            orientation = double('orientation')
            allow(subject).to receive(:pdf_orientation).and_return(orientation)
            expect(wicked_pdf).to receive(:pdf_from_string).with(anything, hash_including(orientation: orientation))
            call_method
          end
        end
      end
    end
  end

  describe 'private methods' do
    describe 'placeholder methods' do
      describe 'the `initialize_controller` method' do
        it 'returns nil' do
          expect(subject.send(:initialize_controller)).to be nil
        end
      end
    end
    describe '`pdf_orientation`' do
      it 'returns :portrait' do
        expect(subject.send(:pdf_orientation)).to eq(:portrait)
      end
    end
  end
end