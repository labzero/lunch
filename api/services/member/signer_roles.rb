module MAPI
  module Services
    module Member
      module SignerRoles
        def self.signer_roles(app, member_id)
          member_id = member_id.to_i
          signers = []

          if app.settings.environment == :production

            signer_roles_sql_query = <<-SQL
            SELECT SIGNERID, LNAME, FNAME, FULLNAME, TITLE, ALLRNA, ALLPRODUCT, ADVSIGNER, COLLATSIGNER,MNYMKTSIGNER, SWAPSIGNER, SECURITYSIGNER, WIRESIGNER, REPOSIGNER, AFFORDABITYSIGNER, LASTUPDATED,  FHLB_ID
            FROM (
              SELECT  SIGNERID, LNAME, FNAME, FULLNAME, TITLE, ALLRNA, ALLPRODUCT, ADVSIGNER, COLLATSIGNER,MNYMKTSIGNER, SWAPSIGNER, SECURITYSIGNER, WIRESIGNER, REPOSIGNER, AFFORDABITYSIGNER, LASTUPDATED,  S.FHLB_ID, x.signer_id, nvl(x.token_active_status, 'N') Active_token_exists_flag
              FROM SIGNER.SIGNERS s LEFT JOIN (
                SELECT UNIQUE es.signer_id, token_active_status
                FROM  WEB_ADM.ETRANSACT_SIGNER ES INNER JOIN WEB_ADM.ETRANSACT_TOKEN ET ON ES.LOGIN_ID  = ET.AD_USERID
                WHERE token_active_status = 'Y') x
              ON s.signerid = x.signer_id (+)
            ) S1
            WHERE  S1.FHLB_ID = #{ActiveRecord::Base.connection.quote(member_id)}
            ORDER BY  ALLRNA ,ALLPRODUCT,ADVSIGNER,AFFORDABITYSIGNER,COLLATSIGNER,MNYMKTSIGNER,SWAPSIGNER,SECURITYSIGNER,WIRESIGNER,LNAME
            SQL

            # get signer roles

            signer_roles_cursor = ActiveRecord::Base.connection.execute(signer_roles_sql_query)
            while row = signer_roles_cursor.fetch_hash()
              signers << {name: row['FULLNAME'], username: row['LOGIN_ID'], roles: MAPI::Services::Users.process_roles(row)}
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