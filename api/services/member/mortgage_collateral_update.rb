require 'net/sftp'

module MAPI
  module Services
    module Member
      module MortgageCollateralUpdate
        include MAPI::Shared::EnterpriseMessaging
        include MAPI::Shared::Utils
        STRING_FIELDS  = %w(mcu_type pledge_type transaction_number).freeze
        INTEGER_FIELDS = %w(accepted_count    depledged_count    pledged_count    rejected_count    renumbered_count    total_count    updated_count).freeze
        FLOAT_FIELDS   = %w(accepted_unpaid   depledged_unpaid   pledged_unpaid   rejected_unpaid   renumbered_unpaid   total_unpaid   updated_unpaid
                            accepted_original depledged_original pledged_original rejected_original renumbered_original total_original updated_original).freeze
        
        def self.mortgage_collateral_update(env, logger, member_id)
          mcu_data = if env == :production
            self.fetch_hash(logger, Private.mcu_sql(member_id))
          else
            self.fake_hash('mortgage_collateral_update')
          end

          processed_data = mcu_data.empty? ? {} : { date_processed: dateify(mcu_data['DATE_PROCESSED']) }
          [[STRING_FIELDS, :to_s], [INTEGER_FIELDS, :to_i], [FLOAT_FIELDS, :to_f]].each do |fields, op|
            fields.each{ |field| processed_data[field] = (mcu_data[field.upcase].try(op) if mcu_data[field.upcase]) }
          end unless mcu_data.empty?
          processed_data.with_indifferent_access
        end

        def self.mcu_upload_file(app, member_id, transaction_id, file_type, pledge_type, local_path, original_filename, username)
          unless should_fake?(app)
            now = Time.zone.now
            server_info = get_message(app, 'GetServerInfo', nil, {})[:headers]
            remote_filename = "#{pledge_type}_#{transaction_id}_#{original_filename.gsub(' ', '_')}"
            remote_path_fragment = "#{server_info['archiveDir']}/MCU/#{member_id}"
            remote_path = ""
            begin
              Net::SFTP.start(server_info['hostname'], 
                              server_info['svcAccountUsername'],
                              password: server_info['svcAccountPassword']) do |sftp|
                sftp.mkdir(remote_path_fragment)
                remote_path_fragment = "#{remote_path_fragment}/#{now.year}"
                sftp.mkdir(remote_path_fragment)
                remote_path_fragment = "#{remote_path_fragment}/#{now.month}"
                sftp.mkdir(remote_path_fragment)
                remote_path = "#{remote_path_fragment}/#{remote_filename}"
                sftp.upload!(local_path, remote_path)
              end
            rescue Exception => e
              message = "Failed to SFTP #{local_path} to #{remote_path}. Reason: #{e.message}"
              app.logger.error(message)
              return { success: false, message: message }
            end
            post_message(app, 'INITIATE_FILE_SUBMISSION', { 'memberId': member_id,
                                                            'fileTypeId': file_type,
                                                            'transactionId': transaction_id,
                                                            'fileName': remote_path,
                                                            'extension': File.extname(remote_path),
                                                            'pledgeType': pledge_type,
                                                            'submittedBy': username })
            post_message(app, 'UPDATE_FILE_STATUS', { 'transactionId': transaction_id, 
                                                      'status': 'FHLBSF Processing' })
          end
          { success: true, message: '' }
        end

        def self.mcu_member_status(app, member_id)
          mcu_member_status = unless should_fake?(app)
            get_message(app, 'GET_MEMBER_TRANSACTIONS', member_id, {partnerId: member_id})[:body]
          else
            fake('member_mcu_status')
          end
          if mcu_member_status
            mcu_member_status.each do |mcu_status|
              mcu_status["mcuType"] = mcu_status.delete("uploadType")
            end
          end
          mcu_member_status
        end

        def self.mcu_transaction_id(app, member_id)
          { transaction_id: should_fake?(app) ? rand(9999..99999) : get_message(app, 'GET_TRANSACTION_ID')[:body] }
        end

        def self.mcu_member_info(app, member_id)
          unless should_fake?(app)
            get_message(app, 'GET_MEMBER_INFO')[:body][member_id.to_s]
          else
            fake_hash('member_mcu_member_info')[member_id.to_s]
          end
        end

        module Private
          def self.mcu_sql(member_id)
            <<-SQL
              SELECT
                FHLB_ID,
                ACTUAL_START_DATE        as date_processed,
                NVL(MCU_PROCESSING_TYPE_DESC, 'Undefined') mcu_type,
                NVL(PLEDGE_TYPE_ID, '-') as  pledge_type,
                TRANS_NUM                as transaction_number,
                SYS_TOTAL_DEPOSIT + SYS_TOTAL_UPDATE + SYS_TOTAL_RENUMBER as accepted_count,
                SYS_TOTAL_WITHDRAWN      as  depledged_count,
                SYS_TOTAL_DEPOSIT        as    pledged_count,
                SYS_TOTAL_ERRORS         as   rejected_count,
                SYS_TOTAL_RENUMBER       as renumbered_count,
                SYS_TOTAL_LOANS          as      total_count,
                SYS_TOTAL_UPDATE         as    updated_count,
                SYS_UPB_DEPOSIT + SYS_UPB_UPDATE + SYS_UPB_RENUMBER as accepted_unpaid,
                SYS_UPB_DEPLEDGE         as  depledged_unpaid,
                SYS_UPB_DEPOSIT          as    pledged_unpaid,
                SYS_UPB_REJECTS          as   rejected_unpaid,
                SYS_UPB_RENUMBER         as renumbered_unpaid,
                SYS_UPB                  as      total_unpaid,
                SYS_UPB_UPDATE           as    updated_unpaid,
                SYS_ORIG_AMOUNT_DEPOSIT + SYS_ORIG_AMOUNT_UPDATE + SYS_ORIG_AMOUNT_RENUMBER as accepted_original,
                SYS_ORIG_AMOUNT_DEPLEDGE as  depledged_original,
                SYS_ORIG_AMOUNT_DEPOSIT  as    pledged_original,
                SYS_ORIG_AMOUNT_REJECTS  as   rejected_original,
                SYS_ORIG_AMOUNT_RENUMBER as renumbered_original,
                SYS_APPRAISED_DEPOSIT    as      total_original,
                SYS_ORIG_AMOUNT_UPDATE   as    updated_original
              FROM FHLBOWN.MCU_PROCESSED_RPT_WEB@colaprod_link MCU
              WHERE FHLB_ID = #{member_id}
            SQL
          end
        end        
      end
    end
  end
end