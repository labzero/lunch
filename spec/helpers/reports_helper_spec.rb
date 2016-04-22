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