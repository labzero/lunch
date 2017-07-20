module MAPI
  module Services
    module Member
      module Beneficiaries
        include MAPI::Shared::Utils
        def self.beneficiaries(app, member_id)
          unless should_fake?(app)
            beneficiaries_query = <<-SQL
              Select
              B.Name Beneficiary_Short_Name,
              B.beneficiary_Name__C Beneficiary_Full_Name,  
              B.care_of__c Care_of,
              B.department__c Department,
              B.street__c Street,
              B.city__c City,
              B.state__c State,
              B.zip__c Zip
              From
              crm.Account A,
              crm.Account_Beneficiary__C Ab,
              crm.Beneficiary__C  B
              Where
              A.Fhlb_Id__C = #{quote(member_id)}
              And Ab.Status__C = 'Active'
              And A.Id = Ab.Account__C
              And Ab.Beneficiary__C = B.Id
              And A.Isdeleted = 'false'
              And Ab.Isdeleted = 'false'
              And B.Isdeleted = 'false'
            SQL
            begin
              beneficiaries = []
              cursor  = execute_sql(app.logger, beneficiaries_query)
              while row = cursor.fetch_hash()
                row['STREET'] = row['STREET'].try(:read)
                beneficiaries << row.with_indifferent_access
              end
              beneficiaries
            rescue => e
              app.logger.error(e.message)
              []
            end
          else
            fake_hashes('beneficiaries')
          end
        end
      end
    end
  end
end