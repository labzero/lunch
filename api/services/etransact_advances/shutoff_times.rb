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
      end
    end
  end
end