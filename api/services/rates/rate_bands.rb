module MAPI
  module Services
    module Rates
      module RateBands
        include MAPI::Shared::Utils
        include MAPI::Shared::Constants

        SQL = "select FOBO_TERM_FREQUENCY,FOBO_TERM_UNIT,LOW_BAND_OFF_BP,LOW_BAND_WARN_BP,HIGH_BAND_OFF_BP,HIGH_BAND_WARN_BP from web_adm.ao_rate_bands"
        VALID_RATE_BAND_UPDATE_FIELDS = ['LOW_BAND_OFF_BP', 'LOW_BAND_WARN_BP', 'HIGH_BAND_OFF_BP', 'HIGH_BAND_WARN_BP']

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

        def self.update_rate_bands(app, rate_bands)
          unless should_fake?(app)
            ActiveRecord::Base.transaction(isolation: :read_committed) do
              rate_bands.each do |term, rate_band_info|
                set_clause = build_update_rate_band_set_clause(rate_band_info)
                update_rate_band_sql = <<-SQL
                  UPDATE WEB_ADM.AO_RATE_BANDS
                  SET #{set_clause}
                  WHERE FOBO_TERM_UNIT = #{quote(TERM_MAPPING[term][:frequency_unit])}
                  AND FOBO_TERM_FREQUENCY = #{quote(TERM_MAPPING[term][:frequency])}
                SQL
                raise MAPI::Shared::Errors::SQLError, "Failed to update rate band with term: #{term}" unless execute_sql(app.logger, update_rate_band_sql)
              end
            end
          end
          true
        end

        def self.build_update_rate_band_set_clause(rate_band_info)
          set_clause = []
          rate_band_info.each do |column_name, column_value|
            column_name = column_name.to_s.upcase
            raise MAPI::Shared::Errors::InvalidFieldError.new("#{column_name} is an invalid field", column_name, column_value) unless VALID_RATE_BAND_UPDATE_FIELDS.include?(column_name)
            set_clause << "#{column_name} = #{quote(column_value.to_i)}"
          end
          set_clause.join(', ')
        end
      end
    end
  end
end