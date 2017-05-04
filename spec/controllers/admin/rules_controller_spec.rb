require 'rails_helper'
include CustomFormattingHelper

RSpec.describe Admin::RulesController, :type => :controller do
  login_user(admin: true)
  it_behaves_like 'an admin controller'

  RSpec.shared_examples 'a RulesController action with before_action methods' do
    it 'sets the active nav to :rules' do
      expect(controller).to receive(:set_active_nav).with(:rules)
      call_action
    end
    context 'when the current user can edit trade rules' do
      allow_policy :web_admin, :edit_trade_rules?
      it 'sets `@can_edit_trade_rules` to true' do
        call_action
        expect(assigns[:can_edit_trade_rules]).to be true
      end
    end
    context 'when the current user cannot edit trade rules' do
      deny_policy :web_admin, :edit_trade_rules?
      it 'sets `@can_edit_trade_rules` to false' do
        begin
          call_action
        rescue Pundit::NotAuthorizedError
        end
        expect(assigns[:can_edit_trade_rules]).to be false
      end
    end
  end

  RSpec.shared_examples 'it checks the edit_trade_rules? web_admin policy' do
    before { allow(subject).to receive(:authorize).and_call_original }
    it 'checks if the current user is allowed to edit trade rules' do
      expect(subject).to receive(:authorize).with(:web_admin, :edit_trade_rules?)
      call_action
    end
    it 'raises any errors raised by checking to see if the user is authorized to modify the advance' do
      error = Pundit::NotAuthorizedError
      allow(subject).to receive(:authorize).and_raise(error)
      expect{call_action}.to raise_error(error)
    end
  end
  
  RSpec.shared_examples 'a RulesController table column that is a text field' do |name, &context_block|
    it 'has a `type` of :text_field' do
      expect(column[:type]).to eq(:text_field)
    end
    it "has a `name` of `#{name}`" do
      expect(column[:name]).to eq(name)
    end
    it 'has a `value_type` of :number' do
      expect(column[:value_type]).to eq(:number)
    end
    it 'has `options` of `{html: false}`' do
      expect(column[:options][:html]).to be false
    end
    context 'when the user can edit trade rules' do
      allow_policy :web_admin, :edit_trade_rules?
      it 'sets `disabled` to false' do
        expect(column[:disabled]).to be false
      end
    end
    context 'when the user cannot edit trade rules' do
      deny_policy :web_admin, :edit_trade_rules?
      it 'sets `disabled` to false' do
        expect(column[:disabled]).to be true
      end
    end
  end

  describe 'GET limits' do
    let(:global_limit_data) {{
      shareholder_total_daily_limit: double('total daily limit'),
      shareholder_total_daily_limit: double('total daily limit'),
      shareholder_web_daily_limit: double('web daily limit')
    }}
    let(:term_limit_data) {{
      term: described_class::VALID_TERMS.sample,
      min_online_advance: double('min online advance', to_i: nil),
      term_daily_limit: double('term daily limit', to_i: nil)
    }}
    let(:etransact_service) { instance_double(EtransactAdvancesService, limits: [term_limit_data], settings: global_limit_data)}
    let(:sentinel) { SecureRandom.hex }
    let(:call_action) { get :limits }
    before do
      allow(EtransactAdvancesService).to receive(:new).and_return(etransact_service)
      allow(controller).to receive(:fhlb_add_unit_to_table_header)
    end
    it_behaves_like 'a RulesController action with before_action methods'

    [:settings, :limits].each do |method|
      it "raises an error if EtransactAdvancesService#{method} returns nil" do
        allow(etransact_service).to receive(method).and_return(nil)
        expect{call_action}.to raise_error('There has been an error and Admin::RulesController#limits has encountered nil. Check error logs.')
      end
    end
    describe '`@global_limits`' do
      let(:global_limits) { call_action; assigns[:global_limits] }
      it 'contains two rows' do
        expect(global_limits[:rows].length).to eq(2)
      end
      describe 'the `per_member` row' do
        let(:per_member_row) { global_limits[:rows][0] }
        describe 'the first column data' do
          it 'calls `fhlb_add_unit_to_table_header` with the proper translation and unit' do
            expect(controller).to receive(:fhlb_add_unit_to_table_header).with(I18n.t('admin.term_rules.daily_limit.per_member'), '$')
            per_member_row
          end
          it 'has a `value` equal to that returned by `fhlb_add_unit_to_table_header`' do
            allow(controller).to receive(:fhlb_add_unit_to_table_header).with(I18n.t('admin.term_rules.daily_limit.per_member'), '$').and_return(sentinel)
            expect(per_member_row[:columns][0][:value]).to eq(sentinel)
          end
        end
        describe 'the second column data' do
          it_behaves_like 'a RulesController table column that is a text field', 'global_limits[shareholder_total_daily_limit]' do
            let(:column) { per_member_row[:columns][1] }
          end
          it 'has a `value` of the global_limit_data[:shareholder_total_daily_limit]' do
            expect(per_member_row[:columns][1][:value]).to eq(global_limit_data[:shareholder_total_daily_limit])
          end
        end
      end
      describe 'the `all_member` row' do
        let(:all_member_row) { global_limits[:rows][1] }
        describe 'the first column data' do
          it 'calls `fhlb_add_unit_to_table_header` with the proper translation and unit' do
            expect(controller).to receive(:fhlb_add_unit_to_table_header).with(I18n.t('admin.term_rules.daily_limit.all_member'), '$')
            all_member_row
          end
          it 'has a `value` equal to that returned by `fhlb_add_unit_to_table_header`' do
            allow(controller).to receive(:fhlb_add_unit_to_table_header).with(I18n.t('admin.term_rules.daily_limit.all_member'), '$').and_return(sentinel)
            expect(all_member_row[:columns][0][:value]).to eq(sentinel)
          end
        end
        describe 'the second column data' do
          it_behaves_like 'a RulesController table column that is a text field', 'global_limits[shareholder_web_daily_limit]' do
            let(:column) { all_member_row[:columns][1] }
          end
          it 'has a `value` of the global_limit_data[:shareholder_web_daily_limit]' do
            expect(all_member_row[:columns][1][:value]).to eq(global_limit_data[:shareholder_web_daily_limit])
          end
        end
      end
    end
    describe '`@term_limits`' do
      let(:term_limits) { call_action; assigns[:term_limits] }
      describe 'column_headings' do
        it 'calls `fhlb_add_unit_to_table_header` with the minimum online translation and unit' do
          expect(controller).to receive(:fhlb_add_unit_to_table_header).with(I18n.t('admin.term_rules.daily_limit.minimum_online'), '$')
          term_limits
        end
        it 'calls `fhlb_add_unit_to_table_header` with the daily limit translation and unit' do
          expect(controller).to receive(:fhlb_add_unit_to_table_header).with(I18n.t('admin.term_rules.daily_limit.daily'), '$')
          term_limits
        end
        it 'contains the proper column_headings' do
          minimum_online_heading = double('minimum online heading')
          daily_limit_heading = double('daily limit heading')
          allow(controller).to receive(:fhlb_add_unit_to_table_header).with(I18n.t('admin.term_rules.daily_limit.minimum_online'), '$').and_return(minimum_online_heading)
          allow(controller).to receive(:fhlb_add_unit_to_table_header).with(I18n.t('admin.term_rules.daily_limit.daily'), '$').and_return(daily_limit_heading)
          expect(term_limits[:column_headings]).to eq(['', minimum_online_heading, daily_limit_heading])
        end
      end
      it 'raises an error if it encounters an unrecognized `:term` in one the etransact_service.limits buckets' do
        term_limit_data[:term] = sentinel
        expect{term_limits}.to raise_error("There has been an error and Admin::RulesController#limits has encountered an etransact_service.limits bucket with an invalid term: #{sentinel}")
      end
      describe 'rows' do
        let(:term_limit_data_buckets) do
          data = []
          described_class::VALID_TERMS.each do |term|
            data << {
              term: term,
              min_online_advance: instance_double(Integer, to_i: nil),
              term_daily_limit: instance_double(Integer, to_i: nil)
            }
          end
          data
        end
        before { allow(etransact_service).to receive(:limits).and_return(term_limit_data_buckets) }
        it 'contains as many rows as etransact_service.limits buckets' do
          expect(term_limits[:rows].length).to eq(term_limit_data_buckets.length)
        end
        described_class::VALID_TERMS.each_with_index do |term, i|
          describe "the `#{term}` term row" do
            let(:term_row) { term_limits[:rows][i] }

            it "has a first column value with the correct translation for the `#{term}` term" do
              expect(term_row[:columns][0][:value]).to eq(I18n.t("admin.term_rules.daily_limit.dates.#{term}"))
            end
            describe 'the second column' do
              it_behaves_like 'a RulesController table column that is a text field', "term_limits[#{term}][min_online_advance]" do
                let(:column) { term_row[:columns][1] }
              end
              it 'has a `value` that is the result of calling `to_i` on the bucket\'s `min_online_advance`' do
                allow(term_limit_data_buckets[i][:min_online_advance]).to receive(:to_i).and_return(sentinel)
                expect(term_row[:columns][1][:value]).to eq(sentinel)
              end
            end
            describe 'the third column' do
              it_behaves_like 'a RulesController table column that is a text field', "term_limits[#{term}][term_daily_limit]" do
                let(:column) { term_row[:columns][2] }
              end
              it 'has a `value` that is the result of calling `to_i` on the bucket\'s `term_daily_limit`' do
                allow(term_limit_data_buckets[i][:term_daily_limit]).to receive(:to_i).and_return(sentinel)
                expect(term_row[:columns][2][:value]).to eq(sentinel)
              end
            end
          end
        end
      end
    end
  end

  describe 'PUT `update_limits`' do
    allow_policy :web_admin, :edit_trade_rules?

    let(:global_limits_param) { {SecureRandom.hex => 'some value'} }
    let(:term_limits_param) { {SecureRandom.hex => 'some value'} }
    let(:etransact_service) { instance_double(EtransactAdvancesService, update_term_limits: {}, update_settings: {})}
    let(:call_action) { put(:update_limits, {global_limits: global_limits_param, term_limits: term_limits_param}) }

    before do
      allow(EtransactAdvancesService).to receive(:new).and_return(etransact_service)
      allow(controller).to receive(:set_flash_message)
    end

    it_behaves_like 'a RulesController action with before_action methods'
    it_behaves_like 'it checks the edit_trade_rules? web_admin policy'
    it 'creates a new instance of EtransactAdvancesService with the request' do
      expect(EtransactAdvancesService).to receive(:new).with(request).and_return(etransact_service)
      call_action
    end
    describe 'updating etransact settings' do
      it 'calls `update_settings` on the EtransactAdvancesService with the `global_limits` param' do
        expect(etransact_service).to receive(:update_settings).with(global_limits_param).and_return({})
        call_action
      end
      it 'raises an error if the `update_settings` method returns nil' do
        allow(etransact_service).to receive(:update_settings).with(global_limits_param).and_return(nil)
        expect{call_action}.to raise_error("There has been an error and Admin::RulesController#update_limits has encountered nil")
      end
    end
    describe 'updating etransact limits' do
      it 'calls `update_term_limits` on the EtransactAdvancesService with the `term_limits` param' do
        expect(etransact_service).to receive(:update_term_limits).with(term_limits_param).and_return({})
        call_action
      end
      it 'raises an error if the `update_term_limits` method returns nil' do
        allow(etransact_service).to receive(:update_term_limits).with(term_limits_param).and_return(nil)
        expect{call_action}.to raise_error("There has been an error and Admin::RulesController#update_limits has encountered nil")
      end
    end
    it 'calls the `set_flash_message` method with the results from `update_term_limits` and `update_settings`' do
      term_limits_results = instance_double(Hash)
      settings_results = instance_double(Hash)
      allow(etransact_service).to receive(:update_term_limits).and_return(term_limits_results)
      allow(etransact_service).to receive(:update_settings).and_return(settings_results)
      expect(controller).to receive(:set_flash_message).with([settings_results, term_limits_results])
      call_action
    end
    it 'redirects to the `rules_term_limits_url`' do
      call_action
      expect(response).to redirect_to(rules_term_limits_url)
    end
  end

  describe 'GET advance_availability_status' do
    let(:call_action) { get :advance_availability_status }
    it_behaves_like 'a RulesController action with before_action methods'
  end

  describe 'GET advance_availability_by_term' do
    let(:sentinel) { SecureRandom.hex }
    let(:term_limit_data) { {term: described_class::VALID_TERMS.sample} }
    let(:etransact_service) { instance_double(EtransactAdvancesService, limits: [term_limit_data]) }
    let(:call_action) { get :advance_availability_by_term }

    before do
      allow(EtransactAdvancesService).to receive(:new).and_return(etransact_service)
    end

    it_behaves_like 'a RulesController action with before_action methods'
    it 'creates a new instance of EtransactAdvancesService with the request' do
      expect(EtransactAdvancesService).to receive(:new).with(request).and_return(etransact_service)
      call_action
    end
    it 'calls `limits` on the EtransactAdvancesService instance' do
      expect(etransact_service).to receive(:limits).and_return({})
      call_action
    end
    it 'raises an error if `limits` returns nil' do
      allow(etransact_service).to receive(:limits).and_return(nil)
      expect{call_action}.to raise_error('There has been an error and Admin::RulesController#advance_availability_by_term has encountered nil. Check error logs.')
    end
    describe 'view instance variables' do
      describe '`@availability_headings`' do
        let(:availability_headings) { call_action; assigns[:availability_headings]}

        it 'contains the appropriate `column_headings`' do
          expect(availability_headings[:column_headings]).to eq(['', I18n.t('dashboard.quick_advance.table.axes_labels.standard'), I18n.t('dashboard.quick_advance.table.axes_labels.securities_backed'), '', ''])
        end
        describe '`rows`' do
          let(:rows) { availability_headings[:rows] }
          it 'contains one row' do
            expect(rows.length).to eq(1)
          end
          describe '`columns`' do
            let(:columns) { rows.first[:columns]}
            it 'has a first column with a nil value' do
              expect(columns[0][:value]).to be nil
            end
            it 'has a second column with a value that is the translation for whole loans' do
              expect(columns[1][:value]).to eq(I18n.t('dashboard.quick_advance.table.whole_loan'))
            end
            it 'has a third column with a value that is the translation for agency loans' do
              expect(columns[2][:value]).to eq(I18n.t('dashboard.quick_advance.table.agency'))
            end
            it 'has a second column with a value that is the translation for aaa loans' do
              expect(columns[3][:value]).to eq(I18n.t('dashboard.quick_advance.table.aaa'))
            end
            it 'has a second column with a value that is the translation for aa loans' do
              expect(columns[4][:value]).to eq(I18n.t('dashboard.quick_advance.table.aa'))
            end
          end
        end
      end
      describe 'term instance variables' do
        let(:term_limit_data_buckets) do
          data = []
          described_class::VALID_TERMS.each do |term|
            data << {
              term: term,
              whole_loan_enabled: double('whole_loan_enabled'),
              sbc_agency_enabled: double('sbc_agency_enabled'),
              sbc_aaa_enabled: double('sbc_aaa_enabled'),
              sbc_aa_enabled: double('sbc_aa_enabled')
            }
          end
          data
        end

        before { allow(etransact_service).to receive(:limits).and_return(term_limit_data_buckets) }

        it 'raises an error if it encounters an unrecognized `:term` in one the etransact_service.limits buckets' do
          term_limit_data_buckets.first[:term] = sentinel
          expect{call_action}.to raise_error("There has been an error and Admin::RulesController#advance_availability_by_term has encountered an etransact_service.limits bucket with an invalid term: #{sentinel}")
        end

        shared_examples 'a RulesController#advance_availability_by_term instance variable term-table row' do |term_label, &context_block|
          let(:columns) { row[:columns] }
          it 'has a first column whose value is the appropriate term_label' do
            expect(columns[0][:value]).to eq(term_label)
          end
          [['second', :whole_loan_enabled], ['third', :sbc_agency_enabled], ['fourth', :sbc_aaa_enabled], ['fifth', :sbc_aa_enabled]].each_with_index do |term_data, i|
            describe "the #{term_data.first} column" do
              type = term_data.last
              let(:column) { columns[i + 1] }
              it "has a name that incorporates the term and `#{type}`" do
                expect(column[:name]).to eq("term_limits[#{bucket[:term]}][#{type.to_s}]")
              end
              it 'has a type of `checkbox`' do
                expect(column[:type]).to eq(:checkbox)
              end
              it 'has `submit_unchecked_boxes` set to true' do
                expect(column[:submit_unchecked_boxes]).to be true
              end
              it "has a checked value that is the `#{type}` value for the bucket" do
                expect(column[:checked]).to eq(bucket[type])
              end
              it 'has a label set to `true`' do
                expect(column[:label]).to eq(true)
              end
              context 'when the user can edit trade rules' do
                allow_policy :web_admin, :edit_trade_rules?
                it 'sets `disabled` to false' do
                  expect(column[:disabled]).to be false
                end
              end
              context 'when the user cannot edit trade rules' do
                deny_policy :web_admin, :edit_trade_rules?
                it 'sets `disabled` to false' do
                  expect(column[:disabled]).to be true
                end
              end
            end
          end
        end

        describe '`@vrc_availability`' do
          let(:vrc_availability) { call_action; assigns[:vrc_availability] }
          it_behaves_like 'a RulesController#advance_availability_by_term instance variable term-table row', I18n.t('admin.advance_availability.availability_by_term.open_label') do
            let(:row) { vrc_availability[:rows].first }
            let(:bucket) { term_limit_data_buckets.select{|bucket| bucket[:term] == :open}.first }
          end

          it 'has one row' do
            expect(vrc_availability[:rows].length).to eq(1)
          end
        end
        describe '`@long_term_availability`' do
          let(:long_term_availability) { call_action; assigns[:long_term_availability] }

          it "has #{described_class::LONG_FRC_TERMS.length} rows" do
            expect(long_term_availability[:rows].length).to eq(described_class::LONG_FRC_TERMS.length)
          end
          described_class::LONG_FRC_TERMS.each_with_index do |term, j|
            it_behaves_like 'a RulesController#advance_availability_by_term instance variable term-table row', I18n.t("admin.term_rules.daily_limit.dates.#{term}") do
              let(:row) { long_term_availability[:rows][j] }
              let(:bucket) { term_limit_data_buckets.select{|bucket| bucket[:term] == term}.first }
            end
          end
        end
        describe '`@frc_availability`' do
          short_term_rows = described_class::VALID_TERMS - [:open] - described_class::LONG_FRC_TERMS
          let(:frc_availability) { call_action; assigns[:frc_availability] }

          it "has #{short_term_rows.length} rows" do
            expect(frc_availability[:rows].length).to eq(short_term_rows.length)
          end
          short_term_rows.each_with_index do |term, k|
            it_behaves_like 'a RulesController#advance_availability_by_term instance variable term-table row', I18n.t("admin.term_rules.daily_limit.dates.#{term}") do
              let(:row) { frc_availability[:rows][k] }
              let(:bucket) { term_limit_data_buckets.select{|bucket| bucket[:term] == term}.first }
            end
          end
        end
      end
    end
  end

  describe 'PUT update_advance_availability_by_term' do
    allow_policy :web_admin, :edit_trade_rules?

    let(:term) { SecureRandom.hex }
    let(:type) { SecureRandom.hex }
    let(:term_limits_param) { {term => {type => false}} }
    let(:etransact_service) { instance_double(EtransactAdvancesService, update_term_limits: {})}
    let(:call_action) { put(:update_advance_availability_by_term, {term_limits: term_limits_param}) }

    before do
      allow(EtransactAdvancesService).to receive(:new).and_return(etransact_service)
      allow(controller).to receive(:set_flash_message)
    end

    it_behaves_like 'a RulesController action with before_action methods'
    it_behaves_like 'it checks the edit_trade_rules? web_admin policy'
    it 'creates a new instance of EtransactAdvancesService with the request' do
      expect(EtransactAdvancesService).to receive(:new).with(request).and_return(etransact_service)
      call_action
    end
    describe 'updating etransact limits' do
      describe 'processing the `term_limits` param' do
        describe 'when the value for a given term and type is `on`' do
          it 'sets the value for that term and type to `true`' do
            term_limits_param[term][type] = 'on'
            expect(etransact_service).to receive(:update_term_limits).with(hash_including({term => {type => true}})).and_return({})
            call_action
          end
        end
        describe 'when the value for a given term and type is not `on`' do
          it 'sets the value for that term and type to `false`' do
            term_limits_param[term][type] = 'off'
            expect(etransact_service).to receive(:update_term_limits).with(hash_including({term => {type => false}})).and_return({})
            call_action
          end
        end
      end
      it 'calls `update_term_limits` on the EtransactAdvancesService with the `term_limits` param' do
        expect(etransact_service).to receive(:update_term_limits).with(term_limits_param).and_return({})
        call_action
      end
      it 'raises an error if the `update_term_limits` method returns nil' do
        allow(etransact_service).to receive(:update_term_limits).with(term_limits_param).and_return(nil)
        expect{call_action}.to raise_error("There has been an error and Admin::RulesController#update_advance_availability_by_term has encountered nil")
      end
    end
    it 'calls the `set_flash_message` method with the results from `update_term_limits`' do
      term_limits_results = instance_double(Hash)
      allow(etransact_service).to receive(:update_term_limits).and_return(term_limits_results)
      expect(controller).to receive(:set_flash_message).with(term_limits_results)
      call_action
    end
    it 'redirects to the `rules_advance_availability_by_term_url`' do
      call_action
      expect(response).to redirect_to(rules_advance_availability_by_term_url)
    end
  end

  describe 'GET advance_availability_by_member' do
    let(:call_action) { get :advance_availability_by_member }
    let(:quick_advance_enabled) { instance_double(Array, :[] => nil, collect: nil) }
    let(:flag) { instance_double(Hash, :[] => nil) }
    let(:member_name) { SecureRandom.hex }
    let(:fhlb_id) { rand(999..99999) }
    let(:members_service) { instance_double(MembersService, quick_advance_enabled: [flag]) }
    let(:enabled) { double('enabled') }
    let(:row_hash) { instance_double(Hash, :[] => nil) }

    before do
      allow(MembersService).to receive(:new).and_return(members_service)
    end

    it 'raises an error if `MembersService.quick_advance_enabled` returns `nil`' do
      allow(members_service).to receive(:quick_advance_enabled).and_return(nil)
      expect { call_action }.to raise_error("There has been an error and Admin::RulesController#advance_availability_by_member has encountered nil")
    end

    it_behaves_like 'a RulesController action with before_action methods'

    describe 'the `@advance_availability_table`' do
      let(:advance_availability_table) { call_action; assigns[:advance_availability_table] }
      it 'sets `@advance_availability_table`' do
        expect(advance_availability_table).not_to be nil
      end
      describe 'with rows' do
        before do
          allow(MembersService).to receive(:new).with(request).and_return(members_service)
        end
        describe 'setting the rows' do
          before do
            allow(quick_advance_enabled).to receive(:collect).and_return(row_hash)
            allow(members_service).to receive(:quick_advance_enabled).and_return(quick_advance_enabled)
          end
          it 'sets the rows hash' do
            expect(advance_availability_table[:rows]).to eq(row_hash)
          end
        end
        describe 'each of which has columns' do
          context 'the first column' do
            it 'sets the first column to the `member_name`' do
              allow(flag).to receive(:[]).with('member_name').and_return(member_name)
              expect(advance_availability_table[:rows][0][:columns][0][:value]).to eq(member_name)
            end
          end
          context 'the second column' do
            it 'sets the name to `quick_advance_enabled`' do
              expect(advance_availability_table[:rows][0][:columns][1][:name]).to eq('quick_advance_enabled')
            end
            it 'sets the value to the `fhlb_id`' do
              allow(flag).to receive(:[]).with('fhlb_id').and_return(fhlb_id)
              expect(advance_availability_table[:rows][0][:columns][1][:value]).to eq(fhlb_id)
            end
            it 'sets the checked value to the `quick_advanced_enabled` flag value' do
              allow(flag).to receive(:[]).with('quick_advance_enabled').and_return(enabled)
              expect(advance_availability_table[:rows][0][:columns][1][:checked]).to eq(enabled)
            end
            it 'sets the type to `:checkbox`' do
              expect(advance_availability_table[:rows][0][:columns][1][:type]).to eq(:checkbox)
            end
          end
        end
      end
    end
  end

  describe 'GET rate_bands' do
    let(:sentinel) { SecureRandom.hex }
    let(:term) { described_class::VALID_TERMS.sample }
    let(:rate_bands) {{
      term => {'LOW_BAND_OFF_BP' => double('LOW_BAND_OFF_BP', to_i: nil),
      'LOW_BAND_WARN_BP' => double('LOW_BAND_WARN_BP', to_i: nil),
      'HIGH_BAND_WARN_BP' => double('HIGH_BAND_WARN_BP', to_i: nil),
      'HIGH_BAND_OFF_BP' => double('HIGH_BAND_OFF_BP', to_i: nil)}
    }}
    let(:rates_service) { instance_double(RatesService, rate_bands: rate_bands)}
    let(:call_action) { get :rate_bands }

    before do
      allow(RatesService).to receive(:new).with(request).and_return(rates_service)
    end

    it_behaves_like 'a RulesController action with before_action methods'
    it 'creates a new instance of the RatesService with the request' do
      expect(RatesService).to receive(:new).with(request).and_return(rates_service)
      call_action
    end
    it 'calls `rate_bands` on the instance of RatesService' do
      expect(rates_service).to receive(:rate_bands).and_return(rate_bands)
      call_action
    end
    it 'raises an error if `rate_bands` returns nil' do
      allow(rates_service).to receive(:rate_bands).and_return(nil)
      expect{call_action}.to raise_error('There has been an error and Admin::RulesController#rate_bands has encountered nil')
    end
    describe '`@rate_bands`' do
      let(:rate_band_var) { call_action; assigns[:rate_bands] }
      describe 'column_headings' do
        let(:translated_string) { double('translation') }
        before { allow(controller).to receive(:t).and_call_original }
        it 'contains the proper translations for the column headings' do
          expect(rate_band_var[:column_headings]).to eq(
            ['', I18n.t('admin.term_rules.rate_bands.low_shutdown_html'), I18n.t('admin.term_rules.rate_bands.low_warning_html'),
             I18n.t('admin.term_rules.rate_bands.high_warning_html'), I18n.t('admin.term_rules.rate_bands.high_shutdown_html')]
          )
        end
        ['low_shutdown_html', 'low_warning_html', 'high_warning_html', 'high_shutdown_html'].each do |translation|
          it "ensures the translation for `#{translation}` is html safe" do
            allow(controller).to receive(:t).with("admin.term_rules.rate_bands.#{translation}").and_return(translated_string)
            expect(translated_string).to receive(:html_safe)
            call_action
          end
        end
      end
      it 'raises an error if it encounters an unrecognized `:term` in one of the rates_service.rate_bands keys' do
        rate_bands[sentinel] = {}
        expect{rate_band_var}.to raise_error("There has been an error and Admin::RulesController#rate_bands has encountered a RatesService.rate_bands bucket with an invalid term: #{sentinel}")
      end
      it 'ignores rate_band info for the `overnight` term' do
        rate_bands['overnight'] = {}
        expect(rate_band_var[:rows].length).to eq(1)
      end
      describe 'rows' do
        let(:rate_bands) do
          data = {}
          described_class::VALID_TERMS.each do |term|
            data[term] = {'LOW_BAND_OFF_BP' => double('LOW_BAND_OFF_BP', to_i: nil),
                          'LOW_BAND_WARN_BP' => double('LOW_BAND_WARN_BP', to_i: nil),
                          'HIGH_BAND_WARN_BP' => double('HIGH_BAND_WARN_BP', to_i: nil),
                          'HIGH_BAND_OFF_BP' => double('HIGH_BAND_OFF_BP', to_i: nil)}
          end
          data
        end
        before { allow(rates_service).to receive(:rate_bands).and_return(rate_bands) }
        it 'contains as many rows as rates_service.rate_bands keys' do
          expect(rate_band_var[:rows].length).to eq(rate_bands.keys.length)
        end
        described_class::VALID_TERMS.each_with_index do |term, i|
          describe "the `#{term}` term row" do
            let(:term_row) { rate_band_var[:rows][i] }

            it "has a first column value with the correct translation for the `#{term}` term" do
              translation = term == 'open' ? 'admin.term_rules.daily_limit.dates.open' : "dashboard.quick_advance.table.axes_labels.#{term}"
              expect(term_row[:columns][0][:value]).to eq(I18n.t(translation))
            end
            describe 'the second column' do
              it_behaves_like 'a RulesController action with before_action methods',  "rate_bands[#{term}][LOW_BAND_OFF_BP]" do
                let(:column) { term_row[:columns][1] }
              end
              it 'has a `value` that is the result of calling `to_i` on the bucket\'s `LOW_BAND_OFF_BP`' do
                allow(rate_bands[term]['LOW_BAND_OFF_BP']).to receive(:to_i).and_return(sentinel)
                expect(term_row[:columns][1][:value]).to eq(sentinel)
              end
            end
            describe 'the third column' do
              it_behaves_like 'a RulesController action with before_action methods',  "rate_bands[#{term}][LOW_BAND_WARN_BP]" do
                let(:column) { term_row[:columns][2] }
              end
              it 'has a `value` that is the result of calling `to_i` on the bucket\'s `LOW_BAND_WARN_BP`' do
                allow(rate_bands[term]['LOW_BAND_WARN_BP']).to receive(:to_i).and_return(sentinel)
                expect(term_row[:columns][2][:value]).to eq(sentinel)
              end
            end
            describe 'the fourth column' do
              it_behaves_like 'a RulesController action with before_action methods',  "rate_bands[#{term}][HIGH_BAND_WARN_BP]" do
                let(:column) { term_row[:columns][3] }
              end
              it 'has a `value` that is the result of calling `to_i` on the bucket\'s `HIGH_BAND_WARN_BP`' do
                allow(rate_bands[term]['HIGH_BAND_WARN_BP']).to receive(:to_i).and_return(sentinel)
                expect(term_row[:columns][3][:value]).to eq(sentinel)
              end
            end
            describe 'the fifth column' do
              it_behaves_like 'a RulesController action with before_action methods',  "rate_bands[#{term}][HIGH_BAND_OFF_BP]" do
                let(:column) { term_row[:columns][4] }
              end
              it 'has a `value` that is the result of calling `to_i` on the bucket\'s `HIGH_BAND_OFF_BP`' do
                allow(rate_bands[term]['HIGH_BAND_OFF_BP']).to receive(:to_i).and_return(sentinel)
                expect(term_row[:columns][4][:value]).to eq(sentinel)
              end
            end
          end
        end
      end
    end
  end

  describe 'PUT update_rate_bands' do
    allow_policy :web_admin, :edit_trade_rules?

    let(:rate_bands_param) { {SecureRandom.hex => 'some value'} }
    let(:rates_service) { instance_double(RatesService, update_rate_bands: {}) }
    let(:call_action) { put(:update_rate_bands, {rate_bands: rate_bands_param}) }

    before do
      allow(RatesService).to receive(:new).and_return(rates_service)
      allow(controller).to receive(:set_flash_message)
    end

    it_behaves_like 'a RulesController action with before_action methods'
    it_behaves_like 'it checks the edit_trade_rules? web_admin policy'
    it 'creates a new instance of RatesService with the request' do
      expect(RatesService).to receive(:new).with(request).and_return(rates_service)
      call_action
    end
    describe 'updating the rate bands' do
      it 'calls `update_rate_bands` on the RatesService with the `rate_bands` param' do
        expect(rates_service).to receive(:update_rate_bands).with(rate_bands_param).and_return({})
        call_action
      end
      it 'raises an error if the `update_term_limits` method returns nil' do
        allow(rates_service).to receive(:update_rate_bands).with(rate_bands_param).and_return(nil)
        expect{call_action}.to raise_error("There has been an error and Admin::RulesController#update_rate_bands has encountered nil")
      end
    end
    it 'calls the `set_flash_message` method with the results from `update_rate_bands`' do
      rate_bands_results = instance_double(Hash)
      allow(rates_service).to receive(:update_rate_bands).and_return(rate_bands_results)
      expect(controller).to receive(:set_flash_message).with(rate_bands_results)
      call_action
    end
    it 'redirects to the `rules_rate_bands_url`' do
      call_action
      expect(response).to redirect_to(rules_rate_bands_url)
    end
  end

  describe 'GET rate_report' do
    let(:sentinel) { SecureRandom.hex }
    let(:type) { SecureRandom.hex }
    let(:build_advance_type_info) do
      Proc.new do |advance_type|
        {
          advance_type => {
            start_of_day_rate: instance_double(Float, to_f: nil),
            rate: instance_double(Float, to_f: nil),
            rate_change_bps: instance_double(Float),
            rate_band_info: {
              low_band_off_rate: instance_double(Float, to_f: nil),
              low_band_warn_rate: instance_double(Float, to_f: nil),
              high_band_warn_rate: instance_double(Float, to_f: nil),
              high_band_off_rate: instance_double(Float, to_f: nil)
            }
          }
        }
      end
    end
    let(:open_rate) {{
      open: build_advance_type_info.call(type)
    }}
    let(:overnight_rate) {{
      overnight: build_advance_type_info.call(type)
    }}
    let(:term) { SecureRandom.hex }
    let(:other_term_rate) {{
      term => build_advance_type_info.call(type)
    }}
    let(:rates_service) { instance_double(RatesService, quick_advance_rates: {}) }
    let(:call_action) { get :rate_report }

    before do
      allow(RatesService).to receive(:new).and_return(rates_service)
      allow(controller).to receive(:process_rate_summary).and_return({})
    end

    it_behaves_like 'a RulesController action with before_action methods'
    it 'creates a new instance of RatesService with the request' do
      expect(RatesService).to receive(:new).with(request).and_return(rates_service)
      call_action
    end
    it 'calls `quick_advance_rates` on the RatesService instance with `:admin` as the member id' do
      expect(rates_service).to receive(:quick_advance_rates).with(:admin).and_return({})
      call_action
    end
    it 'raises an error if `quick_advance_rates` returns nil' do
      allow(rates_service).to receive(:quick_advance_rates).and_return(nil)
      expect{call_action}.to raise_error('There has been an error and Admin::RulesController#rate_report has encountered nil')
    end
    it 'calls `process_rate_summary` with the result of `quick_advance_rates`' do
      raw_rates = instance_double(Hash)
      allow(rates_service).to receive(:quick_advance_rates).and_return(raw_rates)
      expect(controller).to receive(:process_rate_summary).with(raw_rates).and_return({})
      call_action
    end
    shared_examples 'a `rate_report` view instance variable with `column_headings`' do |instance_variable_name|
      let(:translation) { instance_double(String, html_safe: nil) }
      before do
        allow(controller).to receive(:fhlb_add_unit_to_table_header).and_call_original
      end

      threshold_columns = {'low_off' => '%', 'low_warn' => '%', 'high_warn' => '%', 'high_off' => '%'}
      ({'opening_rate' => '%', 'current_rate' => '%', 'change' => 'bps'}.merge(threshold_columns)).each do |header, unit|
        it "calls `fhlb_add_unit_to_table_header` with the translation for `#{header}` and `#{unit}` as arguments" do
          expect(controller).to receive(:fhlb_add_unit_to_table_header).with(I18n.t("admin.term_rules.rate_report.#{header}"), unit)
          call_action
        end
      end
      threshold_columns.each do |header, unit|
        it "calls `html_safe` on the translation for `#{header}`" do
          allow(controller).to receive(:t).with("admin.term_rules.rate_report.#{header}").and_return(translation)
          expect(translation).to receive(:html_safe).and_return('')
          call_action
        end
      end
      it "returns the proper column_headings data for the `#{instance_variable_name}` view variable" do
        call_action
        expect(assigns[instance_variable_name][:column_headings]).to eq(['', '',
          fhlb_add_unit_to_table_header(I18n.t('admin.term_rules.rate_report.opening_rate'), '%'),
          fhlb_add_unit_to_table_header(I18n.t('admin.term_rules.rate_report.current_rate'), '%'),
          fhlb_add_unit_to_table_header(I18n.t('admin.term_rules.rate_report.change'), 'bps'),
          fhlb_add_unit_to_table_header(I18n.t('admin.term_rules.rate_report.low_off'), '%'),
          fhlb_add_unit_to_table_header(I18n.t('admin.term_rules.rate_report.low_warn'), '%'),
          fhlb_add_unit_to_table_header(I18n.t('admin.term_rules.rate_report.high_warn'), '%'),
          fhlb_add_unit_to_table_header(I18n.t('admin.term_rules.rate_report.high_off'), '%')
         ])
      end
    end
    describe 'instance view variables' do
      let(:rate_info) { open_rate.merge(overnight_rate).merge(other_term_rate).with_indifferent_access }
      before do
        allow(controller).to receive(:t).and_call_original
        allow(controller).to receive(:t).with("dashboard.quick_advance.table.axes_labels.#{term}").and_return('')
        allow(controller).to receive(:t).with("dashboard.quick_advance.table.#{type}").and_return('')
        allow(controller).to receive(:process_rate_summary).and_return(rate_info)
      end
      shared_examples 'a rate_report instance variable with rate columns' do |&context_block|
        describe 'the first column' do
          it 'has a `value` that is nil' do
            expect(columns[0][:value]).to eq(nil)
          end
        end
        describe 'the third column' do
          let(:column) { columns[2] }
          it 'calls `to_f` on the `start_of_day_rate`' do
            expect(rate_info[term][type][:start_of_day_rate]).to receive(:to_f)
            call_action
          end
          it 'sets the `value` to the float version of `start_of_day_rate`' do
            allow(rate_info[term][type][:start_of_day_rate]).to receive(:to_f).and_return(sentinel)
            expect(column[:value]).to eq(sentinel)
          end
          it 'sets the `type` to `:rate`' do
            expect(column[:type]).to eq(:rate)
          end
        end
        describe 'the fourth column' do
          let(:column) { columns[3] }
          it 'calls `to_f` on the `rate`' do
            expect(rate_info[term][type][:rate]).to receive(:to_f)
            call_action
          end
          it 'sets the `value` to the float version of `rate`' do
            allow(rate_info[term][type][:rate]).to receive(:to_f).and_return(sentinel)
            expect(column[:value]).to eq(sentinel)
          end
          it 'sets the `type` to `:rate`' do
            expect(column[:type]).to eq(:rate)
          end
        end
        describe 'the fifth column' do
          let(:column) { columns[4] }
          it 'sets the `value` to `rate_change_bps`' do
            expect(column[:value]).to eq(rate_info[term][type][:rate_change_bps])
          end
          it 'sets the `type` to `:basis_point`' do
            expect(column[:type]).to eq(:basis_point)
          end
        end
        describe 'the sixth column' do
          let(:column) { columns[5] }
          it 'calls `to_f` on the `[:rate_band_info][:low_band_off_rate]`' do
            expect(rate_info[term][type][:rate_band_info][:low_band_off_rate]).to receive(:to_f)
            call_action
          end
          it 'sets the `value` to the float version of `[:rate_band_info][:low_band_off_rate]`' do
            allow(rate_info[term][type][:rate_band_info][:low_band_off_rate]).to receive(:to_f).and_return(sentinel)
            expect(column[:value]).to eq(sentinel)
          end
          it 'sets the `type` to `:rate`' do
            expect(column[:type]).to eq(:rate)
          end
        end
        describe 'the seventh column' do
          let(:column) { columns[6] }
          it 'calls `to_f` on the `[:rate_band_info][:low_band_warn_rate]`' do
            expect(rate_info[term][type][:rate_band_info][:low_band_warn_rate]).to receive(:to_f)
            call_action
          end
          it 'sets the `value` to the float version of `[:rate_band_info][:low_band_warn_rate]`' do
            allow(rate_info[term][type][:rate_band_info][:low_band_warn_rate]).to receive(:to_f).and_return(sentinel)
            expect(column[:value]).to eq(sentinel)
          end
          it 'sets the `type` to `:rate`' do
            expect(column[:type]).to eq(:rate)
          end
        end
        describe 'the eighth column' do
          let(:column) { columns[7] }
          it 'calls `to_f` on the `[:rate_band_info][:high_band_warn_rate]`' do
            expect(rate_info[term][type][:rate_band_info][:high_band_warn_rate]).to receive(:to_f)
            call_action
          end
          it 'sets the `value` to the float version of `[:rate_band_info][:high_band_warn_rate]`' do
            allow(rate_info[term][type][:rate_band_info][:high_band_warn_rate]).to receive(:to_f).and_return(sentinel)
            expect(column[:value]).to eq(sentinel)
          end
          it 'sets the `type` to `:rate`' do
            expect(column[:type]).to eq(:rate)
          end
        end
        describe 'the ninth column' do
          let(:column) { columns[8] }
          it 'calls `to_f` on the `[:rate_band_info][:high_band_off_rate]`' do
            expect(rate_info[term][type][:rate_band_info][:high_band_off_rate]).to receive(:to_f)
            call_action
          end
          it 'sets the `value` to the float version of `[:rate_band_info][:high_band_off_rate]`' do
            allow(rate_info[term][type][:rate_band_info][:high_band_off_rate]).to receive(:to_f).and_return(sentinel)
            expect(column[:value]).to eq(sentinel)
          end
          it 'sets the `type` to `:rate`' do
            expect(column[:type]).to eq(:rate)
          end
        end
      end
      describe '`@vrc_rate_report`' do
        let(:vrc_rate_report_rows) { call_action; assigns[:vrc_rate_report][:rows] }
        it_behaves_like 'a `rate_report` view instance variable with `column_headings`', :vrc_rate_report

        describe '`rows`' do
          it 'contains a row for each advance type found under the `open` advance term key' do
            open_rates = {open: {}}
            n = rand(2..5)
            n.times do |i|
              open_rates[:open] = open_rates[:open].merge(build_advance_type_info.call(i))
            end
            allow(controller).to receive(:process_rate_summary).and_return(open_rates.merge(overnight_rate).merge(other_term_rate).with_indifferent_access)
            expect(vrc_rate_report_rows.length).to eq(n)
          end
        end
        describe 'columns' do
          it_behaves_like 'a rate_report instance variable with rate columns' do
            let(:columns) { vrc_rate_report_rows[0][:columns] }
            let(:term) { :open }
          end
          describe 'the second column' do
            it 'has a value that combines the translation for `open` with the translation for the given type' do
              allow(controller).to receive(:t).with("dashboard.quick_advance.table.#{type}").and_return(sentinel)
              expect(vrc_rate_report_rows[0][:columns][1][:value]).to eq(I18n.t('admin.term_rules.daily_limit.dates.open') + ': ' + sentinel)
            end
          end
        end
      end
      describe '`@frc_rate_report`' do
        let(:frc_rate_report_rows) { call_action; assigns[:frc_rate_report][:rows] }
        it_behaves_like 'a `rate_report` view instance variable with `column_headings`', :frc_rate_report

        describe '`rows`' do
          it 'ignores rate info for `open` and `overnight` terms' do
            expect(frc_rate_report_rows.length).to eq(1)
          end
          it 'contains a rows for each advance type found under term keys that are not `open` or `overnight`' do
            other_term_rates = {}
            n_terms = rand(2..5)
            n_types = rand(1..3)
            n_terms.times do
              term_key = SecureRandom.hex
              other_term_rates[term_key] = {}
              n_types.times do |i|
                other_term_rates[term_key] = other_term_rates[term_key].merge(build_advance_type_info.call(i))
              end
            end
            allow(controller).to receive(:process_rate_summary).and_return(open_rate.merge(overnight_rate).merge(other_term_rates).with_indifferent_access)
            expect(frc_rate_report_rows.length).to eq(n_terms * n_types)
          end
          describe 'columns' do
            it_behaves_like 'a rate_report instance variable with rate columns' do
              let(:columns) { frc_rate_report_rows[0][:columns] }
            end
            describe 'the second column' do
              let(:term_translation) { SecureRandom.hex }
              let(:type_translation) { SecureRandom.hex }
              it 'has a value that combines the translation for the term with the translation for the given type' do
                allow(controller).to receive(:t).with("dashboard.quick_advance.table.axes_labels.#{term}").and_return(term_translation)
                allow(controller).to receive(:t).with("dashboard.quick_advance.table.#{type}").and_return(type_translation)
                expect(frc_rate_report_rows[0][:columns][1][:value]).to eq(term_translation + ': ' + type_translation)
              end
            end
          end
        end
      end
    end
  end

  describe 'GET term_details' do
    let(:term_details_data) {{
      term: described_class::VALID_TERMS.sample,
      low_days_to_maturity: double('low days to maturity', to_i: nil),
      high_days_to_maturity: double('high days to maturity', to_i: nil)
    }}
    let(:etransact_service) { instance_double(EtransactAdvancesService, limits: [term_details_data] ) }
    let(:sentinel) { SecureRandom.hex }
    let(:call_action) { get :term_details }
    before do
      allow(EtransactAdvancesService).to receive(:new).and_return(etransact_service)
    end
    it_behaves_like 'a RulesController action with before_action methods'
    it 'creates a new instance of EtransactAdvancesService with the request' do
      expect(EtransactAdvancesService).to receive(:new).with(request).and_return(etransact_service)
      call_action
    end
    it 'calls `limits` on the EtransactAdvancesService' do
      expect(etransact_service).to receive(:limits).and_return({})
      call_action
    end
    it 'raises an error if EtransactAdvancesService#limits returns nil' do
      allow(etransact_service).to receive(:limits).and_return(nil)
      expect{call_action}.to raise_error('There has been an error and EtransactAdvancesService#limits has encountered nil. Check error logs.')
    end

    describe '`@term_details`' do
      let(:term_details) { call_action; assigns[:term_details] }
      before { allow(controller).to receive(:t).and_call_original }
      describe 'column_headings' do
        it 'contains the proper column_headings' do
          low_days_heading = I18n.t('admin.term_rules.term_details.low_days_to_maturity')
          high_days_heading = I18n.t('admin.term_rules.term_details.high_days_to_maturity')
          expect(term_details[:column_headings]).to eq(['', low_days_heading, high_days_heading])
        end
      end
      it 'raises an error if it encounters an unrecognized `:term` in one the etransact_service.limits buckets' do
        term_details_data[:term] = sentinel
        expect{term_details}.to raise_error("There has been an error and Admin::RulesController#term_details has encountered an etransact_service.limits bucket with an invalid term: #{sentinel}")
      end
      describe 'rows' do
        let(:term_details_data_buckets) do
          data = []
          described_class::VALID_TERMS.each do |term|
            data << {
              term: term,
              low_days_to_maturity: instance_double(Integer, to_i: nil),
              high_days_to_maturity: instance_double(Integer, to_i: nil)
            }
          end
          data
        end
        before { allow(etransact_service).to receive(:limits).and_return(term_details_data_buckets) }
        it 'contains as many rows as etransact_service.limits buckets' do
          expect(term_details[:rows].length).to eq(term_details_data_buckets.length)
        end
        described_class::VALID_TERMS.each_with_index do |term, i|
          describe "the `#{term}` term row" do
            let(:term_row) { term_details[:rows][i] }
            it "has a first column value with the correct translation for the `#{term}` term" do
              expect(term_row[:columns][0][:value]).to eq(I18n.t("admin.term_rules.daily_limit.dates.#{term}"))
            end
            describe 'the second column' do
              it 'has a `value_type` of :number' do
                expect(term_row[:columns][1][:type]).to eq(:number)
              end
              it 'has a `value` that is the result of calling `to_i` on the bucket\'s `low_days_to_maturity`' do
                allow(term_details_data_buckets[i][:low_days_to_maturity]).to receive(:to_i).and_return(sentinel)
                expect(term_row[:columns][1][:value]).to eq(sentinel)
              end
            end
            describe 'the third column' do
              it 'has a `value_type` of :number' do
                expect(term_row[:columns][2][:type]).to eq(:number)
              end
              it 'has a `value` that is the result of calling `to_i` on the bucket\'s `term_daily_limit`' do
                allow(term_details_data_buckets[i][:high_days_to_maturity]).to receive(:to_i).and_return(sentinel)
                expect(term_row[:columns][2][:value]).to eq(sentinel)
              end
             end
           end
         end
       end
     end
   end

  describe 'private methods' do
    describe '`set_flash_message`' do
      let(:result) { {} }
      let(:result_with_errors) {{error: double('some error')}}
      context 'when a single result set is passed' do
        it 'sets the `flash[:error]` message if the result set contains an error message' do
          subject.send(:set_flash_message, result_with_errors)
          expect(flash[:error]).to eq(I18n.t('admin.term_rules.messages.error'))
        end
        it 'sets the `flash[:notice] message` if the result set does not contain an error message' do
          subject.send(:set_flash_message, result)
          expect(flash[:notice]).to eq(I18n.t('admin.term_rules.messages.success'))
        end
      end
      context 'when multiple result sets are passed' do
        it 'sets the `flash[:error]` message if any of the passed result sets contains an error message' do
          subject.send(:set_flash_message, [result, result_with_errors, result])
          expect(flash[:error]).to eq(I18n.t('admin.term_rules.messages.error'))
        end
        it 'sets the `flash[:notice] message` if none of the result sets contain an error message' do
          subject.send(:set_flash_message, [result, result, result])
          expect(flash[:notice]).to eq(I18n.t('admin.term_rules.messages.success'))
        end
      end
    end

    describe '`process_rate_summary`' do
      let(:type_1) { SecureRandom.hex }
      let(:type_2) { SecureRandom.hex }
      let(:term_1) { SecureRandom.hex }
      let(:term_2) { SecureRandom.hex }
      let(:term_1_type_1_info) { instance_double(Hash) }
      let(:term_1_type_2_info) { instance_double(Hash) }
      let(:term_2_type_1_info) { instance_double(Hash) }
      let(:term_2_type_2_info) { instance_double(Hash) }
      let(:rate_summary) {{
        'timestamp' => instance_double(DateTime),
        type_1 => {
          term_1 => instance_double(Hash, with_indifferent_access: term_1_type_1_info),
          term_2 => instance_double(Hash, with_indifferent_access: term_2_type_1_info)
        },
        type_2 => {
          term_1 => instance_double(Hash, with_indifferent_access: term_1_type_2_info),
          term_2 => instance_double(Hash, with_indifferent_access: term_2_type_2_info)
        }
      }}
      let(:call_method) { subject.send(:process_rate_summary, rate_summary)}

      it 'does not include the `timestamp` key in the returned hash' do
        expect(call_method.keys).not_to include('timestamp')
      end
      it 'organizes the hash by term at the top level, then by type' do
        expect(call_method).to eq({
          term_1 => {
            type_1 => term_1_type_1_info,
            type_2 => term_1_type_2_info
          },
          term_2 => {
            type_1 => term_2_type_1_info,
            type_2 => term_2_type_2_info
          }
        })
      end
    end
  end
end