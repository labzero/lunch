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
  CURRENT_CREDIT_TYPES = %i(vrc frc arc)
  CURRENT_VRC_CREDIT_TYPES = %i(advance_maturity overnight_fed_funds_benchmark basis_point_spread_to_benchmark advance_rate)
  CURRENT_FRC_CREDIT_TYPES = %i(advance_maturity treasury_benchmark_maturity nominal_yield_of_benchmark basis_point_spread_to_benchmark advance_rate)
  CURRENT_ARC_CREDIT_TYPES = %i(advance_maturity 1_month_libor 3_month_libor 6_month_libor prime)

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

  def rate(type, term)
    begin
      response = @connection["rates/#{type}/#{term}"].get
    rescue RestClient::Exception => e
      Rails.logger.warn("RatesService.rate encountered a RestClient error: #{e.class.name}:#{e.http_code}")
      return nil
    rescue Errno::ECONNREFUSED => e
      Rails.logger.warn("RatesService.rate encountered a connection error: #{e.class.name}")
      return nil
    end

    begin
      data = JSON.parse(response.body).with_indifferent_access
    rescue JSON::ParserError => e
      Rails.logger.warn("RatesService.rate encountered a JSON parsing error: #{e}")
      return nil
    end

    data[:rate] = data[:rate].to_f if data[:rate]
    data[:updated_at] = DateTime.parse(data[:updated_at]) if data[:updated_at]
    data
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

  def quick_advance_preview(member_id, amount, advance_type, advance_term, rate)
    data = JSON.parse(File.read(File.join(Rails.root, 'db', 'service_fakes', 'quick_advance_preview.json'))).with_indifferent_access
    fake_quick_advance_response(data, amount, advance_type, advance_term, rate)
  end

  def quick_advance_confirmation(member_id, amount, advance_type, advance_term, rate)
    # TODO: hit the proper MAPI endpoint, once it exists! In the meantime, always return the fake.
    data = JSON.parse(File.read(File.join(Rails.root, 'db', 'service_fakes', 'quick_advance_confirmation.json'))).with_indifferent_access
    data[:advance_number] = Random.rand(999999).to_s.rjust(6, '0')
    data[:initiated_at] = Time.zone.now.to_datetime
    fake_quick_advance_response(data, amount, advance_type, advance_term, rate)
  end

  def current_price_indications(collateral_type, credit_type)
    collateral_type = collateral_type.to_sym
    credit_type = credit_type.to_sym

    if !CURRENT_CREDIT_TYPES.include?(credit_type)
      Rails.logger.warn("#{credit_type} was passed to RatesService.current_price_indications as the credit_type arg and is invalid. Credit type must be one of these values: #{CURRENT_CREDIT_TYPES}")
      return nil
    end
    if !COLLATERAL_TYPES.include?(collateral_type)
      Rails.logger.warn("#{collateral_type} was passed to RatesService.current_price_indications as the collateral_type arg and is invalid. Collateral type must be one of these values: #{COLLATERAL_TYPES}")
      return nil
    end
    response = @connection["rates/price_indications/current/#{credit_type}/#{collateral_type}"].get
    data ||= JSON.parse(response.body)
    data
  end

  def historical_price_indications(start_date, end_date, collateral_type, credit_type)
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

    # TODO remove this code once you support 'embedded_cap'
    # START of code that should be deleted once embedded_cap is supported
    if credit_type == :embedded_cap 
      Rails.logger.warn("Currently, RatesService.historical_price_indications only accepts 'frc', 'vrc', '1m_libor', '3m_libor', '6m_libor' and daily_prime' as the credit_type arg. You supplied #{credit_type}, which is not yet supported.")
      return nil
    end
    # END of code that should be deleted once embedded_cap is supported

    begin
      response = @connection["rates/price_indication/historical/#{start_date}/#{end_date}/#{collateral_type}/#{credit_type}"].get
    rescue RestClient::Exception => e
      Rails.logger.warn("RatesService.current_overnight_vrc encountered a RestClient error: #{e.class.name}:#{e.http_code}")
      return nil
    rescue Errno::ECONNREFUSED => e
      Rails.logger.warn("RatesService.overnight_vrc encountered a connection error: #{e.class.name}")
      return nil
    end
    JSON.parse(response.body).with_indifferent_access
  end

  protected

  def fake_quick_advance_response(data, amount, advance_type, advance_term, rate)
    data[:funding_date] = data[:funding_date].to_date
    data[:maturity_date] = data[:maturity_date].to_date
    data[:advance_rate] = rate
    data[:advance_amount] = amount
    data[:advance_term] = I18n.t("dashboard.quick_advance.table.axes_labels.#{advance_term}")
    data[:advance_type] = case advance_type
    when 'whole'
      I18n.t('dashboard.quick_advance.table.whole_loan')
    when 'aaa', 'aa', 'agency'
      I18n.t("dashboard.quick_advance.table.#{advance_type}")
    else
      I18n.t('global.none')
    end
    data
  end

end