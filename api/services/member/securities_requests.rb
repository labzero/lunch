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
              rng.rand(1..7).times do
                request_id = rng.rand(100000..999999)
                status = flat_status[rng.rand(0..flat_status.length-1)]
                list << fake_header_details(request_id, end_date, status)
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

        def self.insert_release_header_query(member_id, header_id, user_name, full_name, session_id, pledged_adx_id, delivery_columns, broker_instructions, delivery_type, delivery_values)
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
                    #{quote(format_username(user_name))},
                    #{quote(full_name)},
                    #{quote(format_modification_by(user_name, session_id))},
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
                    #{quote(format_username(user_name))},
                    #{quote(now)},
                    #{quote(format_modification_by(user_name, session_id))},
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

        def self.format_modification_by(username, session_id)
          (format_username(username) + '\\\\' + session_id)[0..LAST_MODIFIED_BY_MAX_LENGTH - 1]
        end

        def self.format_username(username)
          username.downcase
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

        def self.release_request_header_details_query(member_id, header_id)
          <<-SQL
            SELECT PLEDGE_TYPE, REQUEST_STATUS, TRADE_DATE, SETTLE_DATE, DELIVER_TO, BROKER_WIRE_ADDR, ABA_NO, DTC_AGENT_PARTICIPANT_NO,
              MUTUAL_FUND_COMPANY, DELIVERY_BANK_AGENT, REC_BANK_AGENT_NAME, REC_BANK_AGENT_ADDR, CREDIT_ACCT_NO1, CREDIT_ACCT_NO2,
              MUTUAL_FUND_ACCT_NO, CREDIT_ACCT_NO3, CREATED_BY, CREATED_BY_NAME
            FROM SAFEKEEPING.SSK_WEB_FORM_HEADER
            WHERE HEADER_ID = #{quote(header_id)}
            AND FHLB_ID = #{quote(member_id)}
          SQL
        end

        def self.release_request_securities_query(header_id)
          <<-SQL
            SELECT CUSIP, DESCRIPTION, ORIGINAL_PAR, PAYMENT_AMOUNT
            FROM SAFEKEEPING.SSK_WEB_FORM_DETAIL
            WHERE HEADER_ID = #{quote(header_id)}
          SQL
        end

        RELEASE_REQUEST_HEADER_MAPPING = {
          Proc.new { |value| TRANSACTION_CODE.invert[value.to_i] } => ['PLEDGE_TYPE'],
          Proc.new { |value| SETTLEMENT_TYPE.invert[value.to_i] } => ['REQUEST_STATUS'],
          Proc.new { |value| DELIVERY_TYPE.invert[value.to_i] } => ['DELIVER_TO'],
          to_s: ['BROKER_WIRE_ADDR', 'ABA_NO', 'DTC_AGENT_PARTICIPANT_NO', 'MUTUAL_FUND_COMPANY', 'DELIVERY_BANK_AGENT',
                 'REC_BANK_AGENT_NAME', 'REC_BANK_AGENT_ADDR', 'CREDIT_ACCT_NO1', 'CREDIT_ACCT_NO2', 'MUTUAL_FUND_ACCT_NO',
                 'CREDIT_ACCT_NO3', 'CREATED_BY', 'CREATED_BY_NAME'],
          to_date: ['SETTLE_DATE', 'TRADE_DATE']
        }

        RELEASE_REQUEST_SECURITIES_MAPPING = {
          to_s: ['CUSIP', 'DESCRIPTION'],
          to_i: ['ORIGINAL_PAR', 'PAYMENT_AMOUNT']
        }

        def self.release_details(app, member_id, request_id)
          if should_fake?(app)
            header_details = fake_header_details(request_id, Time.zone.today, MAPIRequestStatus::AWAITING_AUTHORIZATION.first)
            securities = fake_securities(request_id, header_details['REQUEST_STATUS'])
          else
            header_details = fetch_hash(app.logger, release_request_header_details_query(member_id, request_id))
            securities = fetch_hashes(app.logger, release_request_securities_query(request_id))
          end
          raise MAPI::Shared::Errors::SQLError, 'No header details found' unless header_details
          raise MAPI::Shared::Errors::SQLError, 'No securities found' unless securities
          header_details = map_hash_values(header_details, RELEASE_REQUEST_HEADER_MAPPING).with_indifferent_access
          securities.collect do |security|
            map_hash_values(security, RELEASE_REQUEST_SECURITIES_MAPPING).with_indifferent_access
          end
          {
            request_id: request_id,
            broker_instructions: broker_instructions_from_header_details(header_details),
            delivery_instructions: delivery_instructions_from_header_details(header_details),
            securities: format_securities(securities),
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
            settlement_date: header['SETTLE_DATE']
          }
        end

        def self.delivery_instructions_from_header_details(header)
          delivery_type = header['DELIVER_TO']
          delivery_type_mapping = delivery_type_mapping(delivery_type)
          required_delivery_keys = delivery_keys_for_delivery_type(delivery_type)
          delivery_instructions = {
            delivery_type: delivery_type
          }
          required_delivery_keys.each do |delivery_key|
            delivery_instructions[delivery_key] = header[delivery_type_mapping[delivery_key]]
          end
          delivery_instructions
        end
        
        def self.format_securities(securities)
          securities.collect do |security|
            {
              cusip: security['CUSIP'],
              description: security['DESCRIPTION'],
              original_par: security['ORIGINAL_PAR'],
              payment_amount: security['PAYMENT_AMOUNT']
            }
          end
        end

        def self.fake_header_details(request_id, end_date, status)
          rng = Random.new(request_id)
          fake_data = fake('securities_release_request_details')
          names = fake_data['names']
          pledge_type = TRANSACTION_CODE.values[rng.rand(0..1)]
          request_status = SETTLEMENT_TYPE.values[rng.rand(0..1)]
          delivery_type = DELIVERY_TYPE.values[rng.rand(0..3)]
          aba_number = rng.rand(10000..99999)
          participant_number = rng.rand(10000..99999)
          account_number = rng.rand(10000..99999)
          submitted_date = end_date - rng.rand(0..4).days
          authorized = MAPIRequestStatus::AUTHORIZED.include?(status)
          authorized_date = submitted_date + rng.rand(0..2).days
          created_by_offset = rng.rand(0..names.length-1)
          created_by = fake_data['usernames'][created_by_offset]
          created_by_name = names[created_by_offset]
          {
            'REQUEST_ID' => request_id,
            'PLEDGE_TYPE' => pledge_type,
            'REQUEST_STATUS' => request_status,
            'DELIVER_TO' => delivery_type,
            'BROKER_WIRE_ADDR' => '123 Fake St., Anywhere, USA',
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
            'FORM_TYPE' => rng.rand(70..73),
            'STATUS' => status,
            'SUBMITTED_DATE' => submitted_date,
            'SUBMITTED_BY' => created_by_name,
            'AUTHORIZED_BY' => authorized ? names[rng.rand(0..names.length-1)] : nil,
            'AUTHORIZED_DATE' => authorized ? authorized_date : nil
          }
        end

        def self.fake_securities(request_id, settlement_type)
          rng = Random.new(request_id)
          securities = []
          fake_data = fake('securities_release_request_details')
          rng.rand(1..6).times do
            original_par = rng.rand(10000..999999)
            securities << {
              'CUSIP' => fake_data['cusips'][rng.rand(0..5)],
              'DESCRIPTION' => fake_data['descriptions'][rng.rand(0..5)],
              'ORIGINAL_PAR' => original_par,
              'PAYMENT_AMOUNT' => (original_par - (original_par/3) if settlement_type == SSKSettlementType::VS_PAYMENT)
            }
          end
          securities
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
      end
    end
  end
end