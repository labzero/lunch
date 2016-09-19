FactoryGirl.define do
  factory :security do
    cusip { SecureRandom.hex }
    description 'some security description'
    custodian_name 'Curious George'
    original_par { rand(10000..999999) }
    payment_amount { rand(10000..999999) }
  end
end