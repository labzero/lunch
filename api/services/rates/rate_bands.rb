module MAPI
  module Services
    module Rates
      module RateBands

        SQL = 'select * from web_adm.ao_rate_bands'

        def self.rate_bands(environment)
          environment == :production ? rate_bands_production : rate_bands_development
        end

        def self.rate_bands_production
          begin
            results = []
            cursor  = ActiveRecord::Base.connection.execute(SQL)
            while row = cursor.fetch_hash()
              results.push(row)
            end
            results
          rescue => e
            warn(:term_bucket_data_production, e.message)
          end
        end

        def self.rate_bands_development
          JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'rate_bands.json')))
        end
      end
    end
  end
end