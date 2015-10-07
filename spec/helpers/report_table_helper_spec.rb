require 'rails_helper'

describe ReportTableHelper do
  describe 'the `missing_data_message` method' do
    it "returns '#{ReportTableHelper::DISABLED_MESSAGE}' if the @report_disabled instance variable is true" do
      helper.instance_variable_set(:@report_disabled, true)
      expect(helper.missing_data_message).to eq(ReportTableHelper::DISABLED_MESSAGE)
    end
    it "returns '#{ReportTableHelper::NO_RECORDS_MESSAGE}' if the @report_disabled instance variable is not true" do
      expect(helper.missing_data_message).to eq(ReportTableHelper::NO_RECORDS_MESSAGE)
    end
  end
end