require 'spec_helper'

describe RatesService do
  subject { RatesService.new }
  it { expect(subject).to respond_to(:overnight_vrc) }
  it { expect(subject).to respond_to(:quick_advance_rates) }
  describe "`overnight_vrc` method" do
    let(:rates) {subject.overnight_vrc}
    it "should return an array of rates" do
      expect(rates.length).to be >= 1
      rates.each do |rate|
        expect(rate.first).to be_kind_of(Date)
        expect(rate.last).to be_kind_of(Float)
      end
    end
    it "should return 30 rates by default" do
      expect(rates.length).to eq(30)
    end
    it "should allow the number of rates returned to be overridden" do
      expect(subject.overnight_vrc(5).length).to eq(5)
    end
    it "should return the rates in ascending date order" do
      last_date = nil
      rates.each do |rate|
        if last_date
          expect(rate.first).to be > last_date
        end
        last_date = rate.first
      end
    end 
  end
  describe "`quick_advance_rates` method" do
    let(:member_id) {double(MEMBER_ID)}
    let(:quick_advance_rates) {subject.quick_advance_rates(member_id)}
    it "should return a hash of hashes containing pledged collateral values" do
      expect(quick_advance_rates.length).to be >= 1
      expect(quick_advance_rates[:overnight][:whole_loan]).to be_kind_of(Float)
      expect(quick_advance_rates[:open][:agency]).to be_kind_of(Float)
      expect(quick_advance_rates["1_week"][:aaa]).to be_kind_of(Float)
      expect(quick_advance_rates["2_weeks"][:aa]).to be_kind_of(Float)
    end
  end
end