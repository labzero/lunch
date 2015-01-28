require 'rails_helper'

describe CorporateCommunication do
  let(:attributes) { [:email_id, :date_sent, :category, :title, :body] }
  it 'validates the presence of all fields' do
    attributes.each do |attribute|
      message = CorporateCommunication.new("#{attribute}" => nil)
      message.valid?
      expect(message.errors[attribute]).to include("can't be blank")
    end
  end
  it 'validates the uniqueness of `email_id` but not the uniqueness of other attributes' do
    title = 'some title'
    body = 'some body'
    date_sent =  "Thu, 15 Jan 2015 13:31:08 -0800 (PST)".to_datetime
    category = 'some category'
    unique_id = 'unique email'
    duplicate_id = "some duplicate id string"
    CorporateCommunication.create( email_id: duplicate_id, title: title, body: body, date_sent: date_sent, category: category)
    duplicate_message = CorporateCommunication.new( email_id: duplicate_id, title: title, body: body, date_sent: date_sent, category: category)
    duplicate_message.valid?
    expect(duplicate_message.errors[:email_id]).to include("has already been taken")
    unique_message = CorporateCommunication.new( email_id: unique_id, title: title, body: body, date_sent: date_sent, category: category)
    expect(unique_message.valid?).to be(true)
  end
end