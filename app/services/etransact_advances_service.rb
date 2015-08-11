class EtransactAdvancesService < MAPIService

  def status
    get_hash(:status, 'etransact_advances/status')
  end
  
  def blackout_dates
    get_json(:blackout_dates, 'etransact_advances/blackout_dates')
  end
  
  def etransact_active?(status_object=nil)
    status_object = self.status unless status_object
    return false unless status_object
    status_object[:etransact_advances_status] 
  end

  def has_terms?(status_object=nil)
    status_object = self.status unless status_object
    return false unless status_object
    status_object[:all_loan_status].select do |term, loans|
      loans.select do |loan,  details|
        details[:display_status] && details[:trade_status]
      end.present?
    end.present?
  end

  def signer_full_name(signer)
    get(:signer_full_name, "etransact_advances/signer_full_name/#{(signer)}").try(:body)
  end

  def quick_advance_validate(member_id, amount, advance_type, advance_term, rate, check_capstock, signer)
    get_hash(:quick_advance_validate, "etransact_advances/validate_advance/#{member_id}/#{amount}/#{advance_type}/#{advance_term}/#{rate}/#{check_capstock}/#{URI.escape(signer)}")
  end

  def quick_advance_execute(member_id, amount, advance_type, advance_term, rate, signer)
    begin
      response = @connection["etransact_advances/execute_advance/#{member_id}/#{amount}/#{advance_type}/#{advance_term}/#{rate}/#{URI.escape(signer)}"].post ''
    rescue RestClient::Exception => e
      return warn(:quick_advance_execute, "RestClient error: #{e.class.name}:#{e.http_code}")
    rescue Errno::ECONNREFUSED => e
      return warn(:quick_advance_execute, "connection error: #{e.class.name}")
    end
    begin
      data = JSON.parse(response.body).with_indifferent_access
    rescue JSON::ParserError => e
      return warn(:quick_advance_execute, "JSON parsing error: #{e}")
    end
    data[:initiated_at] = Time.zone.now.to_datetime
    data
  end

  def check_limits(amount, advance_term)
    response = get(:check_limits, "etransact_advances/limits")
    return nil if response.nil?
    days_to_maturity = get_days_to_maturity(advance_term)
    min_amount = 0
    max_amount = 0
    begin
      limits = JSON.parse(response.body)
    rescue JSON::ParserError => e
      return warn(:check_limits, "JSON parsing error: #{e}")
    end
    limits.each do |row|
      if days_to_maturity >= row['LOW_DAYS_TO_MATURITY'].to_i && days_to_maturity <= row['HIGH_DAYS_TO_MATURITY'].to_i
        min_amount = row['MIN_ONLINE_ADVANCE'].to_i
        max_amount = row['TERM_DAILY_LIMIT'].to_i
        break
      end
    end
    check_limit = 'pass'
    if amount < min_amount
      check_limit = 'low'
    elsif amount > max_amount
      check_limit = 'high'
    end
    {
      status: check_limit,
      low: min_amount,
      high: max_amount
    }
  end

  protected

  def get_days_to_maturity (term)
    maturity_date = Date.today
    if (term == 'overnight') || (term == 'open')
      maturity_date = maturity_date + 1.day
    elsif term[1].upcase == 'W'
      maturity_date = maturity_date + (7*term[0].to_i).day
    elsif term[1].upcase == 'M'
      maturity_date = maturity_date + (term[0].to_i).month
    elsif term[1].upcase == 'Y'
      maturity_date = maturity_date + (term[0].to_i).year
    end
    (maturity_date - Date.today).to_i
  end

end