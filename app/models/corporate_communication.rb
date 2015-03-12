class CorporateCommunication < ActiveRecord::Base
  VALID_CATEGORIES = %w(investor_relations accounting products collateral community_program community_works educational)

  validates_presence_of :email_id, :date_sent, :category, :title, :body
  validates_inclusion_of :category, :in => VALID_CATEGORIES
  validates_uniqueness_of :email_id

end