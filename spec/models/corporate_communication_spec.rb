require 'rails_helper'

describe CorporateCommunication do
  it {should validate_presence_of(:email_id)}
  it {should validate_presence_of(:date_sent)}
  it {should validate_presence_of(:category)}
  it {should validate_presence_of(:title)}
  it {should validate_presence_of(:body)}
  it {should validate_inclusion_of(:category).in_array(CorporateCommunication::VALID_CATEGORIES)}
  it {should validate_uniqueness_of(:email_id)}

end