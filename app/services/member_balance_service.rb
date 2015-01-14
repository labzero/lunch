class MemberBalanceService

  def initialize(member_id)
    @connection = ::RestClient::Resource.new Rails.configuration.mapi.endpoint, headers: {:'Authorization' => "Token token=\"#{ENV['MAPI_SECRET_TOKEN']}\""}
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

    # TODO: hit MAPI endpoint or enpoints to retrieve/construct an object similar to the fake one below. Pass date along, though it won't be used as of yet.
    begin
      data = JSON.parse(File.read(File.join(Rails.root, 'db', 'service_fakes', 'borrowing_capacity_summary.json'))).with_indifferent_access
    rescue JSON::ParserError => e
      Rails.logger.warn("MemberBalanceService.borrowing_capacity_summary encountered a JSON parsing error: #{e}")
      return nil
    end

    # first table - Standard Collateral
    data[:standard_credit_totals] = {}
    standard_collateral_fields = [:count, :original_amount, :unpaid_principal, :market_value, :borrowing_capacity]
    data[:standard][:collateral].each_with_index do |row, i|
      standard_collateral_fields.each do |key|
        data[:standard_credit_totals][key] ||= 0
        data[:standard_credit_totals][key] += row[key]
      end
      if row[:borrowing_capacity] > 0 && row[:unpaid_principal] > 0
        data[:standard][:collateral][i][:bc_upb] = ((row[:borrowing_capacity].to_f / row[:unpaid_principal].to_f) * 100).round
      else
        data[:standard][:collateral][i][:bc_upb] = 0
      end
    end
    data[:net_loan_collateral] = data[:standard_credit_totals][:borrowing_capacity] - data[:standard][:excluded].values.reduce(:+)
    data[:standard_excess_capacity] = data[:net_loan_collateral] - data[:standard][:utilized].values.reduce(:+)

    # second table - Securities Backed Collateral
    data[:sbc_totals] = {}
    securities_backed_collateral_fields = [:total_market_value, :total_borrowing_capacity, :advances, :standard_credit, :remaining_market_value, :remaining_borrowing_capacity]
    securities_backed_collateral_fields.each do |key|
      data[:sbc_totals][key] ||= 0
      data[:sbc][:collateral].each do |row|
        data[:sbc_totals][key] += row[key]
      end
    end
    data[:sbc_excess_capacity] = data[:sbc_totals][:remaining_borrowing_capacity] - data[:sbc][:utilized].values.reduce(:+)

    data[:total_borrowing_capacity] = data[:standard_credit_totals][:borrowing_capacity] + data[:sbc_totals][:remaining_borrowing_capacity]
    data[:remaining_borrowing_capacity] = data[:standard_excess_capacity] + data[:sbc_excess_capacity]

    data

  #   what sort of error checks do we want?  need to think through null checks if various things do not get returned
  end

end
