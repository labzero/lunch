class RatesService < MAPIService
  COLLATERAL_TYPES = %i(standard sbc)
  CREDIT_TYPES = %i(frc vrc 1m_libor 3m_libor 6m_libor daily_prime embedded_cap)
  ARC_CREDIT_TYPES = %i(1m_libor 3m_libor 6m_libor daily_prime)
  HISTORICAL_FRC_TERM_MAPPINGS = {
    :'1m' => '1_month',
    :'2m' => '2_months',
    :'3m' => '3_months',
    :'6m' => '6_months',
    :'1y' => '1_year',
    :'2y' => '2_years',
    :'3y' => '3_years',
    :'5y' => '5_years',
    :'7y' => '7_years',
    :'10y' => '10_years',
    :'15y' => '15_years',
    :'20y' => '20_years',
    :'30y' => '30_years'
  }
  HISTORICAL_ARC_TERM_MAPPINGS = {
    :'1y' => '1_year',
    :'2y' => '2_years',
    :'3y' => '3_years',
    :'5y' => '5_years'
  }
  HISTORICAL_VRC_TERM_MAPPINGS = {
    :'1d' => '1_day'
  }

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
    collateral_type = collateral_type.to_sym
    credit_type = credit_type.to_sym

    if !CREDIT_TYPES.include?(credit_type)
      Rails.logger.warn("#{credit_type} was passed to RatesService.historical_price_indications as the credit_type arg and is invalid. Credit type must be one of these values: #{CREDIT_TYPES}")
      return nil
    end
    if !COLLATERAL_TYPES.include?(collateral_type)
      Rails.logger.warn("#{collateral_type} was passed to RatesService.historical_price_indications as the collateral_type arg and is invalid. Collateral type must be one of these values: #{COLLATERAL_TYPES}")
      return nil
    end

    # TODO remove this code once you support all collateral_types and credit_types
    # START of code that should be deleted once all args are supported
    if credit_type == :embedded_cap || credit_type == :vrc
      Rails.logger.warn("Currently, RatesService.historical_price_indications only accepts 'frc', '1m_libor', '3m_libor', '6m_libor' and daily_prime' as the credit_type arg. You supplied #{credit_type}, which is not yet supported.")
      return nil
    end
    if collateral_type != :standard
      Rails.logger.warn("Currently, RatesService.historical_price_indications only accepts 'standard' as the collateral_type arg. You supplied #{collateral_type}, which is not yet supported.")
      return nil
    end
    # END of code that should be deleted once all args are supported

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
        r = Random.new(date.to_time.to_i + CREDIT_TYPES.index(credit_type))
        data[:rates_by_date].push(
          {
            date: date,
            rates_by_term: []
          }
        )
        terms = case credit_type
        when :frc
          HISTORICAL_FRC_TERM_MAPPINGS.keys
        when :'1m_libor', :'3m_libor', :'6m_libor', :daily_prime
          HISTORICAL_ARC_TERM_MAPPINGS.keys
        else
          # TODO add in the proper terms for 'vrc' and 'embedded_cap' once those are rigged up
        end
        terms.each do |term|
          rate = if ARC_CREDIT_TYPES.include?(credit_type)
            r.rand(-200..200)
          else
            r.rand.round(3)
          end
          data[:rates_by_date].last[:rates_by_term].push(
            term: term,
            rate: rate,
            day_count_basis: "Actual/Actual",
            pay_freq: "Monthly"
          )
        end
      end
    end
    data.with_indifferent_access
  end

end