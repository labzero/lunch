require 'spec_helper'

describe MAPI::ServiceApp do
  describe "historic overnight rates" do
    let(:rates) { get '/rates/historic/overnight'; JSON.parse(last_response.body) }
    it "should return an array of rates" do
      expect(rates.length).to be >= 1
      rates.each do |rate|
        expect(rate.first).to match(/\A\d\d\d\d-(0\d|1[012])-([0-2]\d|3[01])\Z/)
        expect(rate.last).to be_kind_of(Float)
      end
    end
    it "should return 30 rates by default" do
      expect(rates.length).to eq(30)
    end
    it "should allow the number of rates returned to be overridden" do
      get '/rates/historic/overnight', limit: 5
      expect(JSON.parse(last_response.body).length).to eq(5)
    end
    it "should return the rates in ascending date order" do
      last_date = nil
      rates.each do |rate|
        date = Date.parse(rate.first)
        if last_date
          expect(date).to be > last_date
        end
        last_date = date
      end
    end
  end
end