FactoryGirl.define do
  factory :securities_release_request do
    transaction_code { [:standard, :repo].sample }
    settlement_type { [:free,  :payment].sample }
    trade_date Faker::Date.between(30.days.ago, 15.days.ago)
    settlement_date Faker::Date.between(14.days.ago, 2.days.ago)
    delivery_type :dtc
    clearing_agent_participant_number 'some participant number'
    dtc_credit_account_number 'some account number'
    securities { [FactoryGirl.build(:security)] }
  end
end