class RenderPDFJob < FhlbJob
  include CustomFormattingHelper
  queue_as :high_priority

  MARGIN = 19.05 # in mm

  attr_reader :controller, :member

  def perform(member_id, action_name, filename=nil, params={}, view=nil)
    initialize_controller
    configure_controller(member_id, action_name, params)
    return if job_status.canceled?
    set_controller_instance_vars
    return if job_status.canceled?
    file = StringIOWithFilename.new(render_pdf(view))
    file.content_type = 'application/pdf'
    filename ||= controller.report_download_name
    filename ||= "#{controller.action_name.to_s.gsub('_','-')}-#{fhlb_report_date_numeric(Time.zone.today)}" if controller.action_name
    file.original_filename = "#{filename}.pdf"
    return if job_status.canceled?
    job_status.result = file
    job_status.save!
    file.rewind
    file
  end

  def render_html(view)
    controller.class_eval { layout 'print' }
    response = controller.public_send(controller.action_name.to_sym)
    controller.performed? ? response.first : controller.render_to_string(view || controller.action_name)
  end

  def render_footer_html
    controller.render_to_string('pdf_footer', layout: 'print_footer')
  end

  def configure_controller(member_id, action_name, params)
    controller.request = ActionDispatch::TestRequest.new
    controller.response = ActionDispatch::TestResponse.new
    controller.request.env['warden'] = FhlbMember::WardenProxy.new(job_status.user)
    @member = MembersService.new(controller.request).member(member_id)
    raise 'Member not found!' unless member
    controller.session[controller.class.const_get('SessionKeys::MEMBER_ID')] = member_id
    controller.session[controller.class.const_get('SessionKeys::MEMBER_NAME')] = member[:name]
    controller.try(:skip_deferred_load=, true)
    controller.action_name = action_name
    controller.params = params
  end

  def set_controller_instance_vars
    controller.instance_variable_set(:@member_name, member[:name])
    controller.instance_variable_set(:@member_fhfa, member[:fhfa_number])
    controller.instance_variable_set(:@sta_number, member[:sta_number])
    controller.instance_variable_set(:@inline_styles, true)
    controller.instance_variable_set(:@skip_javascript, true)
    controller.instance_variable_set(:@print_layout, true)
  end

  def render_pdf(view)
    WickedPdf.new.pdf_from_string(render_html(view),
      page_size: 'Letter',
      print_media_type: true,
      disable_external_links: true,
      margin: {
        top: MARGIN,
        left: MARGIN,
        right: MARGIN,
        bottom: MARGIN
      },
      disable_smart_shrinking: false,
      footer: { content: render_footer_html },
      orientation: pdf_orientation
    )
  end

  private
  def initialize_controller # Placeholder for testing: method overwritten in children
  end

  def pdf_orientation
    :portrait
  end
end
