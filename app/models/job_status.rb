class JobStatus < ActiveRecord::Base
  validates :job_id, presence: true
  enum status: { unstarted: 0, started: 1, completed: 2, canceled: 3, failed: 4 }

  has_attached_file :result
  do_not_validate_attachment_file_type :result # TODO write validation for pdf and xlsx

#   TODO should record its :finished_at attr when status becomes "completed"

end
