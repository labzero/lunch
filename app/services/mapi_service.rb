class MAPIService

  def initialize(request)
    @connection = ::RestClient::Resource.new Rails.configuration.mapi.endpoint, headers: {:'Authorization' => "Token token=\"#{ENV['MAPI_SECRET_TOKEN']}\"", :'X-Request-ID' => request.uuid}
  end

end