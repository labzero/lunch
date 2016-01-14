module Redis::Store::Marshalling
  def hgetall(key, options=nil)
    unmarshalled = {}
    super(key).each do |key, value|
      unmarshalled[key] = _unmarshal(value, options)
    end
    unmarshalled
  end

  def hmset(key, *attrs)
    options = attrs.pop if attrs.length.odd?
    marshalled_attrs = []
    attrs.each_with_index do |value, index|
      index.odd? ? _marshal(value, options) {|mv| marshalled_attrs << encode(mv)} : marshalled_attrs << encode(value)
    end
    super key, *marshalled_attrs
  end
end
