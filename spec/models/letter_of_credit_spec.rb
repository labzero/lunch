require 'rails_helper'

RSpec.describe LetterOfCredit, :type => :model do
  let(:loc) { LetterOfCredit.new }
  it "is initialized with an `issuance_fee` of `#{described_class::DEFAULT_ISSUANCE_FEE}`" do
    expect(loc.issuance_fee).to eq(described_class::DEFAULT_ISSUANCE_FEE)
  end
  it "is initialized with an `maintenance_fee` of `#{described_class::DEFAULT_MAINTENANCE_FEE}`" do
    expect(loc.maintenance_fee).to eq(described_class::DEFAULT_MAINTENANCE_FEE)
  end
  describe 'attributes' do
    let(:attr_value) { double('some value') }
    [:lc_number, :beneficiary_name, :beneficiary_address, :amount, :issue_date, :expiration_date, :issuance_fee, :maintenance_fee].each do |attr|
      it "has an accessible `#{attr}` attribute" do
        loc.send(:"#{attr}=", attr_value)
        expect(loc.send(attr)).to eq(attr_value)
      end
    end
  end
end