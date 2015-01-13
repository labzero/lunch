module MAPI
  module Services
    module EtransactAdvances
      include MAPI::Services::Base
      include MAPI::Services::Rates
      STATUS_ON_RECORD_NOTFOUND_COUNT = 0

      TERM_BUCKET_MAPPING = {
        :overnight => {
          term_bucket_id: 1,
          term_bucket_label: 'Open and O/N'
        },
        :open => {
          term_bucket_id: 1,
          term_bucket_label: 'Open and O/N'
        },
        :'1week'=> {
          term_bucket_id: 2,
          term_bucket_label: '1 Week'
        },
        :'2week'=> {
          term_bucket_id: 3,
          term_bucket_label: '2 Weeks'
        },
        :'3week'=> {
        term_bucket_id: 4,
        term_bucket_label: '3 Weeks'
        },
        :'1month'=> {
        term_bucket_id: 5,
        term_bucket_label: '1 Month'
        },
        :'2month'=> {
            term_bucket_id: 6,
            term_bucket_label: '2 Months'
        },
        :'3month'=> {
            term_bucket_id: 7,
            term_bucket_label: '3 Months'
        },
        :'6month'=> {
          term_bucket_id: 8,
          term_bucket_label: '4-6 Months'
        },
        :'1year'=> {
            term_bucket_id: 11,
            term_bucket_label: '1 Year'
        },
        :'2year'=> {
            term_bucket_id: 12,
            term_bucket_label: '1 Year'
        },
        :'3year'=> {
            term_bucket_id: 13,
            term_bucket_label: '1 Year'
        }
      }

      TYPE_BUCKET_COLUMN_NO_MAPPING = {
          :whole => {
              colunn_no: 2
          },
          :agency => {
              colunn_no: 3
          },
          :aaa=> {
              colunn_no: 4
          },
          :aa=> {
              colunn_no: 5
          }
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
        end

        # etransact advances status
        relative_get "/status" do
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
            results2 = []
            hash = []
            etransct_all_product_on_cursor = ActiveRecord::Base.connection.execute(etransact_advances_all_product_on_string)
            while row = etransct_all_product_on_cursor.fetch()
              hash = [row[0], row[1], row[2], row[3], row[4], row[5], row[6] , row[7], row[8]]
              results2.push(hash)
            end
          else
            results2 = []
            results = JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'etransact_advances_status.json'))).with_indifferent_access
            etransact_status = results[:etransact_advances_status]
            wl_vrc_status = results[:wl_vrc_status]
            result_jason = JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'etransact_advances_term_buckets_info.json')))
            result_jason.each do |row|
              hash = [row[0], row[1], row[2], row[3], row[4], row[5], row[6] , Date.parse(row[7]), row[8]]
              results2.push(hash)
            end
           end
          # # loop thru to get status for each of the type and term
          loan_status = {}
          LOAN_TERMS.each do |term|
            lookup_term = TERM_BUCKET_MAPPING[term] || 0  #default to 0 if not found
            if lookup_term.to_s != '0' then
              lookup_term_id = TERM_BUCKET_MAPPING[term][:term_bucket_id] || 0
            end
            loan_status[term] ||= {}
            LOAN_TYPES.each do |type|
              trade_status = false
              display_status = false
              bucket_label = 'NotFound'
              results2.each do |row|
                if lookup_term_id == row[0] then
                  bucket_label = row[1].to_s
                  # logic to check if manually turn off regardless of end time
                  # based on Types, will read different column
                  lookup_column = 99 # a dummy number which has no matching column
                 case type.to_s
                  when 'whole'
                    lookup_column = 2
                  when 'agency'
                    lookup_column = 3
                  when 'aaa'
                    lookup_column = 4
                  when 'aa'
                    lookup_column = 5
                 end
                  if row[lookup_column.to_i].to_s == 'Y' then
                    display_status = true
                  else
                    display_status = false
                    trade_status = false
                    break
                  end
                  # logic to check end time
                  # check if there is override for today
                  end_time = row[6].to_s
                  override_date = row[7].to_s
                  override_end_time = row[8]
                  if (Date.parse(override_date) == DateTime.now.to_date) then
                    #check with override_end_time
                    override_end_time += "00"  #add seconds values
                    if (override_end_time >  DateTime.now.strftime("%H%M%S")) then
                      trade_status = true
                    else
                      trade_status = false
                    end
                  else
                   #check with end_time
                    end_time +=  "00"  #add seconds values
                    if (end_time >  DateTime.now.strftime("%H%M%S")) then
                      trade_status = true
                    else
                      trade_status = false
                    end
                  end
                end
               end
              loan_status[term][type] =
                  {'trade_status' => trade_status,
                   'display_status' => display_status,
                  'bucket_label' => bucket_label
                   }
            end
          end
          { etransact_advances_status: etransact_status,
            wl_vrc_status: wl_vrc_status,
            all_loan_status: loan_status
          }.to_json
        end
      end
    end
  end
end