module MAPI
  module Services
    module Rates
      module LoanTerms

        SQL = <<-EOS
            SELECT AO_TERM_BUCKET_ID, TERM_BUCKET_LABEL,
            WHOLE_LOAN_ENABLED, SBC_AGENCY_ENABLED, SBC_AAA_ENABLED, SBC_AA_ENABLED,
            END_TIME, trunc(OVERRIDE_END_DATE) AS OVERRIDE_END_DATE, OVERRIDE_END_TIME
            FROM WEB_ADM.AO_TERM_BUCKETS
        EOS

        def self.loan_terms(environment)
          loan_status = {}
          now = Time.zone.now
          now_string = now.strftime("%H%M%S")
          today_date = now.to_date
          term_bucket_data_array = term_bucket_data(environment)
          MAPI::Shared::Constants::LOAN_TERMS.each do |term|
            lookup_term_id = MAPI::Services::EtransactAdvances::TERM_BUCKET_MAPPING[term]
            loan_status[term] ||= {}
            MAPI::Shared::Constants::LOAN_TYPES.each do |type|
              trade_status = false
              display_status = false
              bucket_label = 'NotFound'
              term_bucket_data_array.each do |row|
                if lookup_term_id == row['AO_TERM_BUCKET_ID'].to_i
                  bucket_label = row['TERM_BUCKET_LABEL']
                  # logic to check if manually turn off regardless of end time
                  # based on Types, will read different column
                  lookup_column = MAPI::Services::EtransactAdvances::TYPE_BUCKET_COLUMN_NO_MAPPING[type]
                  if row[lookup_column] == 'Y'
                    display_status = true
                  else
                    break
                  end
                  # logic to check end time
                  # check if there is override for today
                  end_time = row['END_TIME'] + '00'
                  override_date = row['OVERRIDE_END_DATE']
                  override_end_time = row['OVERRIDE_END_TIME'] + '00'
                  if (override_date.to_date == today_date)
                    # check with override_end_time
                    if (override_end_time > now_string)
                      trade_status = true
                    end
                  elsif (end_time > now_string)
                    trade_status = true
                  end
                end
              end
              loan_status[term][type] = {
                  'trade_status' => trade_status,
                  'display_status' => display_status,
                  'bucket_label' => bucket_label.to_s
              }
            end
          end
          loan_status
        end

        def self.term_bucket_data(environment)
          environment == :production ? term_bucket_data_production : term_bucket_data_development
        end

        def self.term_bucket_data_production
          begin
            results = []
            cursor = ActiveRecord::Base.connection.execute(SQL)
            while row = cursor.fetch_hash()
              results.push(row)
            end
            results
          rescue => e
            warn(:loan_terms_production, e.message)
          end
        end

        def self.term_bucket_data_development
          JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'etransact_advances_term_buckets_info.json')))
        end
      end
    end
  end
end