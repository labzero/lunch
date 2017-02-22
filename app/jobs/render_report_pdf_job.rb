class RenderReportPDFJob < RenderPDFJob
  def initialize_controller
    @controller = ReportsController.new
  end

  def pdf_orientation
    controller.action_name.to_s == 'advances_detail' ? :landscape : :portrait
  end
end
