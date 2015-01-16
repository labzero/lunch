module MAPI
  module Models
    class EtransactAdvances
      include Swagger::Blocks
      swagger_model :etransactAdvancesStatus do
        property :etransact_advances_status do
          key :type, :boolean
          key :description, 'indicate etransact advances is turn on and at least one proudct/term not reach End Time for today'
        end
        property :wl_vrc_status do
          key :type, :boolean
          key :description, 'indicate that wholeloan VRC overnight term is not disabled'
        end
        property :all_loan_status do
          key :type, :AllStatusObject
          key :description, 'An object containing etransact status for each of the specified loan_term and loan_type'
        end
      end
      swagger_model :AllStatusObject do
        property :loan_term do
          key :type, :LoanTypeObject
          key :description, 'An object containing all data relevant to the specified loan_term and loan_type'
          key :enum, [:overnight, :open, :'1week', :'2week', :'3week', :'1month', :'2month', :'3month', :'6month', :'1year', :'2year', :'3year']
        end
      end
      swagger_model :LoanTypeObject do
        property :loan_type do
          key :type, :BucketStatusObject
          key :description, 'An object containing LoanTermObjects relevant to the specified loan_type'
          key :enum, [:whole_loan, :agency, :aaa, :aa]
        end
      end
      swagger_model :BucketStatusObject do
        property :trade_status do
          key :type, :boolean
          key :description, 'Indicate of trading is still available'
        end
        property :display_status do
          key :type, :boolean
          key :description, 'Indicate whether to display the rates'
        end
        property :bucket_label do
          key :type, :string
          key :description, 'Advances Type/Term bucket label'
        end
      end
    end
  end
end