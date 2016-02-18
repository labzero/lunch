module MAPI
  module Services
    module Users

      include MAPI::Services::Base

      def self.registered(app)
        service_root '/users', app
        swagger_api_root :users do
          api do
            key :path, '/{username}/roles'
            operation do
              key :method, 'GET'
              key :summary, 'Find signer roles for a specific username'
              key :notes, 'Returns an array of roles'
              key :type, :array
              key :nickname, :userRoles
              items do
                key :'$ref', :string
              end
              parameter do
                key :paramType, :path
                key :name, :username
                key :required, true
                key :type, :string
                key :description, 'The username to find roles for'
              end
              response_message do
                key :code, 404
                key :message, 'Invalid username supplied'
              end
            end
          end
        end

        relative_get '/:username/roles' do
          username = params[:username]
          roles = []
          signer_id = nil
          if settings.environment == :production
            signer_id_query = <<-SQL
              SELECT SIGNER_ID FROM WEB_ADM.ETRANSACT_SIGNER WHERE LOWER(LOGIN_ID) = #{ActiveRecord::Base.connection.quote(username.downcase)}
            SQL
            ActiveRecord::Base.connection.execute(signer_id_query).fetch do |row|
              signer_id = row[0].to_i
            end
            halt 404, 'User not found' unless signer_id

            roles_query = <<-SQL
              SELECT *
              FROM (
                SELECT  signerid, LNAME, FNAME, FULLNAME, TITLE, ALLRNA, ALLPRODUCT, ADVSIGNER, COLLATSIGNER,MNYMKTSIGNER, SWAPSIGNER, SECURITYSIGNER, WIRESIGNER, REPOSIGNER, AFFORDABITYSIGNER, LASTUPDATED,  S.FHLB_ID, x.signer_id, nvl(x.token_active_status, 'N') Active_token_exists_flag
                FROM SIGNER.SIGNERS s LEFT JOIN (
                  SELECT UNIQUE es.signer_id, token_active_status
                  FROM  WEB_ADM.ETRANSACT_SIGNER ES INNER JOIN WEB_ADM.ETRANSACT_TOKEN ET ON ES.LOGIN_ID  = ET.AD_USERID
                  WHERE token_active_status = 'Y') x
                ON s.signerid = x.signer_id (+)
              ) S1
              WHERE SIGNERID = #{ActiveRecord::Base.connection.quote(signer_id)}
            SQL

            ActiveRecord::Base.connection.execute(roles_query).fetch_hash do |row|
              roles << MAPI::Services::Users.process_roles(row)
            end
            roles.flatten!
          else
            data = JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'user_roles.json')))
            halt 404, 'User not found' unless data[username]
            roles = data[username]
          end
          roles.to_json
        end
      end
      
      def self.process_roles(record)
        roles = []
        roles << 'signer' # because we found them in the DB

        # The bank uses -1 for true, 0 for false
        if record['ADVSIGNER'] == -1 || record['ALLRNA'] == -1 || record['ALLPRODUCT'] == -1
          roles << 'signer-advances'
        end
        if record['COLLATSIGNER'] == -1 || record['ALLRNA'] == -1 || record['ALLPRODUCT'] == -1
          roles << 'signer-collateral'
        end
        if record['MNYMKTSIGNER'] == -1 || record['ALLRNA'] == -1 || record['ALLPRODUCT'] == -1
          roles << 'signer-moneymarket'
        end
        if record['SWAPSIGNER'] == -1 || record['ALLRNA'] == -1 || record['ALLPRODUCT'] == -1
          roles << 'signer-creditswap'
        end
        if record['SECURITYSIGNER'] == -1 || record['ALLRNA'] == -1 || record['ALLPRODUCT'] == -1
          roles << 'signer-securities'
        end
        if record['WIRESIGNER'] == -1
          roles << 'signer-wiretransfers'
        end
        if record['REPOSIGNER'] == -1 || record['ALLRNA'] == -1 || record['ALLPRODUCT'] == -1
          roles << 'signer-repurchaseagreement'
        end
        if record['AFFORDABITYSIGNER'] == -1 || record['ALLRNA'] == -1 || record['ALLPRODUCT'] == -1
          roles << 'signer-affordability'
        end
        if record['ALLRNA'] == -1
          roles << 'signer-manager'
        end
        if record['ALLPRODUCT'] == -1
          roles << 'signer-entire-authority'
        end
        if record['ACTIVE_TOKEN_EXISTS_FLAG'] == 'Y'
          roles << 'signer-etransact'
        end
        roles
      end
    end
  end
end