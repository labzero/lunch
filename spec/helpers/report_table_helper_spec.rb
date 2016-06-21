require 'rails_helper'

describe ReportTableHelper do
  describe 'the `missing_data_message` method' do
    describe 'with no passed argument' do
      it "returns 'I18n.t('errors.table_data_unavailable')' if the @report_disabled instance variable is true" do
        helper.instance_variable_set(:@report_disabled, true)
        expect(helper.missing_data_message).to eq(I18n.t('errors.table_data_unavailable'))
      end
      it "returns 'I18n.t('errors.table_data_no_records')' if the @report_disabled instance variable is not true" do
        expect(helper.missing_data_message).to eq(I18n.t('errors.table_data_no_records'))
      end
    end
    describe 'with a passed disabled state' do
      it "returns 'I18n.t('errors.table_data_unavailable')' if passed true" do
        expect(helper.missing_data_message(true)).to eq(I18n.t('errors.table_data_unavailable'))
      end
      it "returns 'I18n.t('errors.table_data_no_records')' if passed false" do
        expect(helper.missing_data_message(false)).to eq(I18n.t('errors.table_data_no_records'))
      end
    end
  end
end