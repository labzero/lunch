class QuickReportSet < ActiveRecord::Base
  has_many :quick_reports, dependent: :destroy
  scope :for_member, ->(member_id) { where(member_id: member_id) }
  scope :for_period, ->(period) { where(period: period) }

  delegate :reports_named, to: :quick_reports

  validates :member_id, presence: true
  validates :period, presence: true, format: /\A\d\d\d\d-(0[1-9]|1[0-2])\z/

  def self.latest
    order('period DESC').first
  end

  def self.latest_with_reports
    joins(:quick_reports).order('period DESC').where.not('quick_reports.report_file_name': nil).first
  end

  def self.current_period
    (Time.zone.now - 1.month).strftime('%Y-%m')
  end

  def has_reports?(*report_names)
    report_names = report_names.flatten
    quick_reports.reports_named(report_names).completed.count == report_names.count
  end

  def missing_reports(*report_names)
    report_names = report_names.flatten.collect(&:to_s)
    report_names - quick_reports.reports_named(report_names).completed.collect(&:report_name)
  end

  def completed?(report_names=member.quick_report_list)
    missing_reports(report_names).empty?
  end

  def member
    @member ||= Member.new(member_id)
  end
end
