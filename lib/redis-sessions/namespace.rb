module Redis::Store::Namespace
  def hmset(key, *attrs)
    namespace(key) { |key| super(key, *attrs) }
  end

  def hgetall(key, options=nil)
    namespace(key) { |key| super(key, options) }
  end

  def hdel(key, *attrs)
    namespace(key) { |key| super(key, *attrs) }
  end
end