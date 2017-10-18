require 'spec_helper'

describe MAPI::ServiceApp do
  let(:credits) do
    new_array = []
    credits = JSON.parse(File.read(File.join(MAPI.root, 'spec', 'fixtures', 'credits.json')))
    credits.each do |credit|
      credit[:LCX_CURRENT_PAR] = rand(0..1000000)
      new_array << credit.with_indifferent_access
    end
    new_array
  end
  let(:formatted_credits) { double('an array of credits') }

  describe 'member letters_of_credit' do

    let(:total_current_par) { credits.inject(0) {|sum, credit| sum + credit[:LCX_CURRENT_PAR]} }
    let(:member_letters_of_credit) { MAPI::Services::Member::LettersOfCredit.letters_of_credit(subject, member_id) }

    it 'calls the `letters_of_credit` method when the endpoint is hit' do
      allow(MAPI::Services::Member::LettersOfCredit).to receive(:letters_of_credit).and_return('a response')
      get "/member/#{member_id}/letters_of_credit"
      expect(last_response.status).to eq(200)
    end

    [:test, :production].each do |env|
      describe "`letters_of_credit` method in the #{env} environment" do
        let(:credits_result_set) {double('Oracle Result Set', fetch_hash: nil)} if env == :production
        let(:credits_result) {[credits[0], credits[1], credits[2], nil]} if env == :production

        before do
          if env == :production
            allow(MAPI::ServiceApp).to receive(:environment).at_least(1).and_return(:production)
            allow(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(credits_result_set)
            allow(credits_result_set).to receive(:fetch_hash).and_return(*credits_result)
          end
        end
        if env == :production
          describe 'when the database returns no credits' do
            before { allow(credits_result_set).to receive(:fetch_hash).and_return(nil) }
            it 'returns nil for the `as_of_date`' do
              expect(member_letters_of_credit[:as_of_date]).to be_nil
            end
            it 'returns nil for the `total_current_par`' do
              expect(member_letters_of_credit[:total_current_par]).to be_nil
            end
            it 'returns an empty array for `credits`' do
              expect(member_letters_of_credit[:credits]).to eq([])
            end
          end
          it "returns an object with a `total_current_par` that is the sum of the individual credit's ADVDET_CURRENT_PAR" do
            expect(member_letters_of_credit[:total_current_par]).to eq(total_current_par)
          end
          it 'returns an object with an array of formatted `credits`' do
            allow(MAPI::Services::Member::LettersOfCredit::Private).to receive(:format_credits).with(credits).and_return(formatted_credits)
            expect(member_letters_of_credit[:credits]).to eq(formatted_credits)
          end
        end
        it 'returns an object with an `as_of_date`' do
          expect(member_letters_of_credit[:as_of_date]).to be_kind_of(Date)
        end
        it "returns an object with a `total_current_par`" do
          expect(member_letters_of_credit[:total_current_par]).to be_kind_of(Integer)
        end
        it 'returns an object with an array of formatted `credits`' do
          expect(member_letters_of_credit[:credits]).to be_kind_of(Array)
        end
      end
    end
  end


  describe 'letter_of_credit' do
    letters_of_credit_module = MAPI::Services::Member::LettersOfCredit
    let(:lc_number) { SecureRandom.hex }
    let(:app) { instance_double(MAPI::ServiceApp, logger: double('logger', error: nil)) }
    let(:call_method) { MAPI::Services::Member::LettersOfCredit.letter_of_credit(app, member_id, lc_number) }

    context 'when `should_fake?` returns true' do
      let(:letter_of_credit) { double(Hash) }
      let(:locs) { instance_double(Hash, :[] => nil) }
      let(:v) {instance_double(Hash, :[] => nil) }
      before do
        allow(letters_of_credit_module).to receive(:should_fake?).and_return(true)
        allow(locs).to receive(:[]).and_return(credits)
        allow(locs).to receive(:any?).and_return(true)
        allow(credits).to receive(:select).and_yield(v).and_return(letter_of_credit)
        allow(credits).to receive(:first).and_return(letter_of_credit)
        allow(letter_of_credit).to receive(:first).and_return(letter_of_credit)
        allow(letter_of_credit).to receive(:[]=).with(any_args).and_return(letter_of_credit)
      end

      it 'calls `should_fake?` with the app passed as an argument' do
        expect(letters_of_credit_module).to receive(:should_fake?).with(app).and_return(true)
        call_method
      end
      it 'calls `fake` with `letters_of_credit`' do
        expect(letters_of_credit_module).to receive(:fake).with('letters_of_credit').and_return({})
        call_method
      end
    end

    context 'when `should_fake?` returns false' do
      let(:letter_of_credit) { instance_double(Hash) }
      let(:cursor) { double(OCI8::Cursor) }
      let(:loc_result) { [credits[0], nil] }
      before do
        allow(letters_of_credit_module).to receive(:should_fake?).and_return(false)
        allow(letters_of_credit_module).to receive(:execute_sql).with(app.logger, anything).and_return(cursor)
        allow(cursor).to receive(:fetch_hash).and_return(*loc_result)
      end

      it 'invokes execute sql with a logger and a sql query' do
        expect(letters_of_credit_module).to receive(:execute_sql).with(app.logger, anything).and_return(cursor)
        call_method
      end

      it 'calls `should_fake?` with the app passed as an argument' do
        expect(letters_of_credit_module).to receive(:should_fake?).with(app).and_return(false)
        call_method
      end

      describe 'when the database does not return the requested letter of credit' do
        before { allow(letters_of_credit_module).to receive(:execute_sql).and_return({}) }
        it 'returns an empty array for `beneficiaries`' do
          expect(call_method).to eq({})
        end
      end

      it 'returns an object with an `letter of credit` hash' do
        expect(call_method).to be_kind_of(Hash)
      end

      describe 'the SQL query' do
        describe 'the selected fields' do
          ['LR.FHLB_ID','LR.LC_LC_NUMBER', 'LR.LC_SORT_CODE','LR.LCX_CURRENT_PAR', 'LR.LCX_TRANS_SPREAD', 'LR.LC_TRADE_DATE', 'LR.LC_SETTLEMENT_DATE', 'LR.LC_MATURITY_DATE', 'LR.LC_ISSUE_NUMBER', 'LR.LCX_UPDATE_DATE', 'LR.LC_BENEFICIARY', 'LC.LC_EVERGREEN_FLAG'].each do |field|
            it "selects the `#{field}` field" do
              matcher = Regexp.new(/\A\s*SELECT.*\s+#{field}(?:,|\s+)/im)
              expect(letters_of_credit_module).to receive(:execute_sql).with(anything, matcher)
              call_method
            end
          end
        end
        it 'selects from the JOIN of `WEB_INET.WEB_LC_LATESTDATE_RPT` and `PORTFOLIOS.LCS`' do
          matcher = Regexp.new(/\A\s*SELECT.+FROM\s+WEB_LC_LATESTDATE_RPT\s+LR\s+JOIN\s+PORTFOLIOS\.LCS\s+LC\s+ON\s+LR\.LC_LC_NUMBER\s+=\s+LC\.LC_LC_NUMBER/im)
          expect(letters_of_credit_module).to receive(:execute_sql).with(anything, matcher)
          call_method
        end
      end
    end
  end

  describe 'private methods' do
    describe '`format_credits` method' do
      let(:formatted_credits) { MAPI::Services::Member::LettersOfCredit::Private.format_credits(credits) }

      [:maturity_date, :trade_date, :trade_date].each do |property|
        it "returns an object with a `#{property}` formatted as a date" do
          formatted_credits.each do |credit|
            expect(credit[property]).to be_kind_of(Date)
          end
        end
      end
      [:current_par, :maintenance_charge].each do |property|
        it "returns an object with a `#{property}` formatted as a string" do
          formatted_credits.each do |credit|
            expect(credit[property]).to be_kind_of(Integer)
          end
        end
      end
      [:lc_number, :description, :beneficiary, :evergreen_flag].each do |property|
        it "returns an object with a `#{property}` formatted as a string" do
          formatted_credits.each do |credit|
            expect(credit[property]).to be_kind_of(String)
          end
        end
      end
      describe 'handling nil values' do
        [:maturity_date, :trade_date, :trade_date, :current_par, :maintenance_charge, :lc_number, :description, :beneficiary, :evergreen_flag].each do |property|
          it "returns an object with a nil value for `#{property}` if that property doesn't have a value" do
            MAPI::Services::Member::LettersOfCredit::Private.format_credits([{}, {}]).each do |credit|
              expect(credit[property]).to be_nil
            end
          end
        end
      end
    end
  end
end
