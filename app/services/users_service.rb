class UsersService < MAPIService

  def user_roles(username)
    begin
      JSON.parse(@connection["users/#{username}/roles"].get.body)
    rescue RestClient::Exception => e
      warn(:user_roles, "RestClient error: #{e.class.name}:#{e.http_code}") unless e.http_body == 'User not found'
    rescue Errno::ECONNREFUSED => e
      warn(:user_roles, "connection error: #{e.class.name}")
    end
  end

end