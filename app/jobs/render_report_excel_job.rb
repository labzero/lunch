class RenderReportExcelJob < ActiveJob::Base
  queue_as :high_priority

  def perform(member_id, report_name, params={})
    controller = ReportsController.new
    controller.request = ActionDispatch::TestRequest.new
    controller.response = ActionDispatch::TestResponse.new

    member = MembersService.new(controller.request).member(member_id)
    raise 'Member not found!' unless member

    controller.session['member_id'] = member[:id]
    controller.session['member_name'] = member[:name]
    controller.params = params
    controller.send(report_name.to_sym)
    xlsx = controller.render_to_string(template: "reports/#{report_name}", handlers: [:axlsx], formats: [:xlsx])
    xlsx
  end
end
