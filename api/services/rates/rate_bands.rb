module MAPI
  module Services
    module Rates
      module RateBands

        SQL = 'select * from web_adm.ao_rate_bands'

        def self.rate_bands(environment)
          environment == :production ? rate_bands_production : rate_bands_development
        end

        def self.rate_bands_production
          MAPI::Shared::ActiveRecord.fetch_hashes(SQL)
        end

        def self.rate_bands_development
          JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'rate_bands.json')))
        end
      end
    end
  end
end