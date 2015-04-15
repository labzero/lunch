class JobStatus < ActiveRecord::Base
  validates :user_id, presence: true
  enum status: { unstarted: 0, started: 1, completed: 2, failed: 3 }

  has_attached_file :file
  
end
