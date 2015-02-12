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

end