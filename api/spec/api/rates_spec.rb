require 'spec_helper'

describe MAPI::ServiceApp do
  before do
    header 'Authorization', "Token token=\"#{ENV['MAPI_SECRET_TOKEN']}\""
  end
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

  describe "current rates" do

    MAPI::Services::Rates::LOAN_TYPES.each do |loan|
      MAPI::Services::Rates::LOAN_TERMS.each do |term|
        it "should return a #{loan}:#{term} rate" do
          get "/rates/#{loan}/#{term}"
          rate = JSON.parse(last_response.body)
          expect(rate['rate']).to be_kind_of(Float)
          expect(rate['updated_at']).to match(/\A\d\d\d\d-(0\d|1[012])-([0-2]\d|3[01]) ([01]\d|2[0-3]):[0-5]\d:[0-5]\d [+-](0\d|1[012])[0-5][0-5]\Z/)
          date = DateTime.parse(rate['updated_at'])
          expect(date).to be <= DateTime.now
        end
      end
    end
  end

  describe "rate summary" do
    let(:rate_summary) { get '/rates/summary'; JSON.parse(last_response.body).with_indifferent_access }
    let(:loan_terms) { [:overnight, :open, :'1week', :'2week', :'3week', :'1month', :'2month', :'3month', :'6month', :'1year', :'2year', :'3year'] }
    let (:loan_types) { [:whole, :agency, :aaa, :aa] }
    it "should return rates for default loan_types at default loan_terms" do
      loan_terms.each do |loan_type|
        loan_types.each do |loan_term|
          expect(rate_summary[loan_term][loan_type][:rate]).to be_kind_of(String)
        end
      end
    end
    it "should return other data relevant to each loan_term" do
      loan_types.each do |loan_type|
        loan_terms.each do |loan_term|
          expect(rate_summary[loan_type][loan_term][:label]).to be_kind_of(String)
          expect(rate_summary[loan_type][loan_term][:payment_on]).to be_kind_of(String)
          expect(rate_summary[loan_type][loan_term][:interest_day_count]).to be_kind_of(String)
          expect(rate_summary[loan_type][loan_term][:maturity_date]).to be_kind_of(String)
        end
      end
    end
    it "should return a timestamp" do
      expect(rate_summary[:timestamp]).to be_kind_of(String)
    end
  end
end