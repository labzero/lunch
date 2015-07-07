class EtransactAdvancesService < MAPIService

  def etransact_active?
    begin
      response = @connection["etransact_advances/status"].get
    rescue RestClient::Exception => e
      Rails.logger.warn("EtransactAdvancesService.etransact_active? encountered a RestClient error: #{e.class.name}:#{e.http_code}")
      return false
    rescue Errno::ECONNREFUSED => e
      Rails.logger.warn("EtransactAdvancesService.etransact_active? encountered a connection error: #{e.class.name}")
      return false
    end
    data = JSON.parse(response.body).with_indifferent_access
    data[:etransact_advances_status]
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

end