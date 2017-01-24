class LettersOfCreditController < ApplicationController
  include ReportsHelper
  include CustomFormattingHelper

  LC_INSTRUMENT_TYPE = 'LC'.freeze

  before_action do
    set_active_nav(:letters_of_credit)
    @html_class ||= 'white-background'
    @page_title ||= I18n.t('global.page_meta_title', title: I18n.t('letters_of_credit.title'))
  end

  def manage
    member_balances = MemberBalanceService.new(current_member_id, request)
    historic_locs = member_balances.letters_of_credit
    intraday_locs = member_balances.todays_credit_activity
    raise StandardError, "There has been an error and LettersOfCreditController#manage has encountered nil. Check error logs." if historic_locs.nil? || intraday_locs.nil?
    historic_locs = historic_locs[:credits]
    intraday_locs = intraday_locs.select{ |activity| activity[:instrument_type] == LC_INSTRUMENT_TYPE }
    locs = dedupe_locs(intraday_locs, historic_locs)
    rows = if locs.present?
      sort_report_data(locs, :lc_number).collect do |credit|
        {
          columns: [
            {value: credit[:lc_number], type: nil},
            {value: credit[:current_par], type: :currency_whole},
            {value: credit[:trade_date], type: :date},
            {value: credit[:maturity_date], type: :date},
            {value: credit[:description], type: nil},
            {value: credit[:maintenance_charge], type: :basis_point},
            {value: t('global.view_pdf'), type: nil}
          ]
        }
      end
    else
      []
    end
    @title = t('letters_of_credit.manage.title')
    @table_data = {
      column_headings: [t('reports.pages.letters_of_credit.headers.lc_number'), fhlb_add_unit_to_table_header(t('reports.pages.letters_of_credit.headers.current_amount'), '$'), t('global.issue_date'), t('letters_of_credit.manage.expiration_date'), t('reports.pages.letters_of_credit.headers.credit_program'), t('reports.pages.letters_of_credit.headers.annual_maintenance_charge'), t('global.actions')],
      rows: rows
    }
  end

  private

  def dedupe_locs(intraday_locs, historic_locs)
    deduped_locs = {}
    (intraday_locs + historic_locs).each do |loc|
      if deduped_locs[loc[:lc_number]]
        deduped_locs[loc[:lc_number]][:description] ||= loc[:description] # Intraday LOCs do not currently contain a cica program description
      else
        deduped_locs[loc[:lc_number]] = loc
      end
    end
    deduped_locs.values
  end

end