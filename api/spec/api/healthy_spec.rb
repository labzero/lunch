require 'spec_helper'

describe MAPI::HealthApp do
  describe "health check" do
    it "should return 'OK'" do
      get '/'
      expect(last_response.body).to eq('OK')
    end
  end
end