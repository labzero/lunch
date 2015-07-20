require 'spec_helper'

describe MAPI::ServiceApp do

  before do
    header 'Authorization', "Token token=\"#{ENV['MAPI_SECRET_TOKEN']}\""
  end

  describe 'member interest_rate_resets' do
    describe 'the `interest_rate_resets` method' do
      let(:interest_rate_reset_data) { JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'interest_rate_resets.json')))
      }
      let(:interest_rate_resets) { MAPI::Services::Member::InterestRateResets.interest_rate_resets(subject, MEMBER_ID) }
      let(:max_advances_update_date) { [Date.new(2015,1,31)] }
      let(:max_advances_business_date) { [Date.new(2015,1,30)] }
      let(:advances_prior_business_date) { [Date.new(2015,1,29)] }

      it 'calls the `interest_rate_resets` method when the endpoint is hit' do
        allow(MAPI::Services::Member::InterestRateResets).to receive(:interest_rate_resets).and_return('a response')
        get "/member/#{MEMBER_ID}/interest_rate_resets"
        expect(last_response.status).to eq(200)
      end

      [:test, :production].each do |env|
        describe "in the #{env} environment" do
          if env == :production
            let(:interest_rate_reset_result_set) {double('Oracle Result Set', fetch_hash: nil, fetch: nil)}
            let(:interest_rate_reset_result) {[interest_rate_reset_data[0],interest_rate_reset_data[1], nil]}
            let(:logger) { double('Logger', :error => nil)}

            before do
              allow(MAPI::ServiceApp).to receive(:environment).at_least(1).and_return(:production)
              allow(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(interest_rate_reset_result_set)
              allow(interest_rate_reset_result_set).to receive(:fetch).and_return(max_advances_update_date, max_advances_business_date, advances_prior_business_date)
              allow(interest_rate_reset_result_set).to receive(:fetch_hash).and_return(*interest_rate_reset_result)
            end
            it 'returns nil if `max_advances_update_date` is nil' do
              allow(interest_rate_reset_result_set).to receive(:fetch).and_return(nil)
              expect(interest_rate_resets).to be_nil
            end
            it 'returns nil if `max_advances_business_date` is nil' do
              allow(interest_rate_reset_result_set).to receive(:fetch).and_return(max_advances_update_date, nil)
              expect(interest_rate_resets).to be_nil
            end
            it 'returns nil if `advances_prior_business_date` is nil' do
              allow(interest_rate_reset_result_set).to receive(:fetch).and_return(max_advances_update_date, max_advances_business_date, nil)
              expect(interest_rate_resets).to be_nil
            end
          end
          it "returns an object with a `date_processed` attribute" do
            expect(interest_rate_resets[:date_processed]).to be_kind_of(Date)
          end
          it "returns an object with an `interest_rate_resets` attribute" do
            expect(interest_rate_resets[:interest_rate_resets]).to be_kind_of(Array)
          end
          describe 'the `interest_rate_resets` array' do
            it 'contains objects with an `effective_date`' do
              interest_rate_resets[:interest_rate_resets].each do |reset|
                expect(reset[:effective_date]).to be_kind_of(Date)
              end
            end
            it 'contains objects with an `advance_number`' do
              interest_rate_resets[:interest_rate_resets].each do |reset|
                expect(reset[:advance_number]).to be_kind_of(String)
              end
            end
            it 'contains objects with a `prior_rate`' do
              interest_rate_resets[:interest_rate_resets].each do |reset|
                expect(reset[:prior_rate]).to be_kind_of(Float)
              end
            end
            it 'contains objects with a `new_rate`' do
              interest_rate_resets[:interest_rate_resets].each do |reset|
                expect(reset[:new_rate]).to be_kind_of(Float)
              end
            end
            it 'contains objects with a `next_reset`' do
              interest_rate_resets[:interest_rate_resets].each do |reset|
                expect(reset[:next_reset]).to be_kind_of(Date) if reset[:next_reset]
              end
            end
          end

        end
      end

    end
  end
end
