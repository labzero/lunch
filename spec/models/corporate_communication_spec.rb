require 'rails_helper'

describe CorporateCommunication do
  [:email_id, :date_sent, :category, :title, :body].each do |attr|
    it "should validate the presence of `#{attr}`" do
      expect(subject).to validate_presence_of attr
    end
  end
  it 'should validate that the `category` attribute is one of the valid categories' do
    expect(subject).to validate_inclusion_of(:category).in_array(CorporateCommunication::VALID_CATEGORIES)
  end
  it 'should validate the uniqueness of `email_id`' do
    expect(subject).to validate_uniqueness_of(:email_id)
  end

end