module MAPI
  module Services
    module Member
      module SecuritiesRequests
        include MAPI::Shared::Utils
        include MAPI::Shared::Constants

        module SSKRequestStatus
          SIGNED = 85
          ACKNOWLEDGED = 86
          SUBMITTED = 90
        end

        module SSKFormType
          SECURITIES_PLEDGED = 70
          SECURITIES_RELEASE = 71
          SAFEKEPT_DEPOSIT = 72
          SAFEKEPT_RELEASE = 73
        end

        module SSKDeliverTo
          FED = 30
          DTC = 31
          INTERNAL_TRANSFER = 32
          MUTUAL_FUND = 33
          PHYSICAL_SECURITIES = 34
        end

        module SSKPledgeTo
          SBC = 20
          STANDARD_CREDIT = 21
        end

        module SSKTransactionCode
          STANDARD = 50
          REPO = 51
        end

        module SSKSettlementType
          FREE = 60
          VS_PAYMENT = 61
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
          Proc.new { |value| DELIVERY_TYPE.invert[value.to_i] } => ['DELIVER_TO', 'RECEIVE_FROM'],
          to_s: ['REQUEST_ID', 'SUBMITTED_BY', 'AUTHORIZED_BY'],
          to_date: ['SETTLE_DATE', 'SUBMITTED_DATE', 'AUTHORIZED_DATE']
        }.freeze

        REQUEST_HEADER_MAPPING = {
          Proc.new { |value| TRANSACTION_CODE.invert[value.to_i] } => ['PLEDGE_TYPE'],
          Proc.new { |value| SETTLEMENT_TYPE.invert[value.to_i] } => ['REQUEST_STATUS'],
          Proc.new { |value| DELIVERY_TYPE.invert[value.to_i] } => ['DELIVER_TO', 'RECEIVE_FROM'],
          Proc.new { |value| REQUEST_FORM_TYPE_MAPPING[value] } => ['FORM_TYPE'],
          Proc.new { |value| PLEDGE_TO.invert[value.to_i] } => ['PLEDGE_TO'],
          to_s: ['BROKER_WIRE_ADDR', 'ABA_NO', 'DTC_AGENT_PARTICIPANT_NO', 'MUTUAL_FUND_COMPANY', 'DELIVERY_BANK_AGENT',
                 'REC_BANK_AGENT_NAME', 'REC_BANK_AGENT_ADDR', 'CREDIT_ACCT_NO1', 'CREDIT_ACCT_NO2', 'MUTUAL_FUND_ACCT_NO',
                 'CREDIT_ACCT_NO3', 'CREATED_BY', 'CREATED_BY_NAME'],
          to_date: ['SETTLE_DATE', 'TRADE_DATE', 'AUTHORIZED_DATE']
        }.freeze

        RELEASE_REQUEST_SECURITIES_MAPPING = {
          to_s: ['CUSIP', 'DESCRIPTION'],
          to_i: ['ORIGINAL_PAR', 'PAYMENT_AMOUNT']
        }.freeze

        NEXT_ID_SQL = 'SELECT SAFEKEEPING.SSK_WEB_FORM_SEQ.NEXTVAL FROM DUAL'.freeze
        BROKER_INSTRUCTIONS_MAPPING = { 'transaction_code' => 'PLEDGE_TYPE',
                                        'settlement_type' => 'REQUEST_STATUS',
                                        'trade_date' => 'TRADE_DATE',
                                        'settlement_date' => 'SETTLE_DATE' }.freeze
        ADDITIONAL_BROKER_INSTRUCTIONS_MAPPING_FOR_PLEDGING = { 'pledge_to' => 'PLEDGE_TO' }.freeze
        DELIVERY_TYPE = { 'fed' => SSKDeliverTo::FED,
                          'dtc' => SSKDeliverTo::DTC,
                          'mutual_fund' => SSKDeliverTo::MUTUAL_FUND,
                          'physical_securities' => SSKDeliverTo::PHYSICAL_SECURITIES,
                          'transfer' => SSKDeliverTo::INTERNAL_TRANSFER  }.freeze
        PLEDGE_TO = { 'standard' => SSKPledgeTo::STANDARD_CREDIT, 'sbc' => SSKPledgeTo::SBC }
        TRANSACTION_CODE = { 'standard' => SSKTransactionCode::STANDARD, 'repo' => SSKTransactionCode::REPO }.freeze
        SETTLEMENT_TYPE = { 'free' => SSKSettlementType::FREE, 'vs_payment' => SSKSettlementType::VS_PAYMENT }.freeze
        ACCOUNT_NUMBER_MAPPING = { 'fed' => 'CREDIT_ACCT_NO1',
                                   'dtc' => 'CREDIT_ACCT_NO2',
                                   'mutual_fund' => 'MUTUAL_FUND_ACCT_NO',
                                   'physical_securities' => 'CREDIT_ACCT_NO3' }
        REQUIRED_SECURITY_RELEASE_KEYS = [ 'cusip', 'description', 'original_par' ].freeze
        REQUIRED_SECURITY_TRANSFER_KEYS = [ 'cusip', 'description', 'original_par' ].freeze
        REQUIRED_SECURITY_INTAKE_KEYS = [ 'cusip', 'original_par' ].freeze
        LAST_MODIFIED_BY_MAX_LENGTH = 30
        BROKER_WIRE_ADDRESS_FIELDS = ['clearing_agent_fed_wire_address_1', 'clearing_agent_fed_wire_address_2'].freeze
        FED_AMOUNT_LIMIT = 50000000
        MAX_DATE_RESTRICTION = 3.months

        KINDS_FOR_FLOW = {
          release: [:pledge_release, :safekept_release].freeze,
          intake: [:pledge_intake, :safekept_intake].freeze,
          transfer: [:pledge_transfer, :safekept_transfer].freeze
        }.freeze

        KIND_TRANSFER_MAPPING = {
          pledge_transfer: {
            adx_type: :pledged_intake,
            account_column_name: 'RECEIVE_FROM'
          },
          safekept_transfer: {
            adx_type: :pledged_release,
            account_column_name: 'DELIVER_TO'
          }
        }.freeze

        module ADXAccountTypeMapping
          SYMBOL_TO_STRING = { pledged: 'Pledged', unpledged: 'Unpledged' }.freeze
          STRING_TO_SYMBOL = {'U' => :unpledged, 'P' => :pledged}.freeze
          SYMBOL_TO_SQL_COLUMN_NAME = { pledged_intake: 'PLEDGED_ADX_ID',
                                        pledged_release: 'PLEDGED_ADX_ID',
                                        unpledged_intake: 'UNPLEDGED_ADX_ID',
                                        unpledged_release: 'UNPLEDGED_ADX_ID' }.freeze
          SYMBOL_TO_SSK_FORM_TYPE = { pledged_intake: SSKFormType::SECURITIES_PLEDGED,
                                      pledged_release: SSKFormType::SECURITIES_RELEASE,
                                      unpledged_intake: SSKFormType::SAFEKEPT_DEPOSIT,
                                      unpledged_release: SSKFormType::SAFEKEPT_RELEASE }.freeze
        end

        def self.requests_query(member_id, status_array, start_date)
          quoted_statuses = status_array.collect { |status| quote(status) }.join(',')
          <<-SQL
            SELECT HEADER_ID AS REQUEST_ID, FORM_TYPE, DELIVER_TO, RECEIVE_FROM, SETTLE_DATE, CREATED_DATE AS SUBMITTED_DATE, CREATED_BY_NAME AS SUBMITTED_BY,
            SIGNED_BY_NAME AS AUTHORIZED_BY, SIGNED_DATE AS AUTHORIZED_DATE, STATUS FROM SAFEKEEPING.SSK_WEB_FORM_HEADER
            WHERE FHLB_ID = #{quote(member_id)} AND STATUS IN (#{quoted_statuses}) AND SETTLE_DATE >= #{quote(start_date)}
            AND FORM_TYPE IS NOT NULL
          SQL
        end

        def self.requests(app, member_id, status = MAPIRequestStatus::AUTHORIZED, start_date=nil)
          flat_status = flat_unique_array(status)
          requests = (
            start_date ||= Time.zone.today - 7.days
            if should_fake?(app)
              self.fake_header_details_array(member_id.to_i, start_date).select do |header_details|
                flat_status.include?(header_details['STATUS']) && header_details['SUBMITTED_DATE'] >= start_date
              end
            else
              fetch_hashes(app.logger, requests_query(member_id, flat_status, start_date))
            end
          )
          requests.collect do |request|
            request['KIND'] = kind_from_details(request)
            mapped_request = map_hash_values(request, REQUEST_VALUE_MAPPING, true).with_indifferent_access
            mapped_request
          end
        end

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
            when 'transfer'
              []
          else
            raise MAPI::Shared::Errors::InvalidFieldError.new("delivery_type must be one of the following values: #{DELIVERY_TYPE.keys.join(', ')}", :delivery_type, DELIVERY_TYPE.keys)
          end
        end

        def self.insert_release_header_query(member_id, header_id, user_name, full_name, session_id, adx_id, delivery_columns, broker_instructions, delivery_type, delivery_values, adx_type)
          adx_type_release = "#{adx_type}_release".to_sym
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
                                                         #{ADXAccountTypeMapping::SYMBOL_TO_SQL_COLUMN_NAME[adx_type_release]},
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
                    #{quote(ADXAccountTypeMapping::SYMBOL_TO_SSK_FORM_TYPE[adx_type_release])},
                    #{quote(now)},
                    #{quote(format_username(user_name))},
                    #{quote(full_name)},
                    #{quote(format_modification_by(user_name, session_id))},
                    #{quote(now)},
                    #{quote(full_name)},
                    #{quote(adx_id)},
                    #{delivery_values.join(', ')}
                   )
          SQL
        end

        def self.insert_intake_header_query(member_id, header_id, user_name, full_name, session_id, adx_id, delivery_columns, broker_instructions, delivery_type, delivery_values, adx_type)
          adx_type_intake = "#{adx_type}_intake".to_sym
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
                                                         #{ADXAccountTypeMapping::SYMBOL_TO_SQL_COLUMN_NAME[adx_type_intake]},
                                                         PLEDGE_TO,
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
                    #{quote(ADXAccountTypeMapping::SYMBOL_TO_SSK_FORM_TYPE[adx_type_intake])},
                    #{quote(now)},
                    #{quote(format_username(user_name))},
                    #{quote(full_name)},
                    #{quote(format_modification_by(user_name, session_id))},
                    #{quote(now)},
                    #{quote(full_name)},
                    #{quote(adx_id)},
                    #{quote(PLEDGE_TO[broker_instructions['pledge_to']])},
                    #{delivery_values.join(', ')}
                   )
          SQL
        end

        def self.insert_transfer_header_query(member_id, header_id, user_name, full_name, session_id, adx_id, un_adx_id, broker_instructions, kind)
          now = Time.zone.today
          <<-SQL
            INSERT INTO SAFEKEEPING.SSK_WEB_FORM_HEADER (HEADER_ID,
                                                         FHLB_ID,
                                                         STATUS,
                                                         PLEDGE_TYPE,
                                                         TRADE_DATE,
                                                         REQUEST_STATUS,
                                                         SETTLE_DATE,
                                                         #{KIND_TRANSFER_MAPPING[kind][:account_column_name]},
                                                         FORM_TYPE,
                                                         CREATED_DATE,
                                                         CREATED_BY,
                                                         CREATED_BY_NAME,
                                                         LAST_MODIFIED_BY,
                                                         LAST_MODIFIED_DATE,
                                                         LAST_MODIFIED_BY_NAME,
                                                         PLEDGED_ADX_ID,
                                                         UNPLEGED_TRANSFER_ADX_ID,
                                                         PLEDGE_TO
                                                        )
            VALUES (#{quote(header_id)},
                    #{quote(member_id)},
                    #{quote(SSKRequestStatus::SUBMITTED)},
                    #{quote(SSKTransactionCode::STANDARD)},
                    #{quote(broker_instructions['trade_date'])},
                    #{quote(SETTLEMENT_TYPE[broker_instructions['settlement_type']])},
                    #{quote(broker_instructions['settlement_date'])},
                    #{quote(SSKDeliverTo::INTERNAL_TRANSFER)},
                    #{quote(ADXAccountTypeMapping::SYMBOL_TO_SSK_FORM_TYPE[KIND_TRANSFER_MAPPING[kind][:adx_type]])},
                    #{quote(now)},
                    #{quote(format_username(user_name))},
                    #{quote(full_name)},
                    #{quote(format_modification_by(user_name, session_id))},
                    #{quote(now)},
                    #{quote(full_name)},
                    #{quote(adx_id)},
                    #{quote(un_adx_id)},
                    #{quote(PLEDGE_TO[broker_instructions['pledge_to']])}
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
                    #{quote(format_username(user_name))},
                    #{quote(now)},
                    #{quote(format_modification_by(user_name, session_id))},
                    #{quote(ssk_id)}
                   )
          SQL
        end

        def self.adx_query(member_id, type)
          <<-SQL
            SELECT ADX.ADX_ID
            FROM SAFEKEEPING.ACCOUNT_DOCKET_XREF ADX, SAFEKEEPING.BTC_ACCOUNT_TYPE BAT, SAFEKEEPING.CUSTOMER_PROFILE CP
            WHERE ADX.BAT_ID = BAT.BAT_ID
            AND ADX.CP_ID = CP.CP_ID
            AND CP.FHLB_ID = #{quote(member_id)}
            AND BAT.BAT_ACCOUNT_TYPE = #{quote(ADXAccountTypeMapping::SYMBOL_TO_STRING[type])}
            AND CONCAT(TRIM(TRANSLATE(ADX.ADX_BTC_ACCOUNT_NUMBER,' 0123456789',' ')), '*') = '*'
            ORDER BY TO_NUMBER(ADX.ADX_BTC_ACCOUNT_NUMBER) ASC
          SQL
        end

        def self.ssk_id_query(member_id, adx_id, cusip)
          <<-SQL
            SELECT SSK.SSK_ID
            FROM SAFEKEEPING.SSK SSK, SAFEKEEPING.SSK_TRANS SSKT
            WHERE UPPER(SSK.SSK_CUSIP) = UPPER(#{quote(cusip)})
            AND SSK.FHLB_ID = #{quote(member_id)}
            AND SSK.ADX_ID = #{quote(adx_id)}
            AND SSKT.SSK_ID = SSK.SSK_ID
            AND SSKT.SSX_BTC_DATE = (SELECT MAX(SSX_BTC_DATE) FROM SAFEKEEPING.SSK_TRANS)
          SQL
        end

        def self.authorize_request_query(member_id, request_id, user_name, full_name, session_id, signer_id)
          now = Time.zone.today
          <<-SQL
            UPDATE SAFEKEEPING.SSK_WEB_FORM_HEADER SET
            STATUS = #{quote(SSKRequestStatus::SIGNED)},
            SIGNED_BY = #{quote(signer_id)},
            SIGNED_BY_NAME = #{quote(full_name)},
            SIGNED_DATE = #{quote(now)},
            LAST_MODIFIED_BY = #{quote(format_modification_by(user_name, session_id))},
            LAST_MODIFIED_DATE = #{quote(now)},
            LAST_MODIFIED_BY_NAME = #{quote(full_name)}
            WHERE HEADER_ID = #{quote(request_id)}
            AND FHLB_ID = #{quote(member_id)}
            AND STATUS = #{quote(SSKRequestStatus::SUBMITTED)}
          SQL
        end

        def self.consolidate_broker_wire_address(delivery_instructions)
          unless (delivery_instructions.keys & BROKER_WIRE_ADDRESS_FIELDS).blank?
            address_1 = delivery_instructions.delete('clearing_agent_fed_wire_address_1')
            address_2 = delivery_instructions.delete('clearing_agent_fed_wire_address_2')
            delivery_instructions['clearing_agent_fed_wire_address'] = [address_1, address_2].join('/')
          end
        end

        def self.format_delivery_columns(delivery_type, required_delivery_keys, provided_delivery_keys)
          delivery_type_map = delivery_type_mapping(delivery_type)
          required_delivery_keys.map do |key|
            raise MAPI::Shared::Errors::MissingFieldError.new("delivery_instructions must contain #{key}", key, required_delivery_keys) unless provided_delivery_keys.include?(key)
            "#{delivery_type_map[key]}"
          end
        end

        def self.format_delivery_values(required_delivery_keys, delivery_instructions)
          required_delivery_keys.map do |key|
            quote(delivery_instructions[key])
          end
        end

        def self.format_modification_by(username, session_id)
          (format_username(username) + '\\\\' + session_id)[0..LAST_MODIFIED_BY_MAX_LENGTH - 1]
        end

        def self.format_username(username)
          username.downcase
        end

        def self.execute_sql_single_result(app, sql, description)
          cursor = execute_sql(app.logger, sql)
          if cursor
            records = cursor.fetch
            if records
              first_record = records.first
              return first_record if first_record
            end
          else
            raise MAPI::Shared::Errors::SQLError, "#{description} returned `nil` for the cursor"
          end
          nil
        end

        def self.validate_broker_instructions(broker_instructions, app, kind)
          raise MAPI::Shared::Errors::MissingFieldError.new('broker_instructions must be a non-empty hash', :broker_instructions) unless !broker_instructions.nil? && broker_instructions.is_a?(Hash) && !broker_instructions.empty?
          broker_instructions_mapping = BROKER_INSTRUCTIONS_MAPPING
          broker_instructions_mapping = broker_instructions_mapping.merge(ADDITIONAL_BROKER_INSTRUCTIONS_MAPPING_FOR_PLEDGING) if [:pledge_intake, :pledge_transfer].include?(kind)
          broker_instructions_mapping.keys.each do |key|
            raise MAPI::Shared::Errors::MissingFieldError.new("broker_instructions must contain a value for #{key}", key) unless broker_instructions[key]
          end
          { 'transaction_code' => TRANSACTION_CODE, 'settlement_type' => SETTLEMENT_TYPE }.each do |key, allowed_values|
            allowed_values = allowed_values.keys
            raise MAPI::Shared::Errors::InvalidFieldError.new("#{key.to_s} must be set to one of the following values: #{allowed_values.join(', ')}", key, allowed_values) unless allowed_values.include?(broker_instructions[key])
          end
          broker_instructions['trade_date'] = dateify(broker_instructions['trade_date'])
          broker_instructions['settlement_date'] = dateify(broker_instructions['settlement_date'])
          validate_broker_instructions_date(app, broker_instructions['trade_date'], 'trade_date')
          validate_broker_instructions_date(app, broker_instructions['settlement_date'], 'settlement_date')
          raise MAPI::Shared::Errors::CustomTypedFieldError.new('trade_date must be on or before settlement_date', :before_trade_date, :settlement_date) unless broker_instructions['trade_date'] <= broker_instructions['settlement_date']
        end

        def self.validate_broker_instructions_date(app, date, attr_name)
          today = Time.zone.today
          max_date = today + MAX_DATE_RESTRICTION
          holidays = MAPI::Services::Rates::Holidays.holidays(app, today, max_date)
          raise MAPI::Shared::Errors::InvalidFieldError.new("#{attr_name} must not be set to a weekend date or a bank holiday", attr_name, :weekend_holiday) if weekend_or_holiday?(date, holidays)
          raise MAPI::Shared::Errors::InvalidFieldError.new("#{attr_name} must not occur before today", attr_name, :past_date) unless attr_name == 'trade_date' || date >= today
          raise MAPI::Shared::Errors::InvalidFieldError.new("#{attr_name} must not occur after 3 months from today", attr_name, :future_date) unless date <= max_date
        end

        def self.validate_securities(securities, settlement_type, delivery_type, type)
          raise MAPI::Shared::Errors::MissingFieldError.new('securities must be an array containing at least one security', :securities) unless !securities.nil? && securities.is_a?(Array) && !securities.empty?
          required_security_keys = case type
          when :release
            REQUIRED_SECURITY_RELEASE_KEYS
          when :intake
            REQUIRED_SECURITY_INTAKE_KEYS
          when :pledge_transfer, :safekept_transfer
            REQUIRED_SECURITY_TRANSFER_KEYS
          end
          required_security_keys += ['payment_amount'] if settlement_type == 'vs_payment' && ![:pledge_transfer, :safekept_transfer].include?(type)
          securities.each do |security|
            raise MAPI::Shared::Errors::MissingFieldError.new('each security must be a non-empty hash', :securities) unless !security.nil? && security.is_a?(Hash) && !security.empty?
            required_security_keys.each do |key|
              raise MAPI::Shared::Errors::CustomTypedFieldError.new("each security must consist of a hash containing a value for #{key}", key, :securities) unless security[key]
            end
          end
          if delivery_type == 'fed'
            securities.each do |security|
              raise MAPI::Shared::Errors::CustomTypedFieldError.new("original par must be less than $#{FED_AMOUNT_LIMIT}", :original_par, :securities, FED_AMOUNT_LIMIT) unless security['original_par'] <= FED_AMOUNT_LIMIT
            end
          end
        end

        def self.validate_delivery_instructions(delivery_instructions)
          raise MAPI::Shared::Errors::MissingFieldError.new('delivery_instructions must be a non-empty hash', :delivery_instructions) unless !delivery_instructions.nil? && delivery_instructions.is_a?(Hash) && !delivery_instructions.empty?
          delivery_type = delivery_instructions['delivery_type']
          raise MAPI::Shared::Errors::InvalidFieldError.new("delivery_instructions must contain the key delivery_type set to one of #{DELIVERY_TYPE.keys.join(', ')}", :delivery_type, DELIVERY_TYPE.keys) unless DELIVERY_TYPE.keys.include?(delivery_type)
        end

        def self.validate_kind(flow, kind)
          raise ArgumentError, "unknown flow: #{flow}" unless KINDS_FOR_FLOW.keys.include?(flow)
          raise ArgumentError, "invalid kind: #{kind}" unless KINDS_FOR_FLOW[flow].include?(kind)
          true
        end

        def self.process_delivery_instructions(delivery_instructions)
          delivery_type = delivery_instructions.delete('delivery_type')
          consolidate_broker_wire_address(delivery_instructions)
          required_delivery_keys = delivery_keys_for_delivery_type(delivery_type)
          {
            delivery_type: delivery_type,
            delivery_columns: format_delivery_columns(delivery_type, required_delivery_keys, delivery_instructions.keys),
            delivery_values: format_delivery_values(required_delivery_keys, delivery_instructions)
          }
        end

        def self.update_request_header_details_query(member_id, header_id, user_name, full_name, session_id, adx_id, delivery_columns, broker_instructions, delivery_type, delivery_values, adx_type, intake_or_release)
          adx_type = "#{adx_type}_#{intake_or_release}".to_sym
          <<-SQL
            UPDATE SAFEKEEPING.SSK_WEB_FORM_HEADER SET
              PLEDGE_TYPE           = #{quote(TRANSACTION_CODE[broker_instructions['transaction_code']])},
              TRADE_DATE            = #{quote(broker_instructions['trade_date'])},
              REQUEST_STATUS        = #{quote(SETTLEMENT_TYPE[broker_instructions['settlement_type']])},
              SETTLE_DATE           = #{quote(broker_instructions['settlement_date'])},
              DELIVER_TO            = #{quote(DELIVERY_TYPE[delivery_type])},
              FORM_TYPE             = #{quote(ADXAccountTypeMapping::SYMBOL_TO_SSK_FORM_TYPE[adx_type])},
              LAST_MODIFIED_BY      = #{quote(format_modification_by(user_name, session_id))},
              LAST_MODIFIED_DATE    = #{quote(Time.zone.today)},
              LAST_MODIFIED_BY_NAME = #{quote(full_name)},
              #{ADXAccountTypeMapping::SYMBOL_TO_SQL_COLUMN_NAME[adx_type]} = #{quote(adx_id)},
              #{delivery_columns.each_with_index.collect{|column_name, i| "#{column_name} = #{delivery_values[i]}"}.join(', ') }
            WHERE HEADER_ID = #{quote(header_id)}
            AND FHLB_ID = #{quote(member_id)}
            AND STATUS = #{quote(SSKRequestStatus::SUBMITTED)}
          SQL
        end
        def self.update_transfer_header_details_query(member_id, header_id, user_name, full_name, session_id, adx_id, un_adx_id, broker_instructions, kind)
          <<-SQL
            UPDATE SAFEKEEPING.SSK_WEB_FORM_HEADER SET
              TRADE_DATE                = #{quote(broker_instructions['trade_date'])},
              REQUEST_STATUS            = #{quote(SETTLEMENT_TYPE[broker_instructions['settlement_type']])},
              SETTLE_DATE               = #{quote(broker_instructions['settlement_date'])},
              #{KIND_TRANSFER_MAPPING[kind][:account_column_name]}        = #{quote(SSKDeliverTo::INTERNAL_TRANSFER)},
              FORM_TYPE                 = #{quote(ADXAccountTypeMapping::SYMBOL_TO_SSK_FORM_TYPE[KIND_TRANSFER_MAPPING[kind][:adx_type]])},
              LAST_MODIFIED_BY          = #{quote(format_modification_by(user_name, session_id))},
              LAST_MODIFIED_DATE        = #{quote(Time.zone.today)},
              LAST_MODIFIED_BY_NAME     = #{quote(full_name)},
              PLEDGED_ADX_ID            = #{quote(adx_id)},
              UNPLEGED_TRANSFER_ADX_ID  = #{quote(un_adx_id)},
              PLEDGE_TO                 = #{quote(PLEDGE_TO[broker_instructions['pledge_to']])}
            WHERE HEADER_ID = #{quote(header_id)}
            AND FHLB_ID = #{quote(member_id)}
            AND STATUS = #{quote(SSKRequestStatus::SUBMITTED)}
          SQL
        end

        def self.update_request_security_query(header_id, user_name, session_id, security, detail_id)
          <<-SQL
            UPDATE SAFEKEEPING.SSK_WEB_FORM_DETAIL SET
              DESCRIPTION        = #{quote(security['description'])},
              ORIGINAL_PAR       = #{quote(nil_to_zero(security['original_par']))},
              PAYMENT_AMOUNT     = #{quote(nil_to_zero(security['payment_amount']))},
              LAST_MODIFIED_DATE = #{quote(Time.zone.today)},
              LAST_MODIFIED_BY   = #{quote(format_modification_by(user_name, session_id))}
            WHERE DETAIL_ID = #{quote(detail_id)}
            AND HEADER_ID = #{quote(header_id)}
          SQL
        end

        def self.delete_request_securities_by_cusip_query(request_id, cusips)
          quoted_cusips = cusips.collect { |cusip| quote(cusip) }.join(',')
          <<-SQL
            DELETE FROM SAFEKEEPING.SSK_WEB_FORM_DETAIL
            WHERE HEADER_ID = #{quote(request_id)}
            AND CUSIP NOT IN (#{quoted_cusips})
          SQL
        end

        def self.create_intake(app, member_id, user_name, full_name, session_id, broker_instructions, delivery_instructions, securities, kind)
          validate_kind(:intake, kind)
          pledged_or_unpledged = adx_type_for_intake(kind)
          validate_delivery_instructions(delivery_instructions)
          validate_securities(securities, broker_instructions['settlement_type'], delivery_instructions['delivery_type'], :intake)
          validate_broker_instructions(broker_instructions, app, kind)
          processed_delivery_instructions = process_delivery_instructions(delivery_instructions)
          user_name.downcase!
          unless should_fake?(app)
            header_id = execute_sql_single_result(app, NEXT_ID_SQL, "Next ID Sequence").to_i
            ActiveRecord::Base.transaction do
              adx_id = execute_sql_single_result(app, adx_query(member_id, pledged_or_unpledged), "ADX ID")
              insert_header_sql = insert_intake_header_query( member_id, header_id, user_name, full_name, session_id,
                                                              adx_id, processed_delivery_instructions[:delivery_columns],
                                                              broker_instructions, processed_delivery_instructions[:delivery_type],
                                                              processed_delivery_instructions[:delivery_values], pledged_or_unpledged)
              raise "failed to insert security intake request header" unless execute_sql(app.logger, insert_header_sql)
              securities.each do |security|
                insert_security_sql = insert_security_query(header_id, execute_sql_single_result(app, NEXT_ID_SQL, "Next ID Sequence").to_i, user_name, session_id, security, nil)
                raise "failed to insert security intake request detail" unless execute_sql(app.logger, insert_security_sql)
              end
            end
          else
            header_id = rand(100000..999999)
          end
          header_id
        end

        def self.update_intake(app, member_id, request_id, user_name, full_name, session_id, broker_instructions, delivery_instructions, securities, kind)
          validate_kind(:intake, kind)
          pledged_or_unpledged = adx_type_for_intake(kind)
          original_delivery_instructions = delivery_instructions.clone # Used to see if header details have changes below
          validate_securities(securities, broker_instructions['settlement_type'], delivery_instructions['delivery_type'], :intake)
          validate_broker_instructions(broker_instructions, app, kind)
          validate_delivery_instructions(delivery_instructions)
          processed_delivery_instructions = process_delivery_instructions(delivery_instructions)
          unless should_fake?(app)
            ActiveRecord::Base.transaction(isolation: :read_committed) do
              cusips = securities.collect{|x| x['cusip']}
              raise MAPI::Shared::Errors::SQLError, 'Failed to delete old security release request detail by CUSIP' unless execute_sql(app.logger, delete_request_securities_by_cusip_query(request_id, cusips))
              adx_id = execute_sql_single_result(app, adx_query(member_id, pledged_or_unpledged), 'Get ADX ID from ADX Type')
              existing_securities = format_securities(fetch_hashes(app.logger, release_request_securities_query(request_id)))
              securities.each do |security|
                existing_security = existing_securities.find { |old_security| old_security[:cusip] == security['cusip'] }
                if existing_security && security_has_changed(security, existing_security)
                  update_security_sql = update_request_security_query(request_id, user_name, session_id, security, existing_security[:detail_id])
                  raise MAPI::Shared::Errors::SQLError, 'Failed to update security intake request detail' unless execute_sql(app.logger, update_security_sql)
                elsif !existing_security
                  detail_id = execute_sql_single_result(app, NEXT_ID_SQL, 'Next ID Sequence').to_i
                  insert_security_sql = insert_security_query(request_id, detail_id, user_name, session_id, security, nil)
                  raise MAPI::Shared::Errors::SQLError, 'Failed to insert new security intake request detail' unless execute_sql(app.logger, insert_security_sql)
                end
                existing_securities.delete(existing_security)
              end
              existing_header = fetch_hash(app.logger, request_header_details_query(member_id, request_id))
              raise MAPI::Shared::Errors::SQLError, 'No header details found to update' unless existing_header
              existing_header = map_hash_values(existing_header, REQUEST_HEADER_MAPPING)
              if header_has_changed(existing_header, broker_instructions, original_delivery_instructions)
                update_header_sql = update_request_header_details_query(member_id, request_id, user_name, full_name,
                  session_id, adx_id, processed_delivery_instructions[:delivery_columns], broker_instructions,
                  processed_delivery_instructions[:delivery_type], processed_delivery_instructions[:delivery_values], pledged_or_unpledged, :intake)
                header_update_count = execute_sql(app.logger, update_header_sql).to_i
                raise MAPI::Shared::Errors::SQLError, 'No header details found to update' unless header_update_count == 1
              end
            end
          end
          true
        end

        def self.create_release(app, member_id, user_name, full_name, session_id, broker_instructions, delivery_instructions, securities, kind)
          validate_kind(:release, kind)
          validate_delivery_instructions(delivery_instructions)
          validate_securities(securities, broker_instructions['settlement_type'], delivery_instructions['delivery_type'], :release)
          adx_type = get_adx_type_from_security(app, securities.first)
          validate_broker_instructions(broker_instructions, app, kind)
          processed_delivery_instructions = process_delivery_instructions(delivery_instructions)
          user_name.downcase!
          unless should_fake?(app)
            header_id = execute_sql_single_result(app, NEXT_ID_SQL, "Next ID Sequence").to_i
            ActiveRecord::Base.transaction do
              adx_id = execute_sql_single_result(app, adx_query(member_id, adx_type), "ADX ID")
              insert_header_sql = insert_release_header_query(member_id,
                                                              header_id,
                                                              user_name,
                                                              full_name,
                                                              session_id,
                                                              adx_id,
                                                              processed_delivery_instructions[:delivery_columns],
                                                              broker_instructions,
                                                              processed_delivery_instructions[:delivery_type],
                                                              processed_delivery_instructions[:delivery_values],
                                                              adx_type)
              raise "failed to insert security release request header" unless execute_sql(app.logger, insert_header_sql)
              securities.each do |security|
                ssk_id = execute_sql_single_result(app, ssk_id_query(member_id, adx_id, security['cusip']), "SSK ID")
                raise "failed to retrieve SSK_ID for security with CUSIP #{security['cusip']}" unless ssk_id
                insert_security_sql = insert_security_query(header_id, execute_sql_single_result(app, NEXT_ID_SQL, "Next ID Sequence").to_i, user_name, session_id, security, ssk_id)
                raise "failed to insert security release request detail" unless execute_sql(app.logger, insert_security_sql)
              end
            end
          else
            header_id = rand(100000..999999)
          end
          header_id
        end

        def self.update_release(app, member_id, request_id, user_name, full_name, session_id, broker_instructions, delivery_instructions, securities, kind)
          validate_kind(:release, kind)
          original_delivery_instructions = delivery_instructions.clone # Used to see if header details have changes below
          validate_securities(securities, broker_instructions['settlement_type'], delivery_instructions['delivery_type'], :release)
          adx_type = get_adx_type_from_security(app, securities.first)
          validate_broker_instructions(broker_instructions, app, kind)
          validate_delivery_instructions(delivery_instructions)
          processed_delivery_instructions = process_delivery_instructions(delivery_instructions)
          unless should_fake?(app)
            ActiveRecord::Base.transaction(isolation: :read_committed) do
              cusips = securities.collect{|x| x['cusip']}
              raise MAPI::Shared::Errors::SQLError, 'Failed to delete old security release request detail by CUSIP' unless execute_sql(app.logger, delete_request_securities_by_cusip_query(request_id, cusips))
              adx_id = execute_sql_single_result(app, adx_query(member_id, adx_type), 'Get ADX ID from ADX Type')
              existing_securities = format_securities(fetch_hashes(app.logger, release_request_securities_query(request_id)))
              securities.each do |security|
                existing_security = existing_securities.find { |old_security| old_security[:cusip] == security['cusip'] }
                if existing_security && security_has_changed(security, existing_security)
                  update_security_sql = update_request_security_query(request_id, user_name, session_id, security, existing_security[:detail_id])
                  raise MAPI::Shared::Errors::SQLError, 'Failed to update security release request detail' unless execute_sql(app.logger, update_security_sql)
                elsif !existing_security
                  ssk_id = execute_sql_single_result(app, ssk_id_query(member_id, adx_id, security['cusip']), 'SSK ID')
                  raise "failed to retrieve SSK_ID for security with CUSIP #{security['cusip']}" unless ssk_id
                  detail_id = execute_sql_single_result(app, NEXT_ID_SQL, 'Next ID Sequence').to_i
                  insert_security_sql = insert_security_query(request_id, detail_id, user_name, session_id, security, ssk_id)
                  raise MAPI::Shared::Errors::SQLError, 'Failed to insert new security release request detail' unless execute_sql(app.logger, insert_security_sql)
                end
                existing_securities.delete(existing_security)
              end
              existing_header = fetch_hash(app.logger, request_header_details_query(member_id, request_id))
              raise MAPI::Shared::Errors::SQLError, 'No header details found to update' unless existing_header
              existing_header = map_hash_values(existing_header, REQUEST_HEADER_MAPPING)
              if header_has_changed(existing_header, broker_instructions, original_delivery_instructions)
                update_header_sql = update_request_header_details_query(member_id, request_id, user_name, full_name,
                  session_id, adx_id, processed_delivery_instructions[:delivery_columns], broker_instructions,
                  processed_delivery_instructions[:delivery_type], processed_delivery_instructions[:delivery_values], adx_type, :release)
                header_update_count = execute_sql(app.logger, update_header_sql).to_i
                raise MAPI::Shared::Errors::SQLError, 'No header details found to update' unless header_update_count == 1
              end
            end
          end
          true
        end

        def self.set_broker_instructions_for_transfer(broker_instructions, kind)
          today = Time.zone.today.iso8601
          broker_instructions['settlement_type'] ||= kind == :pledge_transfer ? 'free' : 'vs_payment'
          broker_instructions['trade_date'] ||= today
          broker_instructions['settlement_date'] ||= today
          broker_instructions['transaction_code'] ||= 'standard'
        end

        def self.create_transfer(app, member_id, user_name, full_name, session_id, broker_instructions, securities, kind)
          validate_kind(:transfer, kind)
          set_broker_instructions_for_transfer(broker_instructions, kind)
          validate_securities(securities, broker_instructions['settlement_type'], :transfer, kind)
          validate_broker_instructions(broker_instructions, app, kind)
          user_name.downcase!
          unless should_fake?(app)
            header_id = execute_sql_single_result(app, NEXT_ID_SQL, "Next ID Sequence").to_i
            ActiveRecord::Base.transaction do
              adx_id = execute_sql_single_result(app, adx_query(member_id, :pledged), "ADX ID")
              un_adx_id = execute_sql_single_result(app, adx_query(member_id, :unpledged), "ADX ID")
              insert_header_sql = insert_transfer_header_query(member_id,
                                                              header_id,
                                                              user_name,
                                                              full_name,
                                                              session_id,
                                                              adx_id,
                                                              un_adx_id,
                                                              broker_instructions,
                                                              kind)
              raise "failed to insert security release request header" unless execute_sql(app.logger, insert_header_sql)
              securities.each do |security|
                final_adx_id = (kind == :safekept_transfer ? adx_id : un_adx_id)
                ssk_id = execute_sql_single_result(app, ssk_id_query(member_id, final_adx_id, security['cusip']), "SSK ID")
                raise "failed to retrieve SSK_ID for security with CUSIP #{security['cusip']}" unless ssk_id
                insert_security_sql = insert_security_query(header_id, execute_sql_single_result(app, NEXT_ID_SQL, "Next ID Sequence").to_i, user_name, session_id, security, ssk_id)
                raise "failed to insert security release request detail" unless execute_sql(app.logger, insert_security_sql)
              end
            end
          else
            header_id = rand(100000..999999)
          end
          header_id
        end

        def self.update_transfer(app, member_id, request_id, user_name, full_name, session_id, broker_instructions, securities, kind)
          validate_kind(:transfer, kind)
          set_broker_instructions_for_transfer(broker_instructions, kind)
          validate_securities(securities, broker_instructions['settlement_type'], :transfer, kind)
          validate_broker_instructions(broker_instructions, app, kind)
          unless should_fake?(app)
            ActiveRecord::Base.transaction(isolation: :read_committed) do
              cusips = securities.collect{|x| x['cusip']}
              raise MAPI::Shared::Errors::SQLError, 'Failed to delete old security transfer request detail by CUSIP' unless execute_sql(app.logger, delete_request_securities_by_cusip_query(request_id, cusips))
              adx_id = execute_sql_single_result(app, adx_query(member_id, :pledged), "ADX ID")
              un_adx_id = execute_sql_single_result(app, adx_query(member_id, :unpledged), "UN_ADX ID")
              existing_securities = format_securities(fetch_hashes(app.logger, release_request_securities_query(request_id)))
              securities.each do |security|
                existing_security = existing_securities.find { |old_security| old_security[:cusip] == security['cusip'] }
                if existing_security && security_has_changed(security, existing_security)
                  update_security_sql = update_request_security_query(request_id, user_name, session_id, security, existing_security[:detail_id])
                  raise MAPI::Shared::Errors::SQLError, 'Failed to update security transfer request detail' unless execute_sql(app.logger, update_security_sql)
                elsif !existing_security
                  ssk_id = execute_sql_single_result(app, ssk_id_query(member_id, adx_id, security['cusip']), 'SSK ID')
                  raise "failed to retrieve SSK_ID for security with CUSIP #{security['cusip']}" unless ssk_id
                  detail_id = execute_sql_single_result(app, NEXT_ID_SQL, 'Next ID Sequence').to_i
                  insert_security_sql = insert_security_query(request_id, detail_id, user_name, session_id, security, ssk_id)
                  raise MAPI::Shared::Errors::SQLError, 'Failed to insert new security transfer request detail' unless execute_sql(app.logger, insert_security_sql)
                end
                existing_securities.delete(existing_security)
              end
              existing_header = fetch_hash(app.logger, request_header_details_query(member_id, request_id))
              raise MAPI::Shared::Errors::SQLError, 'No header details found to update' unless existing_header
              existing_header = map_hash_values(existing_header, REQUEST_HEADER_MAPPING)
              if header_has_changed(existing_header, broker_instructions)
                update_header_sql = update_transfer_header_details_query(member_id,
                                                                        request_id,
                                                                        user_name,
                                                                        full_name,
                                                                        session_id,
                                                                        adx_id,
                                                                        un_adx_id,
                                                                        broker_instructions,
                                                                        kind)
                header_update_count = execute_sql(app.logger, update_header_sql).to_i
                raise MAPI::Shared::Errors::SQLError, 'No header details found to update' unless header_update_count == 1
              end
            end
          end
          true
        end

        def self.security_has_changed(new_security, old_security)
          new_security = new_security.with_indifferent_access
          old_security = old_security.with_indifferent_access
          [:original_par, :payment_amount].each do |integer_key|
            new_security[integer_key] = new_security[integer_key].to_i
            old_security[integer_key] = old_security[integer_key].to_i
          end
          new_security != old_security
        end

        def self.header_has_changed(existing_header, broker_instructions, delivery_instructions=nil)
          existing_header = existing_header.with_indifferent_access
          old_broker_instructions = broker_instructions_from_header_details(existing_header).with_indifferent_access
          if delivery_instructions
            old_delivery_instructions = delivery_instructions_from_header_details(existing_header).with_indifferent_access
            !(old_broker_instructions == broker_instructions.with_indifferent_access && old_delivery_instructions == delivery_instructions.with_indifferent_access)
          else
            !(old_broker_instructions == broker_instructions.with_indifferent_access)
          end
        end

        def self.request_header_details_query(member_id, header_id)
          <<-SQL
            SELECT PLEDGE_TYPE, REQUEST_STATUS, TRADE_DATE, SETTLE_DATE, DELIVER_TO, BROKER_WIRE_ADDR, ABA_NO, DTC_AGENT_PARTICIPANT_NO,
              MUTUAL_FUND_COMPANY, DELIVERY_BANK_AGENT, REC_BANK_AGENT_NAME, REC_BANK_AGENT_ADDR, CREDIT_ACCT_NO1, CREDIT_ACCT_NO2,
              MUTUAL_FUND_ACCT_NO, CREDIT_ACCT_NO3, CREATED_BY, CREATED_BY_NAME, PLEDGED_ADX_ID, UNPLEDGED_ADX_ID, FORM_TYPE, PLEDGE_TO,
              UNPLEGED_TRANSFER_ADX_ID, SIGNED_DATE AS AUTHORIZED_DATE, SIGNED_BY_NAME AS AUTHORIZED_BY
            FROM SAFEKEEPING.SSK_WEB_FORM_HEADER
            WHERE HEADER_ID = #{quote(header_id)}
            AND FHLB_ID = #{quote(member_id)}
          SQL
        end

        def self.release_request_securities_query(header_id)
          <<-SQL
            SELECT DETAIL_ID, CUSIP, DESCRIPTION, ORIGINAL_PAR, PAYMENT_AMOUNT
            FROM SAFEKEEPING.SSK_WEB_FORM_DETAIL
            WHERE HEADER_ID = #{quote(header_id)}
          SQL
        end

        def self.request_details(app, member_id, request_id)
          if should_fake?(app)
            header_details = fake_header_details_array(member_id).select{|header| header['REQUEST_ID'] == request_id}.first
            securities = fake_securities(request_id, header_details['REQUEST_STATUS'])
          else
            header_details = fetch_hash(app.logger, request_header_details_query(member_id, request_id))
            securities = fetch_hashes(app.logger, release_request_securities_query(request_id))
          end
          raise MAPI::Shared::Errors::SQLError, 'No header details found' unless header_details
          raise MAPI::Shared::Errors::SQLError, 'No securities found' unless securities
          kind = kind_from_details(header_details)
          header_details = map_hash_values(header_details, REQUEST_HEADER_MAPPING).with_indifferent_access
          securities.collect do |security|
            map_hash_values(security, RELEASE_REQUEST_SECURITIES_MAPPING).with_indifferent_access
          end
          safekept_account = [:pledge_transfer, :safekept_transfer].include?(kind) ? header_details['UNPLEGED_TRANSFER_ADX_ID'] : header_details['UNPLEDGED_ADX_ID']
          {
            request_id: request_id,
            safekept_account: safekept_account,
            pledged_account: header_details['PLEDGED_ADX_ID'],
            form_type: header_details['FORM_TYPE'],
            broker_instructions: broker_instructions_from_header_details(header_details),
            delivery_instructions: delivery_instructions_from_header_details(header_details),
            securities: format_securities(securities),
            authorized_date: header_details['AUTHORIZED_DATE'],
            authorized_by: header_details['AUTHORIZED_BY'],
            user: {
              username: header_details['CREATED_BY'],
              full_name: header_details['CREATED_BY_NAME'],
              session_id: nil
            }
          }
        end

        def self.broker_instructions_from_header_details(header)
          {
            transaction_code: header['PLEDGE_TYPE'],
            settlement_type: header['REQUEST_STATUS'],
            trade_date: header['TRADE_DATE'],
            settlement_date: header['SETTLE_DATE'],
            pledge_to: header['PLEDGE_TO']
          }
        end

        def self.delivery_instructions_from_header_details(header)
          delivery_type = header['DELIVER_TO'] || header['RECEIVE_FROM']
          delivery_type_mapping = delivery_type_mapping(delivery_type)
          required_delivery_keys = delivery_keys_for_delivery_type(delivery_type)
          delivery_instructions = {
            delivery_type: delivery_type
          }
          required_delivery_keys.each do |delivery_key|
            delivery_instructions[delivery_key] = header[delivery_type_mapping[delivery_key]] unless delivery_key == 'clearing_agent_fed_wire_address'
          end
          if required_delivery_keys.include?('clearing_agent_fed_wire_address')
            addresses = header[delivery_type_mapping['clearing_agent_fed_wire_address']].split('/', 2)
            delivery_instructions['clearing_agent_fed_wire_address_1'] = addresses.shift
            delivery_instructions['clearing_agent_fed_wire_address_2'] = addresses.shift
          end
          delivery_instructions
        end

        def self.format_securities(securities)
          securities.collect do |security|
            {
              detail_id: security['DETAIL_ID'],
              cusip: security['CUSIP'],
              description: security['DESCRIPTION'],
              original_par: security['ORIGINAL_PAR'],
              payment_amount: security['PAYMENT_AMOUNT']
            }
          end
        end

        def self.fake_header_details_array(member_id, start_date = nil)
          today = Time.zone.today
          rng = Random.new(member_id.to_i + today.to_time.to_i)
          start_date ||= today
          list = []
          # require at least one form_type of every type of request
          form_type_status_combos = []
          REQUEST_FORM_TYPE_MAPPING.keys.each do |form_type|
            flat_unique_array(REQUEST_STATUS_MAPPING.values).each do |status|
              form_type_status_combos << [form_type, (DELIVERY_TYPE.values - [SSKDeliverTo::INTERNAL_TRANSFER]).sample(random: rng), status]
              form_type_status_combos << [form_type, SSKDeliverTo::INTERNAL_TRANSFER, status] if [SSKFormType::SECURITIES_PLEDGED, SSKFormType::SECURITIES_RELEASE].include?(form_type)
            end
          end
          form_type_status_combos.shuffle(random: rng)
          length = form_type_status_combos.length
          rng.rand(length..(length*2)).times do
            request_id = fake_request_id(rng)
            combo = form_type_status_combos.pop
            form_type = combo.try(:first) || REQUEST_FORM_TYPE_MAPPING.keys.sample(random: rng)
            status = combo.try(:last) || flat_unique_array(REQUEST_STATUS_MAPPING.values).sample(random: rng)
            delivery_type = combo.try(:[], 1)
            list << fake_header_details(request_id, status, form_type, delivery_type, start_date)
          end
          list
        end

        def self.fake_header_details(request_id, status, form_type = nil, delivery_type = nil, start_date = nil)
          start_date ||= Time.zone.today
          end_date = start_date + 7.days
          rng = Random.new(request_id)
          fake_data = fake('securities_requests')
          names = fake_data['names']
          pledge_type = TRANSACTION_CODE.values.sample(random: rng)
          request_status = SETTLEMENT_TYPE.values.sample(random: rng)
          transfer_form_types = [SSKFormType::SECURITIES_PLEDGED, SSKFormType::SAFEKEPT_DEPOSIT]
          form_type ||= rng.rand(70..73)
          delivery_type ||= (DELIVERY_TYPE.values.select {|type| type != SSKDeliverTo::INTERNAL_TRANSFER || transfer_form_types.include?(form_type) } ).sample(random: rng)
          delivery_field = transfer_form_types.include?(form_type) ? 'RECEIVE_FROM' : 'DELIVER_TO'
          aba_number = rng.rand(10000..99999)
          participant_number = rng.rand(10000..99999)
          account_number = rng.rand(10000..99999)
          submitted_date = rng.rand(start_date..end_date)
          authorized = MAPIRequestStatus::AUTHORIZED.include?(status)
          authorized_date = submitted_date + rng.rand(0..2).days
          created_by_offset = rng.rand(0..names.length-1)
          created_by = fake_data['usernames'][created_by_offset]
          created_by_name = names[created_by_offset]
          authorized_by_name = names.sample(random: rng)
          safekept_account_number = rng.rand(1000..9999)
          pledge_to = PLEDGE_TO.values.sample(random: rng)
          {
            'REQUEST_ID' => request_id,
            'PLEDGE_TYPE' => pledge_type,
            'REQUEST_STATUS' => request_status,
            delivery_field => delivery_type,
            'BROKER_WIRE_ADDR' => '0541254875/FIRST TENN',
            'ABA_NO' => aba_number,
            'DTC_AGENT_PARTICIPANT_NO' => participant_number,
            'MUTUAL_FUND_COMPANY' => "Mutual Funds R'Us",
            'DELIVERY_BANK_AGENT' => 'MI6',
            'REC_BANK_AGENT_NAME' => 'James Bond',
            'REC_BANK_AGENT_ADDR' => '600 Mulberry Court, Boston, MA, 42893',
            'CREDIT_ACCT_NO1' => account_number,
            'CREDIT_ACCT_NO2' => account_number,
            'MUTUAL_FUND_ACCT_NO' => account_number,
            'CREDIT_ACCT_NO3' => account_number,
            'SETTLE_DATE' => (authorized ? authorized_date : submitted_date) + 1.days,
            'TRADE_DATE' => submitted_date,
            'CREATED_BY' => created_by,
            'CREATED_BY_NAME' => created_by_name,
            'FORM_TYPE' => form_type,
            'STATUS' => status,
            'SUBMITTED_DATE' => submitted_date,
            'SUBMITTED_BY' => created_by_name,
            'AUTHORIZED_BY' => authorized ? authorized_by_name : nil,
            'AUTHORIZED_DATE' => authorized ? authorized_date : nil,
            'PLEDGE_TO' => pledge_to,
            'PLEDGED_ADX_ID' => rng.rand(1000..9999),
            'UNPLEDGED_ADX_ID' => safekept_account_number,
            'UNPLEGED_TRANSFER_ADX_ID' => safekept_account_number
          }
        end

        def self.fake_securities(request_id, settlement_type)
          rng = Random.new(request_id)
          securities = []
          fake_data = fake('securities_requests')
          rng.rand(1..6).times do
            original_par = rng.rand(10000..999999)
            securities << {
              'DETAIL_ID' => fake_data['detail_ids'].sample(random: rng),
              'CUSIP' => fake_data['cusips'].sample(random: rng),
              'DESCRIPTION' => fake_data['descriptions'].sample(random: rng),
              'ORIGINAL_PAR' => original_par,
              'PAYMENT_AMOUNT' => (original_par - (original_par/3) if settlement_type == SSKSettlementType::VS_PAYMENT)
            }
          end
          securities
        end

        def self.fake_request_id(rng)
          rng.rand(100000..999999)
        end

        def self.authorize_request(app, member_id, request_id, user_name, full_name, session_id)
          signer_id = nil
          unless should_fake?(app)
            begin
              signer_id = execute_sql_single_result(app, MAPI::Services::Users.signer_id_query(user_name), 'Signer ID')
            rescue MAPI::Shared::Errors::SQLError => e
              raise ArgumentError, 'Signer Not Found'
            end
          end
          query = authorize_request_query(member_id, request_id, user_name, full_name, session_id, signer_id)
          record_count = 0
          if should_fake?(app)
            record_count = 1
          else
            record_count = ActiveRecord::Base.connection.execute(query)
          end
          record_count == 1
        end

        def self.delete_request_header_details_query(member_id, header_id)
          <<-SQL
            DELETE FROM SAFEKEEPING.SSK_WEB_FORM_HEADER
            WHERE HEADER_ID = #{quote(header_id)}
            AND FHLB_ID = #{quote(member_id)}
            AND STATUS = #{quote(SSKRequestStatus::SUBMITTED)}
          SQL
        end

        def self.delete_request_securities_query(header_id)
          <<-SQL
            DELETE FROM SAFEKEEPING.SSK_WEB_FORM_DETAIL
            WHERE HEADER_ID = #{quote(header_id)}
          SQL
        end

        def self.delete_request(app, member_id, request_id)
          header_delete_count = 0
          if should_fake?(app)
            header_delete_count = 1
          else
            connection = ActiveRecord::Base.connection
            connection.transaction(isolation: :read_committed) do
              connection.execute(delete_request_securities_query(request_id))
              header_delete_count = connection.execute(delete_request_header_details_query(member_id, request_id)) || 0
              raise ActiveRecord::Rollback, 'No header details found to delete' unless header_delete_count > 0
            end
          end
          header_delete_count > 0
        end

        def self.adx_type_query(cusip)
          <<-SQL
            SELECT ACCOUNT_TYPE
            FROM SAFEKEEPING.SSK_INTRADAY_SEC_POSITION
            WHERE SSK_CUSIP = #{quote(cusip)}
          SQL
        end

        def self.get_adx_type_from_security(app, security)
          raise ArgumentError, 'security must not be nil' unless security
          if should_fake?(app)
            ADXAccountTypeMapping::SYMBOL_TO_STRING.keys.sample(random: Random.new(security['cusip'].bytes.inject(0, :+)))
          else
            ADXAccountTypeMapping::STRING_TO_SYMBOL[execute_sql_single_result(app, adx_type_query(security['cusip']), 'Get ADX type for a security')]
          end
        end

        def self.kind_from_details(request_details)
          form_type = request_details['FORM_TYPE']
          case form_type
          when SSKFormType::SECURITIES_PLEDGED
            if request_details['RECEIVE_FROM'] == SSKDeliverTo::INTERNAL_TRANSFER
              :pledge_transfer
            else
              :pledge_intake
            end
          when SSKFormType::SECURITIES_RELEASE
            if request_details['DELIVER_TO'] == SSKDeliverTo::INTERNAL_TRANSFER
              :safekept_transfer
            else
              :pledge_release
            end
          when SSKFormType::SAFEKEPT_RELEASE
            :safekept_release
          when SSKFormType::SAFEKEPT_DEPOSIT
            :safekept_intake
          else
            raise ArgumentError, "unknown form_type: #{form_type}"
          end
        end

        def self.adx_type_for_intake(kind)
          kind == :pledge_intake ? :pledged : :unpledged
        end
      end
    end
  end
end