class UsersService < MAPIService

  def user_roles(username)
    begin
      response = @connection["users/#{username}/roles"].get
    rescue RestClient::Exception => e
      Rails.logger.warn("UsersService.user_roles encountered a RestClient error: #{e.class.name}:#{e.http_code}") unless e.message == 'User not found'
      return nil
    rescue Errno::ECONNREFUSED => e
      Rails.logger.warn("UsersService.user_roles encountered a connection error: #{e.class.name}")
      return nil
    end
    JSON.parse(response.body)
  end

end