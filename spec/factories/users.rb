FactoryGirl.define do
  factory :user do
    username "local"
    given_name 'Foo'
    surname 'Bar'
    email 'foo@example.com'
    email_confirmation 'foo@example.com'
  end
end