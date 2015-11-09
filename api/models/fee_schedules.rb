module MAPI
  module Models
    class FeeSchedules
      include Swagger::Blocks
      swagger_model :FeeSchedules do
        key :required, [:securities_services, :wire_transfer_and_sta, :letters_of_credit]
        property :securities_services do
          key :type, :SecuritiesServicesFeesObject
          key :description, 'An object containing the breakdown of Securities Services fees'
        end
        property :wire_transfer_and_sta do
          key :type, :WireTransferAndStaFeesObject
          key :description, 'An object containing the breakdown of Wire Transfer and STA fees'
        end
        property :letters_of_credit do
          key :type, :LettersOfCreditFeesObject
          key :description, 'An object containing the breakdown of Standby Letters of Credit prices and fees'
        end
      end
      swagger_model :SecuritiesServicesFeesObject do
        key :required, [:monthly_maintenance, :monthly_securities, :security_transaction, :miscellaneous]
        property :monthly_maintenance do
          key :type,  :MonthlyMaintenanceFeesObject
          key :description, 'An object containing the breakdown of Monthly Account Maintenance Fees'
        end
        property :monthly_securities do
          key :type, :MonthlySecuritiesFeesObject
          key :description, 'An object containing the breakdown of Monthly Securities Fees'
        end
        property :security_transaction do
          key :type, :SecurityTransactionFeesObject
          key :description, 'An object containing the breakdown of Security Transaction Fees'
        end
        property :miscellaneous do
          key :type, :MiscellaneousFeesObject
          key :description, 'An object containing the breakdown of Miscellaneous Securities Services Fees'
        end
      end
      swagger_model :MonthlyMaintenanceFeesObject do
        key :required, [:less_than_10, :between_10_and_24, :more_than_24]
        property :less_than_10 do
          key :type, :number
          key :format, :float
          key :description, 'Monthly fee when less than 10 lots are held at the end of the month'
        end
        property :between_10_and_24 do
          key :type, :number
          key :format, :float
          key :description, 'Monthly fee when between 10 and 24 lots are held at the end of the month'
        end
        property :more_than_24 do
          key :type, :number
          key :format, :float
          key :description, 'Monthly fee when more than 24 lots are held at the end of the month'
        end
      end
      swagger_model :MonthlySecuritiesFeesObject do
        key :required, [:fed, :dtc, :physical, :euroclear]
        property :fed do
          key :type, :number
          key :format, :float
          key :description, 'Monthly Securities Fee for Federal Reserve Bank Securities'
        end
        property :dtc do
          key :type, :number
          key :format, :float
          key :description, 'Monthly Securities Fee for Depository Securities/ PTC (GNMA)'
        end
        property :physical do
          key :type, :number
          key :format, :float
          key :description, 'Monthly Securities Fee for Physical Securities'
        end
        property :euroclear do
          key :type, :EuroclearMonthlyFeeObject
          key :description, 'An object containing the breakdown of Euroclear monthly securities fees'
        end
      end
      swagger_model :EuroclearMonthlyFeeObject do
        key :required, [:fee_per_par, :per_par_amount]
        property :fee_per_par do
          key :type, :number
          key :format, :float
          key :description, 'The Euroclear fee per par'
        end
        property :per_par_amount do
          key :type, :integer
          key :description, 'The Euroclear par amount to which the `fee_per_par` pertains'
        end
      end
      swagger_model :SecurityTransactionFeesObject do
        key :required, [:fed, :dtc, :physical, :euroclear]
        property :fed do
          key :type, :number
          key :format, :float
          key :description, 'Security Transaction Fee for Federal Reserve Bank Securities'
        end
        property :dtc do
          key :type, :number
          key :format, :float
          key :description, 'Security Transaction Fee for Depository Securities/ PTC (GNMA)'
        end
        property :physical do
          key :type, :number
          key :format, :float
          key :description, 'Security Transaction Fee for Physical Securities'
        end
        property :euroclear do
          key :type, :number
          key :format, :float
          key :description, 'Security Transaction Fee for EURO C.D./CEDEL Eligible Securities'
        end
      end
      swagger_model :MiscellaneousFeesObject do
        key :required, [:all_income_disbursement, :pledge_status_change, :certificate_registration, :research_projects, :special_handling]
        property :all_income_disbursement do
          key :type, :number
          key :format, :float
          key :description, 'Fee for All Income Disbursement'
        end
        property :pledge_status_change do
          key :type, :number
          key :format, :float
          key :description, 'Fee for a Pledge Status Change (i.e. Account Transfer)'
        end
        property :certificate_registration do
          key :type, :number
          key :format, :float
          key :description, 'Fee for Registration of a Certificate'
        end
        property :research_projects do
          key :type, :number
          key :format, :float
          key :description, 'Hourly fee for Research Projects'
        end
        property :special_handling do
          key :type, :number
          key :format, :float
          key :description, 'Fee for Special Handling'
        end
      end
      swagger_model :WireTransferAndStaFeesObject do
        key :required, [:domestic_outgoing_wires, :domestic_incoming_wires, :overdraft_charges, :miscellaneous]
        property :domestic_outgoing_wires do
          key :type, :DomesticOutgoingWiresObject
          key :description, 'An object containing the breakdown of domestic outgoing wire fees'
        end
        property :domestic_incoming_wires do
          key :type, :number
          key :format, :float
          key :description, 'The fee per wire for domestic incoming wires'
        end
        property :overdraft_charges do
          key :type, :OverdraftChargesObject
          key :description, 'An object containing the breakdown of overdraft charges'
        end
        property :miscellaneous do
          key :type, :MiscellaneousWireTransferObject
          key :description, 'An object containing the breakdown of miscellaneous fees associated with wire transfers and STAs'
        end
      end
      swagger_model :DomesticOutgoingWiresObject do
        key :required, [:telephone_repetitive, :telephone_non_repetitive, :drawdown_request, :standing_request]
        property :telephone_repetitive do
          key :type, :number
          key :format, :float
          key :description, 'The fee per wire for domestic outgoing wires, telephone repetitive'  
        end
        property :telephone_non_repetitive do
          key :type, :number
          key :format, :float
          key :description, 'The fee per wire for domestic outgoing wires, telephone non-repetitive'
        end
        property :drawdown_request do
          key :type, :number
          key :format, :float
          key :description, 'The fee per wire for domestic outgoing wires, drawdown request'
        end
        property :standing_request do
          key :type, :number
          key :format, :float
          key :description, 'The fee per wire for domestic outgoing wires, standing request'
        end
      end
      swagger_model :OverdraftChargesObject do
        key :required, [:interest_rate, :processing_fee]
        property :interest_rate do
          key :type, :integer
          key :description, 'The interest rate (in basis points) charged on top of federal funds upon overdraft'
        end
        property :processing_fee do
          key :type, :number
          key :format, :float
          key :description, 'The processing fee charged per overdraft'
        end
      end
      swagger_model :MiscellaneousWireTransferObject do
        key :required, [:photocopies, :special_account_research]
        property :photocopies do
          key :type, :number
          key :format, :float
          key :description, 'The cost of photocopies, per item or statement'
        end
        property :special_account_research do
          key :type, :number
          key :format, :float
          key :description, 'The cost of special account research, per hour '
        end
      end
      swagger_model :LettersOfCreditFeesObject do
        key :required, [:annual_maintenance_charge, :issuance_fee, :draw_fee, :amendment_fee]
        property :annual_maintenance_charge do
          key :type, :AnnualMaintenanceChargeObject
          key :description, 'An object containing the breakdown of LOC annual maintenance charges'
        end
        property :issuance_fee do
          key :type, :IssuanceFeeObject
          key :description, 'An object containing the breakdown of LOC issuance fees'
        end
        property :draw_fee do
          key :type, :integer
          key :description, 'The draw fee, in whole dollars'
        end
        property :amendment_fee do
          key :type, :AmendmentFeeObject
          key :description, 'An object containing the breakdown of LOC amendment fees'
        end
      end
      swagger_model :AnnualMaintenanceChargeObject do
        key :required, [:minimum_annual_fee, :cip_ace, :agency_deposits, :other_purposes]
        property :minimum_annual_fee do
          key :type, :integer
          key :description, 'The minimum annual fee, in whole dollars'
        end
        property :cip_ace do
          key :type, :integer
          key :description, 'The CIP/ACE charge in basis points per annum'
        end
        property :agency_deposits do
          key :type, :integer
          key :description, 'The state and local agency deposits charge in basis points per annum'
        end
        property :other_purposes do
          key :type, :integer
          key :description, 'The charge in basis points per annum of miscellaneous annual maintenance charges'
        end
      end
      swagger_model :IssuanceFeeObject do
        key :required, [:agency_deposits, :other_purposes, :commercial_paper, :tax_exempt_bond]
        property :agency_deposits do
          key :type, :integer
          key :description, 'The state and local agency deposits issuance fee, in whole dollars'
        end
        property :other_purposes do
          key :type, :integer
          key :description, 'The fee, in whole dollars, for other purpose issuance fees'
        end
        property :commercial_paper do
          key :type, :PriceRangeObject
          key :description, 'The upper and lower ranges for the commercial paper issuance fee, in whole dollars'
        end
        property :tax_exempt_bond do
          key :type, :PriceRangeObject
          key :description, 'The upper and lower ranges for the tax-exempt bond issuance fee, in whole dollars'
        end
      end
      swagger_model :PriceRangeObject do
        key :required, [:lower_limit, :upper_limit]
        property :lower_limit do
          key :type, :integer
          key :description, 'The lower limit of the price range, in whole dollars'
        end
        property :upper_limit do
          key :type, :integer
          key :description, 'The upper limit of the price range, in whole dollars'
        end
      end
      swagger_model :AmendmentFeeObject do
        key :required, [:agency_deposits, :other_purposes]
        property :agency_deposits do
          key :type, :integer
          key :description, 'The state and local agency deposits amendment fee, in whole dollars'
        end
        property :other_purposes do
          key :type, :integer
          key :description, 'The fee, in whole dollars, for other purpose amendment fees'
        end
      end
    end
  end
end