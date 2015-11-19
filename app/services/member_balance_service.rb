class MemberBalanceService < MAPIService
  DAILY_BALANCE_KEY = 'Interest Rate / Daily Balance' # the key returned by us from MAPI to let us know a row represents balance at close of business
  STA_RATE_KEY = 'sta_rate'
  def initialize(member_id, request)
    super(request)
    @member_id = member_id
    raise ArgumentError, 'member_id must not be blank' if member_id.blank?
  end

  def pledged_collateral
    if data = get_hash(:pledged_collateral, "member/#{@member_id}/balance/pledged_collateral")
      mortgage_mv = data[:mortgages].to_f
      agency_mv = data[:agency].to_f
      aaa_mv = data[:aaa].to_f
      aa_mv = data[:aa].to_f

      total_collateral = mortgage_mv + agency_mv + aaa_mv + aa_mv
      {
        mortgages: {absolute: mortgage_mv, percentage: mortgage_mv.fdiv(total_collateral)*100},
        agency: {absolute: agency_mv, percentage: agency_mv.fdiv(total_collateral)*100},
        aaa: {absolute: aaa_mv, percentage: aaa_mv.fdiv(total_collateral)*100},
        aa: {absolute: aa_mv, percentage: aa_mv.fdiv(total_collateral)*100}
      }.with_indifferent_access
    end
  end

  def total_securities
    if data = get_hash(:total_securities, "member/#{@member_id}/balance/total_securities")
      pledged_securities = data[:pledged_securities].to_i
      safekept_securities = data[:safekept_securities].to_i
      total_securities = pledged_securities + safekept_securities
      {
        pledged_securities: {absolute: pledged_securities, percentage: pledged_securities.fdiv(total_securities)*100},
        safekept_securities: {absolute: safekept_securities, percentage: safekept_securities.fdiv(total_securities)*100}
      }.with_indifferent_access
    end
  end

  def effective_borrowing_capacity
    if data = get_hash(:effective_borrowing_capacity, "member/#{@member_id}/balance/effective_borrowing_capacity")
      total_capacity = data['total_capacity']
      unused_capacity= data['unused_capacity']
      used_capacity = total_capacity - unused_capacity
    
      {
          used_capacity: {absolute: used_capacity, percentage: used_capacity.fdiv(total_capacity)*100},
          unused_capacity: {absolute: unused_capacity, percentage: unused_capacity.fdiv(total_capacity)*100}
      }.with_indifferent_access
    end 
  end

  def capital_stock_activity(start_date, end_date)
    # get open balance from start date
    unless (opening_balance = get_hash(:capital_stock_activity, "member/#{@member_id}/capital_stock_balance/#{start_date}"))                &&
           (closing_balance = get_hash(:capital_stock_activity, "member/#{@member_id}/capital_stock_balance/#{end_date}"))                  &&
           (activities      = get_hash(:capital_stock_activity, "member/#{@member_id}/capital_stock_activities/#{start_date}/#{end_date}" ))
      return nil
    end

    # begin building response data
    data = {}
    data[:start_date] = opening_balance[:balance_date].try(:to_date)
    data[:start_balance] = opening_balance[:open_balance].to_i
    data[:end_date] = closing_balance[:balance_date].try(:to_date)
    data[:end_balance] = closing_balance[:close_balance].to_i
    data[:activities] = activities[:activities]

    # Tally credits and debits, as the distinction is not made by MAPI. Also format date.
    outstanding = data[:start_balance]
    data[:total_credits] = 0
    data[:total_debits] = 0
    data[:activities].each_with_index do |row, i|
      row[:credit_shares] = 0
      row[:debit_shares] = 0
      fix_date(row, :trans_date)
      shares = row[:share_number].to_i
      begin
        if row[:dr_cr] == 'C'
          row[:credit_shares] = shares
          data[:total_credits] += shares
          outstanding += shares
        elsif row[:dr_cr] == 'D'
          row[:debit_shares] = shares
          data[:total_debits] += shares
          outstanding -= shares
        else
          raise StandardError, "MemberBalanceService.capital_stock_activity returned '#{row[:dr_cr]}' for share type on row number #{i}. Share type should be either 'C' for Credit or 'D' for Debit."
        end
      rescue StandardError => e
        return warn(:capital_stock_activity, e.message, e)
      end
      row[:outstanding_shares] = outstanding
    end
    data
  end

  def borrowing_capacity_summary(date)
    # get borrowing capacity by date
    return nil unless data = get_hash(:borrowing_capacity_summary, "member/#{@member_id}/borrowing_capacity_details/#{date}")
    if data[:standard].length > 0 && data[:sbc].length > 0
      # first table - Standard Collateral
      begin
        standard_collateral_fields = [:count, :original_amount, :unpaid_principal, :market_value, :borrowing_capacity]
        data[:standard_credit_totals] = {}
        # build data[:standard_credit_totals] object here to account for the case where data[:standard][:collateral] comes back empty
        standard_collateral_fields.each do |field_name|
          data[:standard_credit_totals][field_name] = 0
        end
        data[:standard][:collateral].each do |row|
          standard_collateral_fields.each do |key|
            data[:standard_credit_totals][key] += row[key].to_i
          end
          if row[:borrowing_capacity].to_i > 0 && row[:unpaid_principal].to_i > 0
            row[:bc_upb] = ((row[:borrowing_capacity].to_f / row[:unpaid_principal].to_f) * 100).round
          else
            row[:bc_upb] = 0
          end
        end
        data[:net_loan_collateral] = data[:standard_credit_totals][:borrowing_capacity].to_i - data[:standard][:excluded].values.sum 
        data[:net_plus_securities_capacity] = data[:net_loan_collateral] + data[:standard][:securities].to_i
        data[:standard_excess_capacity] = data[:net_plus_securities_capacity].to_i - data[:standard][:utilized].values.sum 
      rescue => e
        return warn(:borrowing_capacity_summary, "malformed data[:standard] hash. It returned #{data[:standard]} and threw the following error: #{e}", e)
      end

      # second table - Securities Backed Collateral
      begin
        data[:sbc_totals] = {}
        securities_backed_collateral_fields = [:total_market_value, :total_borrowing_capacity, :advances, :standard_credit, :remaining_market_value, :remaining_borrowing_capacity]
        securities_backed_collateral_fields.each do |key|
          data[:sbc_totals][key] ||= 0
          data[:sbc][:collateral].each do |type, value|
            data[:sbc_totals][key] += value[key].to_i
          end
        end
        data[:sbc_excess_capacity] = data[:sbc_totals][:remaining_borrowing_capacity].to_i - data[:sbc][:utilized].values.sum
        data[:total_borrowing_capacity] = data[:standard_credit_totals][:borrowing_capacity].to_i + data[:sbc_totals][:total_borrowing_capacity].to_i
        data[:remaining_borrowing_capacity] = data[:standard_excess_capacity].to_i + data[:sbc_excess_capacity].to_i
      rescue => e
        return warn(:borrowing_capacity_summary, "malformed data[:sbc] hash: #{data[:sbc]} and threw the following error: #{e}", e)
      end
    else
      data[:total_borrowing_capacity] = 0
      data[:remaining_borrowing_capacity] = 0
    end

    data
  end

  def settlement_transaction_account(start_date, end_date, filter='all')
    start_date = start_date.try(:to_date)
    end_date = end_date.try(:to_date)
    filter = filter.to_sym

    begin
      response = @connection["member/#{@member_id}/sta_activities/#{start_date.iso8601}/#{end_date.iso8601}"].get
    rescue RestClient::Exception => e
      warn(:settlement_transaction_account, "RestClient error: #{e.class.name}:#{e.http_code}", e)
      return e.http_code == 404 ? {} : nil
    rescue Errno::ECONNREFUSED => e
      return warn(:settlement_transaction_account, "connection error: #{e.class.name}", e)
    end

    begin
      data = JSON.parse(response.body).with_indifferent_access
    rescue JSON::ParserError => e
      return warn(:settlement_transaction_account, "JSON parsing error: #{e}", e)
    end

    data[:activities].each do |activity|
      fix_date(activity,:trans_date)
      activity[:rate] = nil if activity[:rate] == 0
      if activity[:debit]
        activity[:transaction] = activity[:debit] * -1
      elsif activity[:credit]
        activity[:transaction] = activity[:credit]
      end
    end

    fix_date(data, :start_date)
    fix_date(data, :end_date)

    # sort the activities array by description and then by date to wind up with the proper order
    data[:activities] = data[:activities].sort do |a, b|
      if a[:trans_date] == b[:trans_date]
        if a[:descr] == DAILY_BALANCE_KEY && b[:descr] != DAILY_BALANCE_KEY
          -1
        elsif a[:descr] == DAILY_BALANCE_KEY && b[:descr] == DAILY_BALANCE_KEY
          warn(:settlement_transaction_account, "activities array that contains duplicate `end of day balance` entries for the date: #{a[:trans_date]}", e)
          0
        else
          1
        end
      else
        b[:trans_date] <=> a[:trans_date]
      end
    end

    data[:activities].delete_if do |activity|
      activity[filter].nil? unless filter == :all
    end

    data
  end

  def advances_details(as_of_date)
    if data = get_hash(:advances_details, "/member/#{@member_id}/advances_details/#{as_of_date.to_date.iso8601}")
      data[:total_par]              = lenient_sum( data[:advances_details], :current_par ).round
      data[:total_accrued_interest] = lenient_sum( data[:advances_details], :accrued_interest ).to_f
      data[:estimated_next_payment] = lenient_sum( data[:advances_details], :estimated_next_interest_payment ).to_f

      fix_date(data)
    end
    data
  end

  def profile
    if data = get_hash(:profile, "/member/#{@member_id}/member_profile")    
      data[:used_financing_availability] = data[:collateral_borrowing_capacity][:total].to_i - data[:collateral_borrowing_capacity][:remaining].to_i
      data[:uncollateralized_financing_availability] = [data[:total_financing_available].to_i - data[:collateral_borrowing_capacity][:total].to_i, 0].max
    end
    data
  end

  def cash_projections
    if data = get_hash(:cash_projections, "/member/#{@member_id}/cash_projections")
      fix_date(data)
      data[:projections].each do |projection|
        fix_date(projection, :settlement_date)
        fix_date(projection, :maturity_date)
      end
    end
    data
  end

  def settlement_transaction_rate
    get_hash(:settlement_transaction_rate, "/member/#{@member_id}/current_sta_rate")
  end

  def dividend_statement(start_date, div_id)
    div_id ||= 'current'
    if data = get_hash(:dividend_statement, "/member/#{@member_id}/dividend_statement/#{start_date.to_date.iso8601}/#{div_id}")
      fix_date(data, :transaction_date)
      data[:details].each do |detail|
        fix_date(detail, :issue_date)
        fix_date(detail, :start_date)
        fix_date(detail, :end_date)
      end
    end
    data
  end

  def lenient_sum(hashes, field)
    hashes.nil? ? 0 : hashes.map{|hash| hash[field]}.compact.sum
  end

  def securities_transactions(as_of_date)
    if data = get_hash(:securities_transactions, "/member/#{@member_id}/securities_transactions/#{as_of_date.to_date.iso8601}")
      data.merge(
          total_payment_or_principal: lenient_sum(data[:transactions], :payment_or_principal),
          total_interest:             lenient_sum(data[:transactions], :interest),
          total_net:                  lenient_sum(data[:transactions], :total)
      )
    end
  end

  def securities_services_statements_available
    get_json(:securities_services_statements_available, "member/#{@member_id}/securities_services_statements_available").try(:map){ |statement| fix_date(statement, 'report_end_date') }
  end

  def securities_services_statement(date)
    fix_date( fix_date(get_hash(:securities_services_statements, "member/#{@member_id}/securities_services_statements/#{date.to_date.iso8601}"), 'debit_date'), 'month_ending')
  end

  def letters_of_credit
    if data = get_hash(:letters_of_credit, "member/#{@member_id}/letters_of_credit")
      fix_date(data)
      %i(maturity_date settlement_date trade_date).each do |key|
        data[:credits].each { |credit| fix_date(credit,key) }
      end
    end
    data
  end

  def active_advances
    get_json(:active_advances, "member/#{@member_id}/active_advances")
  end
  
  def fix_date(data, field=:as_of_date)
    data[field] = data[field].to_date if data && data[field]
    data
  end

  def parallel_shift
    fix_date( get_hash(:parallel_shift, "member/#{@member_id}/parallel_shift_analysis") )
  end

  def current_securities_position(custody_account_type)
    fix_date( get_hash(:current_securities_position, "member/#{@member_id}/current_securities_position/#{custody_account_type}") )
  end

  def monthly_securities_position(month_end_date, custody_account_type)
    month_end_date = month_end_date.to_date.strftime('%Y-%m-%d')
    fix_date( get_hash(:monthly_securities_position, "member/#{@member_id}/monthly_securities_position/#{month_end_date}/#{custody_account_type}") )
  end

  def forward_commitments
    if data = get_hash(:forward_commitments, "member/#{@member_id}/forward_commitments")
      fix_date( data )
      unless data[:advances].blank?
        data[:advances].collect do |advance|
          %i(trade_date funding_date maturity_date).each { |date_attr| fix_date(advance, date_attr) }
          advance
        end
      end
    end
    data
  end

  def capital_stock_and_leverage
    get_hash(:capital_stock_and_leverage, "member/#{@member_id}/capital_stock_and_leverage")
  end

  def capital_stock_trial_balance(date)
    get_hash(:capital_stock_trial_balance, "member/#{@member_id}/capital_stock_trial_balance/#{date.iso8601}")
  end

  def interest_rate_resets
    fix_date(get_hash(:interest_rate_resets, "/member/#{@member_id}/interest_rate_resets"), :date_processed)
  end

  def todays_credit_activity
    if data = get_json(:todays_credit_activity, "/member/#{@member_id}/todays_credit_activity")
      processed_data = []
      data.each do |activity|
        activity = activity.with_indifferent_access
        # Handling for Advances that have been EXERCISED
        if (activity[:instrument_type] == 'ADVANCE' || activity[:instrument_type] == 'LC') && activity[:status] == 'EXERCISED'
          activity[:product_description] = activity[:termination_full_partial]
          activity[:interest_rate] = nil
        else
          activity[:product_description] =
            # handling for Termination Par
          if !activity[:termination_par].blank?
            if !activity[:termination_full_partial].blank?
              if activity[:instrument_type] == 'ADVANCE' || activity[:instrument_type] == 'LC'
                           activity[:termination_full_partial]
              elsif activity[:status] == 'TERMINATED'
                'TERMINATION'
              else
                activity[:instrument_type]
              end
            # else - leave the product_description as-is
            end
          elsif activity[:instrument_type] == 'ADVANCE'
            activity[:instrument_type] + ' ' + activity[:sub_product]
          else
            activity[:instrument_type]
          end
        end
        %i(funding_date maturity_date).each { |date_attr| fix_date(activity, date_attr) }
        processed_data.push(activity)
      end
      processed_data
    end
  end
  
  def mortgage_collateral_update
    fix_date(get_hash(:mortgage_collateral_update, "/member/#{@member_id}/mortgage_collateral_update"), :date_processed)
  end
end
