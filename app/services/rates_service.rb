class RatesService
  def initialize
    @connection = ::RestClient::Resource.new Rails.configuration.mapi.endpoint
  end

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
    raise ArgumentError, 'member_id must not be blank' if member_id.blank?
    raise ArgumentError, 'advance_type must not be blank' if advance_type.blank?
    raise ArgumentError, 'advance_term must not be blank' if advance_term.blank?
    raise ArgumentError, 'rate must not be blank' if rate.blank?

    # TODO: hit the proper MAPI endpoint, once it exists! In the meantime, always return the fake.
    # if @connection
    #   # hit the proper MAPI endpoint
    # else
    #   JSON.parse(File.read(File.join(Rails.root, 'db', 'service_fakes', 'quick_advance_preview.json'))).with_indifferent_access
    # end

    data = JSON.parse(File.read(File.join(Rails.root, 'db', 'service_fakes', 'quick_advance_preview.json'))).with_indifferent_access
    data[:funding_date] = data[:funding_date].gsub('-', ' ')
    data[:maturity_date] = data[:maturity_date].gsub('-', ' ')
    data
  end

  def quick_advance_confirmation(member_id, advance_type, advance_term, rate)
    raise ArgumentError, 'member_id must not be blank' if member_id.blank?
    raise ArgumentError, 'advance_type must not be blank' if advance_type.blank?
    raise ArgumentError, 'advance_term must not be blank' if advance_term.blank?
    raise ArgumentError, 'rate must not be blank' if rate.blank?

    # TODO: hit the proper MAPI endpoint, once it exists! In the meantime, always return the fake.
    # if @connection
    #   # hit the proper MAPI endpoint
    # else
    #   JSON.parse(File.read(File.join(Rails.root, 'db', 'service_fakes', 'quick_advance_confirmation.json'))).with_indifferent_access
    # end

    data = JSON.parse(File.read(File.join(Rails.root, 'db', 'service_fakes', 'quick_advance_confirmation.json'))).with_indifferent_access
    data[:funding_date] = data[:funding_date].gsub('-', ' ')
    data[:maturity_date] = data[:maturity_date].gsub('-', ' ')
    data
  end

end