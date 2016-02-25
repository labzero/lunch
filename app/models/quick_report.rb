class QuickReport < ActiveRecord::Base
  belongs_to :quick_report_set
  has_attached_file :report, preserve_files: false, keep_old_files: false
  scope :reports_named, ->(name) { where(report_name: name) }
  scope :completed, ->() { where.not(report_file_name: nil) }

  validates :report_name, presence: true
  do_not_validate_attachment_file_type :report

  include PaperclipAttachmentAsString
end
