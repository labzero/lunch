module RedisHelper
  def self.add_url_namespace(url, namespace)
    redis_uri = URI(url)
    redis_uri.path = case redis_uri.path
    when '', '/'
      '/' + namespace
    when /\A\/\d+(\/)?\z/
      redis_uri.path + ('/' if $1.nil?).to_s + namespace
    else
      redis_uri.path + '-' + namespace
    end
    redis_uri.to_s
  end

  def self.namespace_from_url(url)
    matches = URI(url).path.match(/\A\/(?:\d+(?:\/|\z))?(.+)?\z/)
    matches[1] if matches
  end
end