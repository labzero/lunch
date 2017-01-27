class LettersOfCreditController < ApplicationController
  include ReportsHelper
  include CustomFormattingHelper
  include ContactInformationHelper
  include SidebarHelper

  LC_INSTRUMENT_TYPE = 'LC'.freeze

  before_action do
    set_active_nav(:letters_of_credit)
    @html_class ||= 'white-background'
  end

  before_action only: [:new] do
    authorize :letters_of_credit, :request?
  end

  before_action except: [:manage] do
    @profile = sanitized_profile
    @contacts = member_contacts
  end

  def manage
    set_titles(t('letters_of_credit.manage.title'))
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
    @table_data = {
      column_headings: [t('reports.pages.letters_of_credit.headers.lc_number'), fhlb_add_unit_to_table_header(t('reports.pages.letters_of_credit.headers.current_amount'), '$'), t('global.issue_date'), t('letters_of_credit.manage.expiration_date'), t('reports.pages.letters_of_credit.headers.credit_program'), t('reports.pages.letters_of_credit.headers.annual_maintenance_charge'), t('global.actions')],
      rows: rows
    }
  end

  def new
    set_titles(t('letters_of_credit.request.title'))
    @letter_of_credit = LetterOfCredit.new
    @beneficiary_dropdown_options = BeneficiariesService.new.all.collect{|beneficiary| [beneficiary[:name], beneficiary[:name]] }
  end

  private

  def set_titles(title)
    @title = title
    @page_title = t('global.page_meta_title', title: title)
  end

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