require 'spec_helper'

describe RatesService do
  subject { RatesService.new }
  it { expect(subject).to respond_to(:overnight_vrc) }
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
end