require 'spec_helper'

describe MAPI::ServiceApp do

  describe 'member beneficiaries' do
    beneficiaries_module = MAPI::Services::Member::Beneficiaries
    let(:app) { instance_double(MAPI::ServiceApp, logger: double('logger', error: nil)) }
    let(:call_method) { MAPI::Services::Member::Beneficiaries.beneficiaries(app, member_id) }
    let(:beneficiaries) do
      new_array = []
      beneficiaries = JSON.parse(File.read(File.join(MAPI.root, 'spec', 'fixtures', 'beneficiaries.json')))
      beneficiaries.each do |beneficiaries|
        new_array << beneficiaries.with_indifferent_access
      end
      new_array
    end
    let(:cursor) { double(OCI8::Cursor) }
    let(:beneficiaries_result) {[beneficiaries[0], beneficiaries[1], beneficiaries[2], nil]}

    context 'when `should_fake?` returns true' do
      before do
        allow(beneficiaries_module).to receive(:should_fake?).and_return(true)
      end

      it 'calls `should_fake?` with the app passed as an argument' do
        expect(beneficiaries_module).to receive(:should_fake?).with(app).and_return(true)
        call_method
      end
      it 'calls `fake` with `beneficiaries`' do
        expect(beneficiaries_module).to receive(:fake).with('beneficiaries').and_return([])
        call_method
      end
    end
    context 'when `should_fake?` returns false' do
      before do
        allow(beneficiaries_module).to receive(:should_fake?).and_return(false)
        allow(beneficiaries_module).to receive(:execute_sql).with(app.logger, anything).and_return(cursor)
        allow(cursor).to receive(:fetch_hash).and_return(*beneficiaries_result)
      end

      it 'invokes execute sql with a logger and a sql query' do
        expect(beneficiaries_module).to receive(:execute_sql).with(app.logger, anything).and_return(cursor)
        call_method
      end
      it 'calls `should_fake?` with the app passed as an argument' do
        expect(beneficiaries_module).to receive(:should_fake?).with(app).and_return(false)
        call_method
      end
      describe 'when the database returns no beneficiaries' do
        before { allow(beneficiaries_module).to receive(:execute_sql).and_return([]) }
        it 'returns an empty array for `beneficiaries`' do
          expect(call_method).to eq([])
        end
      end
      it 'returns an object with an array of `beneficiaries`' do
        expect(call_method).to be_kind_of(Array)
      end
      describe 'the SQL query' do
        describe 'the selected fields' do
          ['BENEFICIARY_SHORT_NAME', 'BENEFICIARY_FULL_NAME', 'CARE_OF', 'DEPARTMENT', 'STREET', 'CITY', 'STATE', 'ZIP'].each do |field|
            it "selects the `#{field}` field" do
              matcher = Regexp.new(/\A\s*SELECT.*\s+#{field}(?:,|\s+)/im)
              expect(beneficiaries_module).to receive(:execute_sql).with(anything, matcher).and_return([])
              call_method
            end
          end
        end
        it 'selects from `crm.Account`' do
          matcher = Regexp.new(/\A\s*SELECT.+FROM\s+crm.Account/im)
          expect(beneficiaries_module).to receive(:execute_sql).with(anything, matcher).and_return([])
          call_method
        end
        it 'selects from `crm.Account_Beneficiary__C`' do
          matcher = Regexp.new(/\A\s*SELECT.+FROM.*\s+crm.Account_Beneficiary__C/im)
          expect(beneficiaries_module).to receive(:execute_sql).with(anything, matcher).and_return([])
          call_method
        end
        it 'selects from `crm.Beneficiary__C`' do
          matcher = Regexp.new(/\A\s*SELECT.+FROM.*\s+crm.Beneficiary__C/im)
          expect(beneficiaries_module).to receive(:execute_sql).with(anything, matcher).and_return([])
          call_method
        end
      end
    end
  end
end