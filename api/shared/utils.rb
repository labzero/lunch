module MAPI
  module Shared
    module Utils
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
        
        def fetch_hash(logger, sql)
          begin
            ActiveRecord::Base.connection.execute(sql).try(:fetch_hash) || {}
          rescue => e
            logger.error(:fetch_hash, e.message)
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
              map_values.each{ |op, keys| keys.each{ |key| row[key] = row[key].try(op) } }
              row = Hash[row.map{ |k,v| [k.downcase,v] }] if downcase_keys
              results.push(row)
            end
            results
          rescue => e
            logger.error(:fetch_hashes, e.message)
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
            logger.error(:fetch_objects, e.message)
            nil
          end
        end

        def decimal_to_percentage_rate(rate)
          rate.to_f.round(7) * 100.0 if rate
        end

        def percentage_to_decimal_rate(rate)
          rate.to_f / 100.0 if rate
        end
      end
    end
  end
end
