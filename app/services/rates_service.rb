class RatesService < MAPIService
  COLLATERAL_TYPES = %i(standard sbc)
  CREDIT_TYPES = %i(frc vrc arc 1m_libor 3m_libor 6m_libor daily_prime embedded_cap)
  HISTORICAL_FRC_TERMS = %i(1m 2m 3m 6m 1y 2y 3y 5y 7y 10y 15y 20y 30y)

  def overnight_vrc(days=30)
    begin
      response = @connection['rates/historic/overnight'].get params: {limit: days}
    rescue RestClient::Exception => e
      Rails.logger.warn("RatesService.overnight_vrc encountered a RestClient error: #{e.class.name}:#{e.http_code}")
      return nil
    rescue Errno::ECONNREFUSED => e
      Rails.logger.warn("RatesService.overnight_vrc encountered a connection error: #{e.class.name}")
      return nil
    end
    data ||= JSON.parse(response.body)
    data.collect! do |row|
      [Date.parse(row[0]), row[1].to_f]
    end
  end

  def current_overnight_vrc
    begin
      response = @connection['rates/whole/overnight'].get
    rescue RestClient::Exception => e
      Rails.logger.warn("RatesService.current_overnight_vrc encountered a RestClient error: #{e.class.name}:#{e.http_code}")
      return nil
    rescue Errno::ECONNREFUSED => e
      Rails.logger.warn("RatesService.overnight_vrc encountered a connection error: #{e.class.name}")
      return nil
    end
    data ||= JSON.parse(response.body)
    {rate: data['rate'], updated_at: DateTime.parse(data['updated_at'])}
  end

  def quick_advance_rates(member_id)
    # we're not doing anything with member id right now, but presumably will need to use it at some point to check if
    # certain rates are available (e.g. member has enough collateral)
    raise ArgumentError, 'member_id must not be blank' if member_id.blank?
    response = @connection['rates/summary'].get
    JSON.parse(response.body).with_indifferent_access
  end

  def quick_advance_preview(member_id, advance_type, advance_term, rate)
    data = JSON.parse(File.read(File.join(Rails.root, 'db', 'service_fakes', 'quick_advance_preview.json'))).with_indifferent_access
    data[:funding_date] = data[:funding_date].gsub('-', ' ')
    data[:maturity_date] = data[:maturity_date].gsub('-', ' ')
    data
  end

  def quick_advance_confirmation(member_id, advance_type, advance_term, rate)
    # TODO: hit the proper MAPI endpoint, once it exists! In the meantime, always return the fake.

    data = JSON.parse(File.read(File.join(Rails.root, 'db', 'service_fakes', 'quick_advance_confirmation.json'))).with_indifferent_access
    data[:funding_date] = data[:funding_date].gsub('-', ' ')
    data[:maturity_date] = data[:maturity_date].gsub('-', ' ')
    data
  end

  def historical_price_indications(start_date, end_date, collateral_type, credit_type)
    # TODO: hit the proper MAPI endpoint, once it exists! In the meantime, construct plausible fake data.
    start_date = start_date.to_date
    end_date = end_date.to_date

    if !CREDIT_TYPES.include?(credit_type.to_sym)
      Rails.logger.warn("#{credit_type} was passed to RatesService.historical_price_indications as the credit_type arg and is invalid. Credit type must be one of these values: #{CREDIT_TYPES}")
      return nil
    end
    if !COLLATERAL_TYPES.include?(collateral_type.to_sym)
      Rails.logger.warn("#{collateral_type} was passed to RatesService.historical_price_indications as the collateral_type arg and is invalid. Collateral type must be one of these values: #{COLLATERAL_TYPES}")
      return nil
    end
    data = {
        start_date: start_date.to_date,
        end_date: end_date.to_date,
        collateral_type: collateral_type,
        credit_type: credit_type,
        rates_by_date: []
    }
    (start_date..end_date).each do |date|
      day_of_week = date.wday
      if day_of_week != 0 && day_of_week != 6
        data[:rates_by_date].push(
          {
            date: date,
            rates_by_term: []
          }
        )
        HISTORICAL_FRC_TERMS.each do |term|
          data[:rates_by_date].last[:rates_by_term].push(
            term: term,
            rate: rand.round(3),
            day_count_basis: "Actual/Actual",
            pay_freq: "Monthly"
          )
        end
      end
    end
    data.with_indifferent_access
  end

end