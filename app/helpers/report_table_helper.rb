module ReportTableHelper

  def missing_data_message(report_disabled=@report_disabled)
    report_disabled ? I18n.t('errors.table_data_unavailable') : I18n.t('errors.table_data_no_records')
  end
  
end