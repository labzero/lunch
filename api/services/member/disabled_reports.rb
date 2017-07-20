module MAPI
  module Services
    module Member
      module DisabledReports
        include MAPI::Shared::Utils

        def self.global_disabled_ids(app)
          disabled_ids = unless should_fake?(app)
            global_disabled_ids_query = <<-SQL
              SELECT WEB_FLAG_ID 
              FROM WEB_ADM.WEB_DATA_FLAGS 
              WHERE WEB_FLAG_VALUE = 'N'
            SQL
            fetch_objects(app.logger, global_disabled_ids_query)
          else
            fake('global_report_availability')
          end
          disabled_ids.collect{ |flag| flag.to_i }
        end

        def self.disabled_ids_for_member(app, member_id)
          disabled_ids = unless should_fake?(app)
            disabled_ids_for_member_query = <<-SQL
              SELECT WEB_FLAG_ID 
              FROM WEB_ADM.WEB_DATA_FLAGS_BY_INSTITUTIONS 
              WHERE WEB_FHLB_ID = #{member_id}
            SQL
            fetch_objects(app.logger, disabled_ids_for_member_query)
          else
            fake('global_report_availability')
          end
          disabled_ids.collect{ |flag| flag.to_i }
        end
      end
    end
  end
end
