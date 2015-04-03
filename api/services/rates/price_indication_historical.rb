module MAPI
  module Services
    module Rates
      module PriceIndicationHistorical
        include MAPI::Services::Base
        include MAPI::Shared::Constants

        def self.price_indication_historical(app, start_date, end_date, collateral_type, credit_type)
          env = app.settings.environment
          collateral_type = collateral_type.to_sym
          credit_type = credit_type.to_sym
          start_date = start_date.to_date
          end_date = end_date.to_date
          irdb_lookup = IRDB_CODE_TERM_MAPPING[collateral_type][credit_type]
          irdb_code= irdb_lookup[:code]
          irdb_term_array = irdb_lookup[:terms]
          irdb_term_string = irdb_term_array.map { |i| "'" + i.to_s + "'"}.join(",")
          irdb_min_date = irdb_lookup[:min_date]
          start_date = irdb_min_date if start_date < irdb_min_date

          irdb = Private.irdb_sql_query(start_date, end_date, irdb_code, irdb_term_string)
          irdb_with_benchmark = Private.irdb_with_benchmark_sql_query(start_date, end_date, irdb_code, irdb_term_string)
          london_only_holidays = calendar_holiday_london_only(env, start_date, end_date)

          rate_raw_records = []
          if env == :production
            # daily_prime gets its own SQL query, as it includes both a benchmark rate and also basis_point spreads
            if credit_type == :daily_prime
              historical_rates_cursor = ActiveRecord::Base.connection.execute(irdb_with_benchmark)
            else
              historical_rates_cursor = ActiveRecord::Base.connection.execute(irdb)
            end
            while raw_row = historical_rates_cursor.fetch_hash()
              rate_raw_records.push(raw_row)
            end
          else
            rate_raw_records = Private.fake_historical_price_indications(start_date, end_date, collateral_type, credit_type, irdb_code, irdb_term_array, london_only_holidays)
          end

          rates_by_date = []
          last_date = nil
          rate_raw_records.each do |row|
            data_type = Private.rate_object_data_type(credit_type, row['TRX_IR_CODE'].to_s)
            pay_freq = Private.rate_object_pay_freq(credit_type, row['TRX_TERM_UOM'].to_s, row['TRX_TERM_VALUE'].to_i, row['MS_DATA_FREQ'].to_s)

            # construct a rate object
            rate_object = {
              term: row['TRX_TERM_VALUE'].to_s + row['TRX_TERM_UOM'].to_s,
              type: data_type,
              value: row['TRX_VALUE'].to_f, # Should be fine to make all values floats, even though basis_points and spread_to_benchmark will be Integers. We can handle styling in the app.
              day_count_basis: row['MS_DAY_CNT_BAS'].to_s,
              pay_freq: pay_freq
            }

            # In the case where we've run into a row with a date that is different than that of the preceding row, we need
            # to create a new rates_by_date object and push that to the rates_by_date array.  Then we always push the rate_object
            # to the rates_by_term array of the last object in the rates_by_date array
            if row['TRX_EFFECTIVE_DATE'].to_date != last_date
              # create a new object in the rates_by_date array, push the rate_object into the rates_by_term array of that newly created object
              last_date = row['TRX_EFFECTIVE_DATE'].to_date
              rates_by_date.push({date: last_date, rates_by_term: []})
            end
            # push the rate_object to the rates_by_term array in the last object in the rates_by_date array
            rates_by_date.last[:rates_by_term].push(rate_object)
          end

          # add placeholder rates_by_date object and associated rate_objects for London-only holidays
          if credit_type != :vrc && !london_only_holidays.blank?
            rates_by_date = Private.add_london_holiday_rows(london_only_holidays, rates_by_date, irdb_term_array, credit_type==:daily_prime)
          end
          rates_by_date = Private.add_rate_objects_for_all_terms(rates_by_date, irdb_term_array, credit_type==:daily_prime) # make sure each date object contains the proper number of rate_by_term objects

          {
            start_date: start_date.to_date,
            end_date: end_date.to_date,
            collateral_type: collateral_type.to_s,
            credit_type: credit_type.to_s,
            rates_by_date: rates_by_date
          }
        end

        def self.calendar_holiday_london_only(environment, start_date, end_date)
          holiday_london = []
          holiday_us = []

          cal_connection = MAPI::Services::Rates.init_cal_connection(environment)
          if cal_connection
            message = {'v1:endDate' => end_date.to_date.strftime('%F') , 'v1:startDate' => start_date.to_date.strftime('%F') }
            begin
              response = cal_connection.call(:get_holiday, message_tag: 'holidayRequest', message: message, :soap_header => {'wsse:Security' => {'wsse:UsernameToken' => {'wsse:Username' => ENV['MAPI_FHLBSF_ACCOUNT'], 'wsse:Password' => ENV['SOAP_SECRET_KEY']}}})
            rescue Savon::Error => error
              raise 'Internal Service Error: the holiday calendar service could not be reached'
            end
            response.doc.remove_namespaces!
            holiday_type = response.doc.xpath('//Envelope//Body//holidayResponse//holidays//businessCenters')
            holiday_type.each do |row|
              case row.css('businessCenter').text
                when 'USNY'
                  row.css('days day date').map do |holiday|
                    holiday_us.push(holiday.content)
                  end
                when 'London'
                  row.css('days day date').map do |holiday|
                    holiday_london.push(holiday.content)
                  end
              end
            end
          else
            holiday_london, holiday_us = JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'calendar_london_only_holidays.json')))
          end

          holiday_london.collect! {|date| Time.zone.parse(date)}
          holiday_us.collect! {|date| Time.zone.parse(date)}

          holiday_london_only  = []
          holiday_london.each do |holiday_date|
            holiday_london_only.push(holiday_date) unless (holiday_us.include?(holiday_date) || holiday_date.saturday? || holiday_date.sunday?)
          end
          
          holiday_london_only.delete_if {|date| !(start_date.to_date..end_date.to_date).include?(date.to_date)}
        end

        # private
        module Private
          include MAPI::Shared::Constants

          def self.irdb_sql_query(start_date, end_date, irdb_code, irdb_term_string)
            <<-SQL
              SELECT TRX_IR_CODE, TRX_EFFECTIVE_DATE, TRX_TERM_VALUE, TRX_TERM_UOM, TRX_VALUE,
              MS_DAY_CNT_BAS, MS_DATA_FREQ
              FROM IRDB.IRDB_MASTER M,
              IRDB.IRDB_TRANS T
              WHERE MS_IR_CODE = #{ActiveRecord::Base.connection.quote(irdb_code)}
              AND  MS_IR_CODE =  TRX_IR_CODE
              AND TRX_EFFECTIVE_DATE BETWEEN to_date(#{ActiveRecord::Base.connection.quote(start_date.strftime('%F'))}, 'yyyy-mm-dd') AND
              to_date(#{ActiveRecord::Base.connection.quote(end_date.strftime('%F'))}, 'yyyy-mm-dd')
              and (trim(TRX_TERM_VALUE) || trim(TRX_TERM_UOM)) in (#{irdb_term_string} )
              ORDER BY TRX_EFFECTIVE_DATE
            SQL
          end

          def self.irdb_with_benchmark_sql_query(start_date, end_date, irdb_code, irdb_term_string)
            <<-SQL
              SELECT TRX_IR_CODE, TRX_EFFECTIVE_DATE, TRX_TERM_VALUE, TRX_TERM_UOM, TRX_VALUE,
              MS_DAY_CNT_BAS, MS_DATA_FREQ
              FROM IRDB.IRDB_TRANS T,
              IRDB.IRDB_MASTER M
              WHERE (( MS_IR_CODE = #{ActiveRecord::Base.connection.quote(irdb_code)} and
                     (trim(TRX_TERM_VALUE) || trim(TRX_TERM_UOM)) in (#{irdb_term_string}) )
                    OR (TRX_IR_CODE = 'PRIME') and (trim(TRX_TERM_VALUE) || trim(TRX_TERM_UOM)) = '1D')
              AND  MS_IR_CODE =  TRX_IR_CODE
              AND TRX_EFFECTIVE_DATE BETWEEN to_date(#{ ActiveRecord::Base.connection.quote(start_date.strftime('%F'))}, 'yyyy-mm-dd') AND
              to_date(#{ActiveRecord::Base.connection.quote(end_date.strftime('%F'))}, 'yyyy-mm-dd')
              ORDER BY TRX_EFFECTIVE_DATE
            SQL
          end
          # return an array of hashes mimicking what would be returned from the fetch_hash method operating on a SQL query
          def self.fake_historical_price_indications(start_date, end_date, collateral_type, credit_type, irdb_code, terms, london_holidays)
            rows = []
            (start_date..end_date).each do |date|
              day_of_week = date.wday
              if day_of_week != 0 && day_of_week != 6 && !london_holidays.include?(date) # TODO make sure you're comparing apples to apples with this date comparison
                r = Random.new(date.to_time.to_i + CREDIT_TYPES.index(credit_type) + COLLATERAL_TYPES.index(collateral_type))
                # need to create special case for daily_prime where we add a rate in addition to populating the normal term values with basis points
                if credit_type == :daily_prime
                  data = {
                    'TRX_IR_CODE' => DAILY_PRIME_TRX_IR_CODE_INDEX,
                    'TRX_EFFECTIVE_DATE' => date.strftime('%F'),
                    'TRX_TERM_VALUE' => '1',
                    'TRX_TERM_UOM' => 'D',
                    'TRX_VALUE' => r.rand.round(5),
                    'MS_DAY_CNT_BAS' => 'Actual/360',
                    'MS_DATA_FREQ' => 'Daily'
                  }
                  rows.push(data)
                end
                terms.each do |term|
                  if credit_type == :frc || credit_type == :vrc
                    value = r.rand.round(5)
                  elsif credit_type == :'1m_libor' || credit_type ==  :'3m_libor' || credit_type ==  :'6m_libor' || credit_type == :daily_prime
                    value = r.rand(-200..200)
                  end
                  split_term = term.scan(/\d+|\D+/)
                  data = {
                    'TRX_IR_CODE' => irdb_code,
                    'TRX_EFFECTIVE_DATE' => date.strftime('%F'),
                    'TRX_TERM_VALUE' => split_term.first,
                    'TRX_TERM_UOM' => split_term.last,
                    'TRX_VALUE' => value,
                    'MS_DAY_CNT_BAS' => 'Actual/360', #TODO fake this more accurately for each credit_type and term if we actually start consuming this data
                    'MS_DATA_FREQ' => 'Quarterly' #TODO fake this more accurately for each credit_type and term if we actually start consuming this data
                  }
                  rows.push(data)
                end
              end
            end
            rows
          end

          def self.add_london_holiday_rows(holiday_array, rates_array, terms, daily_prime=false)
            holiday_array.each do |date|
              duplicate_dates = rates_array.select {|rate_object| rate_object[:date].to_date == date.to_date}
              next unless duplicate_dates.blank?
              rates_array.push({date: date.to_date, rates_by_term: []})
              # Build the appropriate number of rate_objects with the correct terms - add an extra for daily_prime to account for its benchmark rate
              if daily_prime
                rates_array.last[:rates_by_term].push(
                    {
                        term: '1D',
                        type: 'index', # placeholder type
                        value: nil,
                        day_count_basis: nil,
                        pay_freq: nil
                    }
                )
              end
              terms.each do |term|
                rates_array.last[:rates_by_term].push(
                  {
                    term: term.to_s,
                    type: 'index', # placeholder type
                    value: nil,
                    day_count_basis: nil,
                    pay_freq: nil
                  }
                )
              end
            end
            # sort rates_by_date array to preserve order
            rates_array.sort_by {|hash| hash[:date]}
          end

          def self.add_rate_objects_for_all_terms(rates_by_date_array, terms, daily_prime=false)
            terms.unshift('1D') if daily_prime
            new_array = []
            rates_by_date_array.each do |rate_by_date_obj|
              new_array << {date: rate_by_date_obj[:date], rates_by_term: []}
              terms.each do |term|
                rate_obj = rate_by_date_obj[:rates_by_term].select {|rate_obj| rate_obj[:term] == term}.first || {
                  term: term.to_s,
                  type: 'index', # placeholder type
                  value: nil,
                  day_count_basis: nil,
                  pay_freq: nil
                }
                new_array.last[:rates_by_term] << rate_obj
              end
            end
            new_array
          end

          # determine the data-type of the value that will be returned for the rate object
          def self.rate_object_data_type(credit_type, trx_ir_code)
            if INDEX_CREDIT_TYPES.include?(credit_type) || (credit_type == :daily_prime && trx_ir_code == DAILY_PRIME_TRX_IR_CODE_INDEX)
              'index'
            elsif BASIS_POINT_CREDIT_TYPES.include?(credit_type) || (credit_type == :daily_prime && trx_ir_code == DAILY_PRIME_TRX_IR_CODE_BASIS_POINT)
              'basis_point'
            end
          end

          # calculate payment frequency: SBC FRC, change payment frequency to 'Semiannual/Maturity' if it is more than 6 months
          def self.rate_object_pay_freq(credit_type, trx_term_uom, trx_term_value, ms_data_freq)
            if credit_type == :frc && ((trx_term_uom == 'M' && trx_term_value > 6) || trx_term_uom == 'Y')
              'Semiannual/Maturity'
            else
              ms_data_freq
            end
          end
        end

      end
    end
  end
end