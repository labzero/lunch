module MAPI
  module Models
    class BorrowingCapacityDetails
      include Swagger::Blocks
      swagger_model :BorrowingCapacityDetails do
        property :date do
          key :type, :date
          key :description, 'As of date of the Borrowing Capacity details'
        end
        property :standard do
          key :type, :StandardCollateralObject
          key :description, 'An object containing the breakdown of Standard Collateral Borrowing Capacity data'
        end
        property :sbc do
          key :type, :SBCCollateralObject
          key :description, 'An object containing the breakdown of Standard Collateral Borrowing Capacity data'
        end
      end
      swagger_model :StandardCollateralObject do
        property :collateral do
          key :type,  :StandardCollateralTypeObject
          key :description, 'An object containing the list of Standard Collateral Type Object'
        end
        property :excluded do
          key :type, :StandardExcludedObject
          key :description, 'An object containing the values for the excluded standard borrowing capacity'
        end
        property :utilized do
          key :type, :StandardUtilizedObject
          key :description, 'An object containing the values for the utilized standard borrowing capacity'
        end
      end
      swagger_model :StandardExcludedObject do
        property :blanket_lien do
          key :type, :number
          key :description, 'Standard - Excluded Standard Blanket Lien BC'
        end
        property :bank do
          key :type, :number
          key :description, 'Standard - Excluded Standard Bank BC'
        end
        property :advances do
          key :type, :number
          key :description, 'Standard - Utilized BC for Advances'
        end
      end
      swagger_model :StandardUtilizedObject do
        property :letters_of_credit do
          key :type, :number
          key :description, 'Standard - Utilized BC for LC'
        end
        property :swap_collateral do
          key :type, :number
          key :description, 'Standard - Utilized BC for SWAP'
        end
        property :sbc_type_deficiencies do
          key :type, :number
          key :description, 'Standard - Utilized BC to cover SBC type deficiencies'
        end
        property :payment_fees do
          key :type, :number
          key :description, 'Standard - Utilized BC for potential payment fees'
        end
        property :other_collateral do
          key :type, :number
          key :description, 'Standard - Utilized BC for other collateral'
        end
        property :mpf_ce_collateral do
          key :type, :number
          key :description, 'Standard - Utilized BC for MPF CE collateral'
        end
      end
      swagger_model :StandardCollateralTypeObject do
        property :type do
          key :type, :string
          key :description, 'Standard collateral loan type'
        end
        property :count do
          key :type, :number
          key :description, 'Count for the specific type'
        end
        property :origianl_amount do
          key :type, :number
          key :description, 'Original amount of the loan'
        end
        property :unpaid_pricincal do
          key :type, :number
          key :description, 'Unpaid principal amount of the loan'
        end
        property :market_value do
          key :type, :number
          key :description, 'Market value of the loan'
        end
        property :borrowing_capactiy do
          key :type, :number
          key :description, 'Borrowing Capacity of the loan'
        end
      end
      swagger_model :SBCCollateralObject do
        property :collateral do
          key :type,  :SBCTypeObject
          key :description, 'An object containing the list of Securities Backed Collateral (SBC) Type Object'
        end
        property :utilized do
          key :type, :SBCUtilizedObject
          key :description, 'An object containing the values for the utilized SBC borrowing capacity'
        end
      end
      swagger_model :SBCTypeObject do
        property :aa do
          key :type,  :SBCTypeDetailObject
          key :description, 'An object containing the list of Securities Backed Collateral (SBC) AA Type Object'
        end
        property :aaa do
          key :type,  :SBCTypeDetailObject
          key :description, 'An object containing the list of Securities Backed Collateral (SBC) AAA Type Object'
        end
        property :agency do
          key :type,  :SBCTypeDetailObject
          key :description, 'An object containing the list of Securities Backed Collateral (SBC) Agency Type Object'
        end
      end
      swagger_model :SBCTypeDetailObject do
        property :total_market_value do
          key :type, :number
          key :description, 'Total market value of this SBC collateral'
        end
        property :total_borrowing_capacity do
          key :type, :number
          key :description, 'Total borrowing capacity of this SBC collateral'
        end
        property :advances do
          key :type, :number
          key :description, 'Advances amount taken for this SBC collateral'
        end
        property :standard_credit do
          key :type, :number
          key :description, 'Standard credit amount for this SBC collateral'
        end
        property :remaining_market_value do
          key :type, :number
          key :description, 'The remaining Market value of this SBC collateral '
        end
        property :borrowing_capactiy do
          key :type, :number
          key :description, 'Remaining Borrowing Capacity of this SBC collateral'
        end
      end
      swagger_model :SBCUtilizedObject do
        property :other_collateral do
          key :type, :number
          key :description, 'SBC - Utilized BC for other collateral'
        end
        property :excluded_regulatory do
          key :type, :number
          key :description, 'SBC - Utilized BC of excluded regularatory'
        end
      end
    end
  end
end