module MAPI
  module Services
    module Member
      module MembersWithDisabledReports
        include MAPI::Shared::Utils

        def self.members_with_disabled_reports(app)
          member_list = unless should_fake?(app)
            fetch_hashes app, <<-SQL
              SELECT FHLB_ID,  CU_SHORT_NAME AS MEMBER_NAME
              FROM WEB_ADM.WEB_DATA_FLAGS_BY_INSTITUTIONS INNER JOIN PORTFOLIOS.CUSTOMERS ON FHLB_ID = WEB_FHLB_ID
            SQL
          else
            fake('members_with_disabled_reports')
          end
          member_list.collect do |member|
            member = member.with_indifferent_access
            {
              "FHLB_ID": member['FHLB_ID'],
              "MEMBER_NAME": member['MEMBER_NAME'],
            }
          end unless member_list.nil?
        end
      end
    end
  end
end
