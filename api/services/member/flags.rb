module MAPI
  module Services
    module Member
      module Flags
        def self.quick_advance_flag(app, member_id)
          member_id = member_id.to_i
          quick_advance_enabled = if app.settings.environment == :production
            quick_advance_flag_query = <<-SQL
              SELECT intraday_status_flag
              FROM web_adm.web_member_data
              WHERE fhlb_id = #{ ActiveRecord::Base.connection.quote(member_id)}
            SQL

            quick_advance_flag_cursor = ActiveRecord::Base.connection.execute(quick_advance_flag_query)
            quick_advance_flag = quick_advance_flag_cursor.fetch || []
            'Y' == quick_advance_flag.first.try(:upcase)
          else
            member_id != 13 # disables "Bank With Disabled Signers" for integration testing
          end
          {quick_advance_enabled: quick_advance_enabled}
        end
      end
    end
  end
end
