class MAPIService

  def initialize(request)
    @connection = ::RestClient::Resource.new Rails.configuration.mapi.endpoint, headers: {:'Authorization' => "Token token=\"#{ENV['MAPI_SECRET_TOKEN']}\"", :'X-Request-ID' => request.uuid}
  end
  
  def warn(name, msg)
    Rails.logger.warn("#{self.class.name}##{name} encountered a #{msg}")
    nil
  end

  def ping
    begin
      response = @connection['healthy'].get
      JSON.parse(response.body)
    rescue Exception => e
      Rails.logger.error("MAPI PING failed: #{e.message}")
      false
    end
  end
  
  # http://stackoverflow.com/questions/5100299/how-to-get-the-name-of-the-calling-method
  # http://stackoverflow.com/questions/133357/how-do-you-find-the-namespace-module-name-programatically-in-ruby-on-rails
  def caller(depth=2)
    "#{self.class.to_s.demodulize}.#{caller_locations(depth,depth)[0].label}" 
  end
  
  def get(name, endpoint)
    begin
      @connection[endpoint].get
    rescue RestClient::Exception => e
      warn(name, "RestClient error: #{e.class.name}:#{e.http_code}")
    rescue Errno::ECONNREFUSED => e
      warn(name, "connection error: #{e.class.name}")
    end
  end
  
  def parse(name, response)
    begin
      response.nil? ? nil : JSON.parse(response.body)
    rescue JSON::ParserError => e
      warn(name, "JSON parsing error: #{e}")
    end
  end
  
  def get_fake_hash(name, filename)
    begin
      JSON.parse(File.read(File.join(Rails.root, 'db', 'service_fakes', filename))).with_indifferent_access
    rescue JSON::ParserError => e
      warn(name, "JSON parsing error: #{e}")
    end
  end
  
  def get_hash(name, endpoint)
    parse(name, get(name, endpoint)).try(:with_indifferent_access)
  end
  
  def get_json(name, endpoint)
    parse(name, get(name, endpoint))
  end
end