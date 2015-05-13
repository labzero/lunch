class MAPIService

  def initialize(request)
    @connection = ::RestClient::Resource.new Rails.configuration.mapi.endpoint, headers: {:'Authorization' => "Token token=\"#{ENV['MAPI_SECRET_TOKEN']}\"", :'X-Request-ID' => request.uuid}
  end

  def ping
    begin
      response = @connection['healthy'].get
      return JSON.parse(response.body)
    rescue Exception => e
      Rails.logger.error("MAPI PING failed: #{e.message}")
      return false
    end
  end

end