module ReportsHelper
  def report_summary_with_date(i18n, date, subs={})
    translation_with_span(i18n, :date, date, 'report-summary-date', subs)
  end

  def securities_services_line_item(i18n, number, subs={})
    translation_with_span(i18n, :number, number, 'securities-services-line-item-number', subs)
  end

  private

  def translation_with_span(i18n, span_key, span_value, klass, subs={})
    subs[span_key.to_sym] = content_tag(:span, span_value, class: klass)
    I18n.t(i18n, subs).html_safe
  end
end