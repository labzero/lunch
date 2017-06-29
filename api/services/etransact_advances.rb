require_relative 'etransact_advances/execute_trade'
require_relative 'rates/loan_terms'
require_relative 'rates/market_data_rates'
require_relative 'etransact_advances/settings'
require_relative 'etransact_advances/limits'
require_relative 'etransact_advances/shutoff_times'

module MAPI
  module Services
    module EtransactAdvances
      include MAPI::Services::Base
      include MAPI::Shared::Utils

      STATUS_ON_RECORD_NOTFOUND_COUNT = 0

      TYPE_BUCKET_COLUMN_NO_MAPPING = {
        :whole => 'WHOLE_LOAN_ENABLED',
        :agency => 'SBC_AGENCY_ENABLED',
        :aaa => 'SBC_AAA_ENABLED',
        :aa => 'SBC_AA_ENABLED'
      }

      MARKUP_MAPPING = {
          whole: 'MU_WL',
          agency: 'MU_AGCY',
          aaa: 'MU_AA',
          aa: 'MU_AAA'
      }.with_indifferent_access

      def self.registered(app)

        service_root '/etransact_advances', app
        swagger_api_root :etransact_advances do

          # etransact advances status endpoint
          api do
            key :path, '/status'
            operation do
              key :method, 'GET'
              key :summary, 'Retrieve status of etransact Advances today'
              key :notes, 'Return status if etransact is turn on for the day and if all products reached it end time for the day'
              key :type, :etransactAdvancesStatus
              key :nickname, :getEtransactAdvancesStatus
              response_message do
                key :code, 200
                key :message, 'OK'
              end
            end
          end
          
          api do
            key :path, '/blackout_dates'
            operation do
              key :method, 'GET'
              key :summary, 'Retrieve list of blackout dates'
              key :notes, 'Returns list of blackout dates (or [] if none exist)'
              key :type, :array
              items do
                key :type, :string
              end
              key :nickname, :getBlackoutDates
            end
          end

          api do
            key :path, '/settings'
            operation do
              key :method, 'GET'
              key :summary, 'Retrieve the settings for eTransact'
              key :notes, 'Returns the all settings currently defined for the eTransact, as defined by the eTransact Web Admin'
              key :type, :EtransactSettings
              key :nickname, :getEtransactSettings
              response_message do
                key :code, 200
                key :message, 'OK'
              end
            end
          end
          api do
            key :path, '/settings'
            operation do
              key :method, 'PUT'
              key :summary, 'Update the settings for eTransact'
              key :nickname, :updateEtransactSettings
              key :consumes, ['application/json']
              parameter do
                key :paramType, :body
                key :name, :body
                key :required, true
                key :type, :EtransactSettings
                key :description, "The hash of etransact setting names and setting values to update."
              end
            end
          end
          api do
            key :path, '/enable_service'
            operation do
              key :method, 'PUT'
              key :summary, 'Enables the eTransact service'
              key :note, "Enables service by setting the 'StartUp' value in the settings table to today's date"
              key :nickname, :enableEtransactService
            end
          end
          api do
            key :path, '/disable_service'
            operation do
              key :method, 'PUT'
              key :summary, 'Disables the eTransact service'
              key :note, "Disables service by setting the 'StartUp' value in the settings table to null"
              key :nickname, :disableEtransactService
            end
          end
          # etransact advances limits endpoint
          api do
            key :path, '/limits'
            operation do
              key :method, 'GET'
              key :summary, 'Retrieve limits of etransact Advances today'
              key :nickname, :getEtransactAdvancesLimits
              key :type, :array
              items do
                key :'$ref', :EtransactLimitsArray
              end
            end
          end
          api do
            key :path, '/limits'
            operation do
              key :method, 'PUT'
              key :summary, 'Update limits of etransact Advances today'
              key :nickname, :updateEtransactAdvancesLimits
              key :consumes, ['application/json']
              parameter do
                key :paramType, :body
                key :name, :body
                key :required, true
                key :type, :EtransactLimitsHash
                key :description, "The hash of etransact term limits and associated values."
              end
            end
          end
          api do
            key :path, '/signer_full_name/{signer}'
            operation do
              key :method, 'GET'
              key :summary, 'Gets Signer Full Name.'
              key :notes, 'Returns the full name of the authorized signer.'
              key :type, :string
              key :nickname, :SignerFullName
              parameter do
                key :paramType, :path
                key :name, :signer
                key :required, true
                key :type, :string
                key :description, 'Authorized signer.'
              end
            end
          end
          api do
            key :path, '/execute_advance/{id}'
            operation do
              key :method, 'POST'
              key :summary, 'Execute new Advance in Calypso.'
              key :notes, 'Returns the result of execute trade.'
              key :type, :ExecuteAdvance
              key :nickname, :ExecuteAdvance
              key :consumes, ['application/json']
              parameter do
                key :paramType, :path
                key :name, :id
                key :required, true
                key :type, :string
                key :description, 'The id to find the members from.'
              end
              parameter do
                key :paramType, :body
                key :name, :body
                key :required, true
                key :type, :MemberQuickAdvanceRequest
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
            key :path, '/validate_advance/{id}/{amount}/{advance_type}/{advance_term}/{rate}/{check_capstock}/{signer}/{maturity_date}'
            operation do
              key :method, 'GET'
              key :summary, 'Validates new Advance in Calypso.'
              key :notes, 'Returns the result of execute trade.'
              key :type, :ExecuteAdvance
              key :nickname, :ExecuteAdvance
              parameter do
                key :paramType, :path
                key :name, :id
                key :required, true
                key :type, :string
                key :description, 'The id to find the members from.'
              end
              parameter do
                key :paramType, :path
                key :name, :amount
                key :required, true
                key :type, :Numeric
                key :description, 'Amount to execute.'
              end
              parameter do
                key :paramType, :path
                key :name, :advance_type
                key :required, true
                key :type, :string
                key :description, 'Collateral type.'
              end
              parameter do
                key :paramType, :path
                key :name, :advance_term
                key :required, true
                key :type, :string
                key :description, 'Term of the advance.'
              end
              parameter do
                key :paramType, :path
                key :name, :rate
                key :required, true
                key :type, :Numeric
                key :description, 'Advance rate.'
              end
              parameter do
                key :paramType, :path
                key :name, :check_capstock
                key :required, true
                key :type, :Boolean
                key :description, 'Check Capital Stock.'
              end
              parameter do
                key :paramType, :path
                key :name, :signer
                key :required, true
                key :type, :string
                key :description, 'Authorized signer.'
              end
              parameter do
                key :paramType, :path
                key :name, :maturity_date
                key :required, true
                key :type, :string
                key :description, 'Maturity date.'
              end
              parameter do
                key :paramType, :path
                key :name, :funding_date
                key :required, false
                key :type, :string
                key :description, 'Funding date.'
              end
              parameter do
                key :paramType, :query
                key :name, :allow_grace_period
                key :required, false
                key :type, :Boolean
                key :description, 'Should the EOD grace period be allowed for this request.'
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
            key :path, '/shutoff_times_by_type'
            operation do
              key :method, 'GET'
              key :summary, 'Fetches the general shutoff times for VRC and FRC advances'
              key :type, :ShutoffTimesByType
              key :nickname, :FetchShutoffTimesByType
            end
          end
          api do
            key :path, '/shutoff_times_by_type'
            operation do
              key :method, 'PUT'
              key :summary, 'Edits the general shutoff times for VRC and FRC advances'
              key :nickname, :EditShutoffTimesByType
              parameter do
                key :paramType, :body
                key :name, :body
                key :required, true
                key :type, :ShutoffTimesByType
                key :description, 'The hash containing the frc and vrc shutoff times.'
              end
            end
          end
          api do
            key :path, '/early_shutoffs'
            operation do
              key :method, 'GET'
              key :summary, 'Fetches all scheduled early shutoffs for advances'
              key :nickname, :FetchEarlyShutoffs
              key :type, :array
              items do
                key :'$ref', :EarlyShutoff
              end
            end
          end
          api do
            key :path, '/early_shutoff'
            operation do
              key :method, 'POST'
              key :summary, 'Schedule a new early shutoff for a given date'
              key :nickname, :NewEarlyShutoff
              key :consumes, ['application/json']
              parameter do
                key :paramType, :body
                key :name, :body
                key :required, true
                key :type, :EarlyShutoff
                key :description, 'The hash containing all relevant data for the early shutoff to be scheduled.'
              end
            end
          end
          api do
            key :path, '/early_shutoff'
            operation do
              key :method, 'PUT'
              key :summary, 'Update a new early shutoff for a given date'
              key :nickname, :UpdateEarlyShutoff
              key :consumes, ['application/json']
              parameter do
                key :paramType, :body
                key :name, :body
                key :required, true
                key :type, :EarlyShutoff
                key :description, 'The hash containing all relevant data for the early shutoff to be updated.'
              end
            end
          end
          api do
            key :path, '/early_shutoff/{shutoff_date}'
            operation do
              key :method, 'DELETE'
              key :summary, 'Delete an early shutoff for a given date'
              key :nickname, :RemoveEarlyShutoff
              parameter do
                key :paramType, :path
                key :name, :shutoff_date
                key :required, true
                key :type, :string
                key :description, 'The iso8601-formatted shutoff date to be deleted.'
                key :notes, 'Format is YYYY-MM-DD'
              end
            end
          end
        end

        # etransact advances limits
        relative_get '/limits' do
          MAPI::Services::EtransactAdvances.rescued_json_response(self) do
            MAPI::Services::EtransactAdvances::Limits.get_limits(self)
          end
        end

        relative_put '/limits' do
          MAPI::Services::EtransactAdvances.rescued_json_response(self) do
            limits_hash = JSON.parse(request.body.read)
            {} if MAPI::Services::EtransactAdvances::Limits.update_limits(self, limits_hash)
          end
        end
        
        relative_get '/blackout_dates' do
          MAPI::Services::Rates::BlackoutDates::blackout_dates(logger, settings.environment).to_json
        end

        relative_get '/settings' do
          MAPI::Services::EtransactAdvances.rescued_json_response(self) do
            MAPI::Services::EtransactAdvances::Settings.settings(settings.environment)
          end
        end

        relative_put '/settings' do
          MAPI::Services::EtransactAdvances.rescued_json_response(self) do
            settings_hash = JSON.parse(request.body.read)
            {} if MAPI::Services::EtransactAdvances::Settings.update_settings(self, settings_hash)
          end
        end

        relative_put '/settings/enable_service' do
          MAPI::Services::EtransactAdvances.rescued_json_response(self) do
            {} if MAPI::Services::EtransactAdvances::Settings.enable_service(self)
          end
        end

        relative_put '/settings/disable_service' do
          MAPI::Services::EtransactAdvances.rescued_json_response(self) do
            {} if MAPI::Services::EtransactAdvances::Settings.disable_service(self)
          end
        end

        # etransact advances status
        relative_get '/status' do
          etransact_advances_turn_on_string = <<-SQL
            SELECT count(*) as status_on_count
            FROM WEB_ADM.AO_SETTINGS
            WHERE SETTING_NAME = 'StartUp'
            AND trunc(to_date(SETTING_VALUE, 'MM/dd/yyyy')) = trunc(sysdate)
          SQL

          etransact_advances_eod_on_string = <<-SQL
            SELECT count(*)
            FROM WEB_ADM.AO_TERM_BUCKETS
            WHERE (END_TIME || '00' > to_char(sysdate, 'HH24MISS')) OR
            ((trunc(OVERRIDE_END_DATE) = trunc(sysdate))
            AND (OVERRIDE_END_TIME || '00' > TO_CHAR(SYSDATE, 'HH24MISS')))
          SQL

          etransact_advances_WLVRC_on_string = <<-SQL
            SELECT count(*) AS WL_VRC_status
            FROM WEB_ADM.AO_TERM_BUCKETS
            WHERE WHOLE_LOAN_ENABLED = 'Y' AND AO_TERM_BUCKET_ID = 1
          SQL

          etransact_status = false  #indicate if etransact is turn on and at least one product has not reach End Time
          wl_vrc_status = false   #indicate if WL VRC is enabled regardless of if etransact is turn on
          etransact_eod = false # indicates that we have reached EOD on the global eTransact flag
          etransact_disabled = false # indiciates that eTransact has been globally disabled
          etransact_no_rows_found = true

          if settings.environment == :production
            etransact_eod_status_on_cursor = ActiveRecord::Base.connection.execute(etransact_advances_eod_on_string)
            row = etransact_eod_status_on_cursor.fetch()
            if row
              etransact_no_rows_found = false 
              etransact_eod = true if row[0].to_i == STATUS_ON_RECORD_NOTFOUND_COUNT
            end

            etransact_status_on_cursor = ActiveRecord::Base.connection.execute(etransact_advances_turn_on_string)
            row = etransact_status_on_cursor.fetch()
            if row
              etransact_no_rows_found = false
              etransact_disabled = true if row[0].to_i == STATUS_ON_RECORD_NOTFOUND_COUNT
            end

            etransact_wl_status_on_cursor = ActiveRecord::Base.connection.execute(etransact_advances_WLVRC_on_string)
            row = etransact_wl_status_on_cursor.fetch()
            if row && row[0].to_i > STATUS_ON_RECORD_NOTFOUND_COUNT
              wl_vrc_status = true
            end
          else
            results = JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'etransact_advances_status.json'))).with_indifferent_access
            wl_vrc_status = results[:wl_vrc_status]
            etransact_eod = results[:eod_reached]
            etransact_disabled = results[:disabled]
            etransact_no_rows_found = false
          end

          etransact_status = !(etransact_no_rows_found || etransact_eod || etransact_disabled)

          {
            eod_reached: false,
            enabled: !etransact_disabled,
            etransact_advances_status: etransact_status,
            wl_vrc_status: wl_vrc_status,
            all_loan_status: MAPI::Services::Rates::LoanTerms.loan_terms(logger,settings.environment)
          }.to_json
        end

        # Signer Full Name
        relative_get '/signer_full_name/:signer' do
          signer = params[:signer]
          MAPI::Services::EtransactAdvances::ExecuteTrade::get_signer_full_name(self.settings.environment, signer)
        end

        # Execute Advance
        relative_post '/execute_advance/:id' do
          member_id = params[:id]
          body = JSON.parse(request.body.read).with_indifferent_access
          amount = body[:amount]
          advance_type = body[:advance_type]
          advance_term = body[:advance_term]
          check_capstock = false;
          rate = body[:rate]
          signer = body[:signer]
          maturity_date = body[:maturity_date].to_date
          allow_grace_period = body[:allow_grace_period] || false
          funding_date = body[:funding_date].try(:to_date)

          begin
            cof_data = MAPI::Services::EtransactAdvances.cof_data_cleanup(MAPI::Services::Rates::MarketDataRates.get_market_cof_rates(self.settings.environment, advance_term, advance_type, funding_date, maturity_date), advance_type)
          rescue Savon::Error => error
            logger.error error
            halt 503, 'Internal Service Error'
          end

          begin
            result = MAPI::Services::EtransactAdvances::ExecuteTrade.execute_trade(self, member_id, 'ADVANCE', 'EXECUTE', amount, advance_term, advance_type, rate, check_capstock, signer, cof_data[:markup], cof_data[:blended_cost_of_funds], cof_data[:cost_of_funds], cof_data[:benchmark_rate], maturity_date, allow_grace_period, funding_date)
          rescue Savon::Error => error
            logger.error error
            halt 503, 'Internal Service Error'
          end
          result.to_json
        end

        # Validate Advance
        relative_get '/validate_advance/:id/:amount/:advance_type/:advance_term/:rate/:check_capstock/:signer/:maturity_date' do
          member_id = params[:id]
          amount = params[:amount]
          advance_type = params[:advance_type]
          advance_term = params[:advance_term]
          rate = params[:rate]
          signer = params[:signer]
          maturity_date = params[:maturity_date].to_date
          check_capstock = params[:check_capstock] == 'true'
          allow_grace_period = params[:allow_grace_period] == 'true'
          funding_date = params[:funding_date].try(:to_date)

          begin
            cof_data = MAPI::Services::EtransactAdvances.cof_data_cleanup(MAPI::Services::Rates::MarketDataRates.get_market_cof_rates(self.settings.environment, advance_term, advance_type, funding_date, maturity_date), advance_type)
          rescue Savon::Error => error
            logger.error error
            halt 503, 'Internal Service Error'
          end

          begin
            result = MAPI::Services::EtransactAdvances::ExecuteTrade.execute_trade(self, member_id, 'ADVANCE', 'VALIDATE', amount, advance_term, advance_type, rate, check_capstock, signer, cof_data[:markup], cof_data[:blended_cost_of_funds], cof_data[:cost_of_funds], cof_data[:benchmark_rate], maturity_date, allow_grace_period, funding_date)
          rescue Savon::Error => error
            logger.error error
            halt 503, 'Internal Service Error'
          end
          result.to_json
        end

        relative_get '/shutoff_times_by_type' do
          MAPI::Services::EtransactAdvances.rescued_json_response(self) do
            MAPI::Services::EtransactAdvances::ShutoffTimes.get_shutoff_times_by_type(self)
          end
        end

        relative_put '/shutoff_times_by_type' do
          MAPI::Services::EtransactAdvances.rescued_json_response(self) do
            shutoff_times = JSON.parse(request.body.read)
            {} if MAPI::Services::EtransactAdvances::ShutoffTimes.edit_shutoff_times_by_type(self, shutoff_times)
          end
        end

        relative_get '/early_shutoffs' do
          MAPI::Services::EtransactAdvances.rescued_json_response(self) do
            MAPI::Services::EtransactAdvances::ShutoffTimes.get_early_shutoffs(self)
          end
        end

        relative_post '/early_shutoff' do
          MAPI::Services::EtransactAdvances.rescued_json_response(self) do
            early_shutoff = JSON.parse(request.body.read)
            {} if MAPI::Services::EtransactAdvances::ShutoffTimes.schedule_early_shutoff(self, early_shutoff)
          end
        end

        relative_put '/early_shutoff' do
          MAPI::Services::EtransactAdvances.rescued_json_response(self) do
            early_shutoff = JSON.parse(request.body.read)
            {} if MAPI::Services::EtransactAdvances::ShutoffTimes.update_early_shutoff(self, early_shutoff)
          end
        end

        relative_delete '/early_shutoff/:shutoff_date' do
          MAPI::Services::EtransactAdvances.rescued_json_response(self) do
            {} if MAPI::Services::EtransactAdvances::ShutoffTimes.remove_early_shutoff(self, params[:shutoff_date])
          end
        end
      end

      def self.cof_data_cleanup(cof_data, advance_type)
        {
          markup: cof_data[MARKUP_MAPPING[advance_type]].to_f / 10000,
          blended_cost_of_funds: cof_data['COF_3L'].to_f / 10000,
          cost_of_funds: cof_data['COF_FIXED'].to_f / 100,
          benchmark_rate: cof_data['ADVANCE_BENCHMARK'].to_f / 100
        }
      end

    end
  end
end