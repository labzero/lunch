module MAPI
  module Services
    module Member
      module SecuritiesRequests
        include MAPI::Shared::Utils
        include MAPI::Shared::Constants

        module SSKRequestStatus
          SIGNED = 85
          ACKNOWLEDGED = 86
          AWAITING_AUTHORIZATION = 87
          SUBMITTED = 90
        end

        module SSKFormType
          SECURITIES_PLEDGED = 70
          SECURITIES_RELEASE = 71
          SAFEKEPT_DEPOSIT = 72
          SAFEKEPT_RELEASE = 73
        end

        module MAPIRequestStatus
          AUTHORIZED = [SSKRequestStatus::SIGNED, SSKRequestStatus::ACKNOWLEDGED]
          AWAITING_AUTHORIZATION = [SSKRequestStatus::SUBMITTED]
        end

        REQUEST_STATUS_MAPPING = {
          authorized: MAPIRequestStatus::AUTHORIZED,
          awaiting_authorization: MAPIRequestStatus::AWAITING_AUTHORIZATION
        }.with_indifferent_access.freeze

        REQUEST_FORM_TYPE_MAPPING = {
          SSKFormType::SECURITIES_PLEDGED => :pledge_intake,
          SSKFormType::SECURITIES_RELEASE => :pledge_release,
          SSKFormType::SAFEKEPT_DEPOSIT => :safekept_intake,
          SSKFormType::SAFEKEPT_RELEASE => :safekept_release
        }.with_indifferent_access.freeze

        REQUEST_VALUE_MAPPING = {
          Proc.new { |value| REQUEST_FORM_TYPE_MAPPING[value] } => ['FORM_TYPE'],
          Proc.new { |value| REQUEST_STATUS_MAPPING[value] } => ['STATUS'],
          to_s: ['REQUEST_ID', 'SUBMITTED_BY', 'AUTHORIZED_BY'],
          to_date: ['SETTLE_DATE', 'SUBMITTED_DATE', 'AUTHORIZED_DATE']
        }.freeze

        def self.requests_query(member_id, status_array, date_range)
          quoted_statuses = status_array.collect { |status| quote(status) }.join(',')
          <<-SQL
            SELECT HEADER_ID AS REQUEST_ID, FORM_TYPE, SETTLE_DATE, CREATED_DATE AS SUBMITTED_DATE, CREATED_BY_NAME AS SUBMITTED_BY,
            SIGNED_BY_NAME AS AUTHORIZED_BY, SIGNED_DATE AS AUTHORIZED_DATE, STATUS FROM SAFEKEEPING.SSK_WEB_FORM_HEADER
            WHERE FHLB_ID = #{quote(member_id)} AND STATUS IN (#{quoted_statuses}) AND SETTLE_DATE >= #{quote(date_range.first)}
            AND SETTLE_DATE <= #{quote(date_range.last)}
          SQL
        end

        def self.requests(app, member_id, status = MAPIRequestStatus::AUTHORIZED, settlement_date_range=nil)
          flat_status = Array.wrap(status).flatten.uniq
          requests = (
            end_date = settlement_date_range.try(:last) || Time.zone.today
            start_date = settlement_date_range.try(:first) || (end_date - 7.days)
            if should_fake?(app)
              rng = Random.new(member_id.to_i + end_date.to_time.to_i + start_date.to_time.to_i + status.sum)
              list = []
              names = fake('securities_request_names')
              rng.rand(1..7).times do
                submitted_date = end_date - rng.rand(0..4).days
                authorized_date = submitted_date + rng.rand(0..2).days
                status = flat_status[rng.rand(0..flat_status.length-1)]
                authorized = MAPIRequestStatus::AUTHORIZED.include?(status)
                list << {
                  'REQUEST_ID' => rng.rand(100000..999999),
                  'FORM_TYPE' => rng.rand(70..73),
                  'STATUS' => status,
                  'SETTLE_DATE' => (authorized ? authorized_date : submitted_date) + 1.days,
                  'SUBMITTED_DATE' => submitted_date,
                  'SUBMITTED_BY' => names[rng.rand(0..names.length-1)],
                  'AUTHORIZED_BY' => authorized ? names[rng.rand(0..names.length-1)] : nil,
                  'AUTHORIZED_DATE' => authorized ? authorized_date : nil
                }
              end
              list
            else
              fetch_hashes(app.logger, requests_query(member_id, flat_status, (start_date..end_date)))
            end
          )
          requests.collect do |request|
            map_hash_values(request, REQUEST_VALUE_MAPPING, true).with_indifferent_access
          end
        end

        module SSKFormType
          SecuritiesPledge = 70
          SecuritiesRelease = 71
          SafekeepingDeposit = 72
          SafekeepingRelease = 73
        end

        module SSKDeliverTo
          FED = 30
          DTC = 31
          INTERNAL_TRANSFER = 32
          MUTUAL_FUND = 33
          PHYSICAL_SECURITIES = 34
        end

        module SSKTransactionCode
          STANDARD = 50
          REPO = 51
        end

        module SSKSettlementType
          FREE = 60
          VS_PAYMENT = 61
        end

        NEXT_ID_SQL = 'SELECT SAFEKEEPING.SSK_WEB_FORM_SEQ.NEXTVAL FROM DUAL'.freeze
        BROKER_INSTRUCTIONS_MAPPING = { 'transaction_code' => 'PLEDGE_TYPE',
                                        'settlement_type' => 'REQUEST_STATUS',
                                        'trade_date' => 'TRADE_DATE',
                                        'settlement_date' => 'SETTLE_DATE' }.freeze
        DELIVERY_TYPE = { 'fed' => SSKDeliverTo::FED,
                          'dtc' => SSKDeliverTo::DTC,
                          'mutual_fund' => SSKDeliverTo::MUTUAL_FUND,
                          'physical_securities' => SSKDeliverTo::PHYSICAL_SECURITIES }.freeze
        TRANSACTION_CODE = { 'standard' => SSKTransactionCode::STANDARD, 'repo' => SSKTransactionCode::REPO }.freeze
        SETTLEMENT_TYPE = { 'free' => SSKSettlementType::FREE, 'vs_payment' => SSKSettlementType::VS_PAYMENT }.freeze
        ACCOUNT_NUMBER_MAPPING = { 'fed' => 'CREDIT_ACCT_NO1',
                                   'dtc' => 'CREDIT_ACCT_NO2',
                                   'mutual_fund' => 'MUTUAL_FUND_ACCT_NO',
                                   'physical_securities' => 'CREDIT_ACCT_NO3' }
        REQUIRED_SECURITY_KEYS = [ 'cusip', 'description', 'original_par' ].freeze
        LAST_MODIFIED_BY_MAX_LENGTH = 30

        def self.delivery_type_mapping(delivery_type)
          { 'clearing_agent_fed_wire_address' => 'BROKER_WIRE_ADDR',
            'aba_number' => 'ABA_NO',
            'clearing_agent_participant_number' => 'DTC_AGENT_PARTICIPANT_NO',
            'mutual_fund_company' => 'MUTUAL_FUND_COMPANY',
            'delivery_bank_agent' => 'DELIVERY_BANK_AGENT',
            'receiving_bank_agent_name' => 'REC_BANK_AGENT_NAME',
            'receiving_bank_agent_address' => 'REC_BANK_AGENT_ADDR',
            'account_number' => ACCOUNT_NUMBER_MAPPING[delivery_type] }
        end

        def self.delivery_keys_for_delivery_type(delivery_type)
          [ 'account_number' ] +
          case delivery_type
            when 'fed'
              [ 'clearing_agent_fed_wire_address', 'aba_number' ]
            when 'dtc'
              [ 'clearing_agent_participant_number' ]
            when 'mutual_fund'
              [ 'mutual_fund_company' ]
            when 'physical_securities'
              [ 'delivery_bank_agent', 'receiving_bank_agent_name', 'receiving_bank_agent_address' ]
          else
            raise ArgumentError, "delivery_type must be one of the following values: #{DELIVERY_TYPE.keys.join(', ')}"
          end
        end

        def self.insert_release_header_query(member_id, header_id, user_name, session_id, full_name, pledged_adx_id, delivery_columns, broker_instructions, delivery_type, delivery_values)
          now = Time.zone.today
          <<-SQL
            INSERT INTO SAFEKEEPING.SSK_WEB_FORM_HEADER (HEADER_ID,
                                                         FHLB_ID,
                                                         STATUS,
                                                         PLEDGE_TYPE,
                                                         TRADE_DATE,
                                                         REQUEST_STATUS,
                                                         SETTLE_DATE,
                                                         DELIVER_TO,
                                                         FORM_TYPE,
                                                         CREATED_DATE,
                                                         CREATED_BY,
                                                         CREATED_BY_NAME,
                                                         LAST_MODIFIED_BY,
                                                         LAST_MODIFIED_DATE,
                                                         LAST_MODIFIED_BY_NAME,
                                                         PLEDGED_ADX_ID,
                                                         #{delivery_columns.join(', ')}
                                                        )
            VALUES (#{quote(header_id)},
                    #{quote(member_id)},
                    #{quote(SSKRequestStatus::SUBMITTED)},
                    #{quote(TRANSACTION_CODE[broker_instructions['transaction_code']])},
                    #{quote(broker_instructions['trade_date'])},
                    #{quote(SETTLEMENT_TYPE[broker_instructions['settlement_type']])},
                    #{quote(broker_instructions['settlement_date'])},
                    #{quote(DELIVERY_TYPE[delivery_type])},
                    #{quote(SSKFormType::SecuritiesRelease)},
                    #{quote(now)},
                    #{quote(user_name)},
                    #{quote(full_name)},
                    #{quote((user_name + '\\\\' + session_id)[0..LAST_MODIFIED_BY_MAX_LENGTH - 1])},
                    #{quote(now)},
                    #{quote(full_name)},
                    #{quote(pledged_adx_id)},
                    #{delivery_values.join(', ')}
                   )
          SQL
        end

        def self.insert_security_query(header_id, detail_id, user_name, session_id, security, ssk_id)
          now = Time.zone.today
          <<-SQL
            INSERT INTO SAFEKEEPING.SSK_WEB_FORM_DETAIL (DETAIL_ID,
                                                         HEADER_ID,
                                                         CUSIP,
                                                         DESCRIPTION,
                                                         ORIGINAL_PAR,
                                                         PAYMENT_AMOUNT,
                                                         CREATED_DATE,
                                                         CREATED_BY,
                                                         LAST_MODIFIED_DATE,
                                                         LAST_MODIFIED_BY,
                                                         SSK_ID
                                                        )
            VALUES (#{quote(detail_id)},
                    #{quote(header_id)},
                    UPPER(#{quote(security['cusip'])}),
                    #{quote(security['description'])},
                    #{quote(nil_to_zero(security['original_par']))},
                    #{quote(nil_to_zero(security['payment_amount']))},
                    #{quote(now)},
                    #{quote(user_name)},
                    #{quote(now)},
                    #{quote((user_name + '\\\\' + session_id)[0..LAST_MODIFIED_BY_MAX_LENGTH - 1])},
                    #{quote(ssk_id)}
                   )
          SQL
        end
        def self.pledged_adx_query(member_id)
          <<-SQL
            SELECT ADX.ADX_ID
            FROM SAFEKEEPING.ACCOUNT_DOCKET_XREF ADX, SAFEKEEPING.BTC_ACCOUNT_TYPE BAT, SAFEKEEPING.CUSTOMER_PROFILE CP
            WHERE ADX.BAT_ID = BAT.BAT_ID
            AND ADX.CP_ID = CP.CP_ID
            AND CP.FHLB_ID = #{quote(member_id)}
            AND UPPER(SUBSTR(BAT.BAT_ACCOUNT_TYPE,1,1)) = 'P'
            AND CONCAT(TRIM(TRANSLATE(ADX.ADX_BTC_ACCOUNT_NUMBER,' 0123456789',' ')), '*') = '*'
            AND (BAT.BAT_ACCOUNT_TYPE NOT LIKE '%DB%' AND BAT.BAT_ACCOUNT_TYPE NOT LIKE '%REIT%')
            ORDER BY TO_NUMBER(ADX.ADX_BTC_ACCOUNT_NUMBER) ASC
          SQL
        end

        def self.ssk_id_query(member_id, pledged_adx_id, cusip)
          <<-SQL
            SELECT SSK.SSK_ID
            FROM SAFEKEEPING.SSK SSK, SAFEKEEPING.SSK_TRANS SSKT
            WHERE UPPER(SSK.SSK_CUSIP) = UPPER(#{quote(cusip)})
            AND SSK.FHLB_ID = #{quote(member_id)}
            AND SSK.ADX_ID = #{quote(pledged_adx_id)}
            AND SSKT.SSK_ID = SSK.SSK_ID
            AND SSKT.SSX_BTC_DATE = (SELECT MAX(SSX_BTC_DATE) FROM SAFEKEEPING.SSK_TRANS)
          SQL
        end

        def self.format_delivery_columns(delivery_type, required_delivery_keys, provided_delivery_keys)
          delivery_type_map = delivery_type_mapping(delivery_type)
          required_delivery_keys.map do |key|
            raise ArgumentError, "delivery_instructions must contain #{key}" unless provided_delivery_keys.include?(key)
            "#{delivery_type_map[key]}"
          end
        end

        def self.format_delivery_values(required_delivery_keys, delivery_instructions)
          required_delivery_keys.map do |key|
            quote(delivery_instructions[key])
          end
        end

        def self.execute_sql_single_result(app, sql, description)
          cursor = execute_sql(app.logger, sql)
          raise MAPI::Shared::Errors::SQLError, "#{description} returned nil" unless cursor
          records = cursor.fetch
          raise MAPI::Shared::Errors::SQLError, "Calling fetch on the cursor returned nil" unless records
          sequence = records.first
          raise MAPI::Shared::Errors::SQLError, "Calling first on the record set returned nil" unless sequence
          sequence
        end

        def self.create_release(app, member_id, user_name, full_name, session_id, broker_instructions, delivery_instructions, securities)
          raise ArgumentError, "broker_instructions must be a non-empty hash" unless !broker_instructions.nil? && broker_instructions.is_a?(Hash) && !broker_instructions.empty?
          raise ArgumentError, "delivery_instructions must be a non-empty hash" unless !delivery_instructions.nil? && delivery_instructions.is_a?(Hash) && !delivery_instructions.empty?
          BROKER_INSTRUCTIONS_MAPPING.keys.each do |key|
            raise ArgumentError, "broker_instructions must contain a value for #{key}" unless broker_instructions[key]
          end
          { 'transaction_code' => TRANSACTION_CODE, 'settlement_type' => SETTLEMENT_TYPE }.each do |key, allowed_values|
            allowed_values = allowed_values.keys
            raise ArgumentError, "#{key.to_s} must be set to one of the following values: #{allowed_values.join(', ')}" unless allowed_values.include?(broker_instructions[key])
          end
          broker_instructions['trade_date'] = dateify(broker_instructions['trade_date'])
          broker_instructions['settlement_date'] = dateify(broker_instructions['settlement_date'])
          delivery_type = delivery_instructions.delete('delivery_type')
          raise ArgumentError, "delivery_instructions must contain the key delivery_type set to one of #{DELIVERY_TYPE.keys.join(', ')}" unless DELIVERY_TYPE.keys.include?(delivery_type)
          provided_delivery_keys = delivery_instructions.keys
          required_delivery_keys = delivery_keys_for_delivery_type(delivery_type)
          delivery_columns = format_delivery_columns(delivery_type, required_delivery_keys, provided_delivery_keys)
          delivery_values = format_delivery_values(required_delivery_keys, delivery_instructions)
          raise ArgumentError, "securities must be an array containing at least one security" unless !securities.nil? && securities.is_a?(Array) && !securities.empty?
          required_security_keys = broker_instructions['settlement_type'] == 'vs_payment' ?
            REQUIRED_SECURITY_KEYS + ['payment_amount'] : REQUIRED_SECURITY_KEYS
          securities.each do |security|
            raise ArgumentError, "each security must be a non-empty hash" unless !security.nil? && security.is_a?(Hash) && !security.empty?
            required_security_keys.each do |key|
              raise ArgumentError, "each security must consist of a hash containing a value for #{key}" unless security[key]
            end
          end
          user_name.downcase!
          unless should_fake?(app)
            header_id = execute_sql_single_result(app, NEXT_ID_SQL, "Next ID Sequence").to_i
            ActiveRecord::Base.transaction do
              pledged_adx_id = execute_sql_single_result(app, pledged_adx_query(member_id), "Pledged ADX ID")
              insert_header_sql = insert_release_header_query(member_id, header_id, user_name, full_name, session_id, pledged_adx_id, delivery_columns, broker_instructions, delivery_type, delivery_values)
              raise "failed to insert security release request header" unless execute_sql(app.logger, insert_header_sql)
              securities.each do |security|
                ssk_id = execute_sql_single_result(app, ssk_id_query(member_id, pledged_adx_id, security['cusip']), "SSK ID")
                insert_security_sql = insert_security_query(header_id, execute_sql_single_result(app, NEXT_ID_SQL, "Next ID Sequence").to_i, user_name, session_id, security, ssk_id)
                raise "failed to insert security release request detail" unless execute_sql(app.logger, insert_security_sql)
              end
            end
          end
          true
        end
      end
    end
  end
end