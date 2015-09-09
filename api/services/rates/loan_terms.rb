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

        def self.appropriate_end_time(bucket, now)
          now[:date] == override_end_date(bucket) ? override_end_time(bucket) : end_time(bucket)
        end

        def self.trade_status(bucket, now)
          now[:time] < appropriate_end_time(bucket, now)
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
          bucket.nil? ? BLANK_TYPES : hash_for_types(bucket, bucket_label(bucket), trade_status(bucket, now))
        end

        def self.display_status(bucket, type)
          bucket[MAPI::Services::EtransactAdvances::TYPE_BUCKET_COLUMN_NO_MAPPING[type]] == 'Y'
        end

        def self.term_to_id(term)
          MAPI::Services::EtransactAdvances::TERM_BUCKET_MAPPING[term]
        end

        BLANK=loan_term(false,  false, 'NotFound')
        BLANK_TYPES=hash_from_pairs( LOAN_TYPES.map{ |type| [type, BLANK] } )

        def self.loan_terms(logger,environment)
          now     = { date: Time.zone.now.to_date, time: Time.zone.now.strftime("%H%M%S") }
          buckets = term_bucket_data(logger, environment).index_by{ |bucket| id(bucket) }
          hash_from_pairs( LOAN_TERMS.map { |term| [term, value_for_term(buckets[term_to_id(term)], now)]} )
        end

        def self.term_bucket_data(logger, environment)
          environment == :production ? term_bucket_data_production(logger) : term_bucket_data_development
        end

        def self.term_bucket_data_production(logger)
          begin
            results = []
            cursor  = ActiveRecord::Base.connection.execute(SQL)
            while row = cursor.fetch_hash()
              results.push(row)
            end
            results
          rescue => e
            logger.error( "MAPI::Services::Rates::LoanTerms.term_bucket_data_production encountered: #{e.message}" )
          end
        end

        def self.term_bucket_data_development
          JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'etransact_advances_term_buckets_info.json')))
        end

        def self.time(bucket, field)
          bucket[field] + '00'
        end

        def self.override_end_time(bucket)
          time(bucket,'OVERRIDE_END_TIME')
        end

        def self.end_time(bucket)
          time(bucket,'END_TIME')
        end

        def self.override_end_date(bucket)
          bucket['OVERRIDE_END_DATE']
        end

        def self.bucket_label(bucket)
          bucket['TERM_BUCKET_LABEL']
        end

        def self.id(bucket)
          bucket['AO_TERM_BUCKET_ID'].to_i
        end
      end
    end
  end
end