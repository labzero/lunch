include ActionDispatch::TestProcess

FactoryGirl.define do
  factory :attachment do
    data { fixture_file_upload(Rails.root.join('spec', 'fixtures', 'corp_com_fixture.txt')) }
  end
end