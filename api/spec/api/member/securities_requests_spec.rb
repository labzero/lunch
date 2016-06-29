require 'spec_helper'

describe MAPI::ServiceApp do
  include MAPI::Shared::Utils
  describe 'Securities Requests' do
    let(:securities_request_module) { MAPI::Services::Member::SecuritiesRequests }
    describe 'GET `/securities/requests`' do
      let(:response) { double('response', to_json: nil) }
      let(:call_endpoint) { get "/member/#{member_id}/securities/requests"}
      before do
        allow(securities_request_module).to receive(:requests).and_return(response)
      end

      it 'calls `MAPI::Services::Member::SecuritiesRequests.requests` with an instance of the MAPI::Service app `member_id` param' do
        expect(securities_request_module).to receive(:requests).with(an_instance_of(MAPI::ServiceApp), any_args)
        call_endpoint
      end
      it 'calls `MAPI::Services::Member::SecuritiesRequests.requests` with the `member_id` param' do
        expect(securities_request_module).to receive(:requests).with(anything, member_id, any_args)
        call_endpoint
      end
      [:authorized, :awaiting_authorization].each do |status|
        mapped_status = MAPI::Services::Member::SecuritiesRequests::REQUEST_STATUS_MAPPING[status]
        it "calls `MAPI::Services::Member::SecuritiesRequests.requests` with `#{mapped_status}` if `#{status}` is passed as the status param" do
          expect(securities_request_module).to receive(:requests).with(anything, anything, mapped_status, any_args)
          get "/member/#{member_id}/securities/requests", status: status
        end
      end
      it 'calls `MAPI::Services::Member::SecuritiesRequests.requests` with `nil` for status if no status is passed' do
        expect(securities_request_module).to receive(:requests).with(anything, anything, nil, any_args)
        call_endpoint
      end
      it 'calls `MAPI::Services::Member::SecuritiesRequests.requests` with `nil` for status if the status param is not `:authorized` or `:awaiting_authorization`' do
        expect(securities_request_module).to receive(:requests).with(anything, anything, nil, any_args)
        get "/member/#{member_id}/securities/requests", status: SecureRandom.hex
      end
      it 'calls `MAPI::Services::Member::SecuritiesRequests.requests` with a range from a hundred years ago to today if no date params are passed' do
        end_date = Time.zone.today
        start_date = (end_date - 100.years)
        expect(securities_request_module).to receive(:requests).with(anything, anything, anything, (start_date..end_date))
        call_endpoint
      end
      it 'calls `MAPI::Services::Member::SecuritiesRequests.requests` with a range calculated from the date params' do
        end_date = (Time.zone.today - rand(10..20).days)
        start_date = (end_date - rand(1..25).years)
        expect(securities_request_module).to receive(:requests).with(anything, anything, anything, (start_date..end_date))
        get "/member/#{member_id}/securities/requests", settle_start_date: start_date, settle_end_date: end_date
      end
    end

    describe '`MAPI::Services::Member::SecuritiesRequests.requests`' do
      let(:app) { double(MAPI::ServiceApp, logger: double('logger')) }
      let(:call_method) { MAPI::Services::Member::SecuritiesRequests.requests(app, member_id) }

      describe 'when using fake data' do
        names = fake('securities_request_names')
        let(:rng) { instance_double(Random) }
        let(:submit_offset) { rand(0..4) }
        let(:authorized_offset) { rand(0..2) }
        let(:request_id) { rand(100000..999999) }
        let(:form_type) { rand(70..73) }
        let(:submitted_date) { Time.zone.today - submit_offset.days }
        let(:authorized_date) { submitted_date + authorized_offset.days }
        let(:submitted_by_offset) { rand(0..names.length-1) }
        let(:authorized_by_offset) { rand(0..names.length-1) }
        before do
          allow(securities_request_module).to receive(:should_fake?).and_return(true)
          allow(Random).to receive(:new).and_return(rng)
          allow(rng).to receive(:rand).and_return(1, submit_offset, authorized_offset, 0, request_id, form_type, submitted_by_offset, authorized_by_offset)
        end

        it 'constructs a list of request objects' do
          n = rand(1..7)
          allow(rng).to receive(:rand).with(1..7).and_return(n)
          expect(call_method.length).to eq(n)
        end
        it 'constructs request objects with a `REQUEST_ID` to pass to `map_hash_values`' do
          expect(securities_request_module).to receive(:map_hash_values).with(hash_including('REQUEST_ID' => request_id), any_args).and_return({})
          call_method
        end
        it 'constructs request objects with a `FORM_TYPE` to pass to `map_hash_values`' do
          expect(securities_request_module).to receive(:map_hash_values).with(hash_including('FORM_TYPE' => form_type), any_args).and_return({})
          call_method
        end
        it 'constructs request objects with a `STATUS` to pass to `map_hash_values`' do
          expect(securities_request_module).to receive(:map_hash_values).with(hash_including('STATUS' => 85), any_args).and_return({})
          call_method
        end
        it 'constructs request objects with a `SETTLE_DATE` to pass to `map_hash_values`' do
          expect(securities_request_module).to receive(:map_hash_values).with(hash_including('SETTLE_DATE' => authorized_date + 1.day), any_args).and_return({})
          call_method
        end
        it 'constructs request objects with a `SUBMITTED_DATE` to pass to `map_hash_values`' do
          expect(securities_request_module).to receive(:map_hash_values).with(hash_including('SUBMITTED_DATE' => submitted_date), any_args).and_return({})
          call_method
        end
        it 'constructs request objects with a `SUBMITTED_BY` to pass to `map_hash_values`' do
          expect(securities_request_module).to receive(:map_hash_values).with(hash_including('SUBMITTED_BY' => names[submitted_by_offset]), any_args).and_return({})
          call_method
        end
        it 'constructs request objects with a `AUTHORIZED_BY` to pass to `map_hash_values`' do
          expect(securities_request_module).to receive(:map_hash_values).with(hash_including('AUTHORIZED_BY' => names[authorized_by_offset]), any_args).and_return({})
          call_method
        end
        it 'constructs request objects with a `AUTHORIZED_DATE` to pass to `map_hash_values`' do
          expect(securities_request_module).to receive(:map_hash_values).with(hash_including('AUTHORIZED_DATE' => authorized_date), any_args).and_return({})
          call_method
        end
      end
      describe 'when using real data' do
        let(:request_query) { double('request query') }
        before do
          allow(securities_request_module).to receive(:should_fake?).and_return(false)
          allow(securities_request_module).to receive(:requests_query).and_return(request_query)
          allow(securities_request_module).to receive(:fetch_hashes).and_return([])
        end
        it 'calls `fetch_hashes` with the logger' do
          expect(securities_request_module).to receive(:fetch_hashes).with(app.logger, anything).and_return([])
          call_method
        end
        it 'calls `fetch_hashes` with the result of `requests_query`' do
          expect(securities_request_module).to receive(:fetch_hashes).with(anything, request_query).and_return([])
          call_method
        end
        it 'calls `requests_query` with the member id' do
          expect(securities_request_module).to receive(:requests_query).with(member_id, any_args).and_return(request_query)
          call_method
        end
        it 'calls `requests_query` with the flattened array for `MAPIRequestStatus::AUTHORIZED` if no status is passed' do
          statuses = Array.wrap(MAPI::Services::Member::SecuritiesRequests::MAPIRequestStatus::AUTHORIZED).flatten.uniq
          expect(securities_request_module).to receive(:requests_query).with(anything, statuses, anything).and_return(request_query)
          call_method
        end
        it 'calls `requests_query` with the flattened array for `MAPIRequestStatus::AWAITING_AUTHORIZATION` if that status is passed' do
          statuses = Array.wrap(MAPI::Services::Member::SecuritiesRequests::MAPIRequestStatus::AWAITING_AUTHORIZATION).flatten.uniq
          expect(securities_request_module).to receive(:requests_query).with(anything, statuses, anything).and_return(request_query)
          MAPI::Services::Member::SecuritiesRequests.requests(app, member_id, MAPI::Services::Member::SecuritiesRequests::MAPIRequestStatus::AWAITING_AUTHORIZATION)
        end
        it 'calls `requests_query` with the date range if one is passed' do
          end_date = (Time.zone.today - rand(10..20).days)
          start_date = (end_date - rand(1..25).years)
          date_range = (start_date..end_date)
          expect(securities_request_module).to receive(:requests_query).with(anything, anything, date_range).and_return(request_query)
          MAPI::Services::Member::SecuritiesRequests.requests(app, member_id, nil, date_range)
        end
        it 'calls `requests_query` with a date range encompassing the last week if no range is passed' do
          end_date = Time.zone.today
          start_date = end_date - 7.days
          date_range = (start_date..end_date)
          expect(securities_request_module).to receive(:requests_query).with(anything, anything, date_range).and_return(request_query)
          call_method
        end
        it 'returns a mapped hash value for each request it finds' do
          n = rand(1..10)
          fetched_hashes = []
          n.times { fetched_hashes << {} }
          allow(securities_request_module).to receive(:fetch_hashes).and_return(fetched_hashes)
          allow(securities_request_module).to receive(:map_hash_values).and_return({})
          expect(call_method.length).to eq(n)
        end
        it 'passes each request to `map_hash_values` with the `REQUEST_VALUE_MAPPING` and an arg of `true` for downcasing' do
          request = double('request')
          mapping = MAPI::Services::Member::SecuritiesRequests::REQUEST_VALUE_MAPPING
          allow(securities_request_module).to receive(:fetch_hashes).and_return([request])
          expect(securities_request_module).to receive(:map_hash_values).with(request, mapping, true).and_return({})
          call_method
        end
      end
    end

    describe '`MAPI::Services::Member::SecuritiesRequests.requests_query`' do
      it 'constructs proper SQL based on the member_id, status array and date range it is passed' do
        status_array = [SecureRandom.hex, SecureRandom.hex, SecureRandom.hex]
        quoted_statuses = status_array.collect { |status| "'#{status}'" }.join(',')
        end_date = Time.zone.today - rand(1..10).days
        start_date = end_date - rand(1..10).days
        date_range = (start_date..end_date)

        sql = <<-SQL
            SELECT HEADER_ID AS REQUEST_ID, FORM_TYPE, SETTLE_DATE, CREATED_DATE AS SUBMITTED_DATE, CREATED_BY_NAME AS SUBMITTED_BY,
            SIGNED_BY_NAME AS AUTHORIZED_BY, SIGNED_DATE AS AUTHORIZED_DATE, STATUS FROM SAFEKEEPING.SSK_WEB_FORM_HEADER
            WHERE FHLB_ID = #{member_id} AND STATUS IN (#{quoted_statuses}) AND SETTLE_DATE >= TO_DATE('#{start_date}','YYYY-MM-DD HH24:MI:SS')
            AND SETTLE_DATE <= TO_DATE('#{end_date}','YYYY-MM-DD HH24:MI:SS')
        SQL
        expect(MAPI::Services::Member::SecuritiesRequests.requests_query(member_id, status_array, date_range)).to eq(sql)
      end
    end

    describe '`MAPI::Services::Member::SecuritiesRequests.create_release`' do
      let(:app) { double(MAPI::ServiceApp, logger: double('logger')) }
      let(:member_id) { rand(9999..99999) }
      let(:header_id) { rand(9999..99999) }
      let(:detail_id) { rand(9999..99999) }
      let(:trade_date) { (Time.zone.today - rand(1..10).days).strftime }
      let(:settlement_date) { (Time.zone.today - rand(1..10).days).strftime }
      let(:broker_instructions) { { 'transaction_code' => rand(0..1) == 0 ? 'standard' : 'repo',
                                    'trade_date' => trade_date,
                                    'settlement_type' => rand(0..1) == 0 ? 'free' : 'vs_payment',
                                    'settlement_date' => settlement_date } }
      let(:delivery_type) { [ 'fed', 'dtc', 'mutual_fund', 'physical_securities' ][rand(0..3)] }
      let(:delivery_columns) { [ SecureRandom.hex, SecureRandom.hex, SecureRandom.hex ] }
      let(:delivery_values) { [ SecureRandom.hex, SecureRandom.hex, SecureRandom.hex ] }
      let(:security) { {  'cusip' => SecureRandom.hex,
                          'description' => SecureRandom.hex,
                          'original_par' => rand(1..100000) + rand.round(2),
                          'payment_amount' => rand(1..100000) + rand.round(2) } }
      let(:required_delivery_keys) { [ 'a', 'b', 'c' ] }
      let(:delivery_columns) { MAPI::Services::Member::SecuritiesRequests.delivery_type_mapping(delivery_type).keys }
      let(:delivery_values) { MAPI::Services::Member::SecuritiesRequests.delivery_type_mapping(delivery_type).values }
      let(:form_type) { MAPI::Services::Member::SecuritiesRequests::SSKFormType::SecuritiesRelease }
      let(:user_name) {  SecureRandom.hex }
      let(:full_name) { SecureRandom.hex }
      let(:session_id) { SecureRandom.hex }
      let(:pledged_adx_id) { rand(1000..10000) }
      let(:ssk_id) { rand(1000..10000) }

      describe '`delivery_keys_for_delivery_type`' do
        it 'returns the correct delivery types for `SSKDeliverTo::FED`' do
          expect(MAPI::Services::Member::SecuritiesRequests.delivery_keys_for_delivery_type('fed')).to eq(
            [ 'account_number', 'clearing_agent_fed_wire_address', 'aba_number' ])
        end

        it 'returns the correct delivery types for `SSKDeliverTo::DTC`' do
          expect(MAPI::Services::Member::SecuritiesRequests.delivery_keys_for_delivery_type('dtc')).to eq(
            [ 'account_number', 'clearing_agent_participant_number' ])
        end

        it 'returns the correct delivery types for `SSKDeliverTo::MUTUAL_FUND`' do
          expect(MAPI::Services::Member::SecuritiesRequests.delivery_keys_for_delivery_type('mutual_fund')).to eq(
            [ 'account_number', 'mutual_fund_company' ])
        end

        it 'returns the correct delivery types for `SSKDeliverTo::PHYSICAL_SECURITIES`' do
          expect(MAPI::Services::Member::SecuritiesRequests.delivery_keys_for_delivery_type('physical_securities')).to eq(
            [ 'account_number', 'delivery_bank_agent', 'receiving_bank_agent_name', 'receiving_bank_agent_address' ])
        end
      end

      describe '`insert_release_header_query`' do
        let(:call_method) { MAPI::Services::Member::SecuritiesRequests.insert_release_header_query( member_id,
                                                                                                    header_id,
                                                                                                    user_name,
                                                                                                    full_name,
                                                                                                    session_id,
                                                                                                    pledged_adx_id,
                                                                                                    delivery_columns,
                                                                                                    broker_instructions,
                                                                                                    delivery_type,
                                                                                                    delivery_values ) }
        it 'expands delivery columns into the insert statement' do
          expect(call_method).to match(
            /\A\s*INSERT\s+INTO\s+SAFEKEEPING\.SSK_WEB_FORM_HEADER\s+\(HEADER_ID,\s+FHLB_ID,\s+STATUS,\s+PLEDGE_TYPE,\s+TRADE_DATE,\s+REQUEST_STATUS,\s+SETTLE_DATE,\s+DELIVER_TO,\s+FORM_TYPE,\s+CREATED_DATE,\s+CREATED_BY,\s+CREATED_BY_NAME,\s+LAST_MODIFIED_BY,\s+LAST_MODIFIED_DATE,\s+LAST_MODIFIED_BY_NAME,\s+PLEDGED_ADX_ID,\s+#{delivery_columns.join(',\s+')}/)
        end

        it 'sets the `header_id`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).and_return(header_id)
          expect(call_method).to match /VALUES\s\(#{header_id},/
        end

        it 'sets the `member_id`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).and_return(member_id)
          expect(call_method).to match /VALUES\s+\((\S+\s+){1}#{member_id}/
        end

        it 'sets the `status`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).and_return(MAPI::Services::Member::SecuritiesRequests::SSKRequestStatus::SUBMITTED)
          expect(call_method).to match /VALUES\s+\((\S+\s+){2}#{MAPI::Services::Member::SecuritiesRequests::SSKRequestStatus::SUBMITTED}/
        end

        it 'sets the `transaction_code`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).and_return(broker_instructions['pledge_type'])
          expect(call_method).to match /VALUES\s+\((\S+\s+){3}#{broker_instructions[:pledge_type]}/
        end

        it 'sets the `trade_date`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).and_return(broker_instructions['trade_date'])
          expect(call_method).to match /VALUES\s+\((\S+\s+){4}#{broker_instructions[:trade_date]}/
        end

        it 'sets the `settlement_type`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).and_return(broker_instructions['settlement_type'])
          expect(call_method).to match /VALUES\s+\((\S+\s+){5}#{broker_instructions[:settlement_type]}/
        end

        it 'sets the `settlement_date`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).and_return(broker_instructions['settlement_date'])
          expect(call_method).to match /VALUES\s+\((\S+\s+){6}#{broker_instructions[:settlement_date]}/
        end

        it 'sets the `delivery_type`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).and_return(delivery_type)
          expect(call_method).to match /VALUES\s+\((\S+\s+){7}#{delivery_type}/
        end

        it 'sets the `form_type`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).and_return(form_type)
          expect(call_method).to match /VALUES\s+\((\S+\s+){8}#{form_type}/
        end

        it 'sets the `created_date`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).and_return(Time.zone.today)
          expect(call_method).to match /VALUES\s+\((\S+\s+){9}#{Time.zone.today}/
        end

        it 'sets the `created_by`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).and_return(user_name)
          expect(call_method).to match /VALUES\s+\((\S+\s+){10}#{user_name}/
        end

        it 'sets the `created_by_name`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).and_return(full_name)
          expect(call_method).to match /VALUES\s+\((\S+\s+){11}#{full_name}/
        end

        it 'sets the `last_modified_by`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).and_return(user_name + '\\\\' + session_id)
          expect(call_method).to match /VALUES\s+\((\S+\s+){12}#{user_name + '\\\\\\\\' + session_id}/
        end

        it 'sets the `last_modified_date`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).and_return(Time.zone.today)
          expect(call_method).to match /VALUES\s+\((\S+\s+){13}#{Time.zone.today}/
        end

        it 'sets the `last_modified_by_name`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).and_return(full_name)
          expect(call_method).to match /VALUES\s+\((\S+\s+){14}#{full_name}/
        end

        it 'sets the `pledged_adx_id`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).and_return(pledged_adx_id)
          expect(call_method).to match /VALUES\s+\((\S+\s+){15}#{pledged_adx_id}/
        end

        describe 'delivery values' do
          before do
            allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).and_return(broker_instructions['trade_date'])
          end
          it 'sets the `delivery_values`' do
            allow(MAPI::Services::Member::SecuritiesRequests).to receive(:format_delivery_values).and_return(delivery_values.join(', '))
            expect(call_method).to match /VALUES\s+\((\S+\s+){16}#{delivery_values.join(',\s+')}/
          end
        end
      end

      describe '`insert_security_query`' do
        let(:call_method) { MAPI::Services::Member::SecuritiesRequests.insert_security_query(header_id, detail_id, user_name, session_id, security, ssk_id) }

        it 'constructs an insert statement with the appropriate column names' do
          expect(call_method).to match(
            /\A\s*INSERT\s+INTO\s+SAFEKEEPING\.SSK_WEB_FORM_DETAIL\s+\(DETAIL_ID,\s+HEADER_ID,\s+CUSIP,\s+DESCRIPTION,\s+ORIGINAL_PAR,\s+PAYMENT_AMOUNT,\s+CREATED_DATE,\s+CREATED_BY,\s+LAST_MODIFIED_DATE,\s+LAST_MODIFIED_BY/)
        end

        it 'sets the `detail_id`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).and_return(detail_id)
          expect(call_method).to match(/VALUES\s+\(#{detail_id}/)
        end

        it 'sets the `header_id`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).and_return(header_id)
          expect(call_method).to match(/VALUES\s+\((\S+\s+){1}#{header_id}/)
        end

        it 'sets the `cusip`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).and_return(security['cusip'])
          expect(call_method).to match(/VALUES\s+\((\S+\s+){2}#{security[:cusip]}/)
        end

        it 'sets the `description`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).and_return(security['description'])
          expect(call_method).to match(/VALUES\s+\((\S+\s+){3}#{security[:description]}/)
        end

        it 'sets the `original_par`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).and_return(security['original_par'])
          expect(call_method).to match(/VALUES\s+\((\S+\s+){4}#{security[:original_par]}/)
        end

        it 'sets the `payment_amount`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).and_return(security['payment_amount'])
          expect(call_method).to match(/VALUES\s+\((\S+\s+){5}#{security[:payment_amount]}/)
        end

        it 'sets the `created_date`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).and_return(Time.zone.today)
          expect(call_method).to match(/VALUES\s+\((\S+\s+){6}#{Time.zone.today}/)
        end

        it 'sets the `created_by`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).and_return(user_name)
          expect(call_method).to match(/VALUES\s+\((\S+\s+){7}#{user_name}/)
        end

        it 'sets the `last_modified_date`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).and_return(Time.zone.today)
          expect(call_method).to match(/VALUES\s+\((\S+\s+){8}#{Time.zone.today}/)
        end

        it 'sets the `last_modified_by`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).and_return(user_name + '\\\\' + session_id)
          expect(call_method).to match(/VALUES\s+\((\S+\s+){9}#{user_name + '\\\\\\\\' + session_id}/)
        end
      end

      describe '`format_delivery_columns`' do
        let(:provided_delivery_keys) { rand(1..5).times.map { SecureRandom.hex } }
        let(:delivery_type) { MAPI::Services::Member::SecuritiesRequests::DELIVERY_TYPE.keys[rand(0..3)] }
        let(:required_delivery_keys) { MAPI::Services::Member::SecuritiesRequests.delivery_keys_for_delivery_type(delivery_type) }
        let(:call_method) { MAPI::Services::Member::SecuritiesRequests.format_delivery_columns(delivery_type,
          required_delivery_keys, provided_delivery_keys) }

        it 'raises an `ArgumentError` if required keys are missing' do
          expect { call_method }.to raise_error(ArgumentError, /delivery_instructions must contain \S+/)
        end

        context 'maps values correctly' do
          let(:provided_delivery_keys) { MAPI::Services::Member::SecuritiesRequests.delivery_keys_for_delivery_type(delivery_type) }
          it 'maps values using delivery type mappings' do
            expect(call_method).to eq(
              required_delivery_keys.map { |key|
                MAPI::Services::Member::SecuritiesRequests.delivery_type_mapping(delivery_type)[key] })
          end
        end
      end

      describe '`format_delivery_values`' do
        let(:delivery_instruction_value) { SecureRandom.hex }
        let(:d1) { SecureRandom.hex }
        let(:d2) { SecureRandom.hex }
        let(:d3) { SecureRandom.hex }
        let(:delivery_instructions) { { 'a' => d1, 'b' => d2, 'c' => d3 } }

        let(:call_method) { MAPI::Services::Member::SecuritiesRequests.format_delivery_values(required_delivery_keys,
          delivery_instructions) }

        it 'calls `quote` on the delivery instruction value' do
          [d1, d2, d3].each do |key|
            expect(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(key)
          end
          call_method
        end

        it 'maps keys to values in `delivery_instructions`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).and_return(delivery_instruction_value)
          expect(call_method).to eq([delivery_instruction_value, delivery_instruction_value, delivery_instruction_value])
        end
      end

      context 'executing a single result sql statement' do
        let(:sql) { double('SQL Statement') }
        let(:description) { SecureRandom.hex }
        let(:single_result) { double('The Single Result') }
        let(:results_array) { instance_double(Array, first: single_result) }
        let(:cursor) { double('cursor', fetch: results_array) }
        let(:call_method) { MAPI::Services::Member::SecuritiesRequests.execute_sql_single_result(app, sql, description) }

        before do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:execute_sql).with(app.logger, sql).and_return(cursor)
        end

        it 'raises an error if sequence call returns nil' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:execute_sql).with(app.logger, sql).and_return(nil)
          expect { call_method }.to raise_error(MAPI::Shared::Errors::SQLError, "#{description} returned nil")
        end

        it 'calls `fetch` on the cusor' do
          expect(cursor).to receive(:fetch).and_return(results_array)
          call_method
        end

        it 'raises an error if `fetch` returns nil' do
          allow(cursor).to receive(:fetch).and_return(nil)
          expect { call_method }.to raise_error(MAPI::Shared::Errors::SQLError, "Calling fetch on the cursor returned nil")
        end

        context 'handling the results array' do
          before do
            allow(cursor).to receive(:fetch).and_return(results_array)
          end

          it 'calls `first` on the results array' do
            expect(results_array).to receive(:first).and_return(single_result)
            call_method
          end

          it 'raises an error if calling `first` on results returns nil' do
            allow(results_array).to receive(:first).and_return(nil)
            expect { call_method }.to raise_error(MAPI::Shared::Errors::SQLError, "Calling first on the record set returned nil")
          end

          context 'gets the record' do
            before do
              allow(results_array).to receive(:first).and_return(single_result)
            end

            it 'returns result' do
              expect(call_method).to eq(single_result)
            end
          end
        end
      end

      describe '`pledged_adx_query`' do
        let(:call_method) { MAPI::Services::Member::SecuritiesRequests.pledged_adx_query(member_id) }

        before do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).and_return(member_id)
        end

        it 'constructs the appropriate sql' do
          expect(call_method).to eq(<<-SQL
            SELECT ADX.ADX_ID
            FROM SAFEKEEPING.ACCOUNT_DOCKET_XREF ADX, SAFEKEEPING.BTC_ACCOUNT_TYPE BAT, SAFEKEEPING.CUSTOMER_PROFILE CP
            WHERE ADX.BAT_ID = BAT.BAT_ID
            AND ADX.CP_ID = CP.CP_ID
            AND CP.FHLB_ID = #{member_id}
            AND UPPER(SUBSTR(BAT.BAT_ACCOUNT_TYPE,1,1)) = 'P'
            AND CONCAT(TRIM(TRANSLATE(ADX.ADX_BTC_ACCOUNT_NUMBER,' 0123456789',' ')), '*') = '*'
            AND (BAT.BAT_ACCOUNT_TYPE NOT LIKE '%DB%' AND BAT.BAT_ACCOUNT_TYPE NOT LIKE '%REIT%')
            ORDER BY TO_NUMBER(ADX.ADX_BTC_ACCOUNT_NUMBER) ASC
            SQL
          )
        end
      end

      describe '`ssk_id_query`' do
        let(:cusip) { SecureRandom.hex }
        let(:call_method) { MAPI::Services::Member::SecuritiesRequests.ssk_id_query(member_id, pledged_adx_id, cusip) }

        before do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(member_id).and_return(member_id)
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(pledged_adx_id).and_return(pledged_adx_id)
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(cusip).and_return(cusip)
        end

        it 'constructs the appropriate sql' do
          expect(call_method).to eq(<<-SQL
            SELECT SSK.SSK_ID
            FROM SAFEKEEPING.SSK SSK, SAFEKEEPING.SSK_TRANS SSKT
            WHERE UPPER(SSK.SSK_CUSIP) = UPPER(#{cusip})
            AND SSK.FHLB_ID = #{member_id}
            AND SSK.ADX_ID = #{pledged_adx_id}
            AND SSKT.SSK_ID = SSK.SSK_ID
            AND SSKT.SSX_BTC_DATE = (SELECT MAX(SSX_BTC_DATE) FROM SAFEKEEPING.SSK_TRANS)
            SQL
          )
        end
      end

      describe '`create_release method`' do
        let(:app) { double(MAPI::ServiceApp, logger: double('logger')) }
        let(:member_id) { rand(100000..999999) }
        let(:delivery_type) { MAPI::Services::Member::SecuritiesRequests::DELIVERY_TYPE.keys[rand(0..3)] }
        let(:delivery_instructions) {
          MAPI::Services::Member::SecuritiesRequests.delivery_keys_for_delivery_type(delivery_type).map do |key|
            [key, SecureRandom.hex]
          end.to_h.merge('delivery_type' => delivery_type) }
        let(:securities) { [ security, security, security ]}
        let(:call_method) { MAPI::Services::Member::SecuritiesRequests.create_release(app,
                                                                                      member_id,
                                                                                      user_name,
                                                                                      full_name,
                                                                                      session_id,
                                                                                      broker_instructions,
                                                                                      delivery_instructions,
                                                                                      securities) }
        context 'validations' do
          before do
            allow(securities_request_module).to receive(:should_fake?).and_return(true)
          end

          context 'missing broker_instructions' do
            let(:broker_instructions) { nil }
            it 'raises an error if `broker_instructions` is nil' do
              expect{ call_method }.to raise_error(ArgumentError, "broker_instructions must be a non-empty hash")
            end
          end

          context 'missing delivery_instructions' do
            let(:delivery_instructions) { nil }
            it 'raises an error if `delivery_instructions` is nil' do
              expect{ call_method }.to raise_error(ArgumentError, "delivery_instructions must be a non-empty hash")
            end
          end

          context 'missing values in broker_instructions' do
            before do
              broker_instructions.delete(broker_instructions.keys[rand(0..3)])
            end

            it 'raises an error if something is missing' do
              expect{ call_method }.to raise_error(ArgumentError, /broker_instructions must contain a value for \S+/)
            end
          end

          context 'incorrect `transaction_code`' do
            before do
              broker_instructions['transaction_code'] = SecureRandom.hex
            end

            it 'raises an error if `transaction_code` is out of range' do
              expect{ call_method }.to raise_error(ArgumentError, /transaction_code must be set to one of the following values: \S/)
            end
          end

          context 'incorrect `settlement_type`' do
            before do
              broker_instructions['settlement_type'] = SecureRandom.hex
            end

            it 'raises an error if `settlement_type` is out of range' do
              expect{ call_method }.to raise_error(ArgumentError, /settlement_type must be set to one of the following values: \S/)
            end
          end

          context 'incorrect `delivery_type`' do
            before do
              delivery_instructions['delivery_type'] = SecureRandom.hex
            end
            it 'raises an error if `delivery_type` is out of range' do
              expect{ call_method }.to raise_error(ArgumentError, /delivery_instructions must contain the key delivery_type set to one of \S/)
            end
          end

          context 'missing `securities`' do
            let(:securities) { nil }
            it 'raises an error if `securities` is nil' do
              expect{ call_method }.to raise_error(ArgumentError, "securities must be an array containing at least one security")
            end
          end

          context 'empty `securities`' do
            let(:securities) { [ ] }
            it 'raises an error if `securities` is empty' do
              expect{ call_method }.to raise_error(ArgumentError, "securities must be an array containing at least one security")
            end
          end

          context do
            before do
              allow(MAPI::Services::Member::SecuritiesRequests).to receive(:format_delivery_columns).and_return(
                delivery_columns)
              allow(MAPI::Services::Member::SecuritiesRequests).to receive(:format_delivery_values).and_return(
                delivery_values)
            end

            it 'calls `dateify` on `trade_date`' do
              allow(MAPI::Services::Member::SecuritiesRequests).to receive(:dateify).with(settlement_date)
              expect(MAPI::Services::Member::SecuritiesRequests).to receive(:dateify).with(trade_date)
              call_method
            end

            it 'calls `dateify` on `settlement_date`' do
              allow(MAPI::Services::Member::SecuritiesRequests).to receive(:dateify).with(trade_date)
              expect(MAPI::Services::Member::SecuritiesRequests).to receive(:dateify).with(settlement_date)
              call_method
            end

            it 'calls `delete(:delivery_type)` on `delivery_instructions`' do
              expect(delivery_instructions).to receive(:delete).with('delivery_type').and_return(delivery_type)
              call_method
            end

            it 'raises an `ArgumentError` if `delivery_type` is out of range' do
              allow(delivery_instructions).to receive(:delete).with('delivery_type').and_return(SecureRandom.hex)
              expect { call_method }.to raise_error(ArgumentError, "delivery_instructions must contain the key delivery_type set to one of fed, dtc, mutual_fund, physical_securities")
            end
          end

          context 'securities validation' do
            context do
              let(:securities) { nil }
              it 'raises an `ArgumentError` if securities is nil' do
                expect { call_method }.to raise_error(ArgumentError, "securities must be an array containing at least one security")
              end
            end

            context do
              let(:securities) { {} }
              it 'raises an `ArgumentError` if securities is not an array' do
                expect { call_method }.to raise_error(ArgumentError, "securities must be an array containing at least one security")
              end
            end

            context do
              let(:securities) { [] }
              it 'raises an `ArgumentError` if the securities array is empty' do
                expect { call_method }.to raise_error(ArgumentError, "securities must be an array containing at least one security")
              end
            end

            context do
              let(:securities) { [ security, nil, security ] }
              it 'raises an `ArgumentError` if the securities array contains a `nil`' do
                expect { call_method }.to raise_error(ArgumentError, "each security must be a non-empty hash")
              end
            end

            context do
              let(:securities) { [ security, [], security ] }
              it 'raises an `ArgumentError` if the securities array contains a non-hash value' do
                expect { call_method }.to raise_error(ArgumentError, "each security must be a non-empty hash")
              end
            end

            context do
              let(:broker_instructions) { { 'transaction_code' => rand(0..1) == 0 ? 'standard' : 'repo',
                                            'trade_date' => trade_date,
                                            'settlement_type' => 'free',
                                            'settlement_date' => settlement_date } }
              let(:security_without_cusip) { { 'description' => SecureRandom.hex,
                                               'original_par' => rand(1..100000) + rand.round(2),
                                               'payment_amount' => rand(1..100000) + rand.round(2) } }
              let(:securities) { [ security, security_without_cusip, security ] }
              it 'raises an `ArgumentError` if a security is missing a key' do
                expect { call_method }.to raise_error(ArgumentError, /each security must consist of a hash containing a value for \S+/)
              end
            end

            context do
              let(:broker_instructions) { { 'transaction_code' => rand(0..1) == 0 ? 'standard' : 'repo',
                                            'trade_date' => trade_date,
                                            'settlement_type' => 'vs_payment',
                                            'settlement_date' => settlement_date } }
              let(:security_without_payment_amount) { { 'cusip' => SecureRandom.hex,
                                                        'description' => SecureRandom.hex,
                                                        'original_par' => rand(1..100000) + rand.round(2) } }
              let(:securities) { [ security, security_without_payment_amount, security ] }
              it 'raises an `ArgumentError` if `settlement_type` is `vs_payment` and `payment_amount` is missing' do
                expect { call_method }.to raise_error(ArgumentError, /each security must consist of a hash containing a value for payment_amount/)
              end
            end
          end
          it 'passes all validations' do
            expect { call_method }.to_not raise_error
          end
        end

        context 'preparing and executing SQL' do
          let(:next_id) { double('Next ID') }
          let(:sequence_result) { double('Sequence Result', to_i: next_id) }
          let(:pledged_adx_sql) { double('Pledged ADX SQL') }
          let(:ssk_sql) { double('SSK SQL') }
          before do
            allow(MAPI::Services::Member::SecuritiesRequests).to receive(:format_delivery_columns).and_return(
              delivery_columns)
            allow(MAPI::Services::Member::SecuritiesRequests).to receive(:format_delivery_values).and_return(
              delivery_values)
            allow(securities_request_module).to receive(:should_fake?).and_return(false)
            allow(securities_request_module).to receive(:pledged_adx_query).with(member_id).and_return(pledged_adx_sql)
            allow(securities_request_module).to receive(:ssk_id_query).with(member_id, pledged_adx_id, security['cusip']).
              exactly(3).times.and_return(ssk_sql)
            allow(securities_request_module).to receive(:execute_sql_single_result).with(
              app,
              MAPI::Services::Member::SecuritiesRequests::NEXT_ID_SQL,
              "Next ID Sequence").and_return(sequence_result)
            allow(securities_request_module).to receive(:execute_sql_single_result).with(
              app,
              pledged_adx_sql,
              "Pledged ADX ID").and_return(pledged_adx_id)
            allow(securities_request_module).to receive(:execute_sql_single_result).with(
              app,
              ssk_sql,
              "SSK ID").and_return(ssk_id)
          end

          context 'calls `execute_sql`' do
            let(:insert_header_sql) { double('Insert Header SQL') }
            let(:insert_security_sql) { double('Insert Security SQL') }

            before do
              allow(MAPI::Services::Member::SecuritiesRequests).to receive(:insert_release_header_query).with(
                member_id,
                next_id,
                user_name,
                full_name,
                session_id,
                pledged_adx_id,
                delivery_columns,
                broker_instructions,
                delivery_type,
                delivery_values).and_return(insert_header_sql)
              allow(MAPI::Services::Member::SecuritiesRequests).to receive(:insert_security_query).with(next_id,
                next_id, user_name, session_id, security, ssk_id).exactly(3).times.and_return(insert_security_sql)
            end

            it 'inserts the header' do
              allow(MAPI::Services::Member::SecuritiesRequests).to receive(:execute_sql).with(app.logger,
                insert_security_sql).exactly(3).times.and_return(true)
              expect(MAPI::Services::Member::SecuritiesRequests).to receive(:execute_sql).with(app.logger,
                insert_header_sql).and_return(true)
              call_method
            end

            it 'inserts the securities' do
              allow(MAPI::Services::Member::SecuritiesRequests).to receive(:execute_sql).with(app.logger,
                insert_header_sql).and_return(true)
              expect(MAPI::Services::Member::SecuritiesRequests).to receive(:execute_sql).with(app.logger,
                insert_security_sql).exactly(3).times.and_return(true)
              call_method
            end

            it 'raises errors for SQL failures on header insert' do
              allow(MAPI::Services::Member::SecuritiesRequests).to receive(:execute_sql).with(app.logger,
                insert_header_sql).and_return(false)
              expect { call_method }.to raise_error(Exception)
            end

            it 'raises errors for SQL failures on securities insert' do
              allow(MAPI::Services::Member::SecuritiesRequests).to receive(:execute_sql).with(app.logger,
                insert_header_sql).and_return(true)
              allow(MAPI::Services::Member::SecuritiesRequests).to receive(:execute_sql).with(app.logger,
                insert_security_sql).and_return(false)
              expect { call_method }.to raise_error(Exception)
            end
          end
        end
      end
    end
  end
end