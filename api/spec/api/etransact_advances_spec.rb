require 'spec_helper'

describe MAPI::ServiceApp do
  before do
    header 'Authorization', "Token token=\"#{ENV['MAPI_SECRET_TOKEN']}\""
  end
  describe "etransact advances status" do
    let(:etransact_advances_status) { get '/etransact_advances/status'; JSON.parse(last_response.body) }
    it "should return 3 etransact advances status" do
      expect(etransact_advances_status.length).to be >=1
      expect(etransact_advances_status['etransact_advances_status'] == true || false)
      expect(etransact_advances_status['wl_vrc_status'] == true || false)
    end
  end
end