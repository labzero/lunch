class RenderReportPDFJob < ActiveJob::Base
  queue_as :high_priority

  MARGIN = 19.05 # in mm

  def perform(member_id, report_name, params={})
    controller = ReportsController.new
    controller.request = ActionDispatch::TestRequest.new
    controller.response = ActionDispatch::TestResponse.new

    member = MembersService.new(controller.request).member(member_id)
    raise 'Member not found!' unless member

    controller.session['member_id'] = member[:id]
    controller.session['member_name'] = member[:name]
    controller.instance_variable_set(:@inline_styles, true)
    controller.instance_variable_set(:@skip_javascript, true)
    controller.instance_variable_set(:@print_layout, true)
    controller.instance_variable_set(:@member_name, controller.session['member_name'])
    controller.params = params
    controller.class_eval { layout 'print' }
    html = controller.send(report_name.to_sym).first
    unless controller.performed?
      html = controller.render_to_string("reports/#{report_name}")
    end
    controller.class_eval { layout 'print_footer' }
    footer_html = controller.render_to_string('reports/pdf_footer')

    pdf = WickedPdf.new.pdf_from_string(html, page_size: 'Letter', print_media_type: true, disable_external_links: true, margin: {top: MARGIN, left: MARGIN, right: MARGIN, bottom: MARGIN}, disable_smart_shrinking: false, footer: { content: footer_html})
    pdf # Return the PDF to our caller. In the future we will likely want to store the PDF in some container for proper backgrounding
  end
end
