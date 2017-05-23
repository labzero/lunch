require 'spec_helper'

describe MAPI::ServiceApp do
  let(:member_flags_module) { MAPI::Services::Member::Flags }

  describe '`quick_advance_flag` method' do
    let(:quick_advance_flag) { MAPI::Services::Member::Flags.quick_advance_flag(subject, member_id) }

    it 'calls the `quick_advance_flag` method when the endpoint is hit' do
      allow(MAPI::Services::Member::Flags).to receive(:quick_advance_flag).and_return('a response')
      get "/member/#{member_id}/quick_advance_flag"
      expect(last_response.status).to eq(200)
    end

    describe 'in the :production environment' do
      let(:quick_advance_flag_result_set) {double('Oracle Result Set', fetch: nil)}

      before do
        allow(MAPI::ServiceApp).to receive(:environment).and_return(:production)
        allow(ActiveRecord::Base.connection).to receive(:execute).and_return(quick_advance_flag_result_set)
      end

      it 'returns true for the `quick_advance_enabled` value if the SQL query returns `[\'Y\']`' do
        allow(quick_advance_flag_result_set).to receive(:fetch).and_return(['Y', nil])
        expect(quick_advance_flag[:quick_advance_enabled]).to eq(true)
      end
      it 'returns false for the `quick_advance_enabled` value if the SQL query returns `[\'N\']`' do
        allow(quick_advance_flag_result_set).to receive(:fetch).and_return(['N', nil])
        expect(quick_advance_flag[:quick_advance_enabled]).to eq(false)
      end
      it 'returns false for the `quick_advance_enabled` value if the SQL query returns nil' do
        allow(quick_advance_flag_result_set).to receive(:fetch).and_return([nil])
        expect(quick_advance_flag[:quick_advance_enabled]).to eq(false)
      end
    end

    [:development, :test].each do |env|
      describe "in the #{env} environment" do
        before do
          allow(MAPI::ServiceApp).to receive(:environment).and_return(:env)
        end
        describe 'when the member id is not 13' do
          let(:member_id) { ([*1..10000] - [13]).sample }
          it 'returns true for the `quick_advance_enabled` value ' do
            expect(quick_advance_flag[:quick_advance_enabled]).to eq(true)
          end
        end
        describe 'when the member id is 13' do
          let(:member_id) { 13 }
          it 'returns false for the `quick_advance_enabled` value ' do
            expect(quick_advance_flag[:quick_advance_enabled]).to eq(false)
          end
        end
      end
    end
  end
  describe '`quick_advance_flags` method' do
    let(:quick_advance_flags) { MAPI::Services::Member::Flags.quick_advance_flags(subject) }

    it_behaves_like 'a MAPI endpoint with JSON error handling', '/member/quick_advance_flags', :get, MAPI::Services::Member::Flags, :quick_advance_flags

    it 'calls the `quick_advance_flags` method when the endpoint is hit' do
      expect(MAPI::Services::Member::Flags).to receive(:quick_advance_flags)
      get "/member/quick_advance_flags"
    end

    it 'returns the response' do
      json = SecureRandom.hex
      allow(Swagger::Blocks).to receive(:build_root_json).and_return(double('Swagger Docs', to_json: json))
      allow(MAPI::Services::Member::Flags).to receive(:quick_advance_flags).and_return(double('a response', to_json: json))
      get "/member/quick_advance_flags"
      expect(last_response.body).to eq(json)
    end

    describe 'when `should_fake?` returns false' do
      let(:flags) { instance_double(Array) }
      let(:flag_param) { instance_double(Hash, with_indifferent_access: flag) }
      let(:flag) { instance_double(Hash, :[] => nil) }
      let(:returned_array) { instance_double(Array, first: returned_hash) }
      let(:returned_hash) { instance_double(Array, :[] => nil) }

      before do
        allow(MAPI::Services::Member::Flags).to receive(:should_fake?).and_return(false)
        allow(MAPI::Services::Member::Flags).to receive(:fetch_hashes).and_return(flags)
        allow(flags).to receive(:collect).and_yield(flag_param).and_return(returned_array)
        allow(flag_param).to receive(:with_indifferent_access).and_return(flag)
      end

      describe 'the SQL used to retrieve the quick advance flags' do
        it 'selects the appropriate fields' do
          matcher = Regexp.new(/\s*SELECT\s+fhlb_id,\s+cp_assoc,\s+intraday_status_flag\s+/im)
          expect(MAPI::Services::Member::Flags).to receive(:fetch_hashes).with(anything, matcher)
          quick_advance_flags
        end
        it 'queries the correct table' do
          matcher = Regexp.new(/(\A|\s+)*FROM\s+web_adm.web_member_data\s+/im)
          expect(MAPI::Services::Member::Flags).to receive(:fetch_hashes).with(anything, matcher)
          quick_advance_flags
        end
      end

      describe "when returning the results" do
        let(:fhlb_id) { rand(999..9999) }
        let(:member_name) { SecureRandom.uuid }

        before do
          allow(returned_array).to receive(:first).and_return(returned_hash)
        end

        it 'calls `with_indifferent_access` on the flag' do
          expect(flag_param).to receive(:with_indifferent_access)
          quick_advance_flags
        end
        it 'sets `:fhlb_id`' do
          allow(returned_hash).to receive(:[]).with(:fhlb_id).and_return(fhlb_id)
          allow(flag).to receive(:[]).with('fhlb_id').and_return(fhlb_id)
          expect(quick_advance_flags.first[:fhlb_id]).to eq(fhlb_id)
        end
        it 'sets `:member_name`' do
          allow(returned_hash).to receive(:[]).with(:member_name).and_return(member_name)
          allow(flag).to receive(:[]).with('cp_assoc').and_return(member_name)
          expect(quick_advance_flags.first[:member_name]).to eq(member_name)
        end
        [ 'Y' => true, 'y' => true, 'N' => false, 'n' => false ].each do |intraday_status_flag, value|
          it "sets `:quick_advance_enabled` to `#{value}` when the `intraday_status_flag` is `#{intraday_status_flag}`" do
            allow(returned_hash).to receive(:[]).with(:quick_advance_enabled).and_return(value)
            allow(flag).to receive(:[]).with('intraday_status_flag').and_return(intraday_status_flag)
            expect(quick_advance_flags.first[:quick_advance_enabled]).to eq(value)
          end
        end
        it "sets `:quick_advance_enabled` to `false` when the `intraday_status_flag` is `nil`" do
          allow(returned_hash).to receive(:[]).with(:quick_advance_enabled).and_return(false)
          allow(flag).to receive(:[]).with('intraday_status_flag').and_return(nil)
          expect(quick_advance_flags.first[:quick_advance_enabled]).to eq(false)
        end
      end
      describe 'when `should_fake?` returns true' do
        before do
          allow(MAPI::Services::Member::Flags).to receive(:should_fake?).and_return(true)
        end
        it 'returns fake data' do
          expect(quick_advance_flags).to eq(JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'quick_advance_flags.json'))).collect do |flag|
            {
              fhlb_id: flag['FHLB_ID'],
              member_name: flag['CP_ASSOC'],
              quick_advance_enabled: flag['INTRADAY_STATUS_FLAG'].upcase == 'Y'
            }
          end)
        end
      end
    end
  end

  describe '`update_quick_advance_flags`' do
    let(:app) { double(MAPI::ServiceApp, logger: double('logger')) }
    let(:member_id) { SecureRandom.hex }
    let(:flags) {{
      member_id => true
    }}
    let(:call_method) { member_flags_module.update_quick_advance_flags(app, flags) }
    before do
      allow(member_flags_module).to receive(:should_fake?).and_return(true)
      allow(member_flags_module).to receive(:execute_sql).and_return(true)
      allow(member_flags_module).to receive(:quote)
    end

    context 'when `should_fake?` returns true' do
      it 'returns true' do
        expect(call_method).to be true
      end
    end
    context 'when `should_fake?` returns false' do
      before { allow(member_flags_module).to receive(:should_fake?).and_return(false) }

      it 'executes code within a transaction where the `isolation` has been set to `:read_committed`' do
        expect(ActiveRecord::Base).to receive(:transaction).with(isolation: :read_committed)
        call_method
      end
      it 'returns true if the transaction block executes without error' do
        allow(ActiveRecord::Base).to receive(:transaction).with(isolation: :read_committed)
        expect(call_method).to be true
      end
      describe 'the transaction block' do
        it 'raises an `MAPI::Shared::Errors::SQLError` if `execute_sql` does not succeed' do
          allow(member_flags_module).to receive(:execute_sql).and_return(false)
          expect{call_method}.to raise_error(MAPI::Shared::Errors::SQLError, "Failed to update quick advance flag for member with id: #{member_id}")
        end
        it 'calls `execute_sql` with the logger' do
          expect(member_flags_module).to receive(:execute_sql).with(app.logger, anything).and_return(true)
          call_method
        end
        describe 'the update_quick_advance_flags_sql' do
          it 'executes for each member that is present in the flags hash' do
            n = rand(2..5)
            flags_hash = {}
            n.times do |i|
              flags_hash[i] = double('enabled')
            end
            expect(member_flags_module).to receive(:execute_sql).exactly(n).times.and_return(true)
            member_flags_module.update_quick_advance_flags(app, flags_hash)
          end
          it 'updates the `WEB_ADM.WEB_MEMBER_DATA` table' do
            matcher = Regexp.new(/\A\s*UPDATE.+WEB_ADM.WEB_MEMBER_DATA\s+/im)
            expect(member_flags_module).to receive(:execute_sql).with(anything, matcher).and_return(true)
            call_method
          end
          describe 'the SET clause' do
            context 'when the value for the member indicates etransact should be enabled' do
              let(:call_method) { member_flags_module.update_quick_advance_flags(app, {member_id => true}) }
              it 'quotes the `Y` value' do
                expect(member_flags_module).to receive(:quote).with('Y')
                call_method
              end
              it 'SETs the INTRADAY_STATUS_FLAG to the quoted value' do
                quoted_y_value = SecureRandom.hex
                allow(member_flags_module).to receive(:quote).with('Y').and_return(quoted_y_value)
                matcher = Regexp.new(/\A\s*UPDATE.+WEB_ADM.WEB_MEMBER_DATA\s+.*SET\s+INTRADAY_STATUS_FLAG\s+=\s+#{quoted_y_value}\s+/im)
                expect(member_flags_module).to receive(:execute_sql).with(anything, matcher).and_return(true)
                call_method
              end
            end
            context 'when the value for the member indicates etransact should be disabled' do
              let(:call_method) { member_flags_module.update_quick_advance_flags(app, {member_id => false}) }
              it 'quotes the `N` value' do
                expect(member_flags_module).to receive(:quote).with('N')
                call_method
              end
              it 'SETs the INTRADAY_STATUS_FLAG to the quoted value' do
                quoted_n_value = SecureRandom.hex
                allow(member_flags_module).to receive(:quote).with('N').and_return(quoted_n_value)
                matcher = Regexp.new(/\A\s*UPDATE.+WEB_ADM.WEB_MEMBER_DATA\s+.*SET\s+INTRADAY_STATUS_FLAG\s+=\s+#{quoted_n_value}\s+/im)
                expect(member_flags_module).to receive(:execute_sql).with(anything, matcher).and_return(true)
                call_method
              end
            end
          end
          describe 'the WHERE clause' do
            it 'quotes the member_id' do
              expect(member_flags_module).to receive(:quote).with(member_id)
              call_method
            end
            it 'performs the update on the row where the `FHLB_ID` equals the quoted member_id' do
              quoted_member_id = SecureRandom.hex
              allow(member_flags_module).to receive(:quote).with(member_id).and_return(quoted_member_id)
              matcher = Regexp.new(/\A\s*UPDATE.+WEB_ADM.WEB_MEMBER_DATA\s+.*SET\s+.+WHERE\s+FHLB_ID\s+=\s+#{quoted_member_id}\s*\z/im)
              expect(member_flags_module).to receive(:execute_sql).with(anything, matcher).and_return(true)
              call_method
            end
          end
        end
      end
    end
  end
end