module MAPI
  module Services
    module EtransactAdvances
      module ShutoffTimes
        include MAPI::Shared::Utils
        include MAPI::Shared::Constants
        include MAPI::Shared::Errors

        SHUTOFF_MESSAGE_MAX_LENGTH = 2000

        def self.get_shutoff_times_by_type(app)
          shutoff_by_type_query = <<-SQL
            SELECT PRODUCT_TYPE, END_TIME
            FROM WEB_ADM.AO_TYPE_SHUTOFF
          SQL

          shutoff_times = if should_fake?(app)
            fake('etransact_shutoff_times_by_type')
          else
            fetch_hashes(app.logger, shutoff_by_type_query, {}, true)
          end
          Hash[shutoff_times.collect {|shutoff_time| [shutoff_time['product_type'].downcase, shutoff_time['end_time']]}]
        end

        def self.get_early_shutoffs(app)
          early_shutoffs_query = <<-SQL
            SELECT EARLY_SHUTOFF_DATE, FRC_SHUTOFF_TIME, VRC_SHUTOFF_TIME, DAY_OF_MESSAGE, DAY_BEFORE_MESSAGE
            FROM WEB_ADM.AO_TYPE_EARLY_SHUTOFF
          SQL
          shutoffs = if should_fake?(app)
            fake_hashes('etransact_early_shutoff_times')
          else
            fetch_hashes(app.logger, early_shutoffs_query, {}, true)
          end
          shutoffs.each do |shutoff|
            shutoff['early_shutoff_date'] = shutoff['early_shutoff_date'].to_date.iso8601 if shutoff['early_shutoff_date']
            shutoff['day_of_message'] = shutoff['day_of_message'].gsub("\\n", "\n") if shutoff['day_of_message']
            shutoff['day_before_message'] = shutoff['day_before_message'].gsub("\\n", "\n") if shutoff['day_before_message']
          end
        end

        def self.schedule_early_shutoff(app, shutoff)
          shutoff = shutoff.with_indifferent_access
          validate_early_shutoff(shutoff)
          unless should_fake?(app)
            add_early_shutoff_sql = <<-SQL
              INSERT INTO WEB_ADM.AO_TYPE_EARLY_SHUTOFF (
                EARLY_SHUTOFF_DATE, 
                FRC_SHUTOFF_TIME, 
                VRC_SHUTOFF_TIME, 
                DAY_OF_MESSAGE, 
                DAY_BEFORE_MESSAGE
              ) 
              VALUES (
                TO_DATE(#{quote(shutoff[:early_shutoff_date])}, 'YYYY-MM-DD'),
                #{quote(shutoff[:frc_shutoff_time])},
                #{quote(shutoff[:vrc_shutoff_time])},
                #{quote(shutoff[:day_of_message])},
                #{quote(shutoff[:day_before_message])}
              )
            SQL
            # TODO - this is already catching duplicate date entries, as that's where the unique constraint lies on the table, but you need to explicitly check for this as part of MEM-2373
            raise MAPI::Shared::Errors::SQLError, "Failed to schedule the early shutoff for date: #{shutoff[:early_shutoff_date]}" unless execute_sql(app.logger, add_early_shutoff_sql)
          end
          true
        end

        def self.update_early_shutoff(app, shutoff)
          shutoff = shutoff.with_indifferent_access
          validate_early_shutoff(shutoff)
          unless should_fake?(app)
            update_early_shutoff_sql = <<-SQL
              UPDATE WEB_ADM.AO_TYPE_EARLY_SHUTOFF
              SET 
                EARLY_SHUTOFF_DATE = TO_DATE(#{quote(shutoff[:early_shutoff_date])}, 'YYYY-MM-DD'), 
                FRC_SHUTOFF_TIME = #{quote(shutoff[:frc_shutoff_time])}, 
                VRC_SHUTOFF_TIME = #{quote(shutoff[:vrc_shutoff_time])},
                DAY_OF_MESSAGE = #{quote(shutoff[:day_of_message])},
                DAY_BEFORE_MESSAGE = #{quote(shutoff[:day_before_message])}
              WHERE TO_CHAR(EARLY_SHUTOFF_DATE, 'YYYY-MM-DD') = #{quote(shutoff[:original_early_shutoff_date])}
            SQL
            raise MAPI::Shared::Errors::SQLError, "Failed to update the early shutoff for original date: #{shutoff[:original_early_shutoff_date]}, updated date: #{shutoff[:early_shutoff_date]}" unless execute_sql(app.logger, update_early_shutoff_sql)
          end
          true
        end

        def self.validate_early_shutoff(shutoff)
          raise InvalidFieldError.new('early_shutoff_date must follow ISO8601 standards: YYYY-MM-DD', :early_shutoff_date, shutoff[:early_shutoff_date]) unless shutoff[:early_shutoff_date].to_s.match(REPORT_PARAM_DATE_FORMAT)
          raise InvalidFieldError.new('frc_shutoff_time must be a 4-digit, 24-hour time representation with values between `0000` and `2359`', :frc_shutoff_time, shutoff[:frc_shutoff_time]) unless shutoff[:frc_shutoff_time].to_s.match(TIME_24_HOUR_FORMAT)
          raise InvalidFieldError.new('vrc_shutoff_time must be a 4-digit, 24-hour time representation with values between `0000` and `2359`', :vrc_shutoff_time, shutoff[:vrc_shutoff_time]) unless shutoff[:vrc_shutoff_time].to_s.match(TIME_24_HOUR_FORMAT)
          raise InvalidFieldError.new("day_of_message cannot be longer than #{SHUTOFF_MESSAGE_MAX_LENGTH} characters", :day_of_message, shutoff[:day_of_message]) if shutoff[:day_of_message].to_s.length > SHUTOFF_MESSAGE_MAX_LENGTH
          raise InvalidFieldError.new("day_before_message cannot be longer than #{SHUTOFF_MESSAGE_MAX_LENGTH} characters", :day_before_message, shutoff[:day_before_message]) if shutoff[:day_before_message].to_s.length > SHUTOFF_MESSAGE_MAX_LENGTH
        end
      end
    end
  end
end