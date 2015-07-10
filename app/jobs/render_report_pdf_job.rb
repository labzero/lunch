class RenderReportPDFJob < FhlbJob
  queue_as :high_priority

  MARGIN = 19.05 # in mm

  # TODO create base class, inherit, super perform_later

  def perform(member_id, report_name, filename, params={})
    controller = ReportsController.new
    controller.request = ActionDispatch::TestRequest.new
    controller.response = ActionDispatch::TestResponse.new

    return if job_status.canceled?
    member = MembersService.new(controller.request).member(member_id)
    raise 'Member not found!' unless member

    controller.session['member_id'] = member_id
    controller.session['member_name'] = member[:name]
    controller.instance_variable_set(:@inline_styles, true)
    controller.instance_variable_set(:@skip_javascript, true)
    controller.instance_variable_set(:@print_layout, true)
    controller.instance_variable_set(:@member_name, controller.session['member_name'])
    controller.params = params
    controller.class_eval { layout 'print' }
    return if job_status.canceled?
    response = controller.send(report_name.to_sym)
    if controller.performed?
      html = response.first
    else
      html = controller.render_to_string("reports/#{report_name}")
    end
    controller.class_eval { layout 'print_footer' }
    return if job_status.canceled?
    footer_html = controller.render_to_string('reports/pdf_footer')
    return if job_status.canceled?
    pdf = WickedPdf.new.pdf_from_string(html, page_size: 'Letter', print_media_type: true, disable_external_links: true, margin: {top: MARGIN, left: MARGIN, right: MARGIN, bottom: MARGIN}, disable_smart_shrinking: false, footer: { content: footer_html})
    file = StringIOWithFilename.new(pdf)
    file.content_type = 'application/pdf'
    file.original_filename = "#{filename}.pdf"
    return if job_status.canceled?
    job_status.result = file
    job_status.status = :completed
    job_status.save!
    file
  end
end
