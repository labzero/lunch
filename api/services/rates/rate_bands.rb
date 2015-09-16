module MAPI
  module Services
    module Rates
      module RateBands
        include MAPI::Shared::Utils
        include MAPI::Shared::Constants

        SQL = "select FOBO_TERM_FREQUENCY,FOBO_TERM_UNIT,LOW_BAND_OFF_BP,HIGH_BAND_OFF_BP from web_adm.ao_rate_bands"

        def self.get_terms(rate_band)
          FREQUENCY_MAPPING.fetch( "#{rate_band["FOBO_TERM_FREQUENCY"]}#{rate_band["FOBO_TERM_UNIT"]}", [] )
        end

        def self.rate_bands(logger, environment)
          rate_bands = environment == :production ? rate_bands_production(logger) : rate_bands_development
          return nil if rate_bands.nil?
          rate_bands.each_with_object({}) do |rate_band, h|
            get_terms(rate_band).each{ |term| h[term] = rate_band }
          end.with_indifferent_access
        end

        def self.rate_bands_production(logger)
          fetch_hashes(logger, SQL)
        end

        def self.rate_bands_development
          fake('rate_bands')
        end
      end
    end
  end
end