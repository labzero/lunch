class CorporateCommunication < ActiveRecord::Base
  VALID_CATEGORIES = %w(investor_relations accounting products collateral community_program community_works educational)

  has_many :attachments, -> { where(category: :email_attachment) }, as: :owner
  has_many :images, -> { where(category: :email_image) }, as: :owner, class_name: :Attachment

  validates_presence_of :email_id, :date_sent, :category, :title, :body
  validates_inclusion_of :category, :in => VALID_CATEGORIES
  validates_uniqueness_of :email_id

end