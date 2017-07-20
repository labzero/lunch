require 'rails_helper'

RSpec.describe Admin::DataVisibilityController, :type => :controller do
  login_user(admin: true)

  it_behaves_like 'an admin controller'

  shared_examples 'a DataVisibilityController action with before_action methods' do
    it 'sets the active nav to :data_visibility' do
      expect(controller).to receive(:set_active_nav).with(:data_visibility)
      call_action
    end
    context 'when the current user can edit data visibility' do
      allow_policy :web_admin, :edit_data_visibility?
      it 'sets `@can_edit_data_visibility` to true' do
        call_action
        expect(assigns[:can_edit_data_visibility]).to be true
      end
    end
    context 'when the current user cannot edit data visbility' do
      deny_policy :web_admin, :edit_data_visibility?
      it 'sets `@can_edit_data_visibility` to false' do
        begin
          call_action
        rescue Pundit::NotAuthorizedError
        end
        expect(assigns[:can_edit_data_visibility]).to be false
      end
    end
  end

  describe 'GET view_flags' do
    let(:members_service) { instance_double(MembersService, global_disabled_reports: [], disabled_reports_for_member: [], all_members: []) }
    let(:call_action) { get :view_flags }

    before do
      allow(MembersService).to receive(:new).and_return(members_service)
    end

    it_behaves_like 'a DataVisibilityController action with before_action methods'
    it 'creates a new instance of the MembersService with the request' do
      expect(MembersService).to receive(:new).and_return(members_service)
      call_action
    end
    it 'calls `all_members` on the instance of MembersService' do
      expect(members_service).to receive(:all_members).and_return([])
      call_action
    end
    it 'raises an error if `all_members` returns nil' do
      allow(members_service).to receive(:all_members).and_return(nil)
      expect{call_action}.to raise_error('There has been an error and Admin::DataVisibilityController#view_flags has encountered nil. Check error logs.')
    end
    context 'when a member_id param is not present' do
      it 'calls `global_disabled_reports` on the instance of MembersService' do
        expect(members_service).to receive(:global_disabled_reports).and_return([])
        call_action
      end
      it 'raises an error if `global_disabled_reports` returns nil' do
        allow(members_service).to receive(:global_disabled_reports).and_return(nil)
        expect{call_action}.to raise_error('There has been an error and Admin::DataVisibilityController#view_flags has encountered nil. Check error logs.')
      end
      it 'sets a `@member_dropdown` instance variable with a `default_value` of `all`' do
        call_action
        expect(assigns[:member_dropdown][:default_value]).to eq('all')
      end
    end
    context 'when a member_id param is present' do
      let(:member_id) { SecureRandom.hex }
      let(:call_action) { get :view_flags, member_id: member_id}
      it 'calls `disabled_reports_for_member` with the member_id on the instance of MembersService' do
        expect(members_service).to receive(:disabled_reports_for_member).with(member_id).and_return([])
        call_action
      end
      it 'raises an error if `disabled_reports_for_member` returns nil' do
        allow(members_service).to receive(:disabled_reports_for_member).and_return(nil)
        expect{call_action}.to raise_error('There has been an error and Admin::DataVisibilityController#view_flags has encountered nil. Check error logs.')
      end
      it 'sets a `@member_dropdown` instance variable with a `default_value` that is the member_id' do
        call_action
        expect(assigns[:member_dropdown][:default_value]).to eq(member_id)
      end
    end
    describe 'setting the view instance variables for the tables' do
      let(:disabled_web_flags) { double('disabled web flags') }
      let(:table_sentinel) { double('table instance variable') }
      before do
        allow(controller).to receive(:data_visibility_table)
        allow(members_service).to receive(:global_disabled_reports).and_return(disabled_web_flags)
      end
      {
        account_table: [:account_summary, :authorizations, :settlement_transaction_account, :investments],
        capital_stock_table: [:cap_stock_activity, :cap_stock_trial_balance, :cap_stock_leverage, :dividend_statement],
        price_indications_table: [:current_price_indications, :historical_price_indications],
        collateral_table: [:borrowing_capacity, :mortgage_collateral_update],
        credit_table: [:todays_credit, :advances, :interest_rate, :letters_of_credit, :forward_commitments, :parallel_shift],
        securities_table: [:securities_transactions, :cash_projections, :current_securities_position, :monthly_securities_position, :securities_services]
      }.each do |instance_var, web_flag_keys|
        describe "setting the `@#{instance_var}`" do
          it 'calls `data_visibility_table` with the disabled web flags' do
            expect(controller).to receive(:data_visibility_table).with(disabled_web_flags, anything)
            call_action
          end
          it 'calls `data_visibility_table` with an array of web flag names associated with the table' do
            expect(controller).to receive(:data_visibility_table).with(anything, web_flag_keys)
            call_action
          end
          it "sets `@#{instance_var}` to result of calling `data_visibility_table`" do
            allow(controller).to receive(:data_visibility_table).with(anything, web_flag_keys).and_return(table_sentinel)
            call_action
            expect(assigns[instance_var]).to eq(table_sentinel)
          end
        end
      end
    end
    describe 'setting the `@member_dropdown` view variable' do
      describe 'the `options` value' do
        let(:member) {{
          name: instance_double(String),
          id: instance_double(Integer)
        }}
        it "has a first member whose text is #{I18n.t('admin.data_visibility.all_members')}" do
          call_action
          expect(assigns[:member_dropdown][:options].first.first).to eq(I18n.t('admin.data_visibility.all_members'))
        end
        it "has a first member whose value is `all`" do
          call_action
          expect(assigns[:member_dropdown][:options].first.last).to eq('all')
        end
        it 'contains an array for each member' do
          members = Array.new(rand(2..5)) {instance_double(Hash, :[] => nil)}
          allow(members_service).to receive(:all_members).and_return(members)
          call_action
          expect(assigns[:member_dropdown][:options].length).to eq(members.length + 1)
        end
        it 'sets the text of the member entry to the name of the member' do
          allow(members_service).to receive(:all_members).and_return([member])
          call_action
          expect(assigns[:member_dropdown][:options].last.first).to eq(member[:name])
        end
        it 'sets the value of the member entry to the id of the member' do
          allow(members_service).to receive(:all_members).and_return([member])
          call_action
          expect(assigns[:member_dropdown][:options].last.last).to eq(member[:id])
        end
      end
    end
  end

  describe 'private methods' do
    describe '`data_visibility_table`' do
      visibility_mapping = described_class::DATA_VISIBILITY_MAPPING
      it 'returns a hash with a for for each report_name it is passed' do
        report_names = Array.new(rand(2..5)){visibility_mapping.keys.sample}
        result = subject.send(:data_visibility_table, [], report_names)
        expect(result[:rows].length).to eq(report_names.length)
      end
      describe 'a row column' do
        let(:report_name) { visibility_mapping.keys.sample }
        let(:row) { subject.send(:data_visibility_table, [], [report_name])[:rows].first }
        context 'when the web flags associated with the passed report names overlaps with the passed flags' do
          let(:flags) { visibility_mapping[report_name][:flags] }
          let(:row) { subject.send(:data_visibility_table, flags, [report_name])[:rows].first }

          it 'has a `row_class` of `data-source-disabled`' do
            expect(row[:row_class]).to eq('data-source-disabled')
          end
          it 'has a first row with a `checked` attribute that is false' do
            expect(row[:columns].first[:checked]).to be false
          end
        end
        context 'when the web flags associated with the passed report names do not overlap with the passed flags' do
          it 'does not have a `row_class`' do
            expect(row[:row_class]).to be nil
          end
          it 'has a first row with a `checked` attribute that is true' do
            expect(row[:columns].first[:checked]).to be true
          end
        end
        describe 'the first column in the row' do
          let(:column) { row[:columns].first }

          it 'has a `name` that contains the passed report name' do
            expect(column[:name]).to eq("data_visibility_flags[#{report_name}]")
          end
          it 'has a `type` that is `checkbox`' do
            expect(column[:type]).to eq(:checkbox)
          end
          it 'has a `label` attribute set to true' do
            expect(column[:label]).to be true
          end
          it 'has a `submit_unchecked_boxes` attribute set to true' do
            expect(column[:submit_unchecked_boxes]).to be true
          end
          it 'has a `disabled` attribute set to true' do
            expect(column[:disabled]).to be true
          end
        end
        describe 'the second column in the row' do
          let(:column) { row[:columns].last }
          it 'has a value that is equal to the title associated with the report_name in the DATA_VISIBILITY_MAPPING' do
            expect(column[:value]).to eq(visibility_mapping[report_name][:title])
          end
        end
      end
    end
  end
end