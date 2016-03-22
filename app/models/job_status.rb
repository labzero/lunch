class JobStatus < ActiveRecord::Base
  before_save :if => :status_changed? do
    self.finished_at = Time.zone.now if finished_at.blank?
  end
  validates :job_id, presence: true
  enum status: { unstarted: 0, started: 1, completed: 2, canceled: 3, failed: 4 }
  belongs_to :user

  has_attached_file :result, preserve_files: false, keep_old_files: false
  do_not_validate_attachment_file_type :result

  include PaperclipAttachmentAsString

end
