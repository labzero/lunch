class RenderSecuritiesRequestsPDFJob < FhlbJob
  queue_as :high_priority

  MARGIN = 19.05 # in mm

  ACTION_NAME = 'view_authorized_request'.freeze

  def perform(member_id, params={})
    controller = SecuritiesController.new
    controller.request = ActionDispatch::TestRequest.new
    controller.response = ActionDispatch::TestResponse.new

    return if job_status.canceled?
    member = MembersService.new(controller.request).member(member_id)
    raise 'Member not found!' unless member

    controller.request.env['warden'] = FhlbMember::WardenProxy.new(job_status.user)
    controller.session[SecuritiesController::SessionKeys::MEMBER_ID] = member_id
    controller.session[SecuritiesController::SessionKeys::MEMBER_NAME] = member[:name]
    controller.instance_variable_set(:@inline_styles, true)
    controller.instance_variable_set(:@skip_javascript, true)
    controller.instance_variable_set(:@print_layout, true)
    controller.action_name = ACTION_NAME
    controller.params = params
    controller.class_eval { layout 'print' }
    return if job_status.canceled?
    response = controller.public_send(ACTION_NAME.to_sym)
    if controller.performed?
      html = response.first
    else
      html = controller.render_to_string(ACTION_NAME)
    end
    return if job_status.canceled?
    pdf = WickedPdf.new.pdf_from_string(html, page_size: 'Letter',
                                              print_media_type: true,
                                              disable_external_links: true,
                                              margin: { top: MARGIN,
                                                        left: MARGIN,
                                                        right: MARGIN,
                                                        bottom: MARGIN },
                                              disable_smart_shrinking: false,
                                              footer: { content: "" })
    file = StringIOWithFilename.new(pdf)
    file.content_type = 'application/pdf'
    file.original_filename = "authorized_request_#{params[:request_id]}.pdf"
    return if job_status.canceled?
    job_status.result = file
    job_status.save!
    file.rewind
    file
  end
end