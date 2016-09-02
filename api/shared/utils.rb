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

        def execute_sql(logger, sql)
          begin
            ActiveRecord::Base.connection.execute(sql)
          rescue => e
            logger.error(e.message)
            nil
          end
        end

        def fetch_hash(logger, sql)
          begin
            cursor = execute_sql(logger, sql)
            if cursor
              cursor.fetch_hash || {}
            end
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
            cursor  = execute_sql(logger, sql)
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
            cursor  = execute_sql(logger, sql)
            raise MAPI::Shared::Errors::SQLError, "SQL execution failed" if cursor.nil?
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
          app.settings.environment != :production
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

        def nil_to_zero(value)
          value ? value : 0
        end

        def rescued_json_response(app)
          begin
            results = yield
            results.to_json if results
          rescue MAPI::Shared::Errors::ValidationError => error
            app.logger.error error.message
            app.halt 400, {error: {type: error.try(:type), code: error.code, value: error.value}}.to_json
          rescue => error
            app.logger.error error
            app.halt 400, {error: {type: :unknown, code: :unknown, value: error.message}}.to_json
          end
        end

        def weekend_or_holiday?(date, holidays)
          date.saturday? || date.sunday? || holidays.include?(date)
        end

        def flat_unique_array(array)
          Array.wrap(array).flatten.uniq
        end
      end
    end
  end
end
