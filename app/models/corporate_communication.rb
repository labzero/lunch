class CorporateCommunication < ActiveRecord::Base
  VALID_CATEGORIES = %w(misc investor_relations products credit technical_updates community)

  validates_presence_of :email_id, :date_sent, :category, :title, :body
  validates_inclusion_of :category, :in => VALID_CATEGORIES
  validates_uniqueness_of :email_id

end