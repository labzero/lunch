require 'spec_helper'

describe MAPI::ServiceApp do
  subject { MAPI::Services::Member::CapitalStockTrialBalance }

  describe 'CapitalStockTrialBalance' do
    [:test, :development, :production].each do |environment|
      describe '' do
        let(:app) { double('app', logger: logger, settings: settings) }
        let(:business_date_sql)  { double('business_date_sql') }
        let(:business_date_str)  { double('business_date_str') }
        let(:business_date)      { double('business_date') }
        let(:call_method)        { subject.capital_stock_trial_balance(app, fhlb_id, date) }
        let(:capital_stock_trial_balance) do
          {
              "fhlb_id" => 8976,
              "number_of_shares" => 40040,
              "number_of_certificates" => 3,
              "certificates" => certificates
          }
        end
        let(:certificate1) do
          {
              certificate_sequence: "50173",
              class: "B",
              issue_date: "02-NOV-2009",
              shares_outstanding: 31906,
              transaction_type: "Repurchase"
          }.with_indifferent_access
        end
        let(:certificate2) do
          {
              certificate_sequence: "51186",
              class: "B",
              issue_date: "26-APR-2013",
              shares_outstanding: 8129,
              transaction_type: "Repurchase"
          }.with_indifferent_access
        end
        let(:certificate3) do
          {
              certificate_sequence: "00225",
              class: "B",
              issue_date: "26-MAR-1984",
              shares_outstanding: 5,
              transaction_type: "undefined"
          }.with_indifferent_access
        end
        let(:certificates) { [certificate1, certificate2, certificate3] }
        let(:certificates_sql) { double('certificates_sql') }
        let(:closing_balance) { [{"fhlb_id" => 8976, "number_of_shares" => 40040, "number_of_certificates" => 3}] }
        let(:closing_balance_sql) { double('closing_balance_sql') }
        let(:date) { double('date') }
        let(:fhlb_id) { double('fhlb_id') }
        let(:logger) { double('logger') }
        let(:settings) { double('settings', environment: environment) }

        before do
          allow(business_date_str).to receive(:to_s).and_return(business_date_str)
          allow(Date).to    receive(:parse).with(business_date_str).and_return(business_date)
          allow(subject).to receive(:business_date_sql).with(date).and_return(business_date_sql)
          allow(subject).to receive(:closing_balance_sql).and_return(closing_balance_sql)
          allow(subject).to receive(:certificates_sql).and_return(certificates_sql)
          allow(subject).to receive(:fetch_hashes).with(logger, business_date_sql, {}, true).and_return([{"business_date" => business_date_str}])
          allow(subject).to receive(:fetch_hashes).with(logger, closing_balance_sql, {}, true).and_return(closing_balance)
          allow(subject).to receive(:fetch_hashes).with(logger, certificates_sql, {}, true).and_return(certificates)
        end

        it 'should return a valid result' do
          expect(call_method).to eq(capital_stock_trial_balance)
        end
        it 'should return expected advances detail hash where value could not be nil' do
          call_method['certificates'].each do |row|
            expect(row["certificate_sequence"]).to be_kind_of(String)
            expect(row["class"]).to be_kind_of(String)
            expect(row["issue_date"]).to be_kind_of(String)
            expect(row["shares_outstanding"]).to be_kind_of(Numeric)
            expect(row["transaction_type"]).to be_kind_of(String)
          end
        end
        it 'should return an empty hash if the `closing_balance` SQL query returns no results' do
          allow(subject).to receive(:fetch_hashes).with(logger, closing_balance_sql, {}, true).and_return([])
          allow(subject).to receive(:fake).with('capital_stock_trial_balance_certificates').and_call_original
          allow(subject).to receive(:fake).with('capital_stock_trial_balance_closing_balance').and_return([])
          expect(call_method).to eq({})
        end
        it 'should return an empty hash if the `certificates` SQL query returns no results' do
          allow(subject).to receive(:fetch_hashes).with(logger, certificates_sql, {}, true).and_return([])
          allow(subject).to receive(:fake).with('capital_stock_trial_balance_certificates').and_return([])
          allow(subject).to receive(:fake).with('capital_stock_trial_balance_closing_balance').and_call_original
          expect(call_method).to eq({})
        end
      end
    end

    describe '`business_date_sql` class method' do
      let(:date) { instance_double(Date) }
      let(:call_method) { subject.business_date_sql(date) }

      it 'returns SQL that selects portfolios.cdb_utility.prior_business_day from dual' do
        expect(call_method).to match(/\A\s+SELECT\s+portfolios.cdb_utility.prior_business_day\(.*\)\s+AS\s+business_date\s+FROM\s+dual\s*\z/mi)
      end
      it 'quotes the date and adds 1 before passing to `prior_business_day`' do
        quoted_date = SecureRandom.hex
        allow(subject).to receive(:quote).with(date).and_return(quoted_date)
        expect(call_method).to match(/\s+portfolios.cdb_utility.prior_business_day\(\s*#{quoted_date}\s+\+\s+1\s*\)/mi)
      end
    end

    describe '`closing_balance_sql` class method' do
      let(:fhlb_id) { instance_double(Numeric) }
      let(:date) { instance_double(Date) }
      let(:quoted_date) { SecureRandom.hex }
      let(:quoted_fhlb_id) { SecureRandom.hex }
      let(:call_method) { subject.closing_balance_sql(fhlb_id, date) }

      before do
        allow(subject).to receive(:quote).and_call_original
        allow(subject).to receive(:quote).with(fhlb_id).and_return(quoted_fhlb_id)
        allow(subject).to receive(:quote).with(date).and_return(quoted_date)
      end

      it 'selects the `fhlb_id` from `capstock.capstock_shareholding`' do
        expect(call_method).to match(/\A\s*SELECT\s+(\S+\s+(AS\s+\S+,\s+)?)*fhlb_id((,\s+(\S+\s+(AS\s+\S+)?)*)|\s+)FROM\s+capstock.capstock_shareholding\s/mi)
      end
      it 'selects the sum of `no_share_holding` from `capstock.capstock_shareholding` as `number_of_shares`' do
        expect(call_method).to match(/\A\s*SELECT\s+(\S+\s+(AS\s+\S+,\s+)?)*fhlb_id((,\s+(\S+\s+(AS\s+\S+)?)*)|\s+)FROM\s+capstock.capstock_shareholding\s/mi)
      end
      it 'selects the count of rows as `number_of_certificates`' do
        expect(call_method).to match(/\A\s*SELECT\s+(\S+\s+(AS\s+\S+,\s+)?)*count\(\*\)\s+number_of_certificates((,\s+(\S+\s+(AS\s+\S+)?)*)|\s+)FROM\s+capstock.capstock_shareholding\s/mi)
      end
      it 'filters based on the quouted `fhlb_id`' do
        expect(call_method).to match(/\sWHERE\s+fhlb_id\s*=\s*#{quoted_fhlb_id}\s+/mi)
      end
      it 'filters based on the `sold_date` being missing or greater than the quouted `date`' do
        expect(call_method).to match(/\sWHERE(\s+.+\s+AND)*\s+\(\s*sold_date\s+is\s+null\s+or\s+sold_date\s*>\s*#{quoted_date}\s*\)\s/mi)
      end
      it 'filters based on the `purchase_date` being less than the quouted `date`' do
        expect(call_method).to match(/\sWHERE(\s+.+\s+AND)*\s+purchase_date\s*<=\s*#{quoted_date}\s/mi)
      end
      it 'filters based on the `no_share_holding` being greater than zero' do
        expect(call_method).to match(/\sWHERE(\s+.+\s+AND)*\s+no_share_holding\s*>\s*0\s/mi)
      end
      it 'groups rows based on `fhlb_id`' do
        expect(call_method).to match(/\sWHERE(\s+.+\s+AND)*(\s+.+)?\s+GROUP\s+BY\s+fhlb_id\s*\z/mi)
      end
    end

    describe '`certificates_sql` class method' do
      let(:fhlb_id) { instance_double(Numeric) }
      let(:date) { instance_double(Date) }
      let(:quoted_date) { SecureRandom.hex }
      let(:quoted_fhlb_id) { SecureRandom.hex }
      let(:call_method) { subject.certificates_sql(fhlb_id, date) }

      before do
        allow(subject).to receive(:quote).and_call_original
        allow(subject).to receive(:quote).with(fhlb_id).and_return(quoted_fhlb_id)
        allow(subject).to receive(:quote).with(date).and_return(quoted_date)
      end

      it 'selects the `cert_id` as `certificate_sequence` from `capstock.capstock_trial_balance_web_v`' do
        expect(call_method).to match(/\A\s*SELECT\s+(\S+\s+(AS\s+\S+,\s+)?)*cert_id\s+AS\s+certificate_sequence((,\s+(\S+\s+(AS\s+\S+)?)*)|\s+)FROM\s+capstock.capstock_trial_balance_web_v\s/mi)
      end
      it 'selects the `class` from `capstock.capstock_trial_balance_web_v`' do
        expect(call_method).to match(/\A\s*SELECT\s+(\S+\s+(AS\s+\S+,\s+)?)*class((,\s+(\S+\s+(AS\s+\S+)?)*)|\s+)FROM\s+capstock.capstock_trial_balance_web_v\s/mi)
      end
      it 'selects the `issue_date` from `capstock.capstock_trial_balance_web_v`' do
        expect(call_method).to match(/\A\s*SELECT\s+(\S+\s+(AS\s+\S+,\s+)?)*issue_date((,\s+(\S+\s+(AS\s+\S+)?)*)|\s+)FROM\s+capstock.capstock_trial_balance_web_v\s/mi)
      end
      it 'selects the `no_share_holding` as `shares_outstanding` from `capstock.capstock_trial_balance_web_v`' do
        expect(call_method).to match(/\A\s*SELECT\s+(\S+\s+(AS\s+\S+,\s+)?)*no_share_holding\s+AS\s+shares_outstanding((,\s+(\S+\s+(AS\s+\S+)?)*)|\s+)FROM\s+capstock.capstock_trial_balance_web_v\s/mi)
      end
      it 'selects the `tran_type` as `transaction_type` from `capstock.capstock_trial_balance_web_v`' do
        expect(call_method).to match(/\A\s*SELECT\s+(\S+\s+(AS\s+\S+,\s+)?)*tran_type\s+AS\s+transaction_type((,\s+(\S+\s+(AS\s+\S+)?)*)|\s+)FROM\s+capstock.capstock_trial_balance_web_v\s/mi)
      end
      it 'filters based on the quouted `fhlb_id`' do
        expect(call_method).to match(/\sWHERE\s+fhlb_id\s*=\s*#{quoted_fhlb_id}\s+/mi)
      end
      it 'filters based on the `sold_date` being missing or greater than the quouted `date`' do
        expect(call_method).to match(/\sWHERE(\s+.+\s+AND)*\s+\(\s*sold_date\s+is\s+null\s+or\s+sold_date\s*>\s*#{quoted_date}\s*\)\s/mi)
      end
      it 'filters based on the `issue_date` being less than the quouted `date`' do
        expect(call_method).to match(/\sWHERE(\s+.+\s+AND)*\s+issue_date\s*<=\s*#{quoted_date}\s/mi)
      end
      it 'filters based on the `purchase_date` being less than the quouted `date`' do
        expect(call_method).to match(/\sWHERE(\s+.+\s+AND)*\s+purchase_date\s*<=\s*#{quoted_date}\s/mi)
      end
    end
  end
end
