module MAPI
  module Services
    module Rates
      module LoanTerms
        include MAPI::Shared::Utils
        include MAPI::Shared::Constants

        SQL = <<-EOS
            SELECT AO_TERM_BUCKET_ID, TERM_BUCKET_LABEL,
            WHOLE_LOAN_ENABLED, SBC_AGENCY_ENABLED, SBC_AAA_ENABLED, SBC_AA_ENABLED,
            END_TIME, trunc(OVERRIDE_END_DATE) AS OVERRIDE_END_DATE, OVERRIDE_END_TIME
            FROM WEB_ADM.AO_TERM_BUCKETS
        EOS

        def self.before_end_time?(app, bucket, now)
          end_time = end_time(app, bucket, now)
          end_time ? (now[:time] < end_time) : false
        end

        def self.loan_term(before_end_time, display_status, bucket_label, end_time)
          { trade_status: display_status && before_end_time, display_status: display_status, bucket_label: bucket_label, end_time: end_time.try(:iso8601), end_time_reached: !before_end_time }.with_indifferent_access
        end

        def self.hash_for_type(app, bucket, type, bucket_label, before_end_time, now)
          end_time = end_time(app, bucket, now)
          loan_term(before_end_time, display_status(bucket, type), bucket_label, end_time)
        end

        def self.hash_for_types(app, bucket, label, before_end_time, now)
          hash_from_pairs( LOAN_TYPES.map { |type| [type, hash_for_type(app, bucket, type, label, before_end_time, now)] } )
        end

        def self.value_for_term(app, bucket, now)
          bucket.nil? ? BLANK_TYPES : hash_for_types(app, bucket, bucket['TERM_BUCKET_LABEL'], before_end_time?(app, bucket, now), now)
        end

        def self.display_status(bucket, type)
          bucket[MAPI::Services::EtransactAdvances::TYPE_BUCKET_COLUMN_NO_MAPPING[type]] == 'Y' #veverything else mapping to false is intentional
        end

        def self.term_to_id(term)
          TERM_BUCKET_MAPPING[term]
        end

        def self.disable_term_sql(term_id)
          <<-SQL
              UPDATE WEB_ADM.AO_TERM_BUCKETS SET WHOLE_LOAN_ENABLED = 'N', SBC_AGENCY_ENABLED = 'N',
              SBC_AAA_ENABLED = 'N', SBC_AA_ENABLED = 'N' WHERE AO_TERM_BUCKET_ID = #{quote(term_id)}
          SQL
        end

        def self.disable_term(app, term)
          term_id = term_to_id(term)
          if app.settings.environment == :production
            execute_sql(app.logger, disable_term_sql(term_id)) == 1
          else
            true
          end
        end

        BLANK=loan_term(false,  false, 'NotFound', nil)
        BLANK_TYPES=hash_from_pairs( LOAN_TYPES.map{ |type| [type, BLANK] } )

        def self.loan_terms(app, allow_grace_period=false)
          data = if should_fake?(app)
            fake('etransact_advances_term_buckets_info')
          else
            fetch_hashes(app.logger, SQL, {to_date: ['OVERRIDE_END_DATE']})
          end
          return nil if data.nil?
          buckets = data.index_by{ |bucket| bucket['AO_TERM_BUCKET_ID'] }
          grace_period = if allow_grace_period
            MAPI::Services::EtransactAdvances::Settings.settings(app.settings.environment)['end_of_day_extension']
          else
            0
          end
          now = Time.zone.now
          now_hash = { time: now, date: now.to_date, grace_period: grace_period.to_i }
          hash_from_pairs( LOAN_TERMS.map { |term| [term, value_for_term(app, buckets[term_to_id(term)], now_hash)]} )
        end

        def self.end_time(app, bucket, now)
          if now[:date].present?
            if early_shutoff = early_shutoffs(app).select{ |shutoff| now[:date].to_date.iso8601 == shutoff['early_shutoff_date'] }.first
              if bucket_is_vrc?(bucket)
                parse_time(now[:date], early_shutoff['vrc_shutoff_time']) + now[:grace_period].minutes
              else
                parse_time(now[:date], early_shutoff['frc_shutoff_time']) + now[:grace_period].minutes
              end
            else
              if bucket_is_vrc?(bucket)
                parse_time(now[:date], default_shutoffs(app)['vrc']) + now[:grace_period].minutes
              else
                parse_time(now[:date], default_shutoffs(app)['frc']) + now[:grace_period].minutes
              end
            end
          end
        end

        def self.early_shutoffs(app)
          MAPI::Services::EtransactAdvances::ShutoffTimes.get_early_shutoffs(app)
        end

        def self.default_shutoffs(app)
          MAPI::Services::EtransactAdvances::ShutoffTimes.get_shutoff_times_by_type(app)
        end

        def self.bucket_is_vrc?(bucket)
          bucket['AO_TERM_BUCKET_ID'] == VRC_CREDIT_TYPE_BUCKET_ID
        end
      end
    end
  end
end