module MAPI
  module Services
    module Member
      module AdvancesDetails

        ADVANCES_PAYMENT_FREQUENCY_MAPPING = {
            'D'=> 'Daily',
            'M'=> 'Monthly',
            'Q'=> 'Quarterly',
            'S'=> 'Semiannually',
            'A'=> 'Annually',
            'IAM'=> 'At Maturity',
            '4W'=> 'Every 4 weeks',
            '9W'=> 'Every 9 weeks',
            '13W'=> 'Every 13 weeks',
            '26W'=> 'Every 26 weeks',
            'ME'=> 'Monthend'
        }

        ADVANCES_DAY_COUNT_BASIS_MAPPING = {
            'BOND'=> '30/360',
            'A360'=> 'Actual/360',
            'A365'=> 'Actual/365',
            'ACT365'=> 'Actual/Actual',
            '30/360'=> '30/360',
            'ACT/360'=> 'Actual/360',
            'ACT/365'=> 'Actual/365',
            'ACT/ACT'=> 'Actual/Actual'
        }

        def self.advances_details(app, member_id, as_of_date )
            member_id = member_id.to_i

            advances_detail_connection_string = <<-SQL
            SELECT ADVDET_ADVANCE_NUMBER,
              ADVDET_CURRENT_PAR,
              ADV_DAY_COUNT, ADV_PAYMENT_FREQ,
              ADX_INTEREST_RECEIVABLE,
              ADX_NEXT_INT_PAYMENT_DATE,
              ADVDET_INTEREST_RATE,
              ADVDET_ISSUE_DATE,
              ADVDET_MATURITY_DATE,
              ADVDET_MNEMONIC,
              ADVDET_DATEUPDATE, ADVDET_SUBSIDY_PROGRAM,
              TRADE_DATE,
              FUTURE_INTEREST,
              ADV_INDEX,
              TOTAL_PREPAY_FEES,
              SA_TOTAL_PREPAY_FEES,
              SA_INDICATION_VALUATION_DATE
            FROM WEB_INET.WEB_ADVANCES_DETAIL_RPT
            WHERE fhlb_id = #{ActiveRecord::Base.connection.quote(member_id)}
            SQL

            advances_historical_detail_connection_string = <<-SQL
            SELECT ADVDET_ADVANCE_NUMBER,
              ADVDET_CURRENT_PAR,
              ADV_DAY_COUNT, ADV_PAYMENT_FREQ,
              ADX_INTEREST_RECEIVABLE,
              ADX_NEXT_INT_PAYMENT_DATE,
              ADVDET_INTEREST_RATE,
              ADVDET_ISSUE_DATE,
              ADVDET_MATURITY_DATE,
              ADVDET_MNEMONIC,
              ADVDET_DATEUPDATE, ADVDET_SUBSIDY_PROGRAM,
              TRADE_DATE,
              FUTURE_INTEREST,
              ADV_INDEX,
              TOTAL_PREPAY_FEES,
              SA_TOTAL_PREPAY_FEES,
              SA_INDICATION_VALUATION_DATE
             FROM WEB_INET.WEB_ADVANCES_HISTORICAL_RPT
             WHERE fhlb_id = #{ActiveRecord::Base.connection.quote(member_id)}
             AND (AdvDet_DateUpdate  = to_date(#{ ActiveRecord::Base.connection.quote(as_of_date)}, 'yyyy-mm-dd'))
            SQL

            as_of_date = as_of_date.to_date
            advances_details_records= []
            latest_row_found = false
            now = Time.zone.now
            today_date = now.to_date
            latest_date = as_of_date
            if app.settings.environment == :production

                # if date is yesterday or later, get data from the lastest view
                if as_of_date >  today_date - 2.days
                  cp_advances_cursor = ActiveRecord::Base.connection.execute(advances_detail_connection_string)
                  while row = cp_advances_cursor.fetch_hash()
                    if latest_row_found == false
                      latest_date = row['ADVDET_DATEUPDATE'].to_date
                      latest_row_found = true
                    end
                    advances_details_records.push(row)
                  end
                end
                # if no data found in latest view and date is before today, go to the historical view. Use today just in case retrieval is after today EOD batch job ran
                if as_of_date <  today_date  && !latest_row_found
                  cp_advances_historical_cursor = ActiveRecord::Base.connection.execute(advances_historical_detail_connection_string)
                  while row = cp_advances_historical_cursor.fetch_hash()
                    advances_details_records.push(row)
                  end
                end
              else
                latest_row_found = false
                # if date is yesterday or later, get data from the lastest view
                if as_of_date >  today_date  - 2.days
                  rows = JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'member_advances_latest.json'))).sample
                  rows.collect! do |details|
                    if details['ADVDET_MATURITY_DATE'].to_date < as_of_date
                      details['ADVDET_MATURITY_DATE'] = as_of_date + (1 + rand(30))
                    end
                    if details['ADVDET_ISSUE_DATE'].to_date  > as_of_date
                      details['ADVDET_ISSUE_DATE'] = as_of_date - (1 + rand(7))
                      details['TRADE_DATE'] = details['ADVDET_ISSUE_DATE']
                    end
                    details
                  end
                  latest_row_found = true
                  advances_details_records = rows
                end
                if as_of_date < today_date  && !latest_row_found
                  rows = JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'member_advances_historical.json'))).sample
                  rows.collect! do |details|
                    if details['ADVDET_MATURITY_DATE'].to_date < as_of_date
                      details['ADVDET_MATURITY_DATE'] = as_of_date + (1 + rand(30))
                    end
                    if details['ADVDET_ISSUE_DATE'].to_date  > as_of_date
                      details['ADVDET_ISSUE_DATE'] = as_of_date - (1 + rand(7))
                      details['TRADE_DATE'] = details['ADVDET_ISSUE_DATE']
                    end
                    details
                  end
                  advances_details_records = rows
                end
              end

              # format the result sets with some business logic
              advances_details_formatted = []
              structured_product_indication_date = nil
              advances_details_records.each do |row|

                payment_frequency_description = row['ADV_PAYMENT_FREQ'].to_s
                payment_frequency_description = ADVANCES_PAYMENT_FREQUENCY_MAPPING[payment_frequency_description]
                if payment_frequency_description == nil
                  payment_frequency_description = row['ADV_PAYMENT_FREQ'].to_s
                end
                day_count_basis_description = row['ADV_DAY_COUNT'].to_s
                day_count_basis_description = ADVANCES_DAY_COUNT_BASIS_MAPPING[day_count_basis_description]
                if day_count_basis_description == nil
                  day_count_basis_description = row['ADV_DAY_COUNT'].to_s
                end

                # If data is latest and not historical, get logic to set prepayment indication fees... if TOTAL_PREPAY_FEES is nil, start the logic else, just use the value
                if  latest_row_found
                  prepayment_indication_fees = row['TOTAL_PREPAY_FEES']
                  notes_indicator = nil
                  sa_indication_date = nil
                  if prepayment_indication_fees == nil
                    if (row['SA_TOTAL_PREPAY_FEES'] == nil || row['SA_INDICATION_VALUATION_DATE'] == nil)
                      sa_indication_date = nil
                      if row['ADVDET_MNEMONIC'].downcase.include? 'vrc'
                        notes_indicator = :not_applicable_to_vrc
                      else
                        notes_indicator = :unavailable_online
                      end
                    else
                      prepayment_indication_fees = row['SA_TOTAL_PREPAY_FEES']
                      sa_indication_date = row['SA_INDICATION_VALUATION_DATE'].to_date
                      structured_product_indication_date = sa_indication_date
                      notes_indicator = :prepayment_fee_restructure
                    end
                  end
                else
                  notes_indicator = nil
                  sa_indication_date = nil
                end
                maturity_date = row['ADVDET_MATURITY_DATE'].to_date
                if (maturity_date == ('2038-12-31').to_date)  && (row['ADVDET_MNEMONIC'].downcase.include? 'open')
                  maturity_date = nil
                  open_vrc = true
                else
                  open_vrc = false
                end
                reformat_hash = {'trade_date' => row['TRADE_DATE'].to_date,
                                 'funding_date' => row['ADVDET_ISSUE_DATE'].to_date,
                                 'maturity_date' => maturity_date,
                                 'current_par' => (row['ADVDET_CURRENT_PAR'] || 0).round,
                                 'interest_rate' => (row['ADVDET_INTEREST_RATE'] || 0).to_f.round(5),
                                 'next_interest_pay_date' => (row['ADX_NEXT_INT_PAYMENT_DATE'].to_date if row['ADX_NEXT_INT_PAYMENT_DATE']),
                                 'accrued_interest' => (row['ADX_INTEREST_RECEIVABLE'].to_f if row['ADX_INTEREST_RECEIVABLE']),
                                 'estimated_next_interest_payment' => (row['FUTURE_INTEREST'].to_f if row['FUTURE_INTEREST']),
                                 'interest_payment_frequency' => payment_frequency_description,
                                 'day_count_basis' => day_count_basis_description,
                                 'advance_type' => row['ADVDET_MNEMONIC'],
                                 'advance_number' => row['ADVDET_ADVANCE_NUMBER'],
                                 'discount_program' => (row['ADVDET_SUBSIDY_PROGRAM']),
                                 'prepayment_fee_indication' => prepayment_indication_fees,
                                 'notes' => notes_indicator,
                                 'structure_product_prepay_valuation_date' => sa_indication_date,
                                 'open_vrc_indicator' => open_vrc
                }
                advances_details_formatted.push(reformat_hash)
              end
              {
                  as_of_date: latest_date.to_date,
                  structured_product_indication_date: structured_product_indication_date,
                  advances_details: advances_details_formatted
              }.to_json
          end
      end
    end
  end
end
