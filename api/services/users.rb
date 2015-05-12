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
              SELECT SIGNER_ID FROM WEB_ADM.ETRANSACT_SIGNER WHERE LOGIN_ID = #{ActiveRecord::Base.connection.quote(username)}
            SQL
            ActiveRecord::Base.connection.execute(signer_id_query).fetch do |row|
              signer_id = row[0].to_i
            end
            halt 404, 'User not found' unless signer_id

            roles_query = <<-SQL
              SELECT * FROM SIGNER.SIGNERS WHERE SIGNERID = #{ActiveRecord::Base.connection.quote(signer_id)}
            SQL
            ActiveRecord::Base.connection.execute(roles_query).fetch_hash do |row|
              if row['ADVSIGNER'] == 0 || row['ALLRNA'] == 0 || row['ALLPRODUCT'] == 0
                roles << 'signer-advances'
              end
              if row['COLLATSIGNER'] == 0 || row['ALLRNA'] == 0 || row['ALLPRODUCT'] == 0
                roles << 'signer-collateral'
              end
              if row['MNYMKTSIGNER'] == 0 || row['ALLRNA'] == 0 || row['ALLPRODUCT'] == 0
                roles << 'signer-moneymarket'
              end
              if row['SWAPSIGNER'] == 0 || row['ALLRNA'] == 0 || row['ALLPRODUCT'] == 0
                roles << 'signer-creditswap'
              end
              if row['SECURITYSIGNER'] == 0 || row['ALLRNA'] == 0 || row['ALLPRODUCT'] == 0
                roles << 'signer-securities'
              end
              if row['WIRESIGNER'] == 0 || row['ALLRNA'] == 0 || row['ALLPRODUCT'] == 0
                roles << 'signer-wiretransfers'
              end
              if row['REPOSIGNER'] == 0 || row['ALLRNA'] == 0 || row['ALLPRODUCT'] == 0
                roles << 'signer-repurchaseagreement'
              end
              if row['AFFORDABITYSIGNER'] == 0 || row['ALLRNA'] == 0 || row['ALLPRODUCT'] == 0
                roles << 'signer-affordability'
              end
              if row['ALLRNA'] == 0
                roles << 'access-manager'
              end
            end
          else
            data = JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'user_roles.json')))
            halt 404, 'User not found' unless data[username]
            roles = data[username]
          end
          roles.to_json
        end
      end
    end
  end
end