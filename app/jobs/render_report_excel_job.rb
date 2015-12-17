class RenderReportExcelJob < FhlbJob
  queue_as :high_priority

  def perform(member_id, report_name, filename, params={})
    controller = ReportsController.new
    controller.request = ActionDispatch::TestRequest.new
    controller.response = ActionDispatch::TestResponse.new
    return if job_status.canceled?
    member = MembersService.new(controller.request).member(member_id)
    raise 'Member not found!' unless member
    controller.session['member_id'] = member_id
    controller.session['member_name'] = member[:name]
    controller.params = params
    return if job_status.canceled?
    controller.send(report_name.to_sym)
    return if job_status.canceled?
    xlsx = controller.render_to_string(template: "reports/#{report_name}", handlers: [:axlsx], formats: [:xlsx])
    file = StringIOWithFilename.new(xlsx)
    file.content_type = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    file.original_filename = "#{filename}.xlsx"
    return if job_status.canceled?
    job_status.result = file
    job_status.save!
    file
  end
end
