module MAPI
  module Shared
    module ActiveRecord
      def self.fetch_hashes(sql)
        begin
          results = []
          cursor  = ActiveRecord::Base.connection.execute(sql)
          while row = cursor.fetch_hash()
            results.push(row)
          end
          results
        rescue => e
          warn(:fetch_hashes, e.message)
        end
      end
    end
  end
end