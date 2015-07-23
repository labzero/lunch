require 'spec_helper'

describe MAPI::ServiceApp do

  before do
    header 'Authorization', "Token token=\"#{ENV['MAPI_SECRET_TOKEN']}\""
  end

  describe 'member dividend_statement' do
    describe 'the `dividend_statement` method' do
      let(:date) {  Date.new(2015,1,11) }
      let(:div_id) { double('div id') }
      let(:sta_account_number) { double('an STA account number') }
      let(:dividend_summary_data) { JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'dividend_summary_data.json'))) }
      let(:dividend_details) { JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'dividend_details.json'))) }
      let(:dividend_statement) { MAPI::Services::Member::DividendStatement.dividend_statement(subject, MEMBER_ID, date) }

      it 'calls the `dividend_statement` method when the endpoint is hit' do
        allow(MAPI::Services::Member::DividendStatement).to receive(:dividend_statement).and_return('a response')
        get "/member/#{MEMBER_ID}/dividend_statement/#{date}"
        expect(last_response.status).to eq(200)
      end

      [:test, :production].each do |env|
        describe "in the #{env} environment" do
          if env == :production
            let(:div_id_result_set) {double('Oracle Result Set', fetch: nil)}
            let(:div_id_result) {[div_id]}
            let(:sta_account_number_result_set) {double('Oracle Result Set', fetch: nil)}
            let(:sta_account_number_result) {[sta_account_number]}
            let(:dividend_summary_data_result_set) {double('Oracle Result Set', fetch_hash: nil)}
            let(:dividend_summary_data_result) {dividend_summary_data}
            let(:dividend_details_result_set) {double('Oracle Result Set', fetch_hash: nil)}
            let(:dividend_details_result) {[dividend_details[0],dividend_details[1], dividend_details[2], nil]}

            before do
              allow(MAPI::ServiceApp).to receive(:environment).at_least(1).and_return(:production)
              allow(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(div_id_result_set, sta_account_number_result_set, dividend_summary_data_result_set, dividend_details_result_set)
              allow(div_id_result_set).to receive(:fetch).and_return(div_id_result)
              allow(sta_account_number_result_set).to receive(:fetch).and_return(sta_account_number_result)
              allow(dividend_summary_data_result_set).to receive(:fetch_hash).and_return(dividend_summary_data_result)
              allow(dividend_details_result_set).to receive(:fetch_hash).and_return(*dividend_details_result)
            end
            it 'returns nil if `div_id` is nil' do
              allow(div_id_result_set).to receive(:fetch).and_return(nil)
              expect(dividend_statement).to be_nil
            end
          end
          it "returns an object with a `transaction_date` attribute" do
            expect(dividend_statement[:transaction_date]).to be_kind_of(Date)
          end
          it "returns an object with a `shares_dividend` attribute" do
            expect(dividend_statement[:shares_dividend]).to be_kind_of(Integer)
          end
          it "returns an object with a `sta_account_number` attribute" do
            expect(dividend_statement[:sta_account_number]).to be_kind_of(String)
          end
          %w(annualized_rate rate average_shares_outstanding shares_par_value cash_dividend total_dividend).each do |attr|
            it "returns an object with a `#{attr}` attribute" do
              expect(dividend_statement[attr.to_sym]).to be_kind_of(Float)
            end
          end
          it "returns an object with a `details` attribute" do
            expect(dividend_statement[:details]).to be_kind_of(Array)
          end
          describe 'the `details` array' do
            it 'contains objects with a `certificate_sequence`' do
              dividend_statement[:details].each do |dividend|
                expect(dividend[:certificate_sequence]).to be_kind_of(String)
              end
            end
            %w(issue_date start_date end_date).each do |attr|
              it "contains objects with an `#{attr}`" do
                dividend_statement[:details].each do |dividend|
                  expect(dividend[attr.to_sym]).to be_kind_of(Date)
                end
              end
            end
            %w(shares_outstanding days_outstanding).each do |attr|
              it "contains objects with an `#{attr}`" do
                dividend_statement[:details].each do |dividend|
                  expect(dividend[attr.to_sym]).to be_kind_of(Integer)
                end
              end
            end
            %w(average_shares_outstanding dividend).each do |attr|
              it "contains objects with an `#{attr}`" do
                dividend_statement[:details].each do |dividend|
                  expect(dividend[attr.to_sym]).to be_kind_of(Float)
                end
              end
            end
          end
        end
      end
    end
  end
end
