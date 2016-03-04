class QuickReportPolicy < ApplicationPolicy

  def download?
    record.quick_report_set.member_id.to_s == user.member_id.to_s
  end

end