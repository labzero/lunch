module MAPI
  module Services
    module Member
      module DisabledReports
        include MAPI::Shared::Utils

        def self.disabled_report_ids(app, member_id=nil)
          member_id = member_id.to_i if member_id
          unless should_fake?(app)
            global_report_availability_connection_string = <<-SQL
              SELECT WEB_FLAG_ID 
              FROM WEB_ADM.WEB_DATA_FLAGS 
              WHERE WEB_FLAG_VALUE = 'N'
            SQL
            global_flags = fetch_objects(app.logger, global_report_availability_connection_string)
            member_flags = if member_id
              report_availability_for_member_connection_string = <<-SQL
                SELECT WEB_FLAG_ID 
                FROM WEB_ADM.WEB_DATA_FLAGS_BY_INSTITUTIONS 
                WHERE WEB_FHLB_ID = #{member_id}
              SQL
              fetch_objects(app.logger, report_availability_for_member_connection_string)
            else
              []
            end
          else
            global_flags = fake('global_report_availability')
            member_flags = member_id ? fake('report_availability_for_member') : []
          end
          (global_flags + member_flags).uniq.collect{ |flag| flag.to_i }
        end
      end
    end
  end
end
