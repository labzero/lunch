require 'rails_helper'

RSpec.describe User, :type => :model do
  it "should be able to be instantiated" do
    expect(User.new).to be_kind_of(User)
  end
end
