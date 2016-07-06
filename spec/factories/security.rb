FactoryGirl.define do
  factory :security do
    cusip { SecureRandom.hex }
    description 'some security description'
    original_par { rand(10000..999999) }
    payment_amount nil
  end
end