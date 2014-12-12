class EtransactAdvancesService

  def initialize
    @connection = ::RestClient::Resource.new Rails.configuration.mapi.endpoint, headers: {:'Authorization' => "Token token=\"#{ENV['MAPI_SECRET_TOKEN']}\""}
  end

  def etransact_active?
    response = @connection["etransact_advances/status"].get
    data = JSON.parse(response.body).with_indifferent_access
    data[:etransact_advances_status]
  end

end