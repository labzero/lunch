require_relative 'member/balance'
require_relative 'member/capital_stock'
require_relative 'member/borrowing_capacity_details'
require_relative 'member/settlement_transaction_account'
require_relative 'member/advances_details'
require_relative 'member/profile'
require_relative 'member/disabled_reports'
require_relative 'member/cash_projections'
require_relative 'member/trade_activity'
require_relative 'member/signer_roles'
require_relative 'member/securities_position'
require_relative 'member/forward_commitments'

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
                key :defaultValue,  Date.today()
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
          result
        end

        # Member Profile
        relative_get '/:id/member_profile' do
          member_id = params[:id]
          MAPI::Services::Member::Profile.member_profile(self, member_id)
        end

        relative_get '/' do
          MAPI::Services::Member::Profile.member_list(self)
        end

        # Member Disabled Reports
        relative_get '/:id/disabled_reports' do
          member_id = params[:id]
          MAPI::Services::Member::DisabledReports.disabled_report_ids(self, member_id)
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
    end
  end
end