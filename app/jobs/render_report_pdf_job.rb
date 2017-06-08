class RenderReportPDFJob < RenderPDFJob
  def initialize_controller
    @controller = ReportsController.new
  end
end
