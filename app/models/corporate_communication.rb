class CorporateCommunication < ActiveRecord::Base
  validates :email_id, presence: true, uniqueness: true
  validates :date_sent, presence: true
  validates :category, presence: true
  validates :title, presence: true
  validates :body, presence: true

end