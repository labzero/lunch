module MAPI
  module Services
    module EtransactAdvances
      module Limits
        include MAPI::Shared::Utils
        include MAPI::Shared::Constants

        VALID_LIMIT_FIELDS = %w(AO_TERM_BUCKET_ID WHOLE_LOAN_ENABLED SBC_AGENCY_ENABLED SBC_AAA_ENABLED SBC_AA_ENABLED
          LOW_DAYS_TO_MATURITY HIGH_DAYS_TO_MATURITY MIN_ONLINE_ADVANCE TERM_DAILY_LIMIT PRODUCT_TYPE END_TIME OVERRIDE_END_DATE
          OVERRIDE_END_TIME)

        def self.get_limits(app)
          etransact_limits = <<-SQL
            SELECT AO_TERM_BUCKET_ID, WHOLE_LOAN_ENABLED, SBC_AGENCY_ENABLED, SBC_AAA_ENABLED, SBC_AA_ENABLED, LOW_DAYS_TO_MATURITY,
            HIGH_DAYS_TO_MATURITY, MIN_ONLINE_ADVANCE, TERM_DAILY_LIMIT, PRODUCT_TYPE, END_TIME, OVERRIDE_END_DATE,
            OVERRIDE_END_TIME FROM WEB_ADM.AO_TERM_BUCKETS
          SQL
          etransact_limits_array = if should_fake?(app)
            JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'etransact_limits.json')))
          else
            MAPI::Services::EtransactAdvances.fetch_hashes(app.logger, etransact_limits)
          end
          reverse_bucket_mapping = TERM_BUCKET_MAPPING.invert
          etransact_limits_array.each do |bucket|
            bucket['TERM'] = reverse_bucket_mapping[bucket['AO_TERM_BUCKET_ID']]
          end
          etransact_limits_array
        end

        def self.update_limits(app, limits)
          unless should_fake?(app)
            ActiveRecord::Base.transaction(isolation: :read_committed) do
              limits.each do |term, bucket_data|
                set_clause = build_update_limit_set_clause(bucket_data)
                bucket_id = MAPI::Services::Rates::LoanTerms.term_to_id(term)
                update_limits_sql = <<-SQL
                  UPDATE WEB_ADM.AO_TERM_BUCKETS
                  SET #{set_clause}
                  WHERE AO_TERM_BUCKET_ID = #{quote(bucket_id)}
                SQL
                raise MAPI::Shared::Errors::SQLError, "Failed to update limit with term: #{term}" unless execute_sql(app.logger, update_limits_sql)
              end
            end
          end
          true
        end

        def self.build_update_limit_set_clause(bucket_data)
          set_clause = bucket_data.collect do |key, value|
            key = key.to_s.upcase
            raise MAPI::Shared::Errors::InvalidFieldError.new("#{key} is an invalid field", key, value) unless VALID_LIMIT_FIELDS.include?(key)
            value = process_limit_value(key, value)
            "#{key} = #{quote(value)}"
          end
          set_clause.join(', ')
        end

        def self.process_limit_value(key, value)
          case key
          when 'MIN_ONLINE_ADVANCE', 'TERM_DAILY_LIMIT'
            value.to_s.gsub(',', '').to_i
          else
            value
          end
        end
      end
    end
  end
end