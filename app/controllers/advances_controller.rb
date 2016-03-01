class AdvancesController < ApplicationController

  before_action do
    set_active_nav(:advances)
  end
  
  def manage_advances
    member_balances = MemberBalanceService.new(current_member_id, request)
    active_advances_response = member_balances.active_advances
    raise StandardError, "There has been an error and AdvancesController#manage_advances has encountered nil. Check error logs." if active_advances_response.nil?
    column_headings = [t('common_table_headings.trade_date'), t('common_table_headings.funding_date'), t('common_table_headings.maturity_date'), t('common_table_headings.advance_number'), t('common_table_headings.advance_type'), t('advances.status'), t('advances.rate'), t('common_table_headings.current_par') + ' ($)']
    rows = active_advances_response.collect do |row|
      columns = []
      row.each do |value|
        if value[0]=='interest_rate'
          columns << {type: :index, value: value[1]}
        elsif value[0]=='current_par'
            columns << {type: :number, value: value[1]}
        elsif value[0]=='trade_date' || value[0]=='funding_date' || (value[0]=='maturity_date' and value[1] != 'Open')
          columns << {type: :date, value: value[1]}
        else
          columns << {value: value[1]}
        end
      end
      {columns: columns}
    end
    @advances_data_table = {
        :column_headings => column_headings,
        :rows => rows
    }
  end
end