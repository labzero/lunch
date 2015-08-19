FactoryGirl.define do
  factory :user do
    username 'local'
    ldap_domain 'intranet'
    given_name 'Foo'
    surname 'Bar'
    email 'foo@example.com'
    email_confirmation 'foo@example.com'
    terms_accepted_at nil
  end
end