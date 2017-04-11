require 'rails_helper'

RSpec.describe Admin::RulesController, :type => :controller do
  login_user(admin: true)
  it_behaves_like 'an admin controller'

  RSpec.shared_examples 'a RulesController action with before_action methods' do
    it 'sets the active nav to :rules' do
      expect(controller).to receive(:set_active_nav).with(:rules)
      call_action
    end
  end

  describe 'GET limits' do
    let(:global_limit_data) {{
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
          it 'has a `value` of the global_limit_data[:shareholder_total_daily_limit]' do
            expect(per_member_row[:columns][1][:value]).to eq(global_limit_data[:shareholder_total_daily_limit])
          end
          it 'has a `type` of :number' do
            expect(per_member_row[:columns][1][:type]).to eq(:number)
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
          it 'has a `value` of the global_limit_data[:shareholder_web_daily_limit]' do
            expect(all_member_row[:columns][1][:value]).to eq(global_limit_data[:shareholder_web_daily_limit])
          end
          it 'has a `type` of :number' do
            expect(all_member_row[:columns][1][:type]).to eq(:number)
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
              it 'has a `value` that is the result of calling `to_i` on the bucket\'s `min_online_advance`' do
                allow(term_limit_data_buckets[i][:min_online_advance]).to receive(:to_i).and_return(sentinel)
                expect(term_row[:columns][1][:value]).to eq(sentinel)
              end
              it 'has a type of :number' do
                expect(term_row[:columns][1][:type]).to eq(:number)
              end
            end
            describe 'the third column' do
              it 'has a `value` that is the result of calling `to_i` on the bucket\'s `term_daily_limit`' do
                allow(term_limit_data_buckets[i][:term_daily_limit]).to receive(:to_i).and_return(sentinel)
                expect(term_row[:columns][2][:value]).to eq(sentinel)
              end
              it 'has a type of :number' do
                expect(term_row[:columns][2][:type]).to eq(:number)
              end
            end
          end
        end
      end
    end
  end
end