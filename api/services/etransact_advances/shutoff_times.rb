module MAPI
  module Services
    module EtransactAdvances
      module ShutoffTimes
        include MAPI::Shared::Utils

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
      end
    end
  end
end