require 'rails_helper'

describe ReportsHelper do
  let(:missing_data_message) { double('missing data message', html_safe: nil)}
  { report_summary_with_date: [:date, 'report-summary-date'],
    securities_services_line_item: [:number, 'securities-services-line-item-number'] }.each do |method, arguments|
    describe "`#{method.to_s}`" do
      let(:i18n_string) { double('an I18n key') }
      let(:span_val) { double('a value string') }
      let(:other_arg_hash) { double('an argument hash') }
      let(:response) { double('the interpolated string', html_safe: nil)}
      let(:call_method) { helper.send(method, i18n_string, span_val) }

      before { allow(I18n).to receive(:t).and_return(response) }

      it 'calls `translation_with_span` with the `i18n` string it was passed' do
        expect(helper).to receive(:translation_with_span).with(i18n_string, anything, anything, anything, anything, anything )
        call_method
      end
      it "calls `translation_with_span` with `#{arguments.first}` as the `span_key` arg" do
        expect(helper).to receive(:translation_with_span).with(anything, arguments.first, anything, anything, anything, anything )
        call_method
      end
      it 'calls `translation_with_span` with the span_value it was passed as the `span_value` arg' do
        expect(helper).to receive(:translation_with_span).with(anything, anything, span_val, anything, anything, anything )
        call_method
      end
      it "calls `translation_with_span` with `#{arguments.last}` as the `klass` arg" do
        expect(helper).to receive(:translation_with_span).with(anything, anything, anything, arguments.last, anything, anything )
        call_method
      end
      it 'calls `translation_with_span` with any other substitutions it was given as the `subs` arg' do
        expect(helper).to receive(:translation_with_span).with(anything, anything, anything, anything, anything, anything )
        helper.send(method, i18n_string, span_val, substitutions: other_arg_hash)
      end
      it 'calls `translation_with_span` with an empty hash for the `subs` arg if it was not passed any substitutions' do
        expect(helper).to receive(:translation_with_span).with(anything, anything, anything, anything, {}, anything )
        call_method
      end
      it 'calls `translation_with_span` with a `missing_data_message` if supplied' do
        expect(helper).to receive(:translation_with_span).with(anything, anything, anything, anything, {}, missing_data_message )
        helper.send(method, i18n_string, span_val, substitutions: {}, missing_data_message: missing_data_message)
      end
    end
  end

  describe '`sanitize_profile_if_endpoints_disabled` private method' do
    [:total_financing_available, :sta_balance, :total, :remaining, :capital_stock, :total].each do |attr|
      let(attr) { double(attr.to_s) }
    end
    let(:profile) do
      {
        member_id: member_id,
        total_financing_available: total_financing_available,
        sta_balance: sta_balance,
        credit_outstanding: {total: total},
        collateral_borrowing_capacity: {
          remaining: remaining,
          total: double(Integer),
          standard: {
            remaining: double(Integer),
            total: double(Integer)
          },
          sbc: {
            total_borrowing: double(Integer),
            remaining_borrowing: double(Integer),
            total_market: double(Integer),
            remaining_market: double(Integer),
            aa: {
              total: double(Integer),
              remaining: double(Integer),
              total_market: double(Integer),
              remaining_market: double(Integer)
            },
            aaa: {
              total: double(Integer),
              remaining: double(Integer),
              total_market: double(Integer),
              remaining_market: double(Integer)
            },
            agency: {
              total: double(Integer),
              remaining: double(Integer),
              total_market: double(Integer),
              remaining_market: double(Integer)
            }
          }
        },
        capital_stock: capital_stock
      }
    end
    let(:empty_profile) { {credit_outstanding: {}, collateral_borrowing_capacity: {}} }
    let(:member_id) { double('member id') }
    let(:call_method) { helper.send(:sanitize_profile_if_endpoints_disabled, profile) }

    before do
      allow_any_instance_of(MembersService).to receive(:report_disabled?)
    end

    it 'returns `{credit_outstanding: {}, collateral_borrowing_capacity: {}}` if nil is passed in' do
      expect(helper.send(:sanitize_profile_if_endpoints_disabled, nil)).to eq(empty_profile)
    end
    it 'returns `{credit_outstanding: {}, collateral_borrowing_capacity: {}}` if an empty hash is passed in' do
      expect(helper.send(:sanitize_profile_if_endpoints_disabled, {})).to eq(empty_profile)
    end
    [:total_financing_available, :sta_balance, :capital_stock, [:credit_outstanding, :total], [:collateral_borrowing_capacity, :remaining]].each do |attr|
      if attr.is_a?(Symbol)
        it "returns the original value of `#{attr}` if no flag is set" do
          expect(call_method[attr]).to eq(send(attr))
        end
      else
        it "returns the original value of `[#{attr.first}][#{attr.last}]` if no flag is set" do
          expect(call_method[attr.first][attr.last]).to eq(send(attr.last))
        end
      end
    end
    it 'sets the `total_financing_available` to nil if the MembersService::FINANCING_AVAILABLE_DATA flag is set' do
      allow_any_instance_of(MembersService).to receive(:report_disabled?).with(member_id, [MembersService::FINANCING_AVAILABLE_DATA]).and_return(true)
      expect(call_method[:total_financing_available]).to be_nil
    end
    it 'sets the `sta_balance` to nil if the MembersService::STA_BALANCE_AND_RATE_DATA flag is set' do
      allow_any_instance_of(MembersService).to receive(:report_disabled?).with(member_id, array_including(MembersService::STA_BALANCE_AND_RATE_DATA)).and_return(true)
      expect(call_method[:sta_balance]).to be_nil
    end
    it 'sets the `sta_balance` to nil if the MembersService::STA_DETAIL_DATA flag is set' do
      allow_any_instance_of(MembersService).to receive(:report_disabled?).with(member_id, array_including(MembersService::STA_DETAIL_DATA)).and_return(true)
      expect(call_method[:sta_balance]).to be_nil
    end
    it 'sets the `credit_outstanding.total` to nil if the MembersService::CREDIT_OUTSTANDING_DATA flag is set' do
      allow_any_instance_of(MembersService).to receive(:report_disabled?).with(member_id, [MembersService::CREDIT_OUTSTANDING_DATA]).and_return(true)
      expect(call_method[:credit_outstanding][:total]).to be_nil
    end
    it 'sets the `capital_stock` to nil if the MembersService::FHLB_STOCK_DATA flag is set' do
      allow_any_instance_of(MembersService).to receive(:report_disabled?).with(member_id, [MembersService::FHLB_STOCK_DATA]).and_return(true)
      expect(call_method[:capital_stock]).to be_nil
    end
    describe 'the MembersService::COLLATERAL_HIGHLIGHTS_DATA flag is set' do
      before { allow_any_instance_of(MembersService).to receive(:report_disabled?).with(member_id, [MembersService::COLLATERAL_HIGHLIGHTS_DATA]).and_return(true) }
      it 'sets the `collateral_borrowing_capacity.total` to nil' do
        expect(call_method[:collateral_borrowing_capacity][:total]).to be_nil
      end
      it 'sets the `collateral_borrowing_capacity.remaining` to nil' do
        expect(call_method[:collateral_borrowing_capacity][:remaining]).to be_nil
      end
      it 'sets the `collateral_borrowing_capacity.standard.total` to nil' do
        expect(call_method[:collateral_borrowing_capacity][:standard][:total]).to be_nil
      end
      it 'sets the `collateral_borrowing_capacity.standard.remaining` to nil' do
        expect(call_method[:collateral_borrowing_capacity][:standard][:remaining]).to be_nil
      end
      it 'sets the `collateral_borrowing_capacity.sbc.total_borrowing` to nil' do
        expect(call_method[:collateral_borrowing_capacity][:sbc][:remaining_borrowing]).to be_nil
      end
      it 'sets the `collateral_borrowing_capacity.sbc.remaining_borrowing` to nil' do
        expect(call_method[:collateral_borrowing_capacity][:sbc][:remaining_borrowing]).to be_nil
      end
      it 'sets the `collateral_borrowing_capacity.sbc.total_market` to nil' do
        expect(call_method[:collateral_borrowing_capacity][:sbc][:total_market]).to be_nil
      end
      it 'sets the `collateral_borrowing_capacity.sbc.remaining_market` to nil' do
        expect(call_method[:collateral_borrowing_capacity][:sbc][:remaining_market]).to be_nil
      end
      [:aa, :aaa, :agency].each do |collateral_type|
        it "sets the `collateral_borrowing_capacity.sbc.#{collateral_type}.total` to nil" do
          expect(call_method[:collateral_borrowing_capacity][:sbc][collateral_type][:total]).to be_nil
        end
        it "sets the `collateral_borrowing_capacity.sbc.#{collateral_type}.remaining` to nil" do
          expect(call_method[:collateral_borrowing_capacity][:sbc][collateral_type][:remaining]).to be_nil
        end
        it "sets the `collateral_borrowing_capacity.sbc.#{collateral_type}.total_market` to nil" do
          expect(call_method[:collateral_borrowing_capacity][:sbc][collateral_type][:total_market]).to be_nil
        end
        it "sets the `collateral_borrowing_capacity.sbc.#{collateral_type}.remaining_market` to nil" do
          expect(call_method[:collateral_borrowing_capacity][:sbc][collateral_type][:remaining_market]).to be_nil
        end
      end
    end
  end

  describe 'the `translation_with_span` private method' do
    let(:i18n_string) { double('an I18n key') }
    let(:span_key) { double('key') }
    let(:span_value) { double('value') }
    let(:other_arg) { double('another I18n arg')}
    let(:other_arg_hash) { {foo: other_arg} }
    let(:response) { double('the interpolated string', html_safe: nil)}
    let(:klass) { double('a css class') }
    let(:call_method) { helper.send(:translation_with_span, i18n_string, span_key, span_value, klass, {}, nil ) }

    before do
      allow(I18n).to receive(:t).and_return(response)
      allow(span_key).to receive(:to_sym).and_return(span_key)
    end

    it 'sends the given string to `I18n` interpolation with a `span_key` argument, a value of `span_value` and a class of `klass`' do
      expect(I18n).to receive(:t).with(i18n_string, {span_key => content_tag(:span, span_value, class: klass)}).and_return(response)
      call_method
    end
    it 'sends the given string to `I18n` interpolation with any other args that were passed' do
      expect(I18n).to receive(:t).with(i18n_string, hash_including(foo: other_arg)).and_return(response)
      helper.send(:translation_with_span, i18n_string, span_key, span_value, klass, other_arg_hash, nil)
    end
    it 'returns an `html_safe` interpolated string' do
      expect(response).to receive(:html_safe)
      call_method
    end
    it 'returns `missing_data_message` if `span_value` is missing and `missing_data_message` is supplied' do
      allow(I18n).to receive(:t).and_return(missing_data_message)
      expect(missing_data_message).to receive(:html_safe)
      helper.send(:translation_with_span, i18n_string, span_key, nil, klass, {}, 'missing_data_message')
    end
  end
end