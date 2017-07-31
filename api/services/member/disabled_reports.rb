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

        def self.update_global_ids(app, global_web_flags)
          unless should_fake?(app)
            ActiveRecord::Base.transaction(isolation: :read_committed) do
              global_web_flags.each do |flag|
                flag = flag.with_indifferent_access
                update_global_web_flags_sql = <<-SQL
                  UPDATE WEB_ADM.WEB_DATA_FLAGS
                  SET WEB_FLAG_VALUE = #{quote(flag[:visible] ? 'Y' : 'N')}
                  WHERE WEB_FLAG_ID = #{quote(flag[:web_flag_id])}
                SQL
                raise MAPI::Shared::Errors::SQLError, "Failed to update data visibility flag for web flag with id: #{flag[:web_flag_id]}" unless execute_sql(app.logger, update_global_web_flags_sql)
              end
            end
          end
          true
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

        def self.update_ids_for_member(app, member_id, flags)
          unless should_fake?(app)
            ActiveRecord::Base.transaction(isolation: :read_committed) do
              flags.each do |flag|
                flag = flag.with_indifferent_access
                update_web_flags_sql = if flag[:visible]
                  <<-SQL
                    DELETE FROM WEB_ADM.WEB_DATA_FLAGS_BY_INSTITUTIONS 
                    WHERE WEB_FHLB_ID = #{quote(member_id)} 
                    AND WEB_FLAG_ID = #{quote(flag[:web_flag_id])}
                  SQL
                else
                  <<-SQL
                    INSERT INTO WEB_ADM.WEB_DATA_FLAGS_BY_INSTITUTIONS (WEB_FHLB_ID, WEB_FLAG_ID) 
                    VALUES (#{quote(member_id)}, #{quote(flag[:web_flag_id])})
                  SQL
                end
                raise MAPI::Shared::Errors::SQLError, "Failed to update data visibility flag for web flag with id: #{flag[:web_flag_id]}, where member id is #{member_id}" unless execute_sql(app.logger, update_web_flags_sql)
              end
            end
          end
          true
        end
      end
    end
  end
end
