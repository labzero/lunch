require 'spec_helper'

describe MAPI::ServiceApp do

  before do
    header 'Authorization', "Token token=\"#{ENV['MAPI_SECRET_TOKEN']}\""
  end

  describe 'member capital_stock_and_leverage' do
    let(:capital_stock_and_leverage) {MAPI::Services::Member::CapitalStockAndLeverage.capital_stock_and_leverage(subject, MEMBER_ID)}

    it 'calls the `capital_stock_and_leverage` method when the endpoint is hit' do
      allow(MAPI::Services::Member::CapitalStockAndLeverage).to receive(:capital_stock_and_leverage).and_return('a response')
      get "/member/#{MEMBER_ID}/capital_stock_and_leverage"
      expect(last_response.status).to eq(200)
    end

    describe 'when the `capital_stock_and_leverage` method returns nil' do
      before { allow(MAPI::Services::Member::CapitalStockAndLeverage).to receive(:capital_stock_and_leverage).and_return(nil) }
      it 'returns a 503' do
        get "/member/#{MEMBER_ID}/capital_stock_and_leverage"
        expect(last_response.status).to eq(503)
      end
      it 'logs an error' do
        expect_any_instance_of(Logger).to receive(:error)
        get "/member/#{MEMBER_ID}/capital_stock_and_leverage"
      end
    end

    %i(stock_owned minimum_requirement excess_stock surplus_stock activity_based_requirement remaining_stock remaining_leverage).each do |key|
      it "returns a hash an integer value for the #{key} key" do
        expect(capital_stock_and_leverage[key]).to be_kind_of(Integer)
      end
    end

    describe 'in the production environment' do
      let(:cap_stock_member_details_result_set) {double('Oracle Result Set', fetch_hash: nil)}
      let(:cap_stock_member_details) {[
        {
          TOTAL_CAPITAL_STOCK: rand(90000000),
          ADVANCES_OUTS: rand(90000000),
          TOT_MPF: rand(90000000),
          MORTGAGE_RELATED_ASSETS: rand(90000000)
         }
      ]}
      let(:cap_stock_requirements_result_set) {double('Oracle Result Set', fetch_hash: nil)}
      let(:cap_stock_requirements) {[
        {
          ADVANCES_PCT: rand,
          MPF_PCT: rand,
          SURPLUS_PCT: 1 + rand
        }
      ]}

      before do
        allow(MAPI::ServiceApp).to receive(:environment).at_least(1).and_return(:production)
        allow(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(cap_stock_member_details_result_set, cap_stock_requirements_result_set)
        allow(cap_stock_member_details_result_set).to receive(:fetch_hash).and_return(*cap_stock_member_details)
        allow(cap_stock_requirements_result_set).to receive(:fetch_hash).and_return(*cap_stock_requirements)
      end

      %i(stock_owned minimum_requirement excess_stock surplus_stock activity_based_requirement remaining_stock remaining_leverage).each do |key|
        it "returns a hash with an integer value for the #{key} key" do
          expect(capital_stock_and_leverage[key]).to be_kind_of(Integer)
        end
        it "returns a hash with a nil value for #{key} when the `cap_stock_member_details` SQL does not return anything" do
          allow(cap_stock_member_details_result_set).to receive(:fetch_hash).and_return(nil)
          expect(capital_stock_and_leverage[key]).to be_nil
        end
      end
      it 'returns a `stock_owned` value that is equal to the TOTAL_CAPITAL_STOCK value' do
        expect(capital_stock_and_leverage[:stock_owned]).to eq(cap_stock_member_details.first[:TOTAL_CAPITAL_STOCK])
      end
      describe 'values calculated with the `minimum_stock_requirement`' do
        let(:adv_and_mpf_stock_requirement) { (((cap_stock_member_details.first[:TOT_MPF] * cap_stock_requirements.first[:MPF_PCT]) + (cap_stock_member_details.first[:ADVANCES_OUTS] * cap_stock_requirements.first[:ADVANCES_PCT])) / 100).ceil * 100 }
        describe 'the `activity_based_requirement` value' do
          it 'is equal to the `adv_and_mpf_stock_requirement`' do
            expect(capital_stock_and_leverage[:activity_based_requirement]).to eq(adv_and_mpf_stock_requirement)
          end
        end
        describe 'the `remaining_stock` value' do
          it 'is equal to the `total_capital_stock` minus the `activity_based_requirement`' do
            expect(capital_stock_and_leverage[:remaining_stock]).to eq( cap_stock_member_details.first[:TOTAL_CAPITAL_STOCK] - adv_and_mpf_stock_requirement)
          end
        end
        describe 'the `remaining_leverage` value' do
          describe 'when `total_capital_stock` is greater than `minimum_stock_requirement`' do
            before { cap_stock_member_details.first[:TOTAL_CAPITAL_STOCK] = adv_and_mpf_stock_requirement + 500 }
            it 'equals `total_capital_stock` minus `adv_and_mpf_stock_requirement`, divided by the `advances_percentage` and rounded down to the nearest integer' do
              expect(capital_stock_and_leverage[:remaining_leverage]).to eq(((cap_stock_member_details.first[:TOTAL_CAPITAL_STOCK] - adv_and_mpf_stock_requirement)/cap_stock_requirements.first[:ADVANCES_PCT]).floor)
            end
          end
          describe 'when `total_capital_stock` is less than `minimum_stock_requirement`' do
            before { cap_stock_member_details.first[:TOTAL_CAPITAL_STOCK] = adv_and_mpf_stock_requirement - 500 }
            it 'equals 0' do
              expect(capital_stock_and_leverage[:remaining_leverage]).to eq(0)
            end
          end
          describe 'when `advances_percentage` is 0' do
            before { cap_stock_requirements.first[:ADVANCES_PCT] = 0 }
            it 'equals 0' do
              expect(capital_stock_and_leverage[:remaining_leverage]).to eq(0)
            end
          end
          describe 'when `advances_percentage` is nil' do
            before { cap_stock_requirements.first[:ADVANCES_PCT] = nil }
            it 'equals 0' do
              expect(capital_stock_and_leverage[:remaining_leverage]).to eq(0)
            end
          end
        end
        describe 'the `minimum_requirement` value' do
          let(:mav_stock_requirement) {(cap_stock_member_details.first[:MORTGAGE_RELATED_ASSETS] / 100).ceil * 100}
          it 'is equal to the adv_and_mpf_stock_requirement when adv_and_mpf_stock_requirement is greater than the mav_stock_requirement' do
            cap_stock_member_details.first[:MORTGAGE_RELATED_ASSETS] = adv_and_mpf_stock_requirement - 500
            expect(capital_stock_and_leverage[:minimum_requirement]).to eq(adv_and_mpf_stock_requirement)
          end
          it 'is equal to the mav_stock_requirement when adv_and_mpf_stock_requirement is less than the mav_stock_requirement' do
            cap_stock_requirements.first[:MPF_PCT] = 0
            cap_stock_requirements.first[:ADVANCES_PCT] = 0
            expect(capital_stock_and_leverage[:minimum_requirement]).to eq(mav_stock_requirement)
          end
        end
        describe 'set to equal `adv_and_mpf_stock_requirement`' do
          let(:minimum_stock_requirement) { adv_and_mpf_stock_requirement }
          before { cap_stock_member_details.first[:MORTGAGE_RELATED_ASSETS] = adv_and_mpf_stock_requirement - 500 } # ensure `adv_and_mpf_stock_requirement` is used as `minimum_stock_requirement`
          describe 'the `excess_stock` value' do
            it 'is equal to the `total_capital_stock` minus the `minimum_stock_requirement`' do
              expect(capital_stock_and_leverage[:excess_stock]).to eq(cap_stock_member_details.first[:TOTAL_CAPITAL_STOCK] - minimum_stock_requirement)
            end
          end
          describe 'the `surplus_stock` value' do
            it 'is equal to the `total_capital_stock` minus the `minimum_stock_requirement` times the cap_stock_requirements[:SURPLUS_PCT] and rounded up to the nearest 100' do
              expect(capital_stock_and_leverage[:surplus_stock]).to eq( ((cap_stock_member_details.first[:TOTAL_CAPITAL_STOCK]  - (minimum_stock_requirement * cap_stock_requirements.first[:SURPLUS_PCT])) / 100).ceil * 100 )
            end
          end
        end
      end
    end
  end
end