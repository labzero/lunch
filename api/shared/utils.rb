module MAPI
  module Shared
    module Utils
      CACHE_KEY_SEPARATOR = '.'.freeze
      CACHE_KEY_BASE = ['mapi', 'cache'].join(CACHE_KEY_SEPARATOR).freeze
      extend ActiveSupport::Concern

      module ClassMethods
        def hash_from_pairs(key_value_pairs)
          Hash[key_value_pairs].with_indifferent_access
        end

        def fake(filename)
          JSON.parse(File.read(File.join(MAPI.root, 'fakes', "#{filename}.json")))
        end

        def fake_hash(filename)
          fake(filename).with_indifferent_access
        end

        def fake_hashes(filename)
          fake(filename).collect(&:with_indifferent_access)
        end
        
        def fetch_hash(logger, sql)
          begin
            ActiveRecord::Base.connection.execute(sql).try(:fetch_hash) || {}
          rescue => e
            logger.error(e.message)
            nil
          end
        end

        def quote(value)
          ActiveRecord::Base.connection.quote(value)
        end

        def dateify(date_or_string)
          Date.parse(date_or_string.to_s)
        end

        def fetch_hashes(logger, sql, map_values={}, downcase_keys=false)
          begin
            results = []
            cursor  = ActiveRecord::Base.connection.execute(sql)
            while row = cursor.fetch_hash()
              results.push(map_hash_values(row, map_values, downcase_keys))
            end
            results
          rescue => e
            logger.error(e.message)
            nil
          end
        end

        def fetch_objects(logger, sql)
          begin
            results = []
            cursor  = ActiveRecord::Base.connection.execute(sql)
            while objects = cursor.fetch()
              results += objects
            end
            results
          rescue => e
            logger.error(e.message)
            nil
          end
        end

        def decimal_to_percentage_rate(rate)
          rate.to_f.round(7) * 100.0 if rate
        end

        def percentage_to_decimal_rate(rate)
          rate.to_f / 100.0 if rate
        end

        def request_cache(request, key)
          cache_key = ([CACHE_KEY_BASE] + Array.wrap(key)).join(CACHE_KEY_SEPARATOR)
          unless request.env.has_key?(cache_key)
            request.env[cache_key] = yield
          end
          request.env[cache_key]
        end

        def should_fake?(app)
          app.environment != :production
        end

        def map_hash_values(hash, mapping, downcase_keys=false)
          mapping.each do |op, keys| 
            keys.each do |key|
              hash[key] = if op.respond_to?(:call)
                op.call(hash[key])
              else
                hash[key].try(op)
              end
            end
          end
          downcase_keys ? Hash[hash.map{ |k,v| [k.downcase,v] }] : hash
        end
      end
    end
  end
end
