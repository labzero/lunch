class Rack::Session::Redis

  SEPARATOR = "\x1D".freeze
  SEPARATOR_ESCAPE = "\e".freeze
  SEPARATOR_ESCAPED = "#{SEPARATOR_ESCAPE}#{SEPARATOR}".freeze
  SID_KEY = '__sid__'.freeze

  def generate_sid
    loop do
      sid = super
      break sid unless @pool.exists(sid)
    end
  end

  def get_session(env, sid)
    with_lock(env, [nil, {}]) do
      unless sid and session = fetch_session(@pool, sid, @default_options)
        sid, session = generate_sid, {}
        unless /^OK/ =~ persist_session(@pool, sid, session, @default_options, session)
          raise "Session collision on '#{sid.inspect}'"
        end
      end
      [sid, session]
    end
  end

  def set_session(env, session_id, new_session, options)
    with_lock(env, false) do
      persist_session(@pool, session_id, new_session, options)
      session_id
    end
  end

  protected

  def persist_session(connection, sid, session, options=nil, old_session=nil)
    old_session ||= fetch_session(connection, sid, options)
    update_hash, remove_hash = changed_keys(old_session, session)
    update_hash[SID_KEY] = sid # users aren't allowed to change this value, which is used to reserve space for our session
    connection.multi do |multi|
      multi.hdel(sid, remove_hash.keys) if remove_hash.present?
      multi.hmset(sid, *(update_hash.to_a.flatten(1) + [options])) if update_hash.present?
    end.first
  end

  def fetch_session(connection, sid, options=nil)
    flat_hash = connection.hgetall(sid, options)
    session = {}
    flat_hash.delete(SID_KEY)
    flat_hash.each do |key, value|
      h = session
      path = split_prefixed_key(key)
      path[0..-2].each do |segment|
        h[segment] ||= {}
        h = h[segment]
      end
      h[path.last] = value
    end
    session
  end

  def flatten_session(session, prefix=nil)
    flat_session = {}
    if session.empty?
      flat_session[prefix] = {} if prefix
    else
      session.each do |key, value|
        if value.is_a?(Hash)
          flat_session.merge!(flatten_session(value, prefix_key(prefix, key)))
        else
          flat_session[prefix_key(prefix, key)] = value
        end
      end
    end
    flat_session
  end

  # returns an array of hashes like [{<changed/added keys>: <values>}, {<deleted keys>: <values>}]
  def changed_keys(old_session, new_session)
    flat_old_session = flatten_session(old_session)
    flat_new_session = flatten_session(new_session)

    old_keys = flat_old_session.keys
    new_keys = flat_new_session.keys
    removed_keys = old_keys - new_keys
    added_keys = new_keys - old_keys
    changed_keys = []

    (old_keys & new_keys).each do |key|
      if flat_old_session[key] != flat_new_session[key]
        changed_keys << key
      end
    end

    update_hash = Hash[*(((added_keys + changed_keys).collect { |k| [k, flat_new_session[k]] } ).flatten(1))]
    remove_hash = Hash[*((removed_keys.collect { |k| [k, flat_old_session[k]] } ).flatten(1))]

    [update_hash, remove_hash]
  end

  # prefixes the key with the separator and escapes any separators it finds
  def prefix_key(prefix, key)
    string_key = key.to_s.gsub(SEPARATOR, SEPARATOR_ESCAPED).to_s
    prefix ? prefix.to_s + SEPARATOR + string_key : string_key
  end

  # splits prefixed keys and unescapes separators
  def split_prefixed_key(key)
    key.split(/(?<!#{SEPARATOR_ESCAPE})#{SEPARATOR}/).each { |k| k.gsub!(SEPARATOR_ESCAPED, SEPARATOR) }
  end

end