class Attachment < ActiveRecord::Base
  belongs_to :owner, polymorphic: true
  has_attached_file :data, preserve_files: false, keep_old_files: false, hash_digest: :SHA2

  validates :owner_id, presence: true
  validates :owner_type, presence: true
  do_not_validate_attachment_file_type :data

  include PaperclipAttachmentAsString
end
