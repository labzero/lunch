class QuickReportPolicy < ApplicationPolicy

  def download?
    record.quick_report_set.member_id == user.member_id
  end

end