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

        def fetch_hashes(logger, sql)
          begin
            results = []
            cursor  = ActiveRecord::Base.connection.execute(sql)
            while row = cursor.fetch_hash()
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
          rate.to_f.round(5) * 100.0 if rate
        end

        def percentage_to_decimal_rate(rate)
          rate.to_f / 100.0 if rate
        end
      end
    end
  end
end
