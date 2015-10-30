module MAPI
  module Services
    module Member
      module MortgageCollateralUpdate
        include MAPI::Shared::Utils
        STRING_FIELDS = %w(mcu_type transaction_number pledge_type).freeze
        INTEGER_FIELDS = %w(pledged_count updated_count depledged_count renumbered_count rejected_count accepted_count 
                            pledged_unpaid updated_unpaid depledged_unpaid rejected_unpaid renumbered_unpaid accepted_unpaid 
                            total_count total_unpaid total_original pledged_original updated_original depledged_original 
                            rejected_original renumbered_original accepted_original).freeze
        
        def self.mortgage_collateral_update(env, member_id)
          mcu_data = if env == :production
            mcu_query = <<-SQL
              SELECT 
                FHLB_ID,
                NVL(MCU_PROCESSING_TYPE, '-') MCU_PROCESSING_TYPE,
                NVL(MCU_PROCESSING_TYPE_DESC, 'Undefined') mcu_type,
                TRANS_NUM as transaction_number, 
                NVL(PLEDGE_TYPE_ID, '-') pledge_type,
                SYS_TOTAL_DEPOSIT as pledged_count, 
                SYS_TOTAL_UPDATE as updated_count,
                SYS_TOTAL_WITHDRAWN as depledged_count,
                SYS_TOTAL_RENUMBER as renumbered_count,
                SYS_TOTAL_ERRORS as rejected_count,
                SYS_TOTAL_DEPOSIT + SYS_TOTAL_UPDATE + SYS_TOTAL_RENUMBER accepted_count,
                SYS_TOTAL_LOANS as total_count,
                SYS_UPB_DEPOSIT as pledged_unpaid,
                SYS_UPB_UPDATE as updated_unpaid,
                SYS_UPB_DEPLEDGE as depledged_unpaid,
                SYS_UPB_REJECTS as rejected_unpaid,
                SYS_UPB_RENUMBER as renumbered_unpaid,
                SYS_UPB_DEPOSIT + SYS_UPB_UPDATE + SYS_UPB_RENUMBER accepted_unpaid,
                SYS_UPB as total_unpaid,
                RECONCILE_UPB,
                RECONCILE_TOTAL_LOANS,
                ACTUAL_START_DATE as date_processed,
                SYS_APPRAISED_DEPOSIT as total_original,
                SYS_ORIG_AMOUNT_DEPOSIT as pledged_original,
                SYS_ORIG_AMOUNT_UPDATE as updated_original,
                SYS_ORIG_AMOUNT_DEPLEDGE as depledged_original,
                SYS_ORIG_AMOUNT_REJECTS as rejected_original,
                SYS_ORIG_AMOUNT_RENUMBER as renumbered_original,
                SYS_ORIG_AMOUNT_DEPOSIT +  SYS_ORIG_AMOUNT_UPDATE + SYS_ORIG_AMOUNT_RENUMBER accepted_original
              FROM FHLBOWN.MCU_PROCESSED_RPT_WEB@colaprod_link MCU
              WHERE FHLB_ID = #{ActiveRecord::Base.connection.quote(member_id)}
            SQL
            ActiveRecord::Base.connection.execute(mcu_query).try(:fetch_hash) || {}
          else
            self.fake_hash('mortgage_collateral_update')
          end    
          
          if mcu_data
            processed_data = {
              date_processed: mcu_data['DATE_PROCESSED']
            }
            STRING_FIELDS.each do |field|
              processed_data[field.to_sym] = (mcu_data[field.upcase].to_s if mcu_data[field.upcase])
            end
            INTEGER_FIELDS.each do |field|
              processed_data[field.to_sym] = (mcu_data[field.upcase].round if mcu_data[field.upcase])
            end
            processed_data.with_indifferent_access
          end          
        end
      end
    end
  end
end


