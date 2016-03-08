module MAPI
  module Services
    module Rates
      module LoanTerms
        include MAPI::Shared::Utils
        include MAPI::Shared::Constants

        DATETIME_FORMAT = '%Y-%m-%d%H%M'.freeze

        SQL = <<-EOS
            SELECT AO_TERM_BUCKET_ID, TERM_BUCKET_LABEL,
            WHOLE_LOAN_ENABLED, SBC_AGENCY_ENABLED, SBC_AAA_ENABLED, SBC_AA_ENABLED,
            END_TIME, trunc(OVERRIDE_END_DATE) AS OVERRIDE_END_DATE, OVERRIDE_END_TIME
            FROM WEB_ADM.AO_TERM_BUCKETS
        EOS

        def self.appropriate_end_time(bucket, now)
          override_time = override_end_time(bucket, now)
          now[:date] == override_time.try(:to_date) ? override_time : end_time(bucket, now)
        end

        def self.trade_status(bucket, now)
          end_time = appropriate_end_time(bucket, now)
          end_time ? (now[:time] < end_time) : false
        end

        def self.loan_term(trade_status, display_status, bucket_label)
          { trade_status: display_status && trade_status, display_status: display_status, bucket_label: bucket_label }.with_indifferent_access
        end

        def self.hash_for_type(bucket, type, bucket_label, trade_status)
          loan_term(trade_status, display_status(bucket, type), bucket_label)
        end

        def self.hash_for_types(bucket, label, trade_status)
          hash_from_pairs( LOAN_TYPES.map { |type| [type, hash_for_type(bucket, type, label, trade_status)] } )
        end

        def self.value_for_term(bucket, now)
          bucket.nil? ? BLANK_TYPES : hash_for_types(bucket, bucket['TERM_BUCKET_LABEL'], trade_status(bucket, now))
        end

        def self.display_status(bucket, type)
          bucket[MAPI::Services::EtransactAdvances::TYPE_BUCKET_COLUMN_NO_MAPPING[type]] == 'Y' #veverything else mapping to false is intentional
        end

        def self.term_to_id(term)
          MAPI::Services::EtransactAdvances::TERM_BUCKET_MAPPING[term]
        end

        BLANK=loan_term(false,  false, 'NotFound')
        BLANK_TYPES=hash_from_pairs( LOAN_TYPES.map{ |type| [type, BLANK] } )

        def self.loan_terms(logger, environment, allow_grace_period=false)
          settings = MAPI::Services::EtransactAdvances::Settings.settings(environment)
          now = Time.zone.now
          grace_period = allow_grace_period ? settings['end_of_day_extension'] : 0
          now_hash = { time: now, date: now.to_date, grace_period: grace_period.to_i }
          data = term_bucket_data(logger, environment)
          return nil if data.nil?
          buckets = data.index_by{ |bucket| bucket['AO_TERM_BUCKET_ID'] }
          hash_from_pairs( LOAN_TERMS.map { |term| [term, value_for_term(buckets[term_to_id(term)], now_hash)]} )
        end

        def self.term_bucket_data(logger, environment)
          environment == :production ? term_bucket_data_production(logger) : term_bucket_data_development
        end

        def self.term_bucket_data_production(logger)
          fetch_hashes(logger, SQL)
        end

        def self.term_bucket_data_development
          rows = fake('etransact_advances_term_buckets_info')
          rows.each{ |row| row['OVERRIDE_END_DATE'] = row['OVERRIDE_END_DATE'].to_date }
          rows[rows.index{ |row| /2 years/i === row['TERM_BUCKET_LABEL'] }]['OVERRIDE_END_DATE'] = Time.zone.today
          rows
        end

        def self.parse_time(date, time)
          # we need to change to a DateTime since `change` on Time doesn't support offsets
          parsed = Time.strptime(date.to_s + time.to_s, DATETIME_FORMAT).to_datetime
          parsed.change(offset: Time.zone.formatted_offset)
        end

        def self.override_end_time(bucket, now)
          if bucket['OVERRIDE_END_DATE'].present? && bucket['OVERRIDE_END_TIME'].present?
            parse_time(bucket['OVERRIDE_END_DATE'], bucket['OVERRIDE_END_TIME']) + now[:grace_period].minutes
          end
        end

        def self.end_time(bucket, now)
          if now[:date].present? && bucket['END_TIME'].present?
            parse_time(now[:date], bucket['END_TIME']) + now[:grace_period].minutes
          end
        end
      end
    end
  end
end