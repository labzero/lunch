module MAPI
  module Services
    module Member
      module SignerRoles
        def self.signer_roles(app, member_id)
          member_id = member_id.to_i
          signers = []

          if app.settings.environment == :production

            signer_roles_sql_query = <<-SQL
              SELECT SIGNERID, ET.LOGIN_ID AS LOGIN_ID, LNAME, FNAME, FULLNAME, TITLE, ALLRNA, ALLPRODUCT, ADVSIGNER, COLLATSIGNER,
              MNYMKTSIGNER, SWAPSIGNER, SECURITYSIGNER, WIRESIGNER, REPOSIGNER, AFFORDABITYSIGNER, LASTUPDATED,  FHLB_ID
              FROM SIGNER.SIGNERS SIGNERS LEFT JOIN WEB_ADM.ETRANSACT_SIGNER ET ON (SIGNERS.SIGNERID = ET.SIGNER_ID)
              WHERE SIGNERS.FHLB_ID = #{ActiveRecord::Base.connection.quote(member_id)}
            SQL

            # get signer roles

            signer_roles_cursor = ActiveRecord::Base.connection.execute(signer_roles_sql_query)
            while row = signer_roles_cursor.fetch_hash()
              signers << {name: row['FULLNAME'], username: row['LOGIN_ID'], roles: MAPI::Services::Users.process_roles(row), first_name: row['FNAME'], last_name: row['LNAME']}
            end

          else
            data = JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'signer_roles.json')))
            signers = data[member_id.to_s] unless data[member_id.to_s].blank?
          end
          signers

        end
      end
    end
  end
end