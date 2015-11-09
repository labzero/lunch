module MAPI
  module Services
    module Fees
      include MAPI::Services::Base
      include MAPI::Shared::Utils
      
      SECURITIES_SERVICES_FEE_MAPPING = {
        federal_securities:          1,
        depository_securities:       2,
        physical_securities:         3,
        euroclear_securities:        4,
        physical_foreign_securities: 5,
        all_income_disbursements:    6,
        pledge_status_change:        7,
        certificate_registration:    8,
        research_projects:           9,
        special_handling:           10,
        maintenance_fee_1_to_9:     11,
        maintenance_fee_10_to_24:   12,
        maintenance_fee_25_or_more: 13
      }.freeze
      
      SECURITIES_SERVICES_FEE_SQL = <<-SQL
        SELECT BF_ROW_ID, FEE_PER_TRANS, FEE_PER_LOT, FEE_PER_PAR, PER_PAR_AMOUNT, MAINT_FEE, HOURLY_RATE, BILLING_DESCRIPTION
        FROM SAFEKEEPING.BILL_FEES
      SQL

      def self.registered(app)
        service_root '/fees', app
        swagger_api_root :fees do
        # fee schedules endpoint
        api do
          key :path, '/schedules'
          operation do
            key :method, 'GET'
            key :summary, 'Retrieve the schedule of fees charged by FHLB to member banks'
            key :notes, 'The fees charged are not specific to particular member banks'
            key :type, :feeSchedules
            key :nickname, :getFeeSchedules
            response_message do
              key :code, 200
              key :message, 'OK'
            end
          end
        end
        end

        relative_get "/schedules" do
          begin
            MAPI::Services::Fees.fee_schedules(self.settings.environment, logger).to_json
          rescue Savon::Error => error
            logger.error error
            halt 503, 'Internal Service Error'
          end
        end
      end
      
      def self.fee_schedules(env, logger)
        if env == :production 
          securities_services_fees = fetch_hashes(logger, SECURITIES_SERVICES_FEE_SQL)
        else
          securities_services_fees = fake('securities_services_fees')
        end
        
        other_fee_data = YAML.load(File.read(File.join(MAPI.root, 'config', 'fees.yml'))).with_indifferent_access
        {
          securities_services: Private.process_securities_services_fees(securities_services_fees),
          wire_transfer_and_sta: other_fee_data[:wire_transfer_and_sta],
          letters_of_credit: other_fee_data[:letters_of_credit]
        }
      end
      
      module Private
        def self.process_securities_services_fees(fees)
          {
            monthly_maintenance: {
              less_than_10: self.find_row(fees, :maintenance_fee_1_to_9)['MAINT_FEE'].try(:to_f), 
              between_10_and_24: self.find_row(fees, :maintenance_fee_10_to_24)['MAINT_FEE'].try(:to_f), 
              more_than_24: self.find_row(fees, :maintenance_fee_25_or_more)['MAINT_FEE'].try(:to_f)
            },
            monthly_securities: {
              fed: self.find_row(fees, :federal_securities)['FEE_PER_LOT'].try(:to_f),
              dtc: self.find_row(fees, :depository_securities)['FEE_PER_LOT'].try(:to_f),
              physical: self.find_row(fees, :physical_securities)['FEE_PER_LOT'].try(:to_f),
              euroclear: {
                fee_per_par: self.find_row(fees, :euroclear_securities)['FEE_PER_PAR'].try(:to_f),
                per_par_amount: self.find_row(fees, :euroclear_securities)['PER_PAR_AMOUNT'].try(:to_i)
              }
            },
            security_transaction: {
              fed: self.find_row(fees, :federal_securities)['FEE_PER_TRANS'].try(:to_f),
              dtc: self.find_row(fees, :depository_securities)['FEE_PER_TRANS'].try(:to_f),
              physical: self.find_row(fees, :physical_securities)['FEE_PER_TRANS'].try(:to_f),
              euroclear: self.find_row(fees, :euroclear_securities)['FEE_PER_TRANS'].try(:to_f)
            },
            miscellaneous: {
              all_income_disbursement: self.find_row(fees, :all_income_disbursements)['FEE_PER_TRANS'].try(:to_f),
              pledge_status_change: self.find_row(fees, :pledge_status_change)['FEE_PER_TRANS'].try(:to_f),
              certificate_registration: self.find_row(fees, :certificate_registration)['FEE_PER_TRANS'].try(:to_f),
              research_projects: self.find_row(fees, :research_projects)['HOURLY_RATE'].try(:to_f),
              special_handling: self.find_row(fees, :special_handling)['FEE_PER_TRANS'].try(:to_f)
            }
          } 
        end
        
        def self.find_row(rows, key) 
          raise 'Invalid mapping' unless SECURITIES_SERVICES_FEE_MAPPING.keys.include?(key)
          rows.select{|x| x['BF_ROW_ID'] == SECURITIES_SERVICES_FEE_MAPPING[key]}.first || {}
        end
      end      
    end
  end
end