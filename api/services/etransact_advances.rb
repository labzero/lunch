require_relative 'etransact_advances/execute_trade'

module MAPI
  module Services
    module EtransactAdvances
      include MAPI::Services::Base

      STATUS_ON_RECORD_NOTFOUND_COUNT = 0

      TERM_BUCKET_MAPPING = {
        :overnight => 1,
        :open => 1,
        :'1week'=> 2,
        :'2week'=> 3,
        :'3week'=> 4,
        :'1month'=> 5,
        :'2month'=> 6,
        :'3month'=> 7,
        :'6month'=> 8,
        :'1year'=> 11,
        :'2year'=> 12,
        :'3year'=> 13,
      }

      TYPE_BUCKET_COLUMN_NO_MAPPING = {
        :whole => 'WHOLE_LOAN_ENABLED',
        :agency => 'SBC_AGENCY_ENABLED',
        :aaa => 'SBC_AAA_ENABLED',
        :aa => 'SBC_AA_ENABLED'
      }

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
            key :path, '/execute_advance/{id}/{amount}/{advance_type}/{advance_term}/{rate}/{signer}'
            operation do
              key :method, 'POST'
              key :summary, 'Execute new Advance in Calypso.'
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
                key :name, :signer
                key :required, true
                key :type, :string
                key :description, 'Authorized signer.'
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
            key :path, '/{validate_advance/{id}/{amount}/{advance_type}/{advance_term}/{rate}/{signer}'
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
                key :name, :signer
                key :required, true
                key :type, :string
                key :description, 'Authorized signer.'
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

          etransact_advances_all_product_on_string = <<-SQL
            SELECT AO_TERM_BUCKET_ID, TERM_BUCKET_LABEL,
            WHOLE_LOAN_ENABLED, SBC_AGENCY_ENABLED, SBC_AAA_ENABLED, SBC_AA_ENABLED,
            END_TIME, trunc(OVERRIDE_END_DATE) AS OVERRIDE_END_DATE, OVERRIDE_END_TIME
            FROM WEB_ADM.AO_TERM_BUCKETS
          SQL

          if settings.environment == :production
            etransact_status = false  #indicat if etransact is turn on and at least one product has not reach End Time
            wl_vrc_status = false   #indicate if WL VRC is enabled regardless of if etransact is turn on
            etransact_eod_status_on_cursor = ActiveRecord::Base.connection.execute(etransact_advances_eod_on_string)
            while row = etransact_eod_status_on_cursor.fetch()
              if row[0].to_i > STATUS_ON_RECORD_NOTFOUND_COUNT
                etransact_status = true
                break
              end
            end
            if etransact_status
              etransact_status_on_cursor = ActiveRecord::Base.connection.execute(etransact_advances_turn_on_string)
              while row = etransact_status_on_cursor.fetch()
                if row[0].to_i == STATUS_ON_RECORD_NOTFOUND_COUNT
                  etransact_status = false
                  break
                end
              end
            end
            etransact_wl_status_on_cursor = ActiveRecord::Base.connection.execute(etransact_advances_WLVRC_on_string)
            while row = etransact_wl_status_on_cursor.fetch()
              if row[0].to_i > STATUS_ON_RECORD_NOTFOUND_COUNT
                wl_vrc_status = true
                break
              end
            end
            term_bucket_data_array = []
            etransct_all_product_on_cursor = ActiveRecord::Base.connection.execute(etransact_advances_all_product_on_string)

            while row = etransct_all_product_on_cursor.fetch_hash()
              term_bucket_data_array.push(row)
            end
          else
            term_bucket_data_array = []
            results = JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'etransact_advances_status.json'))).with_indifferent_access
            etransact_status = results[:etransact_advances_status]
            wl_vrc_status = results[:wl_vrc_status]
            term_bucket_data_array = JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'etransact_advances_term_buckets_info.json')))
          end
          # # loop thru to get status for each of the type and term
          loan_status = {}
          now = Time.zone.now
          now_string = now.strftime("%H%M%S")
          today_date = now.to_date

          MAPI::Shared::Constants::LOAN_TERMS.each do |term|
            lookup_term_id = TERM_BUCKET_MAPPING[term]
            loan_status[term] ||= {}
            MAPI::Shared::Constants::LOAN_TYPES.each do |type|
              trade_status = false
              display_status = false
              bucket_label = 'NotFound'
              term_bucket_data_array.each do |row|
                if lookup_term_id == row['AO_TERM_BUCKET_ID'].to_i
                  bucket_label = row['TERM_BUCKET_LABEL']
                  # logic to check if manually turn off regardless of end time
                  # based on Types, will read different column
                  lookup_column = TYPE_BUCKET_COLUMN_NO_MAPPING[type]
                  if row[lookup_column] == 'Y'
                    display_status = true
                  else
                    break
                  end
                  # logic to check end time
                  # check if there is override for today
                  end_time = row['END_TIME'] + '00'
                  override_date = row['OVERRIDE_END_DATE']
                  override_end_time = row['OVERRIDE_END_TIME'] + '00'
                  if (override_date.to_date == today_date)
                    # check with override_end_time
                    if (override_end_time > now_string)
                      trade_status = true
                    end
                  elsif (end_time > now_string)
                    trade_status = true
                  end
                end
              end
              loan_status[term][type] = {
                'trade_status' => trade_status,
                'display_status' => display_status,
                'bucket_label' => bucket_label.to_s
              }
            end

          end
          {
            etransact_advances_status: etransact_status,
            wl_vrc_status: wl_vrc_status,
            all_loan_status: loan_status
          }.to_json
        end

        # Signer Full Name
        relative_get '/signer_full_name/:signer' do
          signer = params[:signer]
          MAPI::Services::EtransactAdvances::ExecuteTrade::get_signer_full_name(self.settings.environment, signer)
        end

        # Execute Advance
        relative_post '/execute_advance/:id/:amount/:advance_type/:advance_term/:rate/:signer' do
          member_id = params[:id]
          amount = params[:amount]
          advance_type = params[:advance_type]
          advance_term = params[:advance_term]
          rate = params[:rate]
          signer = params[:signer]
          markup = 0
          blendedcostoffunds = 0
          costoffunds = 0
          benchmarkrate = 0
          begin
            result = MAPI::Services::EtransactAdvances::ExecuteTrade.execute_trade(self, member_id, 'ADVANCE', 'EXECUTE', amount, advance_term, advance_type, rate, signer, markup, blendedcostoffunds, costoffunds, benchmarkrate)
          rescue Savon::Error => error
            logger.error error
            halt 503, 'Internal Service Error'
          end
          result
        end

        # Validate Advance
        relative_get '/validate_advance/:id/:amount/:advance_type/:advance_term/:rate/:signer' do
          member_id = params[:id]
          amount = params[:amount]
          advance_type = params[:advance_type]
          advance_term = params[:advance_term]
          rate = params[:rate]
          signer = params[:signer]
          markup = 0
          blendedcostoffunds = 0
          costoffunds = 0
          benchmarkrate = 0
          begin
            result = MAPI::Services::EtransactAdvances::ExecuteTrade.execute_trade(self, member_id, 'ADVANCE', 'VALIDATE', amount, advance_term, advance_type, rate, signer, markup, blendedcostoffunds, costoffunds, benchmarkrate)
          rescue Savon::Error => error
            logger.error error
            halt 503, 'Internal Service Error'
          end
          result
        end
      end
    end
  end
end