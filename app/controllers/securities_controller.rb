class SecuritiesController < ApplicationController
  include CustomFormattingHelper

  def manage
    member_balances = MemberBalanceService.new(current_member_id, request)
    securities = member_balances.managed_securities
    raise StandardError, "There has been an error and SecuritiesController#manage has encountered nil. Check error logs." if securities.nil?

    rows = []
    securities.each do |security|
      rows << {
        columns:[
          {value: security[:cusip] || t('global.missing_value')},
          {value: security[:description] || t('global.missing_value')},
          {value: custody_account_type_to_status(security[:custody_account_type])},
          {value: security[:eligibility] || t('global.missing_value')},
          {value: security[:maturity_date], type: :date},
          {value: security[:authorized_by] || t('global.missing_value')},
          {value: security[:current_par], type: :number},
          {value: security[:borrowing_capacity], type: :number}
        ]
      }
    end

    @securities_table_data = {
      column_headings: [t('common_table_headings.cusip'), t('common_table_headings.description'), t('common_table_headings.status'), t('securities.manage.eligibility'), t('common_table_headings.maturity_date'), t('securities.manage.authorized_by'), fhlb_add_unit_to_table_header(t('common_table_headings.current_par'), '$'), fhlb_add_unit_to_table_header(t('global.borrowing_capacity'), '$')],
      rows: rows
    }
  end

  private

  def custody_account_type_to_status(custody_account_type)
    custody_account_type = custody_account_type.to_s.upcase if custody_account_type
    case custody_account_type
      when 'P'
        I18n.t('securities.manage.pledged')
      when 'U'
        I18n.t('securities.manage.safekept')
      else
        I18n.t('global.missing_value')
    end
  end

end