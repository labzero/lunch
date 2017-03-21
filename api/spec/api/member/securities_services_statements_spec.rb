require 'spec_helper'

describe MAPI::ServiceApp do
  subject { MAPI::Services::Member::SecuritiesServicesStatements }

  describe 'SecuritiesServicesStatements' do
    let(:logger) { double('logger')  }
    let(:fhlb_id){ double('fhlb_id') }
    let(:date){ double('date') }

    before do
      allow(date).to receive(:+).and_return(date)
    end

    describe 'multi_level_merge' do
      it 'should work on the simple case' do
        result = {}
        expect(subject.multi_level_merge(result, [:key], :value)).to eq({key: :value})
        expect(subject.multi_level_merge(result, [:key2], :value2)).to eq({key: :value, key2: :value2})
      end

      it 'should work on the nested case' do
        result = {}
        expect(subject.multi_level_merge(result, %w(key1 key2 key3 key4), :value)).to eq({"key1" => { "key2" => { "key3" => { "key4" => :value }}}})
        expect(subject.multi_level_merge(result, %w(key1 key2 key3 key5), :value2)).to eq({"key1" => { "key2" => { "key3" => { "key4" => :value, "key5" => :value2 }}}})
      end
    end

    describe 'multi_level_transform' do
      let(:real_data){subject.fake('securities_services_statements')}
      let(:real_result) do
        {
            account_maintenance: { total: 100.0 },
            certifications: {total:0.0, cost: 40.0, count: 0},
            contact: {city: "OAKLAND", name: "UNITED BUSINESS BANK, F.S.B.", state: "CA", zip: "94621-1447"},
            debit_date: "2015-01-30",
            handling: {total: 0.0, count: 0, cost: 40.0},
            income_disbursement: {total: 195.0, cost: 5.0, count: 39},
            member_id: 129,
            month_ending: "2014-12-31",
            pledge_status_change: {total: 0.0, cost: 10.0, count: 0},
            research: {total: 0.0, count: 0, cost: 40.0},
            securities_fees: {dtc:       {cost: 2.5,  count: 19, total: 47.5},
                              euroclear: {cost: 0.01, count:  0, total:  0.0},
                              fed:       {cost: 1.0,  count: 30, total: 30.0},
                              funds:     {cost: 4.5,  count:  0, total:  0.0}},
            sta_account_number: "12345678",
            total: 372.5,
            transaction_fees: {dtc:       {cost:  15.0, count: 0, total: 0.0},
                               euroclear: {cost:  75.0, count: 0, total: 0.0},
                               fed:       {cost:  10.0, count: 0, total: 0.0},
                               funds:     {cost: 150.0, count: 0, total: 0.0}}
        }.with_indifferent_access
      end

      it 'should work on real data' do
        expect(subject.multi_level_transform(real_data.first.with_indifferent_access, subject::MAP_KEYS)).to eq(real_result)
      end

      it 'should work on the simple cases' do
        expect(subject.multi_level_transform({ key: :value, key2: :value2 }, { key: 'a/b/c', key2: 'a/b/d' }).with_indifferent_access).to eq({ 'a' => { 'b' => { 'c' => :value, 'd' => :value2 }}})
      end
    end

    describe 'production' do
      let(:env){ :production }
      let(:available_statements_sql){ double('available_statements_sql') }
      let(:available_statements_hash) { {'report_end_date' => report_end_date} }
      let(:available_statements_hashes){ [available_statements_hash] }
      let(:statement_sql){ double('statement_sql') }
      let(:statement_hash){ double('statement_record', with_indifferent_access: indifferent_statement_hash) }
      let(:indifferent_statement_hash){ double('indifferent_statement_hash') }
      let(:fixed_statement_hash) { double('fixed_statement_hash') }
      let(:transformed_statement_hash){ double('transformed_statement_hash') }
      let(:report_end_date) { instance_double(String, 'A Report End Date') }
      let(:call_method) { subject.available_statements(logger, env, fhlb_id) }

      before do
        allow(subject).to receive(:available_statements_sql).with(fhlb_id).and_return(available_statements_sql)
        allow(subject).to receive(:statement_sql).with(fhlb_id, date).and_return(statement_sql)
        allow(subject).to receive(:fetch_hashes).with(logger, available_statements_sql, {}, true).and_return(available_statements_hashes)
        allow(subject).to receive(:fetch_hashes).with(logger, statement_sql, subject::MAP_VALUES).and_return([statement_hash])
        allow(subject).to receive(:multi_level_transform).with(statement_hash, subject::MAP_KEYS).and_return(transformed_statement_hash)
        allow(subject).to receive(:dateify)
      end

      describe 'available_statements' do
        it 'should return available_statements_hashes' do
          expect(call_method).to eq(available_statements_hashes)
        end
        it 'converts statement `report_end_date` to a date' do
          converted_report_end_date = instance_double(Date, 'A Converted Report End Date')
          allow(subject).to receive(:dateify).with(report_end_date).and_return(converted_report_end_date)
          expect(call_method.first['report_end_date']).to be(converted_report_end_date)
        end
      end

      describe 'statement' do
        it 'should return transformed_statement_hash' do
          expect(subject.statement(logger, env, fhlb_id, date)).to eq(transformed_statement_hash)
        end

        it 'should handle empty results' do
          allow(subject).to receive(:fetch_hashes).with(logger, statement_sql, subject::MAP_VALUES).and_return([])
          expect(subject.statement(logger, env, fhlb_id, date)).to eq({})
        end
      end
    end
    [:test, :development].each do |env|
      describe env do
        describe 'available_statements' do
          let(:available_statements){ double('available_statements') }
          it 'should return available_statements_records' do
            allow(subject).to receive(:fake).with('securities_services_statements_available').and_return(available_statements)
            allow(available_statements).to receive(:each).and_return(available_statements)
            expect(subject.available_statements(logger, env, fhlb_id)).to eq(available_statements)
          end
        end

        describe 'statement' do
          let(:statement_hash){ double('statement_hash', with_indifferent_access: indifferent_hash, :[]= => nil) }
          let(:indifferent_hash){ double('indifferent_hash') }
          let(:fixup_hash){ double('fixup_hash') }
          let(:transformed_hash){ double('transformed_hash') }
          it 'should return statement_records' do
            allow(subject).to receive(:fake).with('securities_services_statements').and_return([statement_hash])
            allow(subject).to receive(:multi_level_transform).with(statement_hash, subject::MAP_KEYS).and_return(transformed_hash)
            expect(subject.statement(logger, env, fhlb_id, date)).to eq(transformed_hash)
          end
        end
      end
    end

    describe '`available_statements_sql` class method' do
      let(:fhlb_id) { instance_double(Numeric) }
      let(:quoted_fhlb_id) { SecureRandom.hex }
      let(:call_method) { subject.available_statements_sql(fhlb_id) }

      before do
        allow(subject).to receive(:quote).with(fhlb_id).and_return(quoted_fhlb_id)
      end

      it 'selects the distinct `SSX_BTC_DATE` as `report_end_date` from `SAFEKEEPING.SECURITIES_FEES_STMT_WEB`' do
        expect(call_method).to match(/\A\s*SELECT\s+(\S+\s+(AS\s+\S+,\s+)?)*DISTINCT\s+SSX_BTC_DATE\s+AS\s+report_end_date((,\s+(\S+\s+(AS\s+\S+)?)*)|\s+)FROM\s+SAFEKEEPING.SECURITIES_FEES_STMT_WEB\s/mi)
      end

      it 'filters based on the quouted `fhlb_id`' do
        expect(call_method).to match(/\sWHERE\s+fhlb_id\s*=\s*#{quoted_fhlb_id}\s+/mi)
      end

      it 'orders rows based on descending `SSX_BTC_DATE`' do
        expect(call_method).to match(/\sWHERE(\s+.+\s+AND)*(\s+.+)?\s+ORDER\s+BY\s+SSX_BTC_DATE\s+DESC\s*\z/mi)
      end
    end

    describe '`statement_sql` class method' do
      let(:fhlb_id) { instance_double(Numeric) }
      let(:report_date) { instance_double(Date, 'A Report Date') }
      let(:quoted_report_date) { SecureRandom.hex }
      let(:quoted_fhlb_id) { SecureRandom.hex }
      let(:call_method) { subject.statement_sql(fhlb_id, report_date) }

      before do
        allow(subject).to receive(:quote).with(fhlb_id).and_return(quoted_fhlb_id)
        allow(subject).to receive(:quote).with(report_date).and_return(quoted_report_date)
      end

      # it 'selects the distinct `SSX_BTC_DATE` as `report_end_date` from `SAFEKEEPING.SECURITIES_FEES_STMT_WEB`' do
      #   expect(call_method).to match(/\A\s*SELECT\s+(\S+\s+(AS\s+\S+,\s+)?)*DISTINCT\s+SSX_BTC_DATE\s+AS\s+report_end_date((,\s+(\S+\s+(AS\s+\S+)?)*)|\s+)FROM\s+SAFEKEEPING.SECURITIES_FEES_STMT_WEB\s/mi)
      # end

      MAPI::Services::Member::SecuritiesServicesStatements::MAP_KEYS.each do |field, _|
        it "selects the `#{field}` from `SAFEKEEPING.SECURITIES_FEES_STMT_WEB`" do
          expect(call_method).to match(/\A\s*SELECT\s+.*#{field}(,[^,]*)*\s+FROM\s+SAFEKEEPING.SECURITIES_FEES_STMT_WEB\s/mi)
        end
      end

      it 'filters based on the quouted `fhlb_id`' do
        expect(call_method).to match(/\sWHERE(\s+\S+\s+=\s+\S+\s+AND)*\s+FHLB_ID\s+=\s+#{quoted_fhlb_id}(\s+|\z)/mi)
      end

      it 'filters based on the quouted `report_date`' do
        expect(call_method).to match(/\sWHERE(\s+\S+\s+=\s+\S+\s+AND)*\s+SSX_BTC_DATE\s+=\s+#{quoted_report_date}(\s+|\z)/mi)
      end
    end
  end
end