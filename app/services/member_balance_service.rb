class MemberBalanceService < MAPIService
  DAILY_BALANCE_KEY = 'Interest Rate / Daily Balance' # the key returned by us from MAPI to let us know a row represents balance at close of business
  STA_RATE_KEY = 'sta_rate'
  def initialize(member_id, request)
    super(request)
    @member_id = member_id
    raise ArgumentError, 'member_id must not be blank' if member_id.blank?
  end

  def pledged_collateral
    begin
      response = @connection["member/#{@member_id}/balance/pledged_collateral"].get
    rescue RestClient::Exception => e
      Rails.logger.warn("MemberBalanceService.pledged_collateral encountered a RestClient error: #{e.class.name}:#{e.http_code}")
      return nil
    rescue Errno::ECONNREFUSED => e
      Rails.logger.warn("MemberBalanceService.pledged_collateral encountered a connection error: #{e.class.name}")
      return nil
    end
    data = JSON.parse(response.body).with_indifferent_access

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

  def total_securities
    begin
      response = @connection["member/#{@member_id}/balance/total_securities"].get
    rescue RestClient::Exception => e
      Rails.logger.warn("MemberBalanceService.total_securities encountered a RestClient error: #{e.class.name}:#{e.http_code}")
      return nil
    rescue Errno::ECONNREFUSED => e
      Rails.logger.warn("MemberBalanceService.total_securities encountered a connection error: #{e.class.name}")
      return nil
    end
    data = JSON.parse(response.body).with_indifferent_access
    pledged_securities = data[:pledged_securities].to_i
    safekept_securities = data[:safekept_securities].to_i
    total_securities = pledged_securities + safekept_securities
    {
      pledged_securities: {absolute: pledged_securities, percentage: pledged_securities.fdiv(total_securities)*100},
      safekept_securities: {absolute: safekept_securities, percentage: safekept_securities.fdiv(total_securities)*100}
    }.with_indifferent_access
  end

  def effective_borrowing_capacity
    begin
      response = @connection["member/#{@member_id}/balance/effective_borrowing_capacity"].get
    rescue RestClient::Exception => e
      Rails.logger.warn("MemberBalanceService.total_securities encountered a RestClient error: #{e.class.name}:#{e.http_code}")
      return nil
    rescue Errno::ECONNREFUSED => e
      Rails.logger.warn("MemberBalanceService.total_securities encountered a connection error: #{e.class.name}")
      return nil
    end
    data = JSON.parse(response.body)

    total_capacity = data['total_capacity']
    unused_capacity= data['unused_capacity']
    used_capacity = total_capacity - unused_capacity
    
    {
        used_capacity: {absolute: used_capacity, percentage: used_capacity.fdiv(total_capacity)*100},
        unused_capacity: {absolute: unused_capacity, percentage: unused_capacity.fdiv(total_capacity)*100}
    }.with_indifferent_access
  end

  def capital_stock_activity(start_date, end_date)
    # get open balance from start date
    begin
      opening_balance_response = @connection["member/#{@member_id}/capital_stock_balance/#{start_date}"].get
    rescue RestClient::Exception => e
      Rails.logger.warn("MemberBalanceService.capital_stock_activity encountered a RestClient error while hitting the /member/#{@member_id}/capital_stock_balance/#{start_date} MAPI endpoint: #{e.class.name}:#{e.http_code}")
      return nil
    rescue Errno::ECONNREFUSED => e
      Rails.logger.warn("MemberBalanceService.capital_stock_balance encountered a connection error while hitting the /member/#{@member_id}/capital_stock_balance/#{start_date} MAPI endpoint: #{e.class.name}")
      return nil
    end

    # closing balance from end date
    begin
      closing_balance_response = @connection["member/#{@member_id}/capital_stock_balance/#{end_date}"].get
    rescue RestClient::Exception => e
      Rails.logger.warn("MemberBalanceService.capital_stock_activity encountered a RestClient error while hitting the /member/#{@member_id}/capital_stock_balance/#{start_date} MAPI endpoint: #{e.class.name}:#{e.http_code}")
      return nil
    rescue Errno::ECONNREFUSED => e
      Rails.logger.warn("MemberBalanceService.capital_stock_balance encountered a connection error while hitting the /member/#{@member_id}/capital_stock_balance/#{start_date} MAPI endpoint: #{e.class.name}")
      return nil
    end

    # get activities from date range
    begin
      activities_response = @connection["member/#{@member_id}/capital_stock_activities/#{start_date}/#{end_date}"].get
    rescue RestClient::Exception => e
      Rails.logger.warn("MemberBalanceService.capital_stock_activity encountered a RestClient error while hitting the /member/{id}/capital_stock_activities/{from_date}/{to_date} MAPI endpoint: #{e.class.name}:#{e.http_code}")
      return nil
    rescue Errno::ECONNREFUSED => e
      Rails.logger.warn("MemberBalanceService.capital_stock_balance encountered a connection error while hitting the /member/{id}/capital_stock_activities/{from_date}/{to_date} MAPI endpoint: #{e.class.name}")
      return nil
    end

    # catch JSON parsing errors
    begin
      opening_balance = JSON.parse(opening_balance_response.body).with_indifferent_access
    rescue JSON::ParserError => e
      Rails.logger.warn("MemberBalanceService.capital_stock_balance encountered a JSON parsing error when parsing opening balance from /member/#{@member_id}/capital_stock_balance/#{start_date} MAPI endpoint: #{e}")
      return nil
    end
    begin
      closing_balance = JSON.parse(closing_balance_response.body).with_indifferent_access
    rescue JSON::ParserError => e
      Rails.logger.warn("MemberBalanceService.capital_stock_balance encountered a JSON parsing error when parsing closing balance from /member/#{@member_id}/capital_stock_balance/#{end_date} MAPI endpoint: #{e}")
      return nil
    end
    begin
      activities = JSON.parse(activities_response.body).with_indifferent_access
    rescue JSON::ParserError => e
      Rails.logger.warn("MemberBalanceService.capital_stock_balance encountered a JSON parsing error when parsing activities from /member/{id}/capital_stock_activities/{from_date}/{to_date} MAPI endpoint: #{e}")
      return nil
    end

    # begin building response data
    data = {}
    data[:start_date] = opening_balance[:balance_date].to_date
    data[:start_balance] = opening_balance[:open_balance].to_i
    data[:end_date] = closing_balance[:balance_date].to_date
    data[:end_balance] = closing_balance[:close_balance].to_i
    data[:activities] = activities[:activities]

    # Tally credits and debits, as the distinction is not made by MAPI. Also format date.
    data[:total_credits] = 0
    data[:total_debits] = 0
    data[:activities].each_with_index do |row, i|
      data[:activities][i][:credit_shares] = 0
      data[:activities][i][:debit_shares] = 0
      data[:activities][i][:trans_date]= data[:activities][i][:trans_date].to_date
      shares = data[:activities][i][:share_number].to_i
      begin
        if row[:dr_cr] == 'C'
          data[:activities][i][:credit_shares] = shares
          data[:total_credits] += shares
        elsif row[:dr_cr] == 'D'
          data[:activities][i][:debit_shares] = shares
          data[:total_debits] += shares
        else
          raise StandardError, "MemberBalanceService.capital_stock_activity returned '#{row[:dr_cr]}' for share type on row number #{i}. Share type should be either 'C' for Credit or 'D' for Debit."
        end
      rescue StandardError => e
        Rails.logger.warn(e)
        return nil
      end
    end
    data
  end

  def borrowing_capacity_summary(date)
    # get borrowing capacity by date
    begin
      response = @connection["member/#{@member_id}/borrowing_capacity_details/#{date}"].get
    rescue RestClient::Exception => e
      Rails.logger.warn("MemberBalanceService.borrowing_capacity_details encountered a RestClient error while hitting the /member/#{@member_id}/borrowing_capacity_details/#{date} MAPI endpoint: #{e.class.name}:#{e.http_code}")
      return nil
    rescue Errno::ECONNREFUSED => e
      Rails.logger.warn("MemberBalanceService.borrowing_capacity_details encountered a connection error while hitting the /member/#{@member_id}/borrowing_capacity_details/#{date} MAPI endpoint: #{e.class.name}")
      return nil
    end

    begin
      data = JSON.parse(response.body).with_indifferent_access
    rescue JSON::ParserError => e
      Rails.logger.warn("MemberBalanceService.borrowing_capacity_details encountered a JSON parsing error: #{e}")
      return nil
    end

    if data[:standard].length > 0 && data[:sbc].length > 0
      # first table - Standard Collateral
      begin
        standard_collateral_fields = [:count, :original_amount, :unpaid_principal, :market_value, :borrowing_capacity]
        data[:standard_credit_totals] = {}
        # build data[:standard_credit_totals] object here to account for the case where data[:standard][:collateral] comes back empty
        standard_collateral_fields.each do |field_name|
          data[:standard_credit_totals][field_name] = 0
        end
        data[:standard][:collateral].each_with_index do |row, i|
          standard_collateral_fields.each do |key|
            data[:standard_credit_totals][key] += row[key].to_i
          end
          if row[:borrowing_capacity].to_i > 0 && row[:unpaid_principal].to_i > 0
            data[:standard][:collateral][i][:bc_upb] = ((row[:borrowing_capacity].to_f / row[:unpaid_principal].to_f) * 100).round
          else
            data[:standard][:collateral][i][:bc_upb] = 0
          end
        end
        data[:net_loan_collateral] = data[:standard_credit_totals][:borrowing_capacity].to_i - data[:standard][:excluded].values.sum
        data[:standard_excess_capacity] = data[:net_loan_collateral].to_i - data[:standard][:utilized].values.reduce(:+)
      rescue => e
        Rails.logger.warn("The data[:standard] hash in MemberBalanceService.borrowing_capacity_summary is malformed in some way. It returned #{data[:standard]} and threw the following error: #{e}")
        return nil
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
        data[:total_borrowing_capacity] = data[:standard_credit_totals][:borrowing_capacity].to_i + data[:sbc_totals][:remaining_borrowing_capacity].to_i
        data[:remaining_borrowing_capacity] = data[:standard_excess_capacity].to_i + data[:sbc_excess_capacity].to_i
      rescue => e
        Rails.logger.warn("The data[:sbc] hash in MemberBalanceService.borrowing_capacity_summary is malformed in some way. It returned #{data[:sbc]} and threw the following error: #{e}")
        return nil
      end
    else
      data[:total_borrowing_capacity] = 0
      data[:remaining_borrowing_capacity] = 0
    end

    data
  end

  def settlement_transaction_account(start_date, end_date, filter='all')
    start_date = start_date.to_date
    end_date = end_date.to_date
    filter = filter.to_sym

    begin
      response = @connection["member/#{@member_id}/sta_activities/#{start_date.iso8601}/#{end_date.iso8601}"].get
    rescue RestClient::Exception => e
      Rails.logger.warn("MemberBalanceService.settlement_transaction_account encountered a RestClient error: #{e.class.name}:#{e.http_code}")
      return nil
    rescue Errno::ECONNREFUSED => e
      Rails.logger.warn("MemberBalanceService.settlement_transaction_account encountered a connection error: #{e.class.name}")
      return nil
    end

    begin
      data = JSON.parse(response.body).with_indifferent_access
    rescue JSON::ParserError => e
      Rails.logger.warn("MemberBalanceService.settlement_transaction_account encountered a JSON parsing error: #{e}")
      return nil
    end

    data[:activities].each_with_index do |activity, i|
      data[:activities][i][:trans_date] = activity[:trans_date].to_date
      data[:activities][i][:rate] = nil if activity[:rate] == 0
      if activity[:debit]
        data[:activities][i][:transaction] = activity[:debit] * -1
      elsif activity[:credit]
        data[:activities][i][:transaction] = activity[:credit]
      end
    end

    data[:start_date] = data[:start_date].to_date
    data[:end_date] = data[:end_date].to_date

    # sort the activities array by description and then by date to wind up with the proper order
    data[:activities] = data[:activities].sort do |a, b|
      if a[:trans_date] == b[:trans_date]
        if a[:descr] == DAILY_BALANCE_KEY && b[:descr] != DAILY_BALANCE_KEY
          -1
        elsif a[:descr] == DAILY_BALANCE_KEY && b[:descr] == DAILY_BALANCE_KEY
          Rails.logger.warn("MemberBalanceService.settlement_transaction_account returned an activities array that contains duplicate `end of day balance` entries for the date: #{a[:trans_date]}")
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
    as_of_date = as_of_date.to_date

    begin
      response = @connection["/member/#{@member_id}/advances_details/#{as_of_date.iso8601}"].get
    rescue RestClient::Exception => e
      Rails.logger.warn("MemberBalanceService.advances_details encountered a RestClient error: #{e.class.name}:#{e.http_code}")
      return nil
    rescue Errno::ECONNREFUSED => e
      Rails.logger.warn("MemberBalanceService.advances_details encountered a connection error: #{e.class.name}")
      return nil
    end

    begin
      data = JSON.parse(response.body).with_indifferent_access
    rescue JSON::ParserError => e
      Rails.logger.warn("MemberBalanceService.advances_details encountered a JSON parsing error: #{e}")
      return nil
    end

    data[:total_par] = 0
    data[:total_accrued_interest] = 0
    data[:estimated_next_payment] = 0
    data[:advances_details].each do |advance|
      data[:total_par] += advance[:current_par] if advance[:current_par]
      data[:total_accrued_interest] += advance[:accrued_interest] if advance[:accrued_interest]
      data[:estimated_next_payment] += advance[:estimated_next_interest_payment] if advance[:estimated_next_interest_payment]
    end

    data[:as_of_date] = data[:as_of_date].to_date
    data[:total_par] = data[:total_par].round
    data[:total_accrued_interest] = data[:total_accrued_interest].to_f
    data[:estimated_next_payment] = data[:estimated_next_payment].to_f

    data
  end

  def profile
    # TODO: hit MAPI endpoint or enpoints to retrieve/construct an object similar to the fake one below. Pass date along, though it won't be used as of yet.
    begin
      data = JSON.parse(File.read(File.join(Rails.root, 'db', 'service_fakes', 'profile.json'))).with_indifferent_access
    rescue JSON::ParserError => e
      Rails.logger.warn("MemberBalanceService.profile encountered a JSON parsing error: #{e}")
      return nil
    end
    data
  end

  def cash_projections
    fake_data = JSON.parse(File.read(File.join(Rails.root, 'db', 'service_fakes', 'cash_projections.json'))).with_indifferent_access
    today = Time.zone.now.to_date
    as_of_date =
      if today.wday == 0
        today - 2.days
      elsif today.wday == 1
        today - 3.days
      else
        today - 1.day
      end

    total_net_amount = 0
    total_principal = 0
    total_interest = 0
    rows = []
    number_of_rows = as_of_date.day + as_of_date.month
    r = Random.new(as_of_date.to_time.to_i + as_of_date.day)

    number_of_rows.times do |i|
      total_amount = r.rand(19..100000) + r.rand.round(2)
      interest = r.rand(1..100000) + r.rand.round(2)
      principal = r.rand(0..8585000) + r.rand.round(2)
      total_net_amount += total_amount
      total_principal += principal
      total_interest += interest
      rows << {
          settlement_date: as_of_date + (r.rand(3..14)).days,
          custody_account: '082131',
          cusip: fake_data[:cusips][r.rand(0..(fake_data[:cusips].length - 1))],
          description: fake_data[:descriptions][r.rand(0..(fake_data[:descriptions].length - 1))],
          transaction_code: 'MBSD',
          pool_number: fake_data[:pools][r.rand(0..(fake_data[:pools].length - 1))],
          original_par: r.rand(250000..22500000),
          coupon_rate: r.rand(0..6) + r.rand.round(3),
          maturity_date: as_of_date + (i.days),
          principal: principal,
          interest: interest,
          total: total_amount,
      }
    end
    {
      as_of_date: as_of_date,
      total_net_amount: total_net_amount,
      total_principal: total_principal,
      total_interest: total_interest,
      projections: rows
    }.with_indifferent_access
  end

  def settlement_transaction_rate
    # TODO: hit MAPI endpoint or enpoints to retrieve/construct an object similar to the fake one below. Pass date along, though it won't be used as of yet.
    begin
      data = JSON.parse(File.read(File.join(Rails.root, 'db', 'service_fakes', 'settlement_transaction_rate.json'))).with_indifferent_access
    rescue JSON::ParserError => e
      Rails.logger.warn("MemberBalanceService.settlement_transaction_rate encountered a JSON parsing error: #{e}")
      return nil
    end
    data
  end

end
