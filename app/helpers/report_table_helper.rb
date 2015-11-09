module ReportTableHelper
  DISABLED_MESSAGE = I18n.t('errors.table_data_unavailable')
  NO_RECORDS_MESSAGE = I18n.t('errors.table_data_no_records')

  def missing_data_message
    @report_disabled ? DISABLED_MESSAGE : NO_RECORDS_MESSAGE
  end
  
end