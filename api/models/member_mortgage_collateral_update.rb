module MAPI
  module Models
    class MemberMortgageCollateralUpdate
      include Swagger::Blocks
      swagger_model :MemberMortgageCollateralUpdate do
        property :date_processed do
          key :type, :date
          key :description, 'The date on which the Mortgage Collateral was updated'
        end
        property :mcu_type do
          key :type, :string
          key :description, 'A description of the MCU type (Complete, Depledge, etc)'
        end
        property :transaction_number do
          key :type, :string
          key :description, 'The transaction number of the Mortgage Collateral Update being shown'
        end
        property :pledge_type do
          key :type, :string
          key :description, 'Pledge type (i.e. FHLB)'
        end
        property :pledged_count do
          key :type, :integer
          key :description, 'A count of the accepted, pledged loans'
        end
        property :updated_count do
          key :type, :integer
          key :description, 'A count of the accepted, updated loans'
        end
        property :renumbered_count do
          key :type, :integer
          key :description, 'A count of the accepted, renumbered loans'
        end
        property :accepted_count do
          key :type, :integer
          key :description, 'A count of the total accepted loans (i.e. pledged, updated and renumbered)'
        end
        property :depledged_count do
          key :type, :integer
          key :description, 'A count of the depledged/deleted loans'
        end
        property :rejected_count do
          key :type, :integer
          key :description, 'A count of the rejected loans'
        end
        property :total_count do
          key :type, :integer
          key :description, 'Total count of all loans'
        end
        property :pledged_unpaid do
          key :type, :integer
          key :description, 'Dollar value of the unpaid portion of accepted, pledged loans'
        end
        property :updated_unpaid do
          key :type, :integer
          key :description, 'Dollar value of the unpaid portion of accepted, updated loans'
        end
        property :renumbered_unpaid do
          key :type, :integer
          key :description, 'Dollar value of the unpaid portion of accepted, renumbered loans'
        end
        property :accepted_unpaid do
          key :type, :integer
          key :description, 'Dollar value of the unpaid portion of total accepted loans (i.e. pledged, updated and renumbered)'
        end
        property :depledged_unpaid do
          key :type, :integer
          key :description, 'Dollar value of the unpaid portion of depledged/deleted loans'
        end
        property :rejected_unpaid do
          key :type, :integer
          key :description, 'Dollar value of the unpaid portion of  rejected loans'
        end
        property :total_unpaid do
          key :type, :integer
          key :description, 'Dollar value of the unpaid portion of all loans'
        end
        property :pledged_original do
          key :type, :integer
          key :description, 'Original dollar value of accepted, pledged loans'
        end
        property :updated_original do
          key :type, :integer
          key :description, 'Original dollar value of accepted, updated loans'
        end
        property :renumbered_original do
          key :type, :integer
          key :description, 'Original dollar value of accepted, renumbered loans'
        end
        property :accepted_original do
          key :type, :integer
          key :description, 'Original dollar value of total accepted loans (i.e. pledged, updated and renumbered)'
        end
        property :depledged_original do
          key :type, :integer
          key :description, 'Original dollar value of depledged/deleted loans'
        end
        property :rejected_original do
          key :type, :integer
          key :description, 'Original dollar value of  rejected loans'
        end
        property :total_original do
          key :type, :integer
          key :description, 'Original dollar value of all loans'
        end        
      end
    end
  end
end
