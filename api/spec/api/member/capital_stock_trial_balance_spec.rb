require 'spec_helper'

describe MAPI::ServiceApp do

  subject { MAPI::Services::Member::CapitalStockTrialBalance }

  before do
    header 'Authorization', "Token token=\"#{ENV['MAPI_SECRET_TOKEN']}\""
  end

  describe 'CapitalStockTrialBalance' do
    [:test, :development, :production].each do |environment|
      describe '' do
        let(:app) { double('app', logger: logger, settings: settings) }
        let(:business_date) { double('business_date') }
        let(:business_date_sql) { double('business_date_sql') }
        let(:call_method){ subject.capital_stock_trial_balance(app, fhlb_id, date) }
        let(:capital_stock_trial_balance) do
          {
              "fhlb_id" => 8976,
              "number_of_shares" => 40035,
              "number_of_certificates" => 2,
              "certificates" => certificates
          }
        end
        let(:certificate1) do
          {
              certificate_sequence: 50173,
              class: "B",
              issue_date: "02-NOV-2009",
              shares_outstanding: 31906,
              transaction_type: "Repurchase"
          }.with_indifferent_access
        end
        let(:certificate2) do
          {
              certificate_sequence: 51186,
              class: "B",
              issue_date: "26-APR-2013",
              shares_outstanding: 8129,
              transaction_type: "Repurchase"
          }.with_indifferent_access
        end
        let(:certificates) { [certificate1, certificate2] }
        let(:certificates_sql) { double('certificates_sql') }
        let(:closing_balance) { [{"fhlb_id" => 8976, "number_of_shares" => 40035, "number_of_certificates" => 2}] }
        let(:closing_balance_sql) { double('closing_balance_sql') }
        let(:date) { double('date') }
        let(:fhlb_id) { double('fhlb_id') }
        let(:logger) { double('logger') }
        let(:settings) { double('settings', environment: environment) }

        before do
          allow(subject).to receive(:business_date_sql).with(date).and_return(business_date_sql)
          allow(subject).to receive(:closing_balance_sql).and_return(closing_balance_sql)
          allow(subject).to receive(:certificates_sql).and_return(certificates_sql)
          allow(subject).to receive(:fetch_hashes).with(logger, business_date_sql).and_return([{"business_date" => business_date}])
          allow(subject).to receive(:fetch_hashes).with(logger, closing_balance_sql).and_return(closing_balance)
          allow(subject).to receive(:fetch_hashes).with(logger, certificates_sql).and_return(certificates)
        end

        it 'should return a valid result' do
          expect(call_method).to eq(capital_stock_trial_balance)
        end

        it 'should return expected advances detail hash where value could not be nil' do
          call_method['certificates'].each do |row|
            expect(row["certificate_sequence"]).to be_kind_of(Numeric)
            expect(row["class"]).to be_kind_of(String)
            expect(row["issue_date"]).to be_kind_of(String)
            expect(row["shares_outstanding"]).to be_kind_of(Numeric)
            expect(row["transaction_type"]).to be_kind_of(String)
          end
        end
      end
    end
  end
end
