class QuickReportsController < ApplicationController

  def pundit_user
    if current_member_id
      Member.new(current_member_id)
    else
      super
    end
  end

  before_action do
    @quick_report = QuickReport.find(params[:id])
    authorize @quick_report, :download?
  end

  def download
    raise ActiveRecord::RecordNotFound unless @quick_report.report.file?
    send_data @quick_report.report_as_string,
      filename: @quick_report.report.original_filename,
      type: @quick_report.report.content_type,
      disposition: 'attachment'
  end
end
