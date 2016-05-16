module ReportsHelper
  def report_summary_with_date(i18n, date, substitutions: {}, missing_data_message: nil)
    translation_with_span(i18n, :date, date, 'report-summary-date', substitutions, missing_data_message)
  end

  def securities_services_line_item(i18n, number, substitutions: {}, missing_data_message: nil)
    translation_with_span(i18n, :number, number, 'securities-services-line-item-number', substitutions, missing_data_message)
  end

  def sanitize_profile_if_endpoints_disabled(profile)
    members_service = MembersService.new(request)
    profile = {credit_outstanding: {}, collateral_borrowing_capacity: {}} if profile.blank?

    if members_service.report_disabled?(current_member_id, [MembersService::FINANCING_AVAILABLE_DATA])
      profile[:total_financing_available] = nil
    end

    if members_service.report_disabled?(current_member_id, [MembersService::STA_BALANCE_AND_RATE_DATA, MembersService::STA_DETAIL_DATA])
      profile[:sta_balance] = nil
    end

    if members_service.report_disabled?(current_member_id, [MembersService::CREDIT_OUTSTANDING_DATA])
      profile[:credit_outstanding][:total] = nil
    end

    if members_service.report_disabled?(current_member_id, [MembersService::COLLATERAL_HIGHLIGHTS_DATA])
      profile[:collateral_borrowing_capacity][:remaining] = nil
      profile[:total_borrowing_capacity_standard] = nil
      profile[:total_borrowing_capacity_sbc_agency] = nil
      profile[:total_borrowing_capacity_sbc_aaa] = nil
      profile[:total_borrowing_capacity_sbc_aa] = nil
    end

    if members_service.report_disabled?(current_member_id, [MembersService::FHLB_STOCK_DATA])
      profile[:capital_stock] = nil
    end

    profile
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