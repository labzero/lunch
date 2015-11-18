require 'spec_helper'
require 'date'

describe MAPI::ServiceApp do
  subject { MAPI::Services::Member }
  before  { header 'Authorization', "Token token=\"#{ENV['MAPI_SECRET_TOKEN']}\"" }

  describe 'capital_stock_trial_balance' do
    let(:result){ { "certificates" => [], "number_of_certificates" => 0, "number_of_shares" => 0 }}
    let(:id) { 750 }
    let(:date) { '2015-10-10' }
    let(:capital_stock_trial_balance) { get "/member/#{id}/capital_stock_trial_balance/#{date}"; JSON.parse(last_response.body) }
    it 'should call CapitalStockTrialBalance.capital_stock_trial_balance with appropriate types of arguments' do
      allow(MAPI::Services::Member::CapitalStockTrialBalance).to receive(:capital_stock_trial_balance).with(anything,kind_of(Numeric),kind_of(Date)).and_return(result)
      expect(capital_stock_trial_balance).to eq(result)
    end
  end
end