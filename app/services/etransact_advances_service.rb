class EtransactAdvancesService < MAPIService

  def status
    begin
      response = @connection["etransact_advances/status"].get
    rescue RestClient::Exception => e
      Rails.logger.warn("EtransactAdvancesService.status encountered a RestClient error: #{e.class.name}:#{e.http_code}")
      return nil
    rescue Errno::ECONNREFUSED => e
      Rails.logger.warn("EtransactAdvancesService.status encountered a connection error: #{e.class.name}")
      return nil
    end
    begin
      data = JSON.parse(response.body).with_indifferent_access
    rescue JSON::ParserError => e
      Rails.logger.warn("EtransactAdvancesService.status encountered a JSON parsing error: #{e}")
      return nil
    end

    data
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
    begin
      response = @connection["etransact_advances/signer_full_name/#{(signer)}"].get
    rescue RestClient::Exception => e
      Rails.logger.warn("EtransactAdvancesService.signer_full_name encountered a RestClient error: #{e.class.name}:#{e.http_code}")
      return nil
    rescue Errno::ECONNREFUSED => e
      Rails.logger.warn("EtransactAdvancesService.signer_full_name encountered a connection error: #{e.class.name}")
      return nil
    end
    response.body
  end

  def quick_advance_validate(member_id, amount, advance_type, advance_term, rate, check_capstock, signer)
    begin
      response = @connection["etransact_advances/validate_advance/#{member_id}/#{amount}/#{advance_type}/#{advance_term}/#{rate}/#{check_capstock}/#{URI.escape(signer)}"].get
    rescue RestClient::Exception => e
      Rails.logger.warn("EtransactAdvancesService.quick_advance_validate encountered a RestClient error: #{e.class.name}:#{e.http_code}")
      return nil
    rescue Errno::ECONNREFUSED => e
      Rails.logger.warn("EtransactAdvancesService.quick_advance_validate encountered a connection error: #{e.class.name}")
      return nil
    end
    begin
      data = JSON.parse(response.body).with_indifferent_access
    rescue JSON::ParserError => e
      Rails.logger.warn("EtransactAdvancesService.quick_advance_validate encountered a JSON parsing error: #{e}")
      return nil
    end
    data
  end

  def quick_advance_execute(member_id, amount, advance_type, advance_term, rate, signer)
    begin
      response = @connection["etransact_advances/execute_advance/#{member_id}/#{amount}/#{advance_type}/#{advance_term}/#{rate}/#{URI.escape(signer)}"].post ''
    rescue RestClient::Exception => e
      Rails.logger.warn("EtransactAdvancesService.quick_advance_execute encountered a RestClient error: #{e.class.name}:#{e.http_code}")
      return nil
    rescue Errno::ECONNREFUSED => e
      Rails.logger.warn("EtransactAdvancesService.quick_advance_execute encountered a connection error: #{e.class.name}")
      return nil
    end
    begin
      data = JSON.parse(response.body).with_indifferent_access
    rescue JSON::ParserError => e
      Rails.logger.warn("EtransactAdvancesService.quick_advance_execute encountered a JSON parsing error: #{e}")
      return nil
    end
    data[:initiated_at] = Time.zone.now.to_datetime
    data
  end

  def check_limits(amount, advance_term)
    begin
      response = @connection["etransact_advances/limits"].get
    rescue RestClient::Exception => e
      Rails.logger.warn("EtransactAdvancesService.check_limits encountered a RestClient error: #{e.class.name}:#{e.http_code}")
      return nil
    rescue Errno::ECONNREFUSED => e
      Rails.logger.warn("EtransactAdvancesService.check_limits encountered a connection error: #{e.class.name}")
      return nil
    end
    days_to_maturity = get_days_to_maturity(advance_term)
    min_amount = 0
    max_amount = 0
    begin
      limits = JSON.parse(response.body)
    rescue JSON::ParserError => e
      Rails.logger.warn("EtransactAdvancesService.check_limits encountered a JSON parsing error: #{e}")
      return nil
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