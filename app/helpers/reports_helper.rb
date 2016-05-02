module ReportsHelper
  def report_summary_with_date(i18n, date, substitutions: {}, missing_data_message: nil)
    translation_with_span(i18n, :date, date, 'report-summary-date', substitutions, missing_data_message)
  end

  def securities_services_line_item(i18n, number, substitutions: {}, missing_data_message: nil)
    translation_with_span(i18n, :number, number, 'securities-services-line-item-number', substitutions, missing_data_message)
  end

  private

  def translation_with_span(i18n, span_key, span_value, klass, substitutions, missing_data_message)
    substitutions[span_key.to_sym] = content_tag(:span, span_value, class: klass)
    if missing_data_message && (span_value.nil? || span_value == t('global.missing_value'))
      I18n.t(missing_data_message, substitutions)
    else
      I18n.t(i18n, substitutions)
    end.html_safe
  end
end