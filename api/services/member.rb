require_relative 'member/advances_details'
require_relative 'member/balance'
require_relative 'member/borrowing_capacity_details'
require_relative 'member/capital_stock'
require_relative 'member/capital_stock_and_leverage'
require_relative 'member/capital_stock_trial_balance'
require_relative 'member/cash_projections'
require_relative 'member/disabled_reports'
require_relative 'member/dividend_statement'
require_relative 'member/flags'
require_relative 'member/forward_commitments'
require_relative 'member/interest_rate_resets'
require_relative 'member/letters_of_credit'
require_relative 'member/mortgage_collateral_update'
require_relative 'member/parallel_shift_analysis'
require_relative 'member/profile'
require_relative 'member/securities_position'
require_relative 'member/securities_transactions'
require_relative 'member/securities_services_statements'
require_relative 'member/securities_requests'
require_relative 'member/settlement_transaction_account'
require_relative 'member/signer_roles'
require_relative 'member/trade_activity'

module MAPI
  module Services
    module Member
      include MAPI::Services::Base

      def self.registered(app)
        service_root '/member', app
        swagger_api_root :member do

          # pledged collateral endpoint
          api do
            key :path, '/{id}/balance/pledged_collateral'
            operation do
              key :method, 'GET'
              key :summary, 'Retrieve pledged collateral for member'
              key :notes, 'Returns an array of collateral pledged by a member broken down by security type'
              key :type, :MemberBalancePledgedCollateral
              key :nickname, :getPledgedCollateralForMember
              parameter do
                key :paramType, :path
                key :name, :id
                key :required, true
                key :type, :string
                key :description, 'The id to find the members from'
              end
              response_message do
                key :code, 200
                key :message, 'OK'
              end
            end
          end

          # total securities endpoint
          api do
            key :path, '/{id}/balance/total_securities'
            operation do
              key :method, 'GET'
              key :summary, 'Retrieves counts of pledged and safekept securities for a member'
              key :notes, 'Returns an array containing a count of pledged and safekept securities'
              key :type, :MemberBalanceTotalSecurities
              key :nickname, :getTotalSecuritiesCountForMember
              parameter do
                key :paramType, :path
                key :name, :id
                key :required, true
                key :type, :string
                key :description, 'The id to find the members from'
              end
              response_message do
                key :code, 200
                key :message, 'OK'
              end
            end
          end
          api do
            key :path, '/{id}/balance/effective_borrowing_capacity'
            operation do
              key :method, 'GET'
              key :summary, 'Retrieve effective borrowing capacity for member'
              key :notes, 'Returns total and unused effective borrowing capacity for a member'
              key :type, :MemberBalanceBorrowingCapacity
              key :nickname, :memberBalanceEffectiveBorrowingCapacity
              parameter do
                key :paramType, :path
                key :name, :id
                key :required, true
                key :type, :string
                key :description, 'The id to find the members from'
              end
              response_message do
                key :code, 200
                key :message, 'OK'
              end
            end
          end
          api do
            key :path, "/{id}/capital_stock_balance/{balance_date}"
            operation do
              key :method, 'GET'
              key :summary, 'Retrieve Capital Stock Balance for a specific date for a member'
              key :notes, 'Returns Capital Stock Balance and Open/Close balance for the selected date.'
              key :type, :CapitalStockBalance
              key :nickname, :getCapitalStockBalanceForMember
              parameter do
                key :paramType, :path
                key :name, :id
                key :required, true
                key :type, :string
                key :description, 'The id to find the members from'
              end
              parameter do
                key :paramType, :path
                key :name, :balance_date
                key :required, true
                key :type, :string
                key :description, 'Start date yyyy-mm-dd for the Capital Stock Activities Report.'
              end
              response_message do
                key :code, 200
                key :message, 'OK'
              end
              response_message do
                key :code, 400
                key :message, 'Invalid input'
              end
            end
          end
          api do
            key :path, "/{id}/capital_stock_activities/{from_date}/{to_date}"
            operation do
              key :method, 'GET'
              key :summary, 'Retrieve Capital Stock Activities transactions.'
              key :notes, 'Returns Capital Stock Activities for the selected periord.'
              key :type, :CapitalStockActivities
              key :nickname, :getCapitalStockActivitiesForMember
              parameter do
                key :paramType, :path
                key :name, :id
                key :required, true
                key :type, :string
                key :description, 'The id to find the members from'
              end
              parameter do
                key :paramType, :path
                key :name, :from_date
                key :required, true
                key :type, :string
                key :description, 'Start date yyyy-mm-dd for the Capital Stock Activities Report.'
              end
              parameter do
                key :paramType, :path
                key :name, :to_date
                key :required, true
                key :type, :string
                key :description, 'End date yyyy-mm-dd for the Capital Stock Activities Report.'
              end
              response_message do
                key :code, 200
                key :message, 'OK'
              end
              response_message do
                key :code, 400
                key :message, 'Invalid input'
              end
            end
          end

          api do
            key :path, "/{id}/borrowing_capacity_details/{as_of_date}"
            operation do
              key :method, 'GET'
              key :summary, 'Retrieve Borrowing Capacity details for both Standard and SBC'
              key :notes, 'Returns Borrowing Capacity details values for Standard (which also include collateral type breakdown) and SBC.'
              key :type, :BorrowingCapacityDetails
              key :nickname, :getBorrowingCapactityDetailsForMember
              parameter do
                key :paramType, :path
                key :name, :id
                key :required, true
                key :type, :integer
                key :description, 'The id to find the members from'
              end
              parameter do
                key :paramType, :path
                key :name, :as_of_date
                key :defaultValue,  Time.zone.today()
                key :required, true
                key :type, :date
                key :description, 'As of date for the Borrowing Capacity data.  If not provided, will retrieve intraday position.'
              end
              response_message do
                key :code, 200
                key :message, 'OK'
              end
            end
          end
          api do
            key :path, "/{id}/sta_activities/{from_date}/{to_date}"
            operation do
              key :method, 'GET'
              key :summary, 'Retrieve STA Activities transactions.'
              key :notes, 'Returns STA Activities for the selected periord.'
              key :type, :STAActivities
              key :nickname, :getSTAActivitiesForMember
              parameter do
                key :paramType, :path
                key :name, :id
                key :required, true
                key :type, :string
                key :description, 'The id to find the members from'
              end
              parameter do
                key :paramType, :path
                key :name, :from_date
                key :required, true
                key :type, :string
                key :description, 'Start date yyyy-mm-dd for the STA Activities Report.'
              end
              parameter do
                key :paramType, :path
                key :name, :to_date
                key :required, true
                key :type, :string
                key :description, 'End date yyyy-mm-dd for the STA Activities Report.'
              end
              response_message do
                key :code, 200
                key :message, 'OK'
              end
              response_message do
                key :code, 400
                key :message, 'Invalid input'
              end
              response_message do
                key :code, 404
                key :message, 'No Data Found'
              end
            end
          end
          api do
            key :path, "/{id}/current_sta_rate"
            operation do
              key :method, 'GET'
              key :summary, 'Retrieve the current rate for the member\'s Settlement Transaction Account.'
              key :notes, 'This is the rate as of close of business on the previous day.'
              key :type, :CurrentSTARate
              key :nickname, :getCurrentSTARateForMember
              parameter do
                key :paramType, :path
                key :name, :id
                key :required, true
                key :type, :string
                key :description, 'The id to find the members from'
              end
              response_message do
                key :code, 200
                key :message, 'OK'
              end
            end
          end
          api do
            key :path, "/{id}/advances_details/{as_of_date}"
            operation do
              key :method, 'GET'
              key :summary, 'Retrieve Advances Details daily image of the specific date for a member'
              key :notes, 'Returns Advances Details daily image for the selected date.'
              key :type, :AdvancesDetails
              key :nickname, :getAdvancesDetailsForMember
              parameter do
                key :paramType, :path
                key :name, :id
                key :required, true
                key :type, :string
                key :description, 'The id to find the members from'
              end
              parameter do
                key :paramType, :path
                key :name, :as_of_date
                key :required, true
                key :type, :string
                key :description, 'As of date yyyy-mm-dd for the Advances Details Report.'
              end
              response_message do
                key :code, 200
                key :message, 'OK'
              end
              response_message do
                key :code, 400
                key :message, 'Invalid date'
              end
            end
          end
          api do
            key :path, '/{id}/active_advances'
            operation do
              key :method, 'GET'
              key :summary, 'Retrieve Active Advances for a member'
              key :notes, 'Returns Active Advances.'
              key :type, :ActiveAdvances
              key :nickname, :getActiveAdvancesForMember
              parameter do
                key :paramType, :path
                key :name, :id
                key :required, true
                key :type, :string
                key :description, 'The id to find the members from'
              end
              response_message do
                key :code, 200
                key :message, 'OK'
              end
            end
          end
          api do
            key :path, '/{id}/advance_confirmation/{advance_number}/{confirmation_number}'
            operation do
              key :method, 'GET'
              key :summary, 'Retrieve Advance Confirmation as data stream for a member'
              key :notes, 'Advance confirmation found by member_id, advance_number, confirmation_number'
              key :description, 'Returns an advance confirmation attachment using `rack.hijack` if available to allow streaming.'
              parameter do
                key :paramType, :path
                key :name, :id
                key :required, true
                key :type, :string
                key :description, 'The id to find the members from'
              end
              parameter do
                key :paramType, :path
                key :name, :advance_number
                key :required, true
                key :type, :string
                key :description, 'The advance number for the requested advance'
              end
              parameter do
                key :paramType, :path
                key :name, :confirmation_number
                key :required, true
                key :type, :string
                key :description, 'The confirmation number for the requested advance'
              end
              response_message do
                key :code, 200
                key :message, 'OK'
              end
            end
          end
          api do
            key :path, '/{id}/todays_advances'
            operation do
              key :method, 'GET'
              key :summary, 'Retrieve Todays Advances for a member'
              key :notes, 'Returns Todays Advances.'
              key :type, :ActiveAdvances
              key :nickname, :getTodaysAdvancesForMember
              parameter do
                key :paramType, :path
                key :name, :id
                key :required, true
                key :type, :string
                key :description, 'The id to find the members from'
              end
              response_message do
                key :code, 200
                key :message, 'OK'
              end
            end
          end
          api do
            key :path, '/{id}/member_profile'
            operation do
              key :method, 'GET'
              key :summary, 'Retrieve current member financial profile'
              key :notes, 'Returns a row with member financial profile'
              key :type, :MemberFinancialProfile
              key :nickname, :getFinancialProfileForMember
              parameter do
                key :paramType, :path
                key :name, :id
                key :required, true
                key :type, :string
                key :description, 'The id to find the members from'
              end
            end
          end
          api do
            key :path, '/{id}/member_contacts'
            operation do
              key :method, 'GET'
              key :summary, 'Retrieve current member contacts'
              key :notes, 'Returns a hash with contact info for the member bank\'s Relationship Manager and Collateral Asset Manager'
              key :type, :MemberContacts
              key :nickname, :getContactsForMember
              parameter do
                key :paramType, :path
                key :name, :id
                key :required, true
                key :type, :string
                key :description, 'The id to find the members from'
              end
            end
          end
          api do
            key :path, '/{id}/'
            operation do
              key :method, 'GET'
              key :summary, 'Retrieve current member biographic details'
              key :notes, 'Returns basic details about a member'
              key :type, :MemberDetails
              key :nickname, :getMemberDetails
              parameter do
                key :paramType, :path
                key :name, :id
                key :required, true
                key :type, :string
                key :description, 'The id to find the members from'
              end
            end
          end
          api do
            key :path, '/'
            operation do
              key :method, 'GET'
              key :summary, 'Retrieve list of all members'
              key :type, :array
              items do
                key :'$ref', :Member
              end
              key :nickname, :getMembers
            end
          end
          api do
            key :path, '/{id}/disabled_reports'
            operation do
              key :method, 'GET'
              key :summary, 'Retrieve the IDs of reports flagged as disabled'
              key :notes, 'Retrieve the IDs of reports flagged as disabled'
              key :type, :array
              items do
                key :type, :integer
              end
              key :nickname, :getDisabledReportIDsForMember
              parameter do
                key :paramType, :path
                key :name, :id
                key :required, true
                key :type, :string
                key :description, 'The id to find the members from'
              end
            end
          end
          api do
            key :path, '/{id}/quick_advance_flag'
            operation do
              key :method, 'GET'
              key :summary, 'Retrieve the Quick Advance Flag for the member'
              key :notes, 'Returns a hash whose `quick_advance_flag` property indicates whether quick advances are enabled for a given member'
              key :type, :MemberQuickAdvanceFlag
              key :nickname, :getQuickAdvanceFlagForMember
              parameter do
                key :paramType, :path
                key :name, :id
                key :required, true
                key :type, :string
                key :description, 'The id to find the members from'
              end
            end
          end
          api do
            key :path, '/{id}/cash_projections'
            operation do
              key :method, 'GET'
              key :summary, 'Retrieve cash projections for the last date the projections were calculated by FHLB'
              key :notes, 'Typically the last date the projections were calculated corresponds to the last business day. A given member bank will not necessarily have any cash projections for this date.'
              key :nickname, :getCashProjectionsForMember
              key :type, :MemberCashProjections
              parameter do
                key :paramType, :path
                key :name, :id
                key :required, true
                key :type, :string
                key :description, 'The id to find the members from'
              end
            end
          end
          api do
            key :path, '/{id}/signers'
            operation do
              key :method, 'GET'
              key :summary, 'Retrieve all bank members who are signers'
              key :notes, 'Returns the full name, username and signer roles for each signer'
              key :nickname, :getSignersForMember
              key :type, :MemberSigners
              parameter do
                key :paramType, :path
                key :name, :id
                key :required, true
                key :type, :string
                key :description, 'The id to find the members from'
              end
            end
          end
          api do
            key :path, '/{id}/current_securities_position/{custody_account_type}'
            operation do
              key :method, 'GET'
              key :summary, 'Retrieve current securities of a given account type'
              key :notes, 'Returns all of the current securities, all of the current pledged securities or all of the current unpledged securities based on "custody_account_type"'
              key :nickname, :getCurrentSecuritiesPositionForMembers
              key :type, :MemberSecuritiesPosition
              parameter do
                key :paramType, :path
                key :name, :id
                key :required, true
                key :type, :string
                key :description, 'The id to find the members from'
              end
              parameter do
                key :paramType, :path
                key :name, :custody_account_type
                key :required, true
                key :type, :string
                key :description, 'An argument to request either all securities, pledged securities or unpledged securities'
              end
              response_message do
                key :code, 200
                key :message, 'OK'
              end
              response_message do
                key :code, 400
                key :message, 'Invalid param for custody account type'
              end
            end
          end
          api do
            key :path, '/{id}/managed_securities'
            operation do
              key :method, 'GET'
              key :summary, 'Retrieve all securities currently being managed'
              key :nickname, :getManagedSecuritiesForMembers
              key :type, :MemberSecuritiesPosition
              parameter do
                key :paramType, :path
                key :name, :id
                key :required, true
                key :type, :string
                key :description, 'The id to find the members from'
              end
              response_message do
                key :code, 200
                key :message, 'OK'
              end
            end
          end
          api do
            key :path, '/{id}/monthly_securities_position/{month_end_date}/{custody_account_type}'
            operation do
              key :method, 'GET'
              key :summary, 'Retrieve securities of a given account type for the end of a given month'
              key :notes, 'Returns all of the securities, all of the pledged securities or all of the unpledged securities based on "custody_account_type" for the "month_end_date"'
              key :nickname, :getMonthlySecuritiesPositionForMembers
              key :type, :MemberSecuritiesPosition
              parameter do
                key :paramType, :path
                key :name, :id
                key :required, true
                key :type, :string
                key :description, 'The id to find the members from'
              end
              parameter do
                key :paramType, :path
                key :name, :month_end_date
                key :required, true
                key :type, :string
                key :description, 'The date for which the monthly securities will be returned'
              end
              parameter do
                key :paramType, :path
                key :name, :custody_account_type
                key :required, true
                key :type, :string
                key :description, 'An argument to request either all securities, pledged securities or unpledged securities'
              end
              response_message do
                key :code, 200
                key :message, 'OK'
              end
              response_message do
                key :code, 400
                key :message, 'Invalid param'
              end
            end
          end
          api do
            key :path, '/{id}/forward_commitments'
            operation do
              key :method, 'GET'
              key :summary, 'Retrieve forward commitments for a given member'
              key :notes, 'Retrieve forward commitments for a given member'
              key :nickname, :getForwardCommitmentsForMembers
              key :type, :MemberForwardCommitments
              parameter do
                key :paramType, :path
                key :name, :id
                key :required, true
                key :type, :string
                key :description, 'The id to find the members from'
              end
              response_message do
                key :code, 200
                key :message, 'OK'
              end
            end
          end
          api do
            key :path, '/{id}/capital_stock_and_leverage'
            operation do
              key :method, 'GET'
              key :summary, 'Retrieve the capital stock position and leverage for a given member'
              key :notes, 'Retrieve the capital stock position and leverage for a given member'
              key :nickname, :getCapitalStockAndLeverageForMembers
              key :type, :MemberCapitalStockAndLeverage
              parameter do
                key :paramType, :path
                key :name, :id
                key :required, true
                key :type, :string
                key :description, 'The id to find the members from'
              end
              response_message do
                key :code, 200
                key :message, 'OK'
              end
              response_message do
                key :code, 503
                key :message, 'Capital Stock Requirement Parameters not available'
              end
            end
          end
          api do
            key :path, '/{id}/letters_of_credit'
            operation do
              key :method, 'GET'
              key :summary, 'Retrieve letters of credit for the last date the letters of credit were calculated by FHLB'
              key :notes, 'Typically the last date on which the letters of credit were calculated corresponds to the last business day. A given member bank will not necessarily have any letters of credit for this date.'
              key :nickname, :getLettersOfCreditForMember
              key :type, :MemberLettersOfCredit
              parameter do
                key :paramType, :path
                key :name, :id
                key :required, true
                key :type, :string
                key :description, 'The id to find the members from'
              end
            end
          end
          api do
            key :path, '/{id}/interest_rate_resets'
            operation do
              key :method, 'GET'
              key :summary, 'Retrieve interest rate reset data for the last date this was calculated by FHLB'
              key :notes, 'Typically the last date on which the interest rate resets were calculated corresponds to the last business day. A given member bank will not necessarily have any interest rate reset data for this date.'
              key :nickname, :getInterestRateResetsForMember
              key :type, :MemberInterestRateResets
              parameter do
                key :paramType, :path
                key :name, :id
                key :required, true
                key :type, :string
                key :description, 'The id to find the members from'
              end
            end
          end
          api do
            key :path, '/{id}/parallel_shift_analysis'
            operation do
              key :method, 'GET'
              key :summary, 'Retrieve parallel shift analysis data for the last date the analysis was calculated by FHLB'
              key :notes, 'A given member bank will not necessarily have any parallel shift analysis data for the last date calculated.'
              key :nickname, :getParallelShiftAnalysisForMember
              key :type, :MemberParallelShift
              parameter do
                key :paramType, :path
                key :name, :id
                key :required, true
                key :type, :string
                key :description, 'The id to find the members from'
              end
              response_message do
                key :code, 200
                key :message, 'OK'
              end
              response_message do
                key :code, 503
                key :message, 'Interest Rate Resets not available'
              end
            end
          end
          api do
            key :path, '/{id}/dividend_statement/{date}/{div_id}'
            operation do
              key :method, 'GET'
              key :summary, 'Retrieve dividend statement for a given member and quarter'
              key :notes, 'Retrieve divident statement for a given member and quarter'
              key :nickname, :getDividendStatementForMembers
              key :type, :MemberDividendStatement
              parameter do
                key :paramType, :path
                key :name, :id
                key :required, true
                key :type, :string
                key :description, 'The id to find the members from'
              end
              parameter do
                key :paramType, :path
                key :name, :date
                key :required, true
                key :type, :string
                key :description, 'The date of the earliest allowed report'
              end
              parameter do
                key :paramType, :path
                key :name, :div_id
                key :required, true
                key :type, :string
                key :description, 'The div_id of the desired dividend statement'
                key :notes, 'If `current` is passed as a value, the endpoint will return the most recent dividend statement'
              end
              response_message do
                key :code, 200
                key :message, 'OK'
              end
            end
          end
          api do
            key :path, '/{id}/securities_transactions/{date}'
            operation do
              key :method, 'GET'
              key :summary, 'Retrieve securities transaction for a given member and date'
              key :notes, 'Retrieve securities transaction for a given member and date'
              key :nickname, :getSecuritiesTransactionForMembers
              key :type, :MemberSecuritiesTransactions
              parameter do
                key :paramType, :path
                key :name, :id
                key :required, true
                key :type, :string
                key :description, 'The id to find the members from'
              end
              parameter do
                key :paramType, :path
                key :name, :date
                key :required, true
                key :type, :string
                key :description, 'The date of the requested statement'
              end
              response_message do
                key :code, 200
                key :message, 'OK'
              end
            end
          end
          api do
            key :path, '/{id}/todays_credit_activity'
            operation do
              key :method, 'GET'
              key :summary, 'Retrieve today\'s credit activty for a given member'
              key :notes, 'Retrieve today\'s credit activty for a given member'
              key :nickname, :getTodaysCreditActivityForMember
              key :type, :MemberTodaysCreditActivity
              parameter do
                key :paramType, :path
                key :name, :id
                key :required, true
                key :type, :string
                key :description, 'The id to find the members from'
              end
            end
          end
          api do
            key :path, '/{id}/mortgage_collateral_update'
            operation do
              key :method, 'GET'
              key :summary, 'Retrieve the status of the member\'s last mortgage collateral update'
              key :notes, 'Retrieve the status of the member\'s last mortgage collateral update'
              key :nickname, :getMortgageCollateralUpdateForMember
              key :type, :MemberMortgageCollateralUpdate
              parameter do
                key :paramType, :path
                key :name, :id
                key :required, true
                key :type, :string
                key :description, 'The id to find the members from'
              end
            end
          end
          api do
            key :path, '/{id}/capital_stock_trial_balance/{date}'
            operation do
              key :method, 'GET'
              key :summary, 'Retrieve capital stock trial balance for a given member and date'
              key :notes, 'Retrieve capital stock trial balance for a given member and date'
              key :nickname, :getTodaysCreditActivityForMember
              key :type, :memberCapitalStockTrialBalance
              parameter do
                key :paramType, :path
                key :name, :id
                key :required, true
                key :type, :string
                key :description, 'The member id'
              end
              parameter do
                key :paramType, :path
                key :name, :date
                key :required, true
                key :type, :date
                key :description, 'The last business day'
              end
            end
          end
          api do
            key :path, '/{id}/securities_services_statements_available'
            operation do
              key :method, 'GET'
              key :summary, 'Retrieve the list of dates for which security services statements are available'
              key :notes, 'Retrieve the list of dates for which security services statements are available'
              key :nickname, :getSecurityServicesStatements
              key :type, :array
              items do
                key :'$ref', :memberSecurityServicesStatementDate
              end
              parameter do
                key :paramType, :path
                key :name, :id
                key :required, true
                key :type, :string
                key :description, 'The id to find the list of available statement dates from'
              end
            end
          end
          api do
            key :path, '/{id}/securities_services_statements/{date}'
            operation do
              key :method, 'GET'
              key :summary, 'Retrieve the list of security services for the given date'
              key :notes, 'Retrieve the list of security services for the given date'
              key :nickname, :getSecurityServicesStatementsForDate
              key :type, :array
              items do
                key :'$ref', :memberSecurityServicesStatement
              end
              parameter do
                key :paramType, :path
                key :name, :id
                key :required, true
                key :type, :string
                key :description, 'The id to find the list of available statement dates from'
              end
              parameter do
                key :paramType, :path
                key :name, :date
                key :required, true
                key :type, :string
                key :description, 'The date of the requested statement'
              end
            end
          end
          api do
            key :path, '/{id}/securities/requests'
            operation do
              key :method, 'GET'
              key :summary, 'Retrieve the list of securities requests for a given status'
              key :nickname, 'getAuthorizedSecuritiesRequests'
              key :type, :array
              items do
                key :'$ref', :SecuritiesRequestForm
              end
              parameter do
                key :paramType, :path
                key :name, :id
                key :required, true
                key :type, :string
                key :description, 'The FHLB ID to find authorized securities requests for.'
              end
              parameter do
                key :paramType, :query
                key :name, :status
                key :required, true
                key :type, :string
                key :enum, %i(authorized awaiting_authorization)
                key :description, 'Status to filter the requests by.'
              end
              parameter do
                key :paramType, :query
                key :name, :settle_start_date
                key :type, :string
                key :format, :date
                key :description, 'Only return requests with a settlement date >= this date. Defaults to 100 years ago.'
              end
              parameter do
                key :paramType, :query
                key :name, :settle_end_date
                key :type, :string
                key :format, :date
                key :description, 'Only return requests with a settlement date <= this date.'
              end
            end
          end
        end

        # pledged collateral route
        relative_get "/:id/balance/pledged_collateral" do
          MAPI::Services::Member::Balance.pledge_collateral(self, params[:id])
        end

        # total securities route
        relative_get "/:id/balance/total_securities" do
          MAPI::Services::Member::Balance.total_securities(self, params[:id])
        end

        # effective_borrowing_capacity route
        relative_get "/:id/balance/effective_borrowing_capacity" do
          MAPI::Services::Member::Balance.effective_borrowing_capacity(self, params[:id])
        end

        # capital stock balance
        relative_get "/:id/capital_stock_balance/:balance_date" do
          #1.check that input for from and to dates are valid date and expected format
          balance_date = params[:balance_date]
          check_date_format = balance_date.match(MAPI::Shared::Constants::REPORT_PARAM_DATE_FORMAT)
          if !check_date_format
            halt 400, "Invalid Start Date format of yyyy-mm-dd"
          else
            result = MAPI::Services::Member::CapitalStock.capital_stock_balance(self, params[:id], params[:balance_date])
            result
          end
        end

        # capital stock activities
        relative_get "/:id/capital_stock_activities/:from_date/:to_date" do
          member_id = params[:id]
          from_date = params[:from_date]
          to_date = params[:to_date]
          check_date_ok = true
          [from_date, to_date].each do |date|
            check_date_format = date.match(MAPI::Shared::Constants::REPORT_PARAM_DATE_FORMAT)
            if !check_date_format
              check_date_ok = false
            end
          end
          if check_date_ok
            MAPI::Services::Member::CapitalStock.capital_stock_activities(self, params[:id], params[:from_date], params[:to_date])
          else
            halt 400, "Invalid Start Date format of yyyy-mm-dd"
          end
        end

        # borrowing capacity details
        relative_get "/:id/borrowing_capacity_details/:as_of_date" do
          member_id = params[:id]
          as_of_date = params[:as_of_date]

          #1.check that input date if provided to be valid date and expected format.
          if as_of_date.length > 0
            check_date_format = as_of_date.match(MAPI::Shared::Constants::REPORT_PARAM_DATE_FORMAT)
            if !check_date_format
              halt 400, "Invalid Start Date format of yyyy-mm-dd"
            else
              MAPI::Services::Member::BorrowingCapacity.borrowing_capacity_details(self, member_id, as_of_date)
            end
          end
        end

        # STA activities
        relative_get "/:id/sta_activities/:from_date/:to_date" do
          member_id = params[:id]
          from_date = params[:from_date]
          to_date = params[:to_date]
          check_date_ok = true
          [from_date, to_date].each do |date|
            check_date_format = date.match(MAPI::Shared::Constants::REPORT_PARAM_DATE_FORMAT)
            if !check_date_format
              check_date_ok = false
            end
          end
          if check_date_ok
            result = MAPI::Services::Member::SettlementTransactionAccount.sta_activities(self, member_id, from_date, to_date)
            if result == {}
              halt 404, "No Data Found"
            else
              result
            end
          else
            halt 400, "Invalid Start Date format of yyyy-mm-dd"
          end
        end

        # Current STA Rate
        relative_get '/:id/current_sta_rate' do
          member_id = params[:id]
          MAPI::Services::Member::SettlementTransactionAccount.current_sta_rate(self, member_id).to_json
        end

        # Advances Details
        relative_get "/:id/advances_details/:as_of_date" do
          member_id = params[:id]
          as_of_date = params[:as_of_date]

          #1.check that input for from and to dates are valid date and expected format
          check_date_format = as_of_date.match(MAPI::Shared::Constants::REPORT_PARAM_DATE_FORMAT)
          if !check_date_format
            halt 400, "Invalid Date format of yyyy-mm-dd"
          else
            now = Time.zone.now
            today_date = now.to_date
            if as_of_date.to_date >  today_date
              halt 400, "Invalid future date"
            else
              MAPI::Services::Member::AdvancesDetails.advances_details(self, member_id, as_of_date).to_json
            end
          end

        end

        # Active Advances
        relative_get '/:id/active_advances' do
          member_id = params[:id]
          begin
            result = MAPI::Services::Member::TradeActivity.trade_activity(self, member_id, 'ADVANCE')
          rescue Savon::Error => error
            logger.error error
            halt 503, 'Internal Service Error'
          end
          result.to_json
        end

        # Advance Confirmation
        relative_get '/:id/advance_confirmation/:advance_number/:confirmation_number' do
          member_id = params[:id]
          advance_number = params[:advance_number]
          confirmation_number = params[:confirmation_number]
          begin
            advance_confirmation = MAPI::Services::Member::TradeActivity.advance_confirmation(self, member_id, advance_number, confirmation_number)
            file_path = advance_confirmation[:file_location] if advance_confirmation
            if file_path
              stream = File.open(file_path, 'rb')
              file_name = "attachment; filename=\"advance-confirmation-#{confirmation_number}.pdf\""
              MAPI::Services::Member.stream_attachment(env["rack.hijack?"], headers, stream, File.size(file_path), 'application/pdf', file_name)
            else
              halt 404, 'Resource Not Found'
            end
          rescue Exception => error
            logger.error error
            halt 503, 'Internal Service Error'
          end
        end

        # Todays Advances
        relative_get '/:id/todays_advances' do
          member_id = params[:id]
          begin
            result = MAPI::Services::Member::TradeActivity.todays_trade_activity(self, member_id, 'ADVANCE')
          rescue Savon::Error => error
            logger.error error
            halt 503, 'Internal Service Error'
          end
          result.to_json
        end

        # Member Profile
        relative_get '/:id/member_profile' do
          member_id = params[:id]
          profile = MAPI::Services::Member::Profile.member_profile(self, member_id)
          if profile.nil?
            logger.error 'Member not found'
            halt 404
          end
          profile.to_json
        end

        # Member Contacts
        relative_get '/:id/member_contacts' do
          member_id = params[:id]
          MAPI::Services::Member::Profile.member_contacts(self, member_id).to_json
        end

        relative_get '/' do
          MAPI::Services::Member::Profile.member_list(self)
        end

        # Member Disabled Reports
        relative_get '/:id/disabled_reports' do
          member_id = params[:id]
          MAPI::Services::Member::DisabledReports.disabled_report_ids(self, member_id)
        end

        # Member Quick Advance Flag
        relative_get '/:id/quick_advance_flag' do
          member_id = params[:id]
          MAPI::Services::Member::Flags.quick_advance_flag(self, member_id).to_json
        end

        # Member Cash Projections
        relative_get '/:id/cash_projections' do
          member_id = params[:id]
          MAPI::Services::Member::CashProjections.cash_projections(self, member_id).to_json
        end

        # Member Signer Roles
        relative_get '/:id/signers' do
          member_id = params[:id]
          MAPI::Services::Member::SignerRoles.signer_roles(self, member_id).to_json
        end

        # Member Current Securities Position
        relative_get '/:id/current_securities_position/:custody_account_type' do
          member_id = params[:id]
          custody_account_type = MAPI::Services::Member.custody_account_type(self, params[:custody_account_type])
          MAPI::Services::Member::SecuritiesPosition.securities_position(self, member_id, :current, {custody_account_type: custody_account_type}).to_json
        end

        # Member Managed Securities Position
        relative_get '/:id/managed_securities' do
          member_id = params[:id]
          MAPI::Services::Member::SecuritiesPosition.securities_position(self, member_id, :managed).to_json
        end

        # Member Monthly Securities Position
        relative_get '/:id/monthly_securities_position/:month_end_date/:custody_account_type' do
          member_id = params[:id]
          month_end_date = params[:month_end_date]
          custody_account_type = MAPI::Services::Member.custody_account_type(self, params[:custody_account_type])
          if !month_end_date.match(MAPI::Shared::Constants::REPORT_PARAM_DATE_FORMAT)
            halt 400, "Invalid Start Date format of yyyy-mm-dd"
          else
            start_date = Time.zone.parse(month_end_date).beginning_of_month.strftime('%Y-%m-%d')
            end_date = Time.zone.parse(month_end_date).end_of_month.strftime('%Y-%m-%d')
            MAPI::Services::Member::SecuritiesPosition.securities_position(self, member_id, :monthly, {start_date: start_date, end_date: end_date, custody_account_type: custody_account_type}).to_json
          end
        end

        # Member Forward Commitments
        relative_get '/:id/forward_commitments' do
          member_id = params[:id]
          MAPI::Services::Member::ForwardCommitments.forward_commitments(self, member_id).to_json
        end

        # Member Capital Stock Position and Leverage
        relative_get '/:id/capital_stock_and_leverage' do
          member_id = params[:id]
          result = MAPI::Services::Member::CapitalStockAndLeverage.capital_stock_and_leverage(self, member_id)
          if result.nil?
            logger.error 'Capital Stock Requirement Parameters not available. QTL_APP.CAP_STOCK_REQ_PARAM table returning no results'
            halt 503
          else
            result.to_json
          end
        end

        relative_get '/:id/letters_of_credit' do
          member_id = params[:id]
          MAPI::Services::Member::LettersOfCredit.letters_of_credit(self, member_id).to_json
        end

        relative_get '/:id/interest_rate_resets' do
          member_id = params[:id]
          result = MAPI::Services::Member::InterestRateResets.interest_rate_resets(self, member_id)
          if result.nil?
            logger.error 'Interest Rate Resets returning nil.'
            halt 503
          else
            result.to_json
          end
        end

        relative_get '/:id/parallel_shift_analysis' do
          member_id = params[:id]
          MAPI::Services::Member::ParallelShiftAnalysis.parallel_shift(self, member_id).to_json
        end

        relative_get '/:id/' do
          member_id = params[:id]
          details = MAPI::Services::Member::Profile.member_details(self, logger, member_id)
          if details.nil?
            logger.error 'Member not found'
            halt 404
          else
            details.to_json
          end
        end

        relative_get '/:id/dividend_statement/:date/:div_id' do
          member_id = params[:id]
          div_id = params[:div_id]
          date = params[:date].to_date
          MAPI::Services::Member::DividendStatement.dividend_statement(self.settings.environment, member_id, date, div_id).to_json
        end

        relative_get '/:id/securities_transactions/:date' do
          member_id = params[:id].to_i
          date = params[:date].to_date
          begin
            MAPI::Services::Member::SecuritiesTransactions.securities_transactions(self.settings.environment, logger, member_id, date).to_json
          rescue => e
            logger.error e
            halt 503, 'Internal Service Error'
          end
        end

        # Today's Credit Activity
        relative_get '/:id/todays_credit_activity' do
          member_id = params[:id]
          begin
            MAPI::Services::Member::TradeActivity.todays_credit_activity(self.settings.environment, member_id).to_json
          rescue Savon::Error => error
            logger.error error
            halt 503, 'Internal Service Error'
          end
        end
        
        # Mortgage Collateral Update
        relative_get '/:id/mortgage_collateral_update' do
          member_id = params[:id].to_i
          begin
            MAPI::Services::Member::MortgageCollateralUpdate.mortgage_collateral_update(self.settings.environment, logger, member_id).to_json
          rescue Savon::Error => error
            logger.error error
            halt 503, 'Internal Service Error'
          end
        end

        relative_get '/:id/capital_stock_trial_balance/:date' do
          member_id = params[:id].to_i
          date      = params[:date].to_date
          MAPI::Services::Member::CapitalStockTrialBalance.capital_stock_trial_balance(self, member_id, date).to_json
        end

        relative_get '/:id/securities_services_statements_available' do
          env = self.settings.environment
          id  = params[:id].to_i
          MAPI::Services::Member::SecuritiesServicesStatements.available_statements(logger, env, id).to_json
        end

        relative_get '/:id/securities_services_statements/:date' do
          env  = self.settings.environment
          id   = params[:id].to_i
          date = params[:date].to_date
          MAPI::Services::Member::SecuritiesServicesStatements.statement(logger, env, id, date).to_json
        end

        relative_get '/:id/securities/requests' do
          id = params[:id].to_i
          end_date = (params[:settle_end_date] || Time.zone.today).to_date
          start_date = (params[:settle_start_date] || (end_date - 100.years)).to_date
          MAPI::Services::Member::SecuritiesRequests.requests(self, id, MAPI::Services::Member::SecuritiesRequests::REQUEST_STATUS_MAPPING[params[:status]], (start_date..end_date)).to_json
        end
      end

      def self.custody_account_type(app, custody_account_type)
        case custody_account_type
          when 'pledged'
            'P'
          when 'unpledged'
            'U'
          when 'all'
            nil
          else
            app.halt 400, 'Invalid custody_account_type: must be "all", "pledged" or "unpledged"'
         end
      end

      def self.stream_attachment(hijack_available, headers, stream, file_size, content_type, file_name)
        headers['Content-Length'] = file_size.to_s
        headers['Content-Type'] = content_type
        headers['Content-Disposition'] = file_name

        hijack_stream_processer = lambda do |out|
          begin
            while !stream.eof?
              bytes = stream.read(1024)
              out.write(bytes)
              out.flush
            end
          ensure
            stream.close
            out.close
          end
          out
        end

        if hijack_available
          headers["rack.hijack"] = hijack_stream_processer
        else
          out = StringIO.new
          hijack_stream_processer.call(out)
          out.string
        end
      end
      
    end
  end
end