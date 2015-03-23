module MAPI
  module Services
    module Rates
      module PriceIndicationHistorical
        include MAPI::Services::Base
        IRDB_CODE_TERM_MAPPING =
            {:standard => {
                :vrc => {
                    code:'FRADVN',
                    terms: ['1D'],
                    min_date: '2002-02-28'
                },
                :frc => {
                    code: 'FRADVN',
                    terms: ['1M', '2M', '3M', '6M', '1Y', '2Y', '3Y', '5Y', '7Y', '10Y', '15Y', '20Y', '30Y'],
                    min_date: '1993-02-16'
                },
                :'1m_libor' => {
                    code: 'LARC1M',
                    terms: ['1Y', '2Y', '3Y', '5Y'],
                    min_date: '1997-05-07'
                },
                :'3m_libor' => {
                    code: 'LARC3M',
                    terms: ['1Y', '2Y', '3Y', '5Y'],
                    min_date: '1997-05-07'
                },
                :'6m_libor' => {
                    code: 'LARC6M',
                    terms: ['1Y', '2Y', '3Y', '5Y'],
                    min_date: '1997-05-07'
                },
                :daily_prime => {
                    code: 'APRIMEAT',
                    terms: ['1Y', '2Y', '3Y', '5Y'],
                    min_date: '2002-08-28'
                }
            },
             :sbc => {
                 :vrc => {
                     code: 'SFRC',
                     terms: ['1D'],
                     min_date:'2002-02-28'
                 },
                 :frc => {
                     code: 'SFRC',
                     terms: ['1M', '2M', '3M', '6M', '1Y', '2Y', '3Y', '5Y', '7Y', '10Y', '15Y', '20Y', '30Y'],
                     min_date: '2002-02-28'
                 },
                 :'1m_libor' => {
                     code: 'SARC1M',
                     terms: ['1Y', '2Y', '3Y', '5Y'],
                     min_date: '2002-02-28'
                 },
                 :'3m_libor' => {
                     code: 'SARC3M',
                     terms: ['1Y', '2Y', '3Y', '5Y'],
                     min_date: '2002-02-28'
                 },
                 :'6m_libor' => {
                     code:'SARC6M',
                     terms:['1Y', '2Y', '3Y', '5Y'],
                     min_date: '2002-02-28'
                 }
             }
            }.with_indifferent_access

          SEMIANNUAL_PAY_FREQ = 'At Maturity'
          CREDIT_TYPE_NEED_CHECK_PAY_FREQ = 'frc'
          CREDIT_TYPE_NEED_BENCHMARK = 'daily_prime'

        def self.price_indication_historical(app, start_date, end_date, collateral_type, credit_type)

          collateral_type = collateral_type.to_s
          credit_type = credit_type.to_s
          irdb_lookup = IRDB_CODE_TERM_MAPPING[collateral_type][credit_type]

          irdb_code= irdb_lookup['code'].to_s
          irdb_term_array = irdb_lookup['terms']

          # convert array into string of terms
          irdb_term_string = irdb_term_array.map { |i| "'" + i.to_s + "'"}.join(",")

          irdb_earliest_date = irdb_lookup['min_date']

          #check requested start_date if earlier than irdb_earliest_date, if so, substitute

          if start_date.to_date < irdb_earliest_date.to_date
            start_date = irdb_earliest_date
          end
          #TODO check SQL on Database.. there is issue to be fix
          irdb_connection_string = <<-SQL
            SELECT TRX_IR_CODE, TRX_EFFECTIVE_DATE, TRX_TERM_VALUE,  TRX_TERM_UOM, TRX_VALUE,
            MS_DAY_CNT_BAS, MS_DATA_FREQ
            FROM IRDB.IRDB_MASTER M,
            IRDB.IRDB_TRANS T
            WHERE MS_IR_CODE = #{ActiveRecord::Base.connection.quote(irdb_code)}
            AND  MS_IR_CODE =  TRX_IR_CODE
            AND TRX_EFFECTIVE_DATE BETWEEN to_date(#{ActiveRecord::Base.connection.quote(start_date)}, 'yyyy-mm-dd') AND
            to_date(#{ActiveRecord::Base.connection.quote(end_date)}, 'yyyy-mm-dd')
            and (trim(TRX_TERM_VALUE) || trim(TRX_TERM_UOM)) in (#{irdb_term_string} )
            ORDER BY TRX_EFFECTIVE_DATE
          SQL

          #TODO check SQL on Database, there is issue to be fix
          irdb_with_benchmark_connection_string = <<-SQL
            SELECT TRX_IR_CODE, TRX_EFFECTIVE_DATE, TRX_TERM_VALUE , TRX_TERM_UOM, TRX_VALUE,
            MS_DAY_CNT_BAS, MS_DATA_FREQ
            FROM IRDB.IRDB_TRANS T,
            IRDB.IRDB_MASTER M
            WHERE (( MS_IR_CODE = #{ActiveRecord::Base.connection.quote(irdb_code)} and
                   (trim(TRX_TERM_VALUE) || trim(TRX_TERM_UOM)) in (#{irdb_term_string}) )
                  OR (TRX_IR_CODE = 'PRIME') and (trim(TRX_TERM_VALUE) || trim(TRX_TERM_UOM)) = '1D')
            AND  MS_IR_CODE =  TRX_IR_CODE
            AND TRX_EFFECTIVE_DATE BETWEEN to_date(#{ ActiveRecord::Base.connection.quote(start_date)}, 'yyyy-mm-dd') AND
            to_date(#{ActiveRecord::Base.connection.quote(end_date)}, 'yyyy-mm-dd')
            ORDER BY TRX_EFFECTIVE_DATE
          SQL
          #TODO to delete
          puts irdb_connection_string
          puts irdb_with_benchmark_connection_string

          if app.settings.environment == :production

            #check special case for daily_prime, where we need to retrieve benchmark index, which is of a different ir_code before execute SQL
            if credit_type == CREDIT_TYPE_NEED_BENCHMARK
              historical_rates_cursor = ActiveRecord::Base.connection.execute(irdb_with_benchmark_connection_string)
            else
              historical_rates_cursor = ActiveRecord::Base.connection.execute(irdb_connection_string)
            end
            rate_raw_records = []
            while raw_row = historical_rates_cursor.fetch_hash()
              rate_raw_records.push(raw_row)
            end
          else
            # code to generate fake data...
            start_date_date = start_date.to_date
            end_date_date = end_date.to_date
            fake_data_array = []
            (start_date_date..end_date_date).each do |date|

              day_of_week = date.to_date.wday
              if day_of_week != 0 && day_of_week != 6
                irdb_term_array.each do |term|
                  term_value = term[0..-2].to_i
                  term_uom = term[-1]
                  case credit_type.to_s
                    when 'daily_prime'
                      if term == '1Y'
                        fake_data_array.push(
                          "TRX_IR_CODE"=> 'PRIME',
                          "TRX_EFFECTIVE_DATE"=> date,
                          "TRX_TERM_VALUE"=> 1,
                          "TRX_TERM_UOM"=> 'D',
                          "TRX_VALUE"=>  rand(0.50..4.25).round(2) ,
                          "MS_DAY_CNT_BAS"=> 'Actual/360',
                          "MS_DATA_FREQ"=> 'Daily')
                      end
                      fake_data_array.push(
                        "TRX_IR_CODE"=> irdb_code,
                        "TRX_EFFECTIVE_DATE"=> date,
                        "TRX_TERM_VALUE"=> term_value,
                        "TRX_TERM_UOM"=> term_uom,
                        "TRX_VALUE"=> rand(-200..200),
                        "MS_DAY_CNT_BAS"=> 'Actual/Actual',
                        "MS_DATA_FREQ"=> 'Quarterly')

                    when 'vrc', 'frc'
                      fake_data_array.push(
                        "TRX_IR_CODE"=> irdb_code,
                        "TRX_EFFECTIVE_DATE"=> date,
                        "TRX_TERM_VALUE"=> term_value,
                        "TRX_TERM_UOM"=> term_uom,
                        "TRX_VALUE"=> rand(0.20..3.88).round(2) ,
                        "MS_DAY_CNT_BAS"=> 'Actual/Actual',
                        "MS_DATA_FREQ"=> 'Monthly')
                    else
                      fake_data_array.push(
                        "TRX_IR_CODE"=> irdb_code,
                        "TRX_EFFECTIVE_DATE"=> date,
                        "TRX_TERM_VALUE"=> term_value,
                        "TRX_TERM_UOM"=> term_uom,
                        "TRX_VALUE"=> rand(-200..200),
                        "MS_DAY_CNT_BAS"=> 'Actual/360',
                        "MS_DATA_FREQ"=> 'Monthly')
                  end
                end
              end
              rate_raw_records = fake_data_array
            end
          end

          #TODO create a method to call calendar services to get both LON and NYC Holiday, and pass back LON holiday only that is not weekend or NYC holiday
          #if type is not VRC, and london_holiday date is not in the rate_by_date_hash, add an entry
          puts 'vrc'
          if credit_type.to_s != 'vrc'
            london_holiday_returns = MAPI::Shared::CalendarHolidayServices::calendar_holiday_london_only(start_date, end_date,  app.settings.environment)
            puts london_holiday_returns
            if london_holiday_returns.count > 0
              london_holiday = london_holiday_returns['london_holiday']
            else
              Rails.logger.warn("MAPI::Shared::CapitalStockServices error. Not returning values")
            end
          end

          rates_by_date_hash = {}
          rates_by_date_array = []
          rates_by_date_term_hash = {}
          rates_by_date_term_array = []
          dates_with_rate_array = []
          days_date = start_date.to_date
          first_row = true
          rate_raw_records.each do |row|
            if row['TRX_EFFECTIVE_DATE'].to_date != days_date then
              #before starting a new date, form the rates_by_hash and push into the array
              if !first_row
                rates_by_date_hash = {
                    'date'=> days_date,
                    'rates_by_term'=> rates_by_date_term_array
                }
                rates_by_date_array.push(rates_by_date_hash)
                dates_with_rate_array.push(days_date.to_date)
                #re-initiatlized the hash and array
                rates_by_date_term_hash = {}
                rates_by_date_term_array = []
              end
            end
            first_row = false  #start processing first row so this is no longer true
            #for SBC FRC, change payment frequency to 'Semiannual or At Maturity' if it is more than 6 months
            if credit_type == CREDIT_TYPE_NEED_CHECK_PAY_FREQ
              case row['TRX_TERM_UOM']
                when 'M'
                  if row['TRX_TERM_VALUE'].to_i > 6
                    pay_freq = SEMIANNUAL_PAY_FREQ
                  else
                    pay_freq = row['MS_DATA_FREQ'].to_s
                  end
                when 'Y'
                  pay_freq = SEMIANNUAL_PAY_FREQ
                else
                  pay_freq = row['MS_DATA_FREQ'].to_s
              end
            else
              pay_freq = row['MS_DATA_FREQ'].to_s
            end
            # format the array of hash for rates_by_term for each date
            rates_by_date_term_hash = {
                'term'=> row['TRX_TERM_VALUE'].to_s + row['TRX_TERM_UOM'],
                'rate'=> row['TRX_VALUE'].to_f,
                'day_count_basis' => row['MS_DAY_CNT_BAS'],
                'pay_freq' => pay_freq
            }
            rates_by_date_term_array.push(rates_by_date_term_hash)
            days_date = row['TRX_EFFECTIVE_DATE'].to_date

          end

          # push the last processed rates_by_term into the rates-by_date array
          rates_by_date_hash = {
              'date'=> days_date,
              'rates_by_term'=> rates_by_date_term_array
          }
          rates_by_date_array.push(rates_by_date_hash)

          #TODO add london holiday dates
          london_holiday.each do |ukonly|

            #loop thru for each expected term
            rates_by_date_term_hash = {
                'term'=> nil,
                'rate'=>  nil,
                'day_count_basis' => nil,
                'pay_freq' => nil
            }

            rates_by_date_hash = {
                'date'=> ukonly.to_date,
                'rates_by_term'=> rates_by_date_term_array
            }
          end

          result =
          {
              start_date: start_date.to_date,
              end_date: end_date.to_date,
              collateral_type: collateral_type,
              credit_type: credit_type,
              rates_by_date: rates_by_date_array
          }
          result
         end
      end
    end
  end
end