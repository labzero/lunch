FactoryGirl.define do
  factory :corporate_communication do
    sequence(:email_id) { |n| "email_id#{n}" }
    category CorporateCommunication::VALID_CATEGORIES.sample
    title 'some title'
    body 'some body'
    date_sent "Mon, 27 Jan 2014 13:31:08 -0800 (PST)".to_datetime
  end
end