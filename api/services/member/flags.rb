module MAPI
  module Services
    module Member
      module Flags
        include MAPI::Shared::Utils
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

        def self.quick_advance_flags(app)
          flags = unless should_fake?(app)
            fetch_hashes app, <<-SQL
              SELECT fhlb_id, cp_assoc, intraday_status_flag
              FROM web_adm.web_member_data
            SQL
          else
            JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'quick_advance_flags.json')))
          end
          flags.collect do |flag|
            flag = flag.with_indifferent_access
            {
              fhlb_id: flag['FHLB_ID'],
              member_name: flag['CP_ASSOC'],
              quick_advance_enabled: flag['INTRADAY_STATUS_FLAG'].try(:upcase) == 'Y'
            }
          end
        end

        def self.update_quick_advance_flags(app, flags)
          unless should_fake?(app)
            ActiveRecord::Base.transaction(isolation: :read_committed) do
              flags.each do |member_id, etransact_enabled|
                update_quick_advance_flags_sql = <<-SQL
                  UPDATE  WEB_ADM.WEB_MEMBER_DATA
                  SET INTRADAY_STATUS_FLAG = #{quote(etransact_enabled ? 'Y' : 'N')}
                  WHERE FHLB_ID = #{quote(member_id)}
                SQL
                raise MAPI::Shared::Errors::SQLError, "Failed to update quick advance flag for member with id: #{member_id}" unless execute_sql(app.logger, update_quick_advance_flags_sql)
              end
            end
          end
          true
        end
      end
    end
  end
end