class MAPIService

  def initialize(request)
    @request = request
    @connection = ::RestClient::Resource.new Rails.configuration.mapi.endpoint, headers: {:'Authorization' => "Token token=\"#{ENV['MAPI_SECRET_TOKEN']}\"", :'X-Request-ID' => request_uuid}
  end

  def request
    @request
  end

  def request_uuid
    @request.try(:uuid)
  end

  def request_user
    warden_user = @request.session['warden.user.user.key']
    User.find(warden_user[0][0]) if warden_user
  end

  def request_member_id
    @request.session['member_id']
  end

  def request_member_name
    @request.session['member_name']
  end

  def member_id_to_name(member_id)
    (member_id == request_member_id ? request_member_name : nil) || member_id
  end
  
  def warn(name, msg, error, &error_handler)
    Rails.logger.warn("#{self.class.name}##{name} encountered a #{msg}")
    error_handler.call(name, msg, error) if error_handler
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
  
  def get(name, endpoint, &error_handler)
    begin
      @connection[endpoint].get
    rescue RestClient::Exception => e
      warn(name, "RestClient error: #{e.class.name}:#{e.http_code}", e, &error_handler)
    rescue Errno::ECONNREFUSED => e
      warn(name, "connection error: #{e.class.name}", e, &error_handler)
    end
  end

  def post(name, endpoint, body, content_type = nil, &error_handler)
    begin
      if content_type
        @connection[endpoint].post body, {:content_type => content_type}
      else
        @connection[endpoint].post body
      end
    rescue RestClient::Exception => e
      warn(name, "RestClient error: #{e.class.name}:#{e.http_code}", e, &error_handler)
    rescue Errno::ECONNREFUSED => e
      warn(name, "connection error: #{e.class.name}", e, &error_handler)
    end
  end
  
  def parse(name, response, &error_handler)
    begin
      response.nil? ? nil : JSON.parse(response.body)
    rescue JSON::ParserError => e
      warn(name, "JSON parsing error: #{e}", e, &error_handler)
    end
  end
  
  def get_hash(name, endpoint, &error_handler)
    get_json(name, endpoint, &error_handler).try(:with_indifferent_access)
  end
  
  def get_json(name, endpoint, &error_handler)
    parse(name, get(name, endpoint, &error_handler), &error_handler)
  end

  def post_hash(name, endpoint, body, &error_handler)
    post_json(name, endpoint, body, &error_handler).try(:with_indifferent_access)
  end

  def post_json(name, endpoint, body, &error_handler)
    parse(name, post(name, endpoint, body.to_json, 'application/json', &error_handler), &error_handler)
  end

  def fix_date(data, field=:as_of_date)
    fields = [field].flatten
    fields.each do |field|
      data[field] = data[field].to_date if data && data[field]
    end
    data
  end

end