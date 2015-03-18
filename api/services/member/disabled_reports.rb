module MAPI
  module Services
    module Member
      module DisabledReports
        def self.disabled_report_ids(app, member_id)
          member_id = member_id.to_i
          disabled_report_ids = []

          # reports that have been disabled globally for all members
          global_report_availability_connection_string = <<-SQL
            SELECT WEB_FLAG_ID FROM WEB_ADM.WEB_DATA_FLAGS WHERE WEB_FLAG_VALUE = 'N'
          SQL

          # reports that have been disabled for this specific member
          report_availability_for_member_connection_string = <<-SQL
            SELECT WEB_FLAG_ID FROM WEB_ADM.WEB_DATA_FLAGS_BY_INSTITUTIONS WHERE WEB_FHLB_ID = #{member_id}
          SQL

          if app.settings.environment == :production
            global_report_availability_cursor = ActiveRecord::Base.connection.execute(global_report_availability_connection_string)
            report_availability_for_member_cursor = ActiveRecord::Base.connection.execute(report_availability_for_member_connection_string)
            while row = global_report_availability_cursor.fetch()
              disabled_report_ids << row[0].to_i
            end
            while row = report_availability_for_member_cursor.fetch()
              disabled_report_ids << row[0].to_i
            end
          end

          # return empty array for non-prod environments, as this reflects the norm for most users (i.e. no reports are flagged as disabled)
          disabled_report_ids.uniq.to_json
        end
      end
    end
  end
end
