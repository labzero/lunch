require 'spec_helper'

describe MAPI::ServiceApp do
  include MAPI::Shared::Utils
  describe 'Securities Requests' do
    let(:adx_type) { [:pledged, :unpledged].sample }
    let(:adx_type_string) { MAPI::Services::Member::SecuritiesRequests::ADXAccountTypeMapping::SYMBOL_TO_STRING[adx_type] }
    let(:form_type) { MAPI::Services::Member::SecuritiesRequests::ADXAccountTypeMapping::SYMBOL_TO_SSK_FORM_TYPE["#{adx_type}_release".to_sym] }
    let(:kind) { double('A Kind') }
    securities_request_module = MAPI::Services::Member::SecuritiesRequests

    describe 'GET `/securities/requests`' do
      let(:response) { double('response', to_json: nil) }
      let(:call_endpoint) { get "/member/#{member_id}/securities/requests"}
      before do
        allow(securities_request_module).to receive(:requests).and_return(response)
      end

      it 'calls `MAPI::Services::Member::SecuritiesRequests.requests` with an instance of the MAPI::Service app' do
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

    describe '`MAPI::Services::Member::SecuritiesRequests.fake_header_details_array`' do
      let(:call_method) { MAPI::Services::Member::SecuritiesRequests.fake_header_details_array(member_id) }
      let(:rng) { instance_double(Random, rand: 1) }
      let(:request_id) { rand(100000..999999) }
      before do
        allow(Random).to receive(:new).and_return(rng)
        allow(securities_request_module).to receive(:fake_request_id).with(rng).and_return(request_id)
        allow(securities_request_module).to receive(:fake_header_details).and_return({})
        allow_any_instance_of(Array).to receive(:shuffle).with(random: rng)
      end

      it 'constructs a list of request objects' do
        n = rand(18..36)
        allow(rng).to receive(:rand).with(eq(18..36)).and_return(n)
        expect(call_method.length).to eq(n)
      end
      it 'passes the `request_id` to the `fake_header_details` method' do
        expect(securities_request_module).to receive(:fake_header_details).with(request_id, any_args).and_return({})
        call_method
      end
      it 'passes the `end_date` to the `fake_header_details` method' do
        expect(securities_request_module).to receive(:fake_header_details).with(request_id, Time.zone.today, any_args).and_return({})
        call_method
      end
      it 'passes the `start_date` to the `fake_header_details` method' do
        expect(securities_request_module).to receive(:fake_header_details).with(request_id, anything, anything, anything, anything, Time.zone.today).and_return({})
        call_method
      end
      it 'passes the `end_date` and `start_date` to `fake_header_details` from the supplied range if present' do
        today = Time.zone.today
        range = ((today - 3.days)..today)
        expect(securities_request_module).to receive(:fake_header_details).with(request_id, range.last, anything, anything, anything, range.first).and_return({})
        MAPI::Services::Member::SecuritiesRequests.fake_header_details_array(member_id, range)
      end
      it 'generates at least one request for each form type and status combination' do
        allow(rng).to receive(:rand).with(eq(18..36)).and_return(18)
        form_type_status_combos = []
        securities_request_module::REQUEST_FORM_TYPE_MAPPING.keys.each do |form_type|
          securities_request_module::REQUEST_STATUS_MAPPING.values.flatten.each do |status|
            form_type_status_combos << [form_type, (securities_request_module::DELIVERY_TYPE.values - [securities_request_module::SSKDeliverTo::INTERNAL_TRANSFER]).sample(random: rng), status]
            form_type_status_combos << [form_type, securities_request_module::SSKDeliverTo::INTERNAL_TRANSFER, status] if [securities_request_module::SSKFormType::SECURITIES_PLEDGED, securities_request_module::SSKFormType::SECURITIES_RELEASE].include?(form_type)
          end
        end
        expect(form_type_status_combos.length).to eq(18)
        form_type_status_combos.each do |combo|
          expect(securities_request_module).to receive(:fake_header_details).with(anything, anything, combo.last, combo.first, combo[1], anything).and_return({})
        end
        call_method
      end
    end

    describe '`MAPI::Services::Member::SecuritiesRequests.requests`' do
      let(:app) { double(MAPI::ServiceApp, logger: double('logger')) }
      let(:call_method) { MAPI::Services::Member::SecuritiesRequests.requests(app, member_id) }
      let(:kind) { double('A Kind') }

      shared_examples "common processing" do
        it 'passes each request to `map_hash_values` with the `REQUEST_VALUE_MAPPING` and an arg of `true` for downcasing' do
          mapping = MAPI::Services::Member::SecuritiesRequests::REQUEST_VALUE_MAPPING
          expect(securities_request_module).to receive(:map_hash_values).with(header_details, mapping, true).and_return({})
          call_method
        end
        {
          'fed' => securities_request_module::SSKDeliverTo::FED,
          'dtc' => securities_request_module::SSKDeliverTo::DTC,
          'mutual_fund' => securities_request_module::SSKDeliverTo::MUTUAL_FUND,
          'physical_securities' => securities_request_module::SSKDeliverTo::PHYSICAL_SECURITIES,
          'transfer' => securities_request_module::SSKDeliverTo::INTERNAL_TRANSFER
        }.each do |delivery_type, code|
          it "converts `RECEIVE_FROM` of `#{code}` to `#{delivery_type}`" do
            header_details['RECEIVE_FROM'] = code
            expect(call_method.first['receive_from']).to be(delivery_type)
          end
          it "converts `DELIVER_TO` of `#{code}` to `#{delivery_type}`" do
            header_details['DELIVER_TO'] = code
            expect(call_method.first['deliver_to']).to be(delivery_type)
          end
        end
        it 'calls `kind_from_details` for each request' do
          expect(securities_request_module).to receive(:kind_from_details).with(header_details)
          call_method
        end
        it 'assigns the `kind` to each request' do
          allow(securities_request_module).to receive(:kind_from_details).with(header_details).and_return(kind)
          results = call_method
          expect(results.length).to be >= 1
          results.each do |request|
            expect(request['kind']).to be(kind)
          end
        end
      end

      describe 'when using fake data' do
        let(:today) { Time.zone.today }
        let(:statuses) { instance_double(Array, :include? => true) }
        let(:submitted_date) { instance_double(Date, :>= => true, :<= => true) }
        let(:kind) { double('A Kind') }
        let(:header_details) { {
            'SUBMITTED_DATE' => submitted_date,
            'STATUS' => instance_double(String)
          } }
        let(:header_details_array) {[header_details]}
        before do
          allow(securities_request_module).to receive(:should_fake?).and_return(true)
          allow(securities_request_module).to receive(:flat_unique_array).and_return(statuses)
          allow(securities_request_module).to receive(:fake_header_details_array).and_return(header_details_array)
          allow(securities_request_module).to receive(:kind_from_details).with(header_details_array.first).and_return(kind)
        end

        it 'calls `fake_header_details_array` with the member_id' do
          expect(securities_request_module).to receive(:fake_header_details_array).with(member_id, anything).and_return(header_details_array)
          call_method
        end
        it 'calls `fake_header_details_array` with the `submitted_date_range`' do
          today = Time.zone.today
          allow(Time.zone).to receive(:today).and_return(today)
          expect(securities_request_module).to receive(:fake_header_details_array).with(anything, ((today - 7.days)..today)).and_return(header_details_array)
          call_method
        end
        it 'passes the results of `fake_header_details_array` to `map_hash_values`' do
          header_details_array.each do |header|
            expect(securities_request_module).to receive(:map_hash_values).with(header, any_args).and_return({})
            call_method
          end
        end
        it 'returns the results of `fake_header_details_array` that have a status included in the passed status value' do
          header_details_array.each do |header|
            expect(statuses).to receive(:include?).with(header['STATUS'])
            call_method
          end
        end
        it 'returns the results of `fake_header_details_array` that occur on or after the start_date' do
          expect(submitted_date).to receive(:>=).with(today - 7.days)
          call_method
        end
        it 'returns the results of `fake_header_details_array` that occur on or before the end_date' do
          expect(submitted_date).to receive(:<=).with(today)
          call_method
        end
        include_examples "common processing"
      end
      describe 'when using real data' do
        let(:request_query) { double('request query') }
        let(:header_details) { {} }
        before do
          allow(securities_request_module).to receive(:should_fake?).and_return(false)
          allow(securities_request_module).to receive(:requests_query).and_return(request_query)
          allow(securities_request_module).to receive(:fetch_hashes).and_return([header_details])
          allow(securities_request_module).to receive(:kind_from_details).and_return(double('A Kind'))
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
        include_examples "common processing"
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
            SELECT HEADER_ID AS REQUEST_ID, FORM_TYPE, DELIVER_TO, RECEIVE_FROM, SETTLE_DATE, CREATED_DATE AS SUBMITTED_DATE, CREATED_BY_NAME AS SUBMITTED_BY,
            SIGNED_BY_NAME AS AUTHORIZED_BY, SIGNED_DATE AS AUTHORIZED_DATE, STATUS FROM SAFEKEEPING.SSK_WEB_FORM_HEADER
            WHERE FHLB_ID = #{member_id} AND STATUS IN (#{quoted_statuses}) AND SETTLE_DATE >= TO_DATE('#{start_date}','YYYY-MM-DD HH24:MI:SS')
            AND SETTLE_DATE <= TO_DATE('#{end_date}','YYYY-MM-DD HH24:MI:SS') AND FORM_TYPE IS NOT NULL
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
      let(:delivery_values) { [ SecureRandom.hex, SecureRandom.hex, SecureRandom.hex ] }
      let(:security) { {  'cusip' => SecureRandom.hex,
                          'description' => SecureRandom.hex,
                          'original_par' => rand(1..40000) + rand.round(2),
                          'payment_amount' => rand(1..100000) + rand.round(2) } }
      let(:required_delivery_keys) { [ 'a', 'b', 'c' ] }
      let(:delivery_columns) { MAPI::Services::Member::SecuritiesRequests.delivery_type_mapping(delivery_type).keys }
      let(:delivery_values) { MAPI::Services::Member::SecuritiesRequests.delivery_type_mapping(delivery_type).values }
      let(:user_name) {  SecureRandom.hex }
      let(:full_name) { SecureRandom.hex }
      let(:session_id) { SecureRandom.hex }
      let(:adx_id) { [1000..10000].sample }
      let(:ssk_id) { [1000..10000].sample }

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

        it 'raises an InvalidFieldError if the `delivery_type` is not recognized' do
          delivery_type = SecureRandom.hex
          expect{MAPI::Services::Member::SecuritiesRequests.delivery_keys_for_delivery_type(delivery_type)}.to raise_error(
            MAPI::Shared::Errors::InvalidFieldError, "delivery_type must be one of the following values: #{MAPI::Services::Member::SecuritiesRequests::DELIVERY_TYPE.keys.join(', ')}"
          ) do |error|
            expect(error.code).to eq(:delivery_type)
          end
        end
      end

      describe '`insert_release_header_query`' do
        let(:call_method) { MAPI::Services::Member::SecuritiesRequests.insert_release_header_query( member_id,
                                                                                                    header_id,
                                                                                                    user_name,
                                                                                                    full_name,
                                                                                                    session_id,
                                                                                                    adx_id,
                                                                                                    delivery_columns,
                                                                                                    broker_instructions,
                                                                                                    delivery_type,
                                                                                                    delivery_values,
                                                                                                    adx_type ) }
        let(:sentinel) { SecureRandom.hex }
        let(:today) { Time.zone.today }

        before do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).and_return(SecureRandom.hex)
          allow(Time.zone).to receive(:today).and_return(today)
        end

        it 'expands delivery columns into the insert statement' do
          expect(call_method).to match(
            /\A\s*INSERT\s+INTO\s+SAFEKEEPING\.SSK_WEB_FORM_HEADER\s+\(HEADER_ID,\s+FHLB_ID,\s+STATUS,\s+PLEDGE_TYPE,\s+TRADE_DATE,\s+REQUEST_STATUS,\s+SETTLE_DATE,\s+DELIVER_TO,\s+FORM_TYPE,\s+CREATED_DATE,\s+CREATED_BY,\s+CREATED_BY_NAME,\s+LAST_MODIFIED_BY,\s+LAST_MODIFIED_DATE,\s+LAST_MODIFIED_BY_NAME,\s+#{MAPI::Services::Member::SecuritiesRequests::ADXAccountTypeMapping::SYMBOL_TO_SQL_COLUMN_NAME[adx_type]},\s+#{delivery_columns.join(',\s+')}/)
        end

        it 'sets the `header_id`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(header_id).and_return(sentinel)
          expect(call_method).to match /VALUES\s\(#{sentinel},/
        end

        it 'sets the `member_id`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(member_id).and_return(sentinel)
          expect(call_method).to match /VALUES\s+\((\S+\s+){1}#{sentinel},/
        end

        it 'sets the `status`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(MAPI::Services::Member::SecuritiesRequests::SSKRequestStatus::SUBMITTED).and_return(sentinel)
          expect(call_method).to match /VALUES\s+\((\S+\s+){2}#{sentinel},/
        end

        it 'sets the `transaction_code`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(MAPI::Services::Member::SecuritiesRequests::TRANSACTION_CODE[broker_instructions['transaction_code']]).and_return(sentinel)
          expect(call_method).to match /VALUES\s+\((\S+\s+){3}#{sentinel},/
        end

        it 'sets the `trade_date`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(broker_instructions['trade_date']).and_return(sentinel)
          expect(call_method).to match /VALUES\s+\((\S+\s+){4}#{sentinel},/
        end

        it 'sets the `settlement_type`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(MAPI::Services::Member::SecuritiesRequests::SETTLEMENT_TYPE[broker_instructions['settlement_type']]).and_return(sentinel)
          expect(call_method).to match /VALUES\s+\((\S+\s+){5}#{sentinel},/
        end

        it 'sets the `settlement_date`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(broker_instructions['settlement_date']).and_return(sentinel)
          expect(call_method).to match /VALUES\s+\((\S+\s+){6}#{sentinel},/
        end

        it 'sets the `delivery_type`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(MAPI::Services::Member::SecuritiesRequests::DELIVERY_TYPE[delivery_type]).and_return(sentinel)
          expect(call_method).to match /VALUES\s+\((\S+\s+){7}#{sentinel},/
        end

        it 'sets the `form_type`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(form_type).and_return(sentinel)
          expect(call_method).to match /VALUES\s+\((\S+\s+){8}#{sentinel},/
        end

        it 'sets the `created_date`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(today).and_return(sentinel)
          expect(call_method).to match /VALUES\s+\((\S+\s+){9}#{sentinel},/
        end

        it 'sets the `created_by`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(user_name).and_return(sentinel)
          expect(call_method).to match /VALUES\s+\((\S+\s+){10}#{sentinel},/
        end

        it 'sets the `created_by_name`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(full_name).and_return(sentinel)
          expect(call_method).to match /VALUES\s+\((\S+\s+){11}#{sentinel},/
        end

        it 'sets the `last_modified_by`' do
          formatted_modification_by = double('Formatted Modification By')
          quoted_modification_by = SecureRandom.hex
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:format_modification_by).and_return(formatted_modification_by)
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(formatted_modification_by).and_return(quoted_modification_by)
          expect(call_method).to match /VALUES\s+\((\S+\s+){12}#{quoted_modification_by}/
        end

        it 'sets the `last_modified_date`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).and_return(Time.zone.today)
          expect(call_method).to match /VALUES\s+\((\S+\s+){13}#{Time.zone.today}/
        end

        it 'sets the `last_modified_by_name`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).and_return(full_name)
          expect(call_method).to match /VALUES\s+\((\S+\s+){14}#{full_name}/
        end

        it 'sets the `adx_id`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).and_return(adx_id)
          expect(call_method).to match /VALUES\s+\((\S+\s+){15}#{adx_id}/
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
        let(:sentinel) { SecureRandom.hex }
        let(:today) { Time.zone.today }

        before do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).and_return(SecureRandom.hex)
          allow(Time.zone).to receive(:today).and_return(today)
        end

        it 'constructs an insert statement with the appropriate column names' do
          expect(call_method).to match(
            /\A\s*INSERT\s+INTO\s+SAFEKEEPING\.SSK_WEB_FORM_DETAIL\s+\(DETAIL_ID,\s+HEADER_ID,\s+CUSIP,\s+DESCRIPTION,\s+ORIGINAL_PAR,\s+PAYMENT_AMOUNT,\s+CREATED_DATE,\s+CREATED_BY,\s+LAST_MODIFIED_DATE,\s+LAST_MODIFIED_BY/)
        end

        it 'sets the `detail_id`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(detail_id).and_return(sentinel)
          expect(call_method).to match(/VALUES\s+\(#{sentinel},/)
        end

        it 'sets the `header_id`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(header_id).and_return(sentinel)
          expect(call_method).to match(/VALUES\s+\((\S+\s+){1}#{sentinel},/)
        end

        it 'sets the `cusip`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(security['cusip']).and_return(sentinel)
          expect(call_method).to match(/VALUES\s+\((\S+\s+){2}UPPER\(#{sentinel}\),/)
        end

        it 'sets the `description`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(security['description']).and_return(sentinel)
          expect(call_method).to match(/VALUES\s+\((\S+\s+){3}#{sentinel},/)
        end

        it 'sets the `original_par`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(security['original_par']).and_return(sentinel)
          expect(call_method).to match(/VALUES\s+\((\S+\s+){4}#{sentinel},/)
        end

        it 'sets the `payment_amount`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(security['payment_amount']).and_return(sentinel)
          expect(call_method).to match(/VALUES\s+\((\S+\s+){5}#{sentinel},/)
        end

        it 'sets the `created_date`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(today).and_return(sentinel)
          expect(call_method).to match(/VALUES\s+\((\S+\s+){6}#{sentinel},/)
        end

        it 'sets the `created_by`' do
          formatted_username = SecureRandom.hex
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:format_username).and_return(formatted_username)
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(formatted_username).and_return(sentinel)
          expect(call_method).to match(/VALUES\s+\((\S+\s+){7}#{sentinel},/)
        end

        it 'sets the `last_modified_date`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(today).and_return(sentinel)
          expect(call_method).to match(/VALUES\s+\((\S+\s+){8}#{sentinel},/)
        end

        it 'sets the `last_modified_by`' do
          formatted_modification_by = double('Formatted Modification By')
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:format_modification_by).and_return(formatted_modification_by)
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(formatted_modification_by).and_return(sentinel)
          expect(call_method).to match(/VALUES\s+\((\S+\s+){9}#{sentinel},/)
        end
        it 'sets the `ssk_id`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(ssk_id).and_return(sentinel)
          expect(call_method).to match(/VALUES\s+\((\S+\s+){10}#{sentinel}/)
        end
      end

      describe '`format_delivery_columns`' do
        let(:provided_delivery_keys) { rand(1..5).times.map { SecureRandom.hex } }
        let(:delivery_type) { MAPI::Services::Member::SecuritiesRequests::DELIVERY_TYPE.keys[rand(0..3)] }
        let(:required_delivery_keys) { MAPI::Services::Member::SecuritiesRequests.delivery_keys_for_delivery_type(delivery_type) }
        let(:call_method) { MAPI::Services::Member::SecuritiesRequests.format_delivery_columns(delivery_type,
          required_delivery_keys, provided_delivery_keys) }

        it 'raises a `MissingFieldError` if required keys are missing' do
          expect { call_method }.to raise_error(MAPI::Shared::Errors::MissingFieldError, /delivery_instructions must contain \S+/)
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

      describe '`format_modification_by` class method' do
        let(:username) { double('Username') }
        let(:formatted_username) { SecureRandom.hex(5) }
        let(:session_id) { SecureRandom.hex(5) }
        let(:call_method) { MAPI::Services::Member::SecuritiesRequests.format_modification_by(username, session_id) }
        before do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:format_username).with(username).and_return(formatted_username)
        end
        it 'calls `format_user_name` with the supplied `username`' do
          expect(MAPI::Services::Member::SecuritiesRequests).to receive(:format_username).with(username).and_return(formatted_username)
          call_method
        end
        it 'adds a separator and the `session_id` to the formatted username' do
          expect(call_method).to eq("#{formatted_username}\\\\#{session_id}")
        end
        it 'truncates the formatted modification_by to `LAST_MODIFIED_BY_MAX_LENGTH`' do
          long_session_id = SecureRandom.hex
          result = MAPI::Services::Member::SecuritiesRequests.format_modification_by(username, long_session_id)
          truncated_result = "#{formatted_username}\\\\#{long_session_id}"[0..MAPI::Services::Member::SecuritiesRequests::LAST_MODIFIED_BY_MAX_LENGTH-1]
          expect(result).to eq(truncated_result)
        end
      end
      describe '`format_username` class method' do
        let(:username) { SecureRandom.hex.upcase }
        let(:call_method) { MAPI::Services::Member::SecuritiesRequests.format_username(username)}
        it 'downcases the supplied username' do
          expect(call_method).to eq(username.downcase)
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

        it 'raises an error if SQL query call returns nil' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:execute_sql).with(app.logger, sql).and_return(nil)
          expect { call_method }.to raise_error(Exception)
        end

        it 'calls `fetch` on the cusor' do
          expect(cursor).to receive(:fetch).and_return(results_array)
          call_method
        end

        it 'does not raise an error if `fetch` returns nil' do
          allow(cursor).to receive(:fetch).and_return(nil)
          expect { call_method }.to_not raise_error
        end

        context 'handling the results array' do
          before do
            allow(cursor).to receive(:fetch).and_return(results_array)
          end

          it 'calls `first` on the results array' do
            expect(results_array).to receive(:first).and_return(single_result)
            call_method
          end

          it 'does not raise an error if calling `first` on results returns nil' do
            allow(results_array).to receive(:first).and_return(nil)
            expect { call_method }.to_not raise_error
          end

          it 'does not raise an error if calling `first` on results returns nil and `raise_error_if_nil` is false' do
            allow(results_array).to receive(:first).and_return(nil)
            expect { call_method }.to_not raise_error
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

      describe '`adx_query`' do
        let(:call_method) { MAPI::Services::Member::SecuritiesRequests.adx_query(member_id, adx_type) }

        before do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(member_id).and_return(member_id)
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(adx_type_string).and_return(adx_type_string)
        end

        it 'constructs the appropriate sql' do
          expect(call_method).to eq(<<-SQL
            SELECT ADX.ADX_ID
            FROM SAFEKEEPING.ACCOUNT_DOCKET_XREF ADX, SAFEKEEPING.BTC_ACCOUNT_TYPE BAT, SAFEKEEPING.CUSTOMER_PROFILE CP
            WHERE ADX.BAT_ID = BAT.BAT_ID
            AND ADX.CP_ID = CP.CP_ID
            AND CP.FHLB_ID = #{member_id}
            AND UPPER(SUBSTR(BAT.BAT_ACCOUNT_TYPE,1,1)) = #{adx_type_string}
            AND CONCAT(TRIM(TRANSLATE(ADX.ADX_BTC_ACCOUNT_NUMBER,' 0123456789',' ')), '*') = '*'
            AND (BAT.BAT_ACCOUNT_TYPE NOT LIKE '%DB%' AND BAT.BAT_ACCOUNT_TYPE NOT LIKE '%REIT%')
            ORDER BY TO_NUMBER(ADX.ADX_BTC_ACCOUNT_NUMBER) ASC
            SQL
          )
        end
      end

      describe '`ssk_id_query`' do
        let(:cusip) { SecureRandom.hex }
        let(:call_method) { MAPI::Services::Member::SecuritiesRequests.ssk_id_query(member_id, adx_id, cusip) }

        before do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(member_id).and_return(member_id)
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(adx_id).and_return(adx_id)
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(cusip).and_return(cusip)
        end

        it 'constructs the appropriate sql' do
          expect(call_method).to eq(<<-SQL
            SELECT SSK.SSK_ID
            FROM SAFEKEEPING.SSK SSK, SAFEKEEPING.SSK_TRANS SSKT
            WHERE UPPER(SSK.SSK_CUSIP) = UPPER(#{cusip})
            AND SSK.FHLB_ID = #{member_id}
            AND SSK.ADX_ID = #{adx_id}
            AND SSKT.SSK_ID = SSK.SSK_ID
            AND SSKT.SSX_BTC_DATE = (SELECT MAX(SSX_BTC_DATE) FROM SAFEKEEPING.SSK_TRANS)
            SQL
          )
        end
      end

      describe '`consolidate_broker_wire_address`' do
        let(:delivery_instructions) {{
          foo: SecureRandom.hex,
          bar: SecureRandom.hex
        }}
        let(:call_method) { securities_request_module.consolidate_broker_wire_address(delivery_instructions) }
        describe 'when the `delivery_instructions` hash does not contain keys found in BROKER_WIRE_ADDRESS_FIELDS' do
          it 'does nothing to the delivery_instructions hash' do
            unmutated_delivery_instructions = delivery_instructions.clone
            call_method
            expect(delivery_instructions).to eq(unmutated_delivery_instructions)
          end
        end
        describe 'when the `delivery_instructions` hash contains keys found in BROKER_WIRE_ADDRESS_FIELDS' do
          let(:address_1) { SecureRandom.hex }
          let(:address_2) { SecureRandom.hex }
          before do
            delivery_instructions['clearing_agent_fed_wire_address_1'] = address_1
            delivery_instructions['clearing_agent_fed_wire_address_2'] = address_2
          end
          it 'deletes the `clearing_agent_fed_wire_address_1` from the hash' do
            expect(delivery_instructions['clearing_agent_fed_wire_address_1']).to eq(address_1)
            call_method
            expect(delivery_instructions).not_to have_key('clearing_agent_fed_wire_address_1')
          end
          it 'deletes the `clearing_agent_fed_wire_address_2` from the hash' do
            expect(delivery_instructions['clearing_agent_fed_wire_address_2']).to eq(address_2)
            call_method
            expect(delivery_instructions).not_to have_key('clearing_agent_fed_wire_address_2')
          end
          it 'adds a `clearing_agent_fed_wire_address` value to the hash that joins `clearing_agent_fed_wire_address_1` and `clearing_agent_fed_wire_address_2` with a `/` character' do
            expect(delivery_instructions).not_to have_key('clearing_agent_fed_wire_address')
            call_method
            expect(delivery_instructions['clearing_agent_fed_wire_address']).to eq([address_1, address_2].join('/'))
          end
        end

      end

      describe '`create_release` method' do
        let(:app) { double(MAPI::ServiceApp, logger: double('logger'), settings: nil) }
        let(:member_id) { rand(100000..999999) }
        let(:delivery_type) { MAPI::Services::Member::SecuritiesRequests::DELIVERY_TYPE.keys[rand(0..3)] }
        let(:delivery_instructions) {
          MAPI::Services::Member::SecuritiesRequests.delivery_keys_for_delivery_type(delivery_type).map do |key|
            [key, SecureRandom.hex]
          end.to_h.merge('delivery_type' => delivery_type) }
        let(:security) { { 'cusip' => instance_double(String),
                           'description' => instance_double(String),
                           'original_par' => rand(0...50000000),
                           'payment_amount' => instance_double(Numeric) } }
        let(:securities) { [ security, security, security ]}
        let(:method_params) { [ app,
                                member_id,
                                user_name,
                                full_name,
                                session_id,
                                broker_instructions,
                                delivery_instructions,
                                securities,
                                kind ] }
        let(:adx_type) { [:pledged, :unpledged].sample }
        let(:call_method) { MAPI::Services::Member::SecuritiesRequests.create_release(*method_params) }

        before do
          allow(securities_request_module).to receive(:validate_kind).with(:release, kind).and_return(true)
          allow(securities_request_module).to receive(:get_adx_type_from_security).with(app, security).and_return(adx_type)
          allow(securities_request_module).to receive(:validate_broker_instructions)
        end

        context 'validations' do
          before { allow(securities_request_module).to receive(:should_fake?).and_return(true) }

          it 'calls `validate_broker_instructions` with the `broker_instructions` arg' do
            expect(securities_request_module).to receive(:validate_broker_instructions).with(broker_instructions, anything, anything)
            call_method
          end
          it 'calls `validate_broker_instructions` with the app as an arg' do
            expect(securities_request_module).to receive(:validate_broker_instructions).with(anything, app, anything)
            call_method
          end
          it 'calls `validate_broker_instructions` with `kind` as an arg' do
            expect(securities_request_module).to receive(:validate_broker_instructions).with(anything, anything, kind)
            call_method
          end
          it 'calls `validate_delivery_instructions` with the `delivery_instructions` arg' do
            expect(securities_request_module).to receive(:validate_delivery_instructions).with(delivery_instructions)
            call_method
          end
          it 'calls `validate_securities` with the `securities` arg' do
            expect(securities_request_module).to receive(:validate_securities).with(securities, anything, anything, anything)
            call_method
          end
          it 'calls `validate_securities` with the `settlement_type` arg from the broker instructions' do
            expect(securities_request_module).to receive(:validate_securities).with(anything, broker_instructions['settlement_type'], anything, anything)
            call_method
          end
          it 'calls `validate_securities` with the `delivery_type` arg from the delivery instructions' do
            expect(securities_request_module).to receive(:validate_securities).with(anything, anything, delivery_instructions['delivery_type'], anything)
            call_method
          end
          it 'calls `validate_securities` with `:release`' do
            expect(securities_request_module).to receive(:validate_securities).with(securities, anything, anything, :release)
            call_method
          end
          it 'calls `process_delivery_instructions` with the `delivery_instructions` arg' do
            expect(securities_request_module).to receive(:process_delivery_instructions).with(delivery_instructions)
            call_method
          end
        end

        context 'preparing and executing SQL' do
          let(:next_id) { double('Next ID') }
          let(:sequence_result) { double('Sequence Result', to_i: next_id) }
          let(:adx_sql) { double('ADX SQL') }
          let(:ssk_sql) { double('SSK SQL') }
          let(:adx_type) { [:pledged, :unpledged].sample }

          before do
            allow(MAPI::Services::Member::SecuritiesRequests).to receive(:format_delivery_columns).and_return(
              delivery_columns)
            allow(MAPI::Services::Member::SecuritiesRequests).to receive(:format_delivery_values).and_return(
              delivery_values)
            allow(securities_request_module).to receive(:should_fake?).and_return(false)
            allow(securities_request_module).to receive(:adx_query).with(member_id, adx_type).and_return(adx_sql)
            allow(securities_request_module).to receive(:ssk_id_query).with(member_id, adx_id, security['cusip']).
              exactly(3).times.and_return(ssk_sql)
            allow(securities_request_module).to receive(:execute_sql_single_result).with(
              app,
              MAPI::Services::Member::SecuritiesRequests::NEXT_ID_SQL,
              "Next ID Sequence").and_return(sequence_result)
            allow(securities_request_module).to receive(:execute_sql_single_result).with(
              app,
              adx_sql,
              "ADX ID").and_return(adx_id)
            allow(securities_request_module).to receive(:execute_sql_single_result).with(
              app,
              ssk_sql,
              "SSK ID").and_return(ssk_id)
            allow(securities_request_module).to receive(:get_adx_type_from_security).with(anything, securities.first).and_return(adx_type)
          end

          it 'returns the inserted request ID' do
            allow(MAPI::Services::Member::SecuritiesRequests).to receive(:execute_sql).with(any_args).and_return(true)
            expect(call_method).to be(next_id)
          end

          context 'prepares SQL' do
            before do
              allow(MAPI::Services::Member::SecuritiesRequests).to receive(:execute_sql).with(any_args).and_return(true)
            end

            it 'gets the `adx_type` from the first security' do
              expect(securities_request_module).to receive(:get_adx_type_from_security).with(anything, securities.first).and_return(adx_type)
              call_method
            end

            it 'calls `insert_release_header_query`' do
              expect(MAPI::Services::Member::SecuritiesRequests).to receive(:insert_release_header_query).with(
                member_id,
                next_id,
                user_name,
                full_name,
                session_id,
                adx_id,
                delivery_columns,
                broker_instructions,
                delivery_type,
                delivery_values,
                adx_type)
              call_method
            end

            it 'calls `insert_security_query`' do
              expect(MAPI::Services::Member::SecuritiesRequests).to receive(:insert_security_query).with(next_id,
                next_id, user_name, session_id, security, ssk_id).exactly(3).times
              call_method
            end
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
                adx_id,
                delivery_columns,
                broker_instructions,
                delivery_type,
                delivery_values,
                adx_type).and_return(insert_header_sql)
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

            it 'raises an error if the `SSK_ID` can\'t be found' do
              allow(securities_request_module).to receive(:ssk_id_query).with(member_id, adx_id, security['cusip']).and_return(nil)
              expect { call_method }.to raise_error(Exception)
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
    describe 'GET securities/request/%{request_id}' do
      let(:request_id) { rand(1000..99999) }
      let(:response) { instance_double(Hash, to_json: nil) }
      let(:call_endpoint) { get "/member/#{member_id}/securities/request/#{request_id}"}
      before do
        allow(securities_request_module).to receive(:request_details).and_return(response)
      end
      it 'calls `MAPI::Services::Member::SecuritiesRequests.request_details` with an instance of the MAPI::Service app' do
        expect(securities_request_module).to receive(:request_details).with(an_instance_of(MAPI::ServiceApp), any_args)
        call_endpoint
      end
      it 'calls `MAPI::Services::Member::SecuritiesRequests.request_details` with the `member_id` param' do
        expect(securities_request_module).to receive(:request_details).with(anything, member_id, any_args)
        call_endpoint
      end
      it 'calls `MAPI::Services::Member::SecuritiesRequests.request_details` with the `request_id` param' do
        expect(securities_request_module).to receive(:request_details).with(anything, anything, request_id)
        call_endpoint
      end
      it 'returns the results of `MAPI::Services::Member::SecuritiesRequests.request_details` as JSON' do
        json_response = SecureRandom.hex
        allow(response).to receive(:to_json).and_return(json_response)
        call_endpoint
        expect(call_endpoint.body).to eq(json_response)
      end
    end

    describe '`MAPI::Services::Member::SecuritiesRequests.request_header_details_query`' do
      let(:member_id) { rand(1000..99999) }
      let(:header_id) { rand(1000..99999) }

      before do
        allow(securities_request_module).to receive(:quote).with(member_id).and_return(member_id)
        allow(securities_request_module).to receive(:quote).with(header_id).and_return(header_id)
      end

      it 'constructs the proper SQL' do
        expected_sql = <<-SQL
            SELECT PLEDGE_TYPE, REQUEST_STATUS, TRADE_DATE, SETTLE_DATE, DELIVER_TO, BROKER_WIRE_ADDR, ABA_NO, DTC_AGENT_PARTICIPANT_NO,
              MUTUAL_FUND_COMPANY, DELIVERY_BANK_AGENT, REC_BANK_AGENT_NAME, REC_BANK_AGENT_ADDR, CREDIT_ACCT_NO1, CREDIT_ACCT_NO2,
              MUTUAL_FUND_ACCT_NO, CREDIT_ACCT_NO3, CREATED_BY, CREATED_BY_NAME, PLEDGED_ADX_ID, UNPLEDGED_ADX_ID, FORM_TYPE, PLEDGE_TO
            FROM SAFEKEEPING.SSK_WEB_FORM_HEADER
            WHERE HEADER_ID = #{header_id}
            AND FHLB_ID = #{member_id}
        SQL
        expect(securities_request_module.request_header_details_query(member_id, header_id)).to eq(expected_sql)
      end
    end

    describe '`MAPI::Services::Member::SecuritiesRequests.release_request_securities_query`' do
      let(:header_id) { rand(1000..99999) }

      before { allow(securities_request_module).to receive(:quote).with(header_id).and_return(header_id) }

      it 'constructs the proper SQL' do
        expected_sql = <<-SQL
            SELECT CUSIP, DESCRIPTION, ORIGINAL_PAR, PAYMENT_AMOUNT
            FROM SAFEKEEPING.SSK_WEB_FORM_DETAIL
            WHERE HEADER_ID = #{header_id}
        SQL
        expect(securities_request_module.release_request_securities_query(header_id)).to eq(expected_sql)
      end
    end

    describe '`MAPI::Services::Member::SecuritiesRequests.request_details`' do
      let(:request_id) { rand(1000..99999) }
      let(:app) { double(MAPI::ServiceApp, logger: double('logger')) }
      let(:header_details) {{
        'REQUEST_ID' => request_id,
        'CREATED_BY' => SecureRandom.hex,
        'CREATED_BY_NAME' => SecureRandom.hex,
        'REQUEST_STATUS' => SecureRandom.hex
      }}
      let(:security) { instance_double(Hash) }
      let(:securities) { [security] }
      let(:call_method) { securities_request_module.request_details(app, member_id, request_id) }

      before do
        allow(securities_request_module).to receive(:fake_securities).and_return(securities)
        allow(securities_request_module).to receive(:fake_header_details_array).and_return([header_details])
        allow(securities_request_module).to receive(:fetch_hashes).and_return(securities)
        allow(securities_request_module).to receive(:fetch_hash).and_return(header_details)
        allow(securities_request_module).to receive(:broker_instructions_from_header_details)
        allow(securities_request_module).to receive(:delivery_instructions_from_header_details)
        allow(securities_request_module).to receive(:format_securities)
        allow(securities_request_module).to receive(:should_fake?).and_return(true)
        allow(securities_request_module).to receive(:map_hash_values).with(header_details, any_args).and_return(header_details)
        allow(securities_request_module).to receive(:map_hash_values).with(security, any_args).and_return(security)
        allow(security).to receive(:with_indifferent_access).and_return(security)
      end

      describe 'when using fake data' do
        let(:matched_header_details) {{
          'REQUEST_ID' => request_id,
          'REQUEST_STATUS' => SecureRandom.hex
        }}
        let(:unmatched_header_details) { {'REQUEST_ID' => SecureRandom.hex} }
        let(:header_details_array) {[matched_header_details, unmatched_header_details]}
        before do
          allow(securities_request_module).to receive(:should_fake?).and_return(true)
          allow(securities_request_module).to receive(:fake_header_details_array).and_return(header_details_array)
          allow(securities_request_module).to receive(:map_hash_values).and_return({})
        end

        it 'constructs `fake_securities` using the `request_id` as an arg' do
          expect(securities_request_module).to receive(:fake_securities).with(request_id, anything).and_return(securities)
          call_method
        end
        it 'constructs `fake_securities` using the `REQUEST_STATUS` from the `header_details` as an arg' do
          expect(securities_request_module).to receive(:fake_securities).with(anything, matched_header_details['REQUEST_STATUS']).and_return(securities)
          call_method
        end
        it 'calls `fake_header_details_array` with the member_id' do
          expect(securities_request_module).to receive(:fake_header_details_array).with(member_id).and_return(header_details_array)
          call_method
        end
        it 'selects the header detail hash that matches the `request_id`' do
          expect(securities_request_module).to receive(:map_hash_values).with(matched_header_details, any_args).and_return({})
          call_method
        end
      end
      describe 'when using real data' do
        let(:request_header_details_query) { instance_double(String) }
        let(:release_request_securities_query) { instance_double(String) }
        before do
          allow(securities_request_module).to receive(:should_fake?).and_return(false)
          allow(securities_request_module).to receive(:request_header_details_query).and_return(request_header_details_query)
          allow(securities_request_module).to receive(:release_request_securities_query).and_return(release_request_securities_query)
        end

        describe 'fetching the `header_details`' do
          it 'calls `fetch_hash` with the logger' do
            expect(securities_request_module).to receive(:fetch_hash).with(app.logger, anything).and_return(header_details)
            call_method
          end
          it 'calls `fetch_hash` with the result of `request_header_details_query`' do
            expect(securities_request_module).to receive(:fetch_hash).with(anything, request_header_details_query).and_return(header_details)
            call_method
          end
          it 'calls `request_header_details_query` with the `member_id`' do
            expect(securities_request_module).to receive(:request_header_details_query).with(member_id, anything)
            call_method
          end
          it 'calls `request_header_details_query` with the `request_id`' do
            expect(securities_request_module).to receive(:request_header_details_query).with(anything, request_id)
            call_method
          end
          it 'raises an exception if `fetch_hash` returns nil' do
            allow(securities_request_module).to receive(:fetch_hash)
            expect{call_method}.to raise_error(MAPI::Shared::Errors::SQLError, 'No header details found')
          end
        end
        describe 'fetching the `securities`' do
          it 'calls `fetch_hashes` with the logger' do
            expect(securities_request_module).to receive(:fetch_hashes).with(app.logger, anything).and_return(securities)
            call_method
          end
          it 'calls `fetch_hashes` with the result of `release_request_securities_query`' do
            expect(securities_request_module).to receive(:fetch_hashes).with(anything, release_request_securities_query).and_return(securities)
            call_method
          end
          it 'calls `release_request_securities_query` with the `request_id`' do
            expect(securities_request_module).to receive(:release_request_securities_query).with(request_id)
            call_method
          end
          it 'raises an exception if `fetch_hashes` returns nil' do
            allow(securities_request_module).to receive(:fetch_hashes)
            expect{call_method}.to raise_error(MAPI::Shared::Errors::SQLError, 'No securities found')
          end
        end
      end
      it 'calls `map_hash_values` on the `header_details`' do
        expect(securities_request_module).to receive(:map_hash_values).with(header_details, any_args).and_return(header_details)
        call_method
      end
      it 'calls `map_hash_values` with the `REQUEST_HEADER_MAPPING` for the `header_details`' do
        expect(securities_request_module).to receive(:map_hash_values).with(anything, securities_request_module::REQUEST_HEADER_MAPPING).exactly(:once).and_return(header_details)
        call_method
      end
      it 'calls `map_hash_values` on each security' do
        securities.each do |security|
          expect(securities_request_module).to receive(:map_hash_values).with(security, any_args).and_return(security)
        end
        call_method
      end
      it 'calls `map_hash_values` with the `RELEASE_REQUEST_SECURITIES_MAPPING` for each security' do
        expect(securities_request_module).to receive(:map_hash_values).with(anything, securities_request_module::RELEASE_REQUEST_SECURITIES_MAPPING).exactly(securities.length).and_return(security)
        call_method
      end
      describe 'the returned hash' do
        let(:broker_instructions) { double(Hash) }
        let(:delivery_instructions) { double(Hash) }
        let(:formatted_securities) { double(Array) }
        it 'contains the `request_id` it was passed' do
          expect(call_method[:request_id]).to eq(request_id)
        end
        it 'passes the `header_details` to `broker_instructions_from_header_details`' do
          expect(securities_request_module).to receive(:broker_instructions_from_header_details).with(header_details)
          call_method
        end
        it 'contains `broker_instructions` that are the result of `broker_instructions_from_header_details`' do
          allow(securities_request_module).to receive(:broker_instructions_from_header_details).and_return(broker_instructions)
          expect(call_method[:broker_instructions]).to eq(broker_instructions)
        end
        it 'passes the `header_details` to `delivery_instructions_from_header_details`' do
          expect(securities_request_module).to receive(:delivery_instructions_from_header_details).with(header_details)
          call_method
        end
        it 'contains `broker_instructions` that are the result of `delivery_instructions_from_header_details`' do
          allow(securities_request_module).to receive(:delivery_instructions_from_header_details).and_return(delivery_instructions)
          expect(call_method[:delivery_instructions]).to eq(delivery_instructions)
        end
        it 'passes the securities to the `format_securities` method' do
          expect(securities_request_module).to receive(:format_securities).with(securities)
          call_method
        end
        it 'contains `securities` that are the result of `format_securities`' do
          allow(securities_request_module).to receive(:format_securities).and_return(formatted_securities)
          expect(call_method[:securities]).to eq(formatted_securities)
        end
        it 'contains a `user` hash with a `username` equal to the `CREATED_BY` value in the `header_details`' do
          expect(call_method[:user][:username]).to eq(header_details['CREATED_BY'])
        end
        it 'contains a `user` hash with a `full_name` equal to the `CREATED_BY_NAME` value in the `header_details`' do
          expect(call_method[:user][:full_name]).to eq(header_details['CREATED_BY_NAME'])
        end
        it 'contains a `user` hash with a nil value for `session_id`' do
          expect(call_method[:user][:session_id]).to eq(nil)
        end
        it 'contains a `pledged_account` with the `PLEDGED_ADX_ID`' do
          header_details['PLEDGED_ADX_ID'] = SecureRandom.hex
          expect(call_method[:pledged_account]).to eq(header_details['PLEDGED_ADX_ID'])
        end
        it 'contains a `safekept_account` with the `UNPLEDGED_ADX_ID`' do
          header_details['UNPLEDGED_ADX_ID'] = SecureRandom.hex
          expect(call_method[:safekept_account]).to eq(header_details['UNPLEDGED_ADX_ID'])
        end
        it 'contains a `form_type` with the `FORM_TYPE`' do
          header_details['FORM_TYPE'] = SecureRandom.hex
          expect(call_method[:form_type]).to eq(header_details['FORM_TYPE'])
        end
      end
    end

    describe '`MAPI::Services::Member::SecuritiesRequests.broker_instructions_from_header_details`' do
      let(:header_details) {{
        'PLEDGE_TYPE' => instance_double(String),
        'REQUEST_STATUS' => instance_double(String),
        'TRADE_DATE' => instance_double(Date),
        'SETTLE_DATE' => instance_double(Date),
        'PLEDGE_TO' => instance_double(String)
      }}
      let(:call_method) { securities_request_module.broker_instructions_from_header_details(header_details) }

      {
        transaction_code: 'PLEDGE_TYPE',
        settlement_type: 'REQUEST_STATUS',
        trade_date: 'TRADE_DATE',
        settlement_date: 'SETTLE_DATE',
        pledge_to: 'PLEDGE_TO'
      }.each do |key, value|
        it "returns a hash with a `#{key}` equal to the `#{value}` of the passed `header_details`" do
          expect(call_method[key]).to eq(header_details[value])
        end
      end
    end

    describe '`MAPI::Services::Member::SecuritiesRequests.delivery_instructions_from_header_details`' do
      let(:address_1) { SecureRandom.hex }
      let(:address_2) { SecureRandom.hex }
      let(:address_3) { SecureRandom.hex }
      let(:header_details) {{
        'BROKER_WIRE_ADDR' => [address_1, address_2].join('/'),
        'ABA_NO' => instance_double(String),
        'DTC_AGENT_PARTICIPANT_NO' => instance_double(String),
        'MUTUAL_FUND_COMPANY' => instance_double(String),
        'DELIVERY_BANK_AGENT' => instance_double(String),
        'REC_BANK_AGENT_NAME' => instance_double(String),
        'REC_BANK_AGENT_ADDR' => instance_double(String),
        'CREDIT_ACCT_NO1' => instance_double(String),
        'CREDIT_ACCT_NO2' => instance_double(String),
        'MUTUAL_FUND_ACCT_NO' => instance_double(String),
        'CREDIT_ACCT_NO3' => instance_double(String)
      }}
      let(:call_method) { securities_request_module.delivery_instructions_from_header_details(header_details) }
      securities_request_module::DELIVERY_TYPE.keys.each do |delivery_type|
        ['DELIVER_TO', 'RECEIVE_FROM'].each do |delivery_field|
          describe "when the passed header_details hash has a `#{delivery_field}` value of `#{delivery_type}`" do
            before { header_details[delivery_field] = delivery_type }
            it "returns a hash with a `delivery_type` equal `#{delivery_type}`" do
              expect(call_method[:delivery_type]).to eq(delivery_type)
            end
            securities_request_module.delivery_keys_for_delivery_type(delivery_type).each do |required_key|
              next if required_key == 'clearing_agent_fed_wire_address'
              security_key = securities_request_module.delivery_type_mapping(delivery_type)[required_key]
              it "returns a hash with a `#{required_key}` equal to the `#{security_key}` value of the passed header_details hash" do
                expect(call_method[required_key]).to eq(header_details[security_key])
              end
            end
          end
        end
      end
      describe 'handling the `clearing_agent_fed_wire_address` value' do
        before { header_details['DELIVER_TO'] = 'fed' }
        describe 'when the `clearing_agent_fed_wire_address` header value does not contain the `/` character' do
          before { header_details['BROKER_WIRE_ADDR'] = address_3 }
          it 'assigns the `clearing_agent_fed_wire_address` header value to the `clearing_agent_fed_wire_address_1` field' do
            expect(call_method['clearing_agent_fed_wire_address_1']).to eq(address_3)
          end
          it 'assigns nil to the `clearing_agent_fed_wire_address_2` field' do
            expect(call_method['clearing_agent_fed_wire_address_2']).to be_nil
          end
        end
        describe 'when the `clearing_agent_fed_wire_address` header value contains one `/` character' do
          it 'splits the `clearing_agent_fed_wire_address` header value by the `/` character and assigns `clearing_agent_fed_wire_address_1` the first value' do
            expect(call_method['clearing_agent_fed_wire_address_1']).to eq(address_1)
          end
          it 'splits the `clearing_agent_fed_wire_address` header value by the `/` character and assigns `clearing_agent_fed_wire_address_2` the second value' do
            expect(call_method['clearing_agent_fed_wire_address_2']).to eq(address_2)
          end
        end
        describe 'when the `clearing_agent_fed_wire_address` header value contains more than one `/` character' do
          before { header_details['BROKER_WIRE_ADDR'] = [address_1, address_2, address_3].join('/') }
          it 'splits the `clearing_agent_fed_wire_address` header value by the `/` character and assigns `clearing_agent_fed_wire_address_1` the first value' do
            expect(call_method['clearing_agent_fed_wire_address_1']).to eq(address_1)
          end
          it 'splits the `clearing_agent_fed_wire_address` header value by the `/` character and assigns `clearing_agent_fed_wire_address_2` all remaining values joined by the `/` character' do
            expect(call_method['clearing_agent_fed_wire_address_2']).to eq([address_2, address_3].join('/'))
          end
        end
      end
    end

    describe '`MAPI::Services::Member::SecuritiesRequests.format_securities`' do
      let(:security) {{
        'CUSIP' => instance_double(String),
        'DESCRIPTION' => instance_double(String),
        'ORIGINAL_PAR' => instance_double(Integer),
        'PAYMENT_AMOUNT' => instance_double(Integer)
      }}
      let(:securities) { [security] }
      let(:call_method) { securities_request_module.format_securities(securities) }

      {
        cusip: 'CUSIP',
        description: 'DESCRIPTION',
        original_par: 'ORIGINAL_PAR',
        payment_amount: 'PAYMENT_AMOUNT'
      }.each do |key, value|
        it "returns an array of hashes with a `#{key}` equal to the `#{value}` of each passed security" do
          expect(call_method.length).to be > 0
          call_method.each do |returned_security|
            expect(returned_security[key]).to eq(security[value])
          end
        end
      end
    end

    describe '`MAPI::Services::Member::SecuritiesRequests.fake_header_details`' do
      fake_data = fake('securities_requests')
      names = fake_data['names']
      let(:request_id) { rand(1000..9999)}
      let(:end_date) { Time.zone.today - rand(0..7).days }
      let(:status) { (securities_request_module::MAPIRequestStatus::AUTHORIZED + securities_request_module::MAPIRequestStatus::AWAITING_AUTHORIZATION).sample }
      let(:rng) { instance_double(Random) }
      let(:pledge_type_offset) { rand(0..1) }
      let(:request_status_offset) { rand(0..1) }
      let(:delivery_type_offset) { rand(0..3) }
      let(:aba_number) { rand(10000..99999) }
      let(:participant_number) { rand(10000..99999) }
      let(:account_number) { rand(10000..99999) }
      let(:submitted_date) { Time.zone.today }
      let(:authorized_date_offset) { rand(0..2) }
      let(:created_by_offset) { rand(0..names.length-1) }
      let!(:form_type) { rand(70..73) }
      let(:authorized_by_offset) { rand(0..names.length-1) }
      let(:pledge_to_offset) { rand(0..1) }

      let(:call_method) { securities_request_module.fake_header_details(request_id, end_date, status) }
      before do
        allow(Random).to receive(:new).and_return(rng)
        allow(rng).to receive(:rand).and_return(pledge_type_offset, request_status_offset, delivery_type_offset, aba_number, participant_number, account_number, submitted_date, authorized_date_offset, created_by_offset, authorized_by_offset, pledge_to_offset)
        allow(rng).to receive(:rand).with(eq(70..73)).and_return(form_type)
      end

      it 'constructs a hash with a securities with a `REQUEST_ID` value equal to the passed arg' do
        expect(call_method['REQUEST_ID']).to eq(request_id)
      end
      it 'constructs a hash with a `PLEDGE_TYPE` value' do
        expect(call_method['PLEDGE_TYPE']).to eq(securities_request_module::TRANSACTION_CODE.values[pledge_type_offset])
      end
      it 'constructs a hash with a `REQUEST_STATUS` value' do
        expect(call_method['REQUEST_STATUS']).to eq(securities_request_module::SETTLEMENT_TYPE.values[request_status_offset])
      end
      it 'constructs a hash with a `DELIVER_TO` value when the form_type is SSKFormType::SECURITIES_RELEASE' do
        allow(rng).to receive(:rand).with(eq(70..73)).and_return(securities_request_module::SSKFormType::SECURITIES_RELEASE)
        expect(call_method['DELIVER_TO']).to eq(securities_request_module::DELIVERY_TYPE.values[delivery_type_offset])
      end
      it 'constructs a hash with a `DELIVER_TO` value when the form_type is SSKFormType::SAFEKEPT_RELEASE' do
        allow(rng).to receive(:rand).with(eq(70..73)).and_return(securities_request_module::SSKFormType::SAFEKEPT_RELEASE)
        expect(call_method['DELIVER_TO']).to eq(securities_request_module::DELIVERY_TYPE.values[delivery_type_offset])
      end
      it 'constructs a hash with a `RECEIVE_FROM` value when the form_type is SSKFormType::SAFEKEPT_DEPOSIT' do
        allow(rng).to receive(:rand).with(eq(70..73)).and_return(securities_request_module::SSKFormType::SAFEKEPT_DEPOSIT)
        expect(call_method['RECEIVE_FROM']).to eq(securities_request_module::DELIVERY_TYPE.values[delivery_type_offset])
      end
      it 'constructs a hash with a `RECEIVE_FROM` value when the form_type is SSKFormType::SECURITIES_PLEDGED' do
        allow(rng).to receive(:rand).with(eq(70..73)).and_return(securities_request_module::SSKFormType::SECURITIES_PLEDGED)
        expect(call_method['RECEIVE_FROM']).to eq(securities_request_module::DELIVERY_TYPE.values[delivery_type_offset])
      end
      it 'constructs a hash with an `ABA_NO` value' do
        expect(call_method['ABA_NO']).to eq(aba_number)
      end
      it 'constructs a hash with a `DTC_AGENT_PARTICIPANT_NO` value' do
        expect(call_method['DTC_AGENT_PARTICIPANT_NO']).to eq(participant_number)
      end
      it 'constructs a hash with a `TRADE_DATE` value' do
        expect(call_method['TRADE_DATE']).to eq(submitted_date)
      end
      it 'constructs a hash with a `SUBMITTED_DATE` value' do
        expect(call_method['SUBMITTED_DATE']).to eq(submitted_date)
      end
      it 'constructs a hash with a `CREATED_BY` value' do
        expect(call_method['CREATED_BY']).to eq(fake_data['usernames'][created_by_offset])
      end
      it 'constructs a hash with a `CREATED_BY_NAME` value' do
        expect(call_method['CREATED_BY_NAME']).to eq(names[created_by_offset])
      end
      it 'constructs a hash with a `SUBMITTED_BY` value equal to the `CREATED_BY_NAME`' do
        expect(call_method['SUBMITTED_BY']).to eq(names[created_by_offset])
      end
      it 'constructs a hash with a `FORM_TYPE` value' do
        expect(call_method['FORM_TYPE']).to eq(form_type)
      end
      it 'sets the `FORM_TYPE` to the passed one if provided' do
        form_type = double('A Form Type')
        expect(securities_request_module.fake_header_details(request_id, end_date, status, form_type)['FORM_TYPE']).to eq(form_type)
      end
      it 'constructs a hash with a `PLEDGE_TO` value' do
        expect(call_method['PLEDGE_TO']).to eq(securities_request_module::PLEDGE_TO.values[pledge_to_offset])
      end
      it 'selects a `SUBMITTED_DATE` from the `start_date` and `end_date` if both are provided' do
        start_date = submitted_date
        allow(rng).to receive(:rand).and_return(pledge_type_offset, request_status_offset, delivery_type_offset, aba_number, participant_number, account_number, authorized_date_offset, created_by_offset, authorized_by_offset, pledge_to_offset)
        allow(rng).to receive(:rand).with(eq(70..73)).and_return(form_type)
        expect(rng).to receive(:rand).with((start_date..end_date)).and_return(submitted_date)
        securities_request_module.fake_header_details(request_id, end_date, status, nil, nil, start_date)
      end
      {
        securities_request_module::SSKFormType::SECURITIES_PLEDGED => 'PLEDGED_ADX_ID',
        securities_request_module::SSKFormType::SECURITIES_RELEASE => 'PLEDGED_ADX_ID',
        securities_request_module::SSKFormType::SAFEKEPT_DEPOSIT => 'UNPLEDGED_ADX_ID',
        securities_request_module::SSKFormType::SAFEKEPT_RELEASE => 'UNPLEDGED_ADX_ID'
      }.each do |form_type, field|
        it "constructs a hash with a `#{field}` if the `FORM_TYPE` is `#{form_type}`" do
          allow(rng).to receive(:rand).with(eq(70..73)).and_return(form_type)
          expect(call_method[field]).to be_present
        end
      end
      it 'constructs a hash with a `STATUS` value equal to the passed `status`' do
        expect(call_method['STATUS']).to eq(status)
      end
      [
        'CREDIT_ACCT_NO1',
        'CREDIT_ACCT_NO2',
        'MUTUAL_FUND_ACCT_NO',
        'CREDIT_ACCT_NO3'
      ].each do |key|
        it "constructs a hash with a `#{key}` value" do
          expect(call_method[key]).to eq(account_number)
        end
      end
      {
        'BROKER_WIRE_ADDR' => '0541254875/FIRST TENN',
        'MUTUAL_FUND_COMPANY' => "Mutual Funds R'Us",
        'DELIVERY_BANK_AGENT' => 'MI6',
        'REC_BANK_AGENT_NAME' => 'James Bond',
        'REC_BANK_AGENT_ADDR' => '600 Mulberry Court, Boston, MA, 42893',
      }.each do |key, value|
        it "constructs a hash with a `#{key}` value of `#{value}`" do
          expect(call_method[key]).to eq(value)
        end
      end
      describe 'when an `AUTHORIZED` status is passed' do
        let(:status) { securities_request_module::MAPIRequestStatus::AUTHORIZED.sample }

        it 'constructs a hash with an `AUTHORIZED_DATE` value that is equal to the `SUBMITTED_DATE` plus an offset' do
          expect(call_method['AUTHORIZED_DATE']).to eq(submitted_date + (authorized_date_offset).days)
        end
        it 'constructs a hash with a `SETTLE_DATE` value equal to the `AUTHORIZED_DATE` plus one day' do
          authorized_date = submitted_date + (authorized_date_offset).days
          expect(call_method['SETTLE_DATE']).to eq(authorized_date + 1.day)
        end
        it 'constructs a hash with an `AUTHORIZED_BY` value' do
          expect(call_method['AUTHORIZED_BY']).to eq(fake_data['names'][authorized_by_offset])
        end
      end
      describe 'when an `AWAITING_AUTHORIZATION` status is passed' do
        let(:status) { securities_request_module::MAPIRequestStatus::AWAITING_AUTHORIZATION.sample }

        it 'constructs a hash with a nil value for `AUTHORIZED_DATE`' do
          expect(call_method['AUTHORIZED_DATE']).to be_nil
        end
        it 'constructs a hash with a `SETTLE_DATE` value equal to the `SUBMITTED_DATE` plus one day' do
          expect(call_method['SETTLE_DATE']).to eq(submitted_date + 1.day)
        end
        it 'constructs a hash with a nil value for `AUTHORIZED_BY`' do
          expect(call_method['AUTHORIZED_BY']).to be_nil
        end
      end
    end

    describe '`MAPI::Services::Member::SecuritiesRequests.fake_securities`' do
      let(:request_id) { rand(1000..9999) }
      let(:settlement_type) { securities_request_module::SETTLEMENT_TYPE.values.sample }
      let(:rng) { instance_double(Random, rand: 1) }
      let(:fake_data) { securities_request_module.fake('securities_requests') }
      let(:original_par) { rand(10000..999999) }
      let(:cusip) { fake_data['cusips'].sample }
      let(:description) { fake_data['descriptions'].sample }

      let(:call_method) { securities_request_module.fake_securities(request_id, settlement_type) }
      before do
        allow(securities_request_module).to receive(:fake).with('securities_requests').and_return(fake_data)
        allow(Random).to receive(:new).and_return(rng)
        allow(rng).to receive(:rand).with(eq(10000..999999)).and_return(original_par)
        allow(fake_data['cusips']).to receive(:sample).with(random: rng).and_return(cusip)
        allow(fake_data['descriptions']).to receive(:sample).with(random: rng).and_return(description)
      end

      it 'constructs an array of securities' do
        n = rand(1..6)
        allow(rng).to receive(:rand).with(eq(1..6)).and_return(n)
        expect(call_method.length).to eq(n)
      end
      it 'constructs securities with a `CUSIP` value' do
        results = call_method
        expect(results.length).to be > 0
        results.each do |result|
          expect(result['CUSIP']).to eq(cusip)
        end
      end
      it 'constructs securities with a `DESCRIPTION` value' do
        results = call_method
        expect(results.length).to be > 0
        results.each do |result|
          expect(result['DESCRIPTION']).to eq(description)
        end
      end
      it 'constructs securities with an `ORIGINAL_PAR` value' do
        results = call_method
        expect(results.length).to be > 0
        results.each do |result|
          expect(result['ORIGINAL_PAR']).to eq(original_par)
        end
      end
      describe "when the `settlement_type` is `#{securities_request_module::SSKSettlementType::FREE}`" do
        it 'constructs securities with a nil value for `PAYMENT_AMOUNT`' do
          results = securities_request_module.fake_securities(request_id, securities_request_module::SSKSettlementType::FREE)
          expect(results.length).to be > 0
          results.each do |result|
            expect(result['PAYMENT_AMOUNT']).to be_nil
          end
        end
      end
      describe "when the `settlement_type` is `#{securities_request_module::SSKSettlementType::VS_PAYMENT}`" do
        it 'constructs securities with a nil value for `PAYMENT_AMOUNT`' do
          results = securities_request_module.fake_securities(request_id, securities_request_module::SSKSettlementType::VS_PAYMENT)
          expect(results.length).to be > 0
          results.each do |result|
            expect(result['PAYMENT_AMOUNT']).to eq(original_par - (original_par/3))
          end
        end
      end
    end

    describe '`delete_request_header_details_query` class method' do
      submitted_status = securities_request_module::SSKRequestStatus::SUBMITTED
      let(:header_id) { instance_double(String) }
      let(:member_id) { instance_double(String) }
      let(:sentinel) { SecureRandom.hex }
      let(:call_method) { securities_request_module.delete_request_header_details_query(member_id, header_id) }

      before { allow(securities_request_module).to receive(:quote).and_return(SecureRandom.hex) }

      it 'returns a DELETE query' do
        expect(call_method).to match(/\A\s*DELETE\s+FROM\s+SAFEKEEPING.SSK_WEB_FORM_HEADER\s+/i)
      end
      it 'includes the `header_id` in the WHERE clause' do
        allow(securities_request_module).to receive(:quote).with(header_id).and_return(sentinel)
        expect(call_method).to match(/\sWHERE(\s+\S+\s+=\s+\S+\s+AND)*\s+HEADER_ID\s+=\s+#{sentinel}(\s+|\z)/)
      end
      it 'includes the `member_id` in the WHERE clause' do
        allow(securities_request_module).to receive(:quote).with(member_id).and_return(sentinel)
        expect(call_method).to match(/\sWHERE(\s+\S+\s+=\s+\S+\s+AND)*\s+FHLB_ID\s+=\s+#{sentinel}(\s+|\z)/)
      end
      it "includes the `#{submitted_status}` STATUS in the WHERE clause" do
        allow(securities_request_module).to receive(:quote).with(submitted_status).and_return(sentinel)
        expect(call_method).to match(/\sWHERE(\s+\S+\s+=\s+\S+\s+AND)*\s+STATUS\s+=\s+#{sentinel}(\s+|\z)/)
      end
    end
    describe '`delete_request_securities_query` class method' do
      let(:header_id) { instance_double(String) }
      let(:sentinel) { SecureRandom.hex }
      let(:call_method) { securities_request_module.delete_request_securities_query(header_id) }

      before { allow(securities_request_module).to receive(:quote).and_return(SecureRandom.hex) }

      it 'returns a DELETE query' do
        expect(call_method).to match(/\A\s*DELETE\s+FROM\s+SAFEKEEPING.SSK_WEB_FORM_DETAIL\s+/i)
      end
      it 'includes the `header_id` in the WHERE clause' do
        allow(securities_request_module).to receive(:quote).with(header_id).and_return(sentinel)
        expect(call_method).to match(/\sWHERE(\s+\S+\s+=\s+\S+\s+AND)*\s+HEADER_ID\s+=\s+#{sentinel}(\s+|\z)/)
      end
    end
    describe '`delete_request` class method' do
      let(:request_id) { rand(1000..9999) }
      let(:member_id) { rand(1000..9999) }
      let(:connection) { instance_double(ActiveRecord::ConnectionAdapters::OracleEnhancedAdapter, transaction: nil, execute: nil) }
      let(:delete_request_securities_query) { instance_double(String) }
      let(:delete_request_header_details_query) { instance_double(String) }
      let(:call_method) { securities_request_module.delete_request(app, member_id, request_id) }
      before do
        allow(ActiveRecord::Base).to receive(:connection).and_return(connection)
        allow(securities_request_module).to receive(:delete_request_securities_query).and_return(delete_request_securities_query)
        allow(securities_request_module).to receive(:delete_request_header_details_query).and_return(delete_request_header_details_query)
      end
      describe 'when `should_fake?` returns true' do
        before { allow(securities_request_module).to receive(:should_fake?).and_return(true) }
        it 'returns true' do
          expect(call_method).to be true
        end
      end
      describe 'when `should_fake?` returns false' do
        before { allow(securities_request_module).to receive(:should_fake?).and_return(false) }
        it 'executes code within a transaction where the `isolation` has been set to `:read_committed`' do
          expect(connection).to receive(:transaction).with(isolation: :read_committed)
          call_method
        end
        describe 'the transaction block' do
          before do
            allow(connection).to receive(:transaction) do |&block|
              begin
                block.call
              rescue ActiveRecord::Rollback
              end
            end
          end
          it 'generates a delete request securities query' do
            expect(securities_request_module).to receive(:delete_request_securities_query).with(request_id)
            call_method
          end
          it 'executes the delete request securities query' do
            allow(securities_request_module).to receive(:delete_request_securities_query).with(request_id).and_return(delete_request_securities_query)
            expect(connection).to receive(:execute).with(delete_request_securities_query)
            call_method
          end
          it 'generates a delete request header details query' do
            expect(securities_request_module).to receive(:delete_request_header_details_query).with(member_id, request_id)
            call_method
          end
          it 'executes the delete request header details query' do
            expect(connection).to receive(:execute).with(delete_request_header_details_query)
            call_method
          end
          it 'rolls back the transaction if the delete request header details query deletes no records' do
            allow(connection).to receive(:execute).with(delete_request_header_details_query).and_return(0)
            allow(connection).to receive(:transaction) do |&block|
              expect{block.call}.to raise_error(ActiveRecord::Rollback, 'No header details found to delete')
            end
            call_method
          end
          it 'returns false if the delete request header details query deletes no records' do
            allow(connection).to receive(:execute).with(delete_request_header_details_query).and_return(0)
            expect(call_method).to be false
          end
          it 'returns true if the delete request header details query deletes at least one record' do
            allow(connection).to receive(:execute).with(delete_request_header_details_query).and_return(1)
            expect(call_method).to be true
          end
        end
      end
    end
    describe '`validate_broker_instructions` class method' do
      let(:broker_instructions) {{
        'transaction_code' => securities_request_module::TRANSACTION_CODE.keys.sample,
        'trade_date' => instance_double(String),
        'settlement_type' => securities_request_module::SETTLEMENT_TYPE.keys.sample,
        'settlement_date' => instance_double(String),
        'pledge_to' => securities_request_module::PLEDGE_TO.keys.sample
      }}
      let(:today) { Time.zone.today }
      let(:type) { [ :release, :intake ].sample }
      let(:call_method) { securities_request_module.validate_broker_instructions(broker_instructions, app, type) }

      before do
        allow(securities_request_module).to receive(:dateify).and_return(today)
        allow(securities_request_module).to receive(:validate_broker_instructions_date)
      end

      it 'raises an error if `broker_instructions` is nil' do
        expect{securities_request_module.validate_broker_instructions(nil, app, type)}.to raise_error(MAPI::Shared::Errors::MissingFieldError, "broker_instructions must be a non-empty hash") do |error|
          expect(error.code).to eq(:broker_instructions)
        end
      end
      it 'raises an error if `broker_instructions` is an empty hash' do
        expect{securities_request_module.validate_broker_instructions({}, app, type)}.to raise_error(MAPI::Shared::Errors::MissingFieldError, "broker_instructions must be a non-empty hash") do |error|
          expect(error.code).to eq(:broker_instructions)
        end
      end
      it 'raises an error if a key is missing' do
        broker_instructions.delete('pledge_to')
        missing_key = broker_instructions.keys.sample
        broker_instructions.delete(missing_key)
        expect{call_method}.to raise_error(MAPI::Shared::Errors::MissingFieldError, /broker_instructions must contain a value for \S+/) do |error|
          expect(error.code).to eq(missing_key)
        end
      end
      [:pledge_intake, :pledge_transfer].each do |pledge_to|
        it "raises an error if `kind` is `#{pledge_to}` and `pledge_to` is missing" do
          broker_instructions.delete('pledge_to')
          expect{securities_request_module.validate_broker_instructions(broker_instructions, app, pledge_to)}.to raise_error(MAPI::Shared::Errors::ValidationError, /broker_instructions must contain a value for \S+/) do |error|
            expect(error.code).to eq("pledge_to")
          end
        end
      end
      it 'raises an error if `transaction_code` is out of range' do
        type = :release
        broker_instructions['transaction_code'] = SecureRandom.hex
        expect{call_method}.to raise_error(MAPI::Shared::Errors::InvalidFieldError, /transaction_code must be set to one of the following values: \S/) do |error|
          expect(error.code).to eq('transaction_code')
        end
      end
      it 'raises an error if `settlement_type` is out of range' do
        type = :release
        broker_instructions['settlement_type'] = SecureRandom.hex
        expect{call_method}.to raise_error(MAPI::Shared::Errors::InvalidFieldError, /settlement_type must be set to one of the following values: \S/) do |error|
          expect(error.code).to eq('settlement_type')
        end
      end
      it 'calls `dateify` on `trade_date`' do
        expect(securities_request_module).to receive(:dateify).with(broker_instructions['trade_date']).and_return(today)
        call_method
      end
      it 'calls `dateify` on `settlement_date`' do
        expect(securities_request_module).to receive(:dateify).with(broker_instructions['settlement_date']).and_return(today)
        call_method
      end
      it 'calls `validate_broker_instructions_date` with the `trade_date`' do
        allow(securities_request_module).to receive(:dateify).with(broker_instructions['trade_date']).and_return(today)
        expect(securities_request_module).to receive(:validate_broker_instructions_date).with(app, today, 'trade_date')
        call_method
      end
      it 'calls `validate_broker_instructions_date` with the `settlement_date`' do
        allow(securities_request_module).to receive(:dateify).with(broker_instructions['settlement_date']).and_return(today)
        expect(securities_request_module).to receive(:validate_broker_instructions_date).with(app, today, 'settlement_date')
        call_method
      end
      it 'raises an error if `settlement_date` occurs before the `trade_date`' do
        allow(securities_request_module).to receive(:dateify).with(broker_instructions['settlement_date']).and_return(today - 1.day)
        allow(securities_request_module).to receive(:dateify).with(broker_instructions['trade_date']).and_return(today)
        expect{call_method}.to raise_error(MAPI::Shared::Errors::CustomTypedFieldError, 'trade_date must be on or before settlement_date') do |error|
          expect(error.code).to eq(:settlement_date)
          expect(error.type).to eq(:before_trade_date)
        end
      end
    end
    describe '`validate_broker_instructions_date`' do
      let(:app) { instance_double(MAPI::ServiceApp) }
      let(:date) { instance_double(Date, :>= => true, :<= => true) }
      let(:attr_name) { SecureRandom.hex }
      let(:today) { Time.zone.today }
      let(:max_date) { today + securities_request_module::MAX_DATE_RESTRICTION }
      let(:holidays) { instance_double(Array) }
      let(:call_method) { securities_request_module.validate_broker_instructions_date(app, date, attr_name) }
      before do
        allow(MAPI::Services::Rates::Holidays).to receive(:holidays)
        allow(securities_request_module).to receive(:weekend_or_holiday?).and_return(false)
      end
      it 'fetches the holidays array from the endpoint with the proper args' do
        expect(MAPI::Services::Rates::Holidays).to receive(:holidays).with(app, today, max_date)
        call_method
      end
      it 'calls the `weekend_or_holiday?` method with the date and the holidays array' do
        allow(MAPI::Services::Rates::Holidays).to receive(:holidays).and_return(holidays)
        expect(securities_request_module).to receive(:weekend_or_holiday?).with(date, holidays).and_return(false)
        call_method
      end
      it 'raises an error if the date is a weekend or holiday' do
        allow(securities_request_module).to receive(:weekend_or_holiday?).and_return(true)
        expect{call_method}.to raise_error(MAPI::Shared::Errors::InvalidFieldError, "#{attr_name} must not be set to a weekend date or a bank holiday") do |error|
          expect(error.code).to eq(attr_name)
        end
      end
      it 'raises an error if the date occurs before today' do
        allow(date).to receive(:>=).with(today).and_return(false)
        expect{call_method}.to raise_error(MAPI::Shared::Errors::InvalidFieldError, "#{attr_name} must not occur before today") do |error|
          expect(error.code).to eq(attr_name)
        end
      end
      it 'raises an error if the date occurs after today plus the MAX_DATE_RESTRICTION' do
        allow(date).to receive(:<=).with(max_date).and_return(false)
        expect{call_method}.to raise_error(MAPI::Shared::Errors::InvalidFieldError, "#{attr_name} must not occur after 3 months from today") do |error|
          expect(error.code).to eq(attr_name)
        end
      end
      it 'does not raise an error if the provided date is within range and is not a weekend or holiday' do
        expect{call_method}.not_to raise_error
      end
    end
    describe '`validate_securities` class method' do
      let(:settlement_type) { securities_request_module::SETTLEMENT_TYPE.keys.sample }
      let(:delivery_type) { securities_request_module::DELIVERY_TYPE.keys.sample }
      let(:security) { {  'cusip' => instance_double(String),
                          'description' => instance_double(String),
                          'original_par' => rand(0...50000000),
                          'payment_amount' => instance_double(Numeric),
                          'custodian_name' => instance_double(String) } }
      let(:adx_type) { [:pledged, :unpledged ].sample }

      {
        release: ['cusip', 'description', 'original_par'],
        pledge_transfer: ['cusip', 'description', 'original_par'],
        safekept_transfer: ['cusip', 'description', 'original_par'],
        intake: ['cusip', 'original_par']
      }.each do |type, required_fields|
        describe "for `type` #{type}" do
          let(:call_method) { securities_request_module.validate_securities([security], settlement_type, delivery_type, type) }
          it 'raises an error if securities is nil' do
            expect{securities_request_module.validate_securities(nil, settlement_type, delivery_type, type)}.to raise_error(MAPI::Shared::Errors::MissingFieldError, 'securities must be an array containing at least one security') do |error|
              expect(error.code).to eq(:securities)
            end
          end
          it 'raises an error if securities is an empty array' do
            expect{securities_request_module.validate_securities([], settlement_type, delivery_type, type)}.to raise_error(MAPI::Shared::Errors::MissingFieldError, 'securities must be an array containing at least one security') do |error|
              expect(error.code).to eq(:securities)
            end
          end
          it 'raises an error if the securities array contains a nil value' do
            expect{securities_request_module.validate_securities([security, nil], settlement_type, delivery_type, type)}.to raise_error(MAPI::Shared::Errors::MissingFieldError, 'each security must be a non-empty hash') do |error|
              expect(error.code).to eq(:securities)
            end
          end
          it 'raises an error if the securities array contains an empty hash value' do
            expect{securities_request_module.validate_securities([security, {}], settlement_type, delivery_type, type)}.to raise_error(MAPI::Shared::Errors::MissingFieldError, 'each security must be a non-empty hash') do |error|
              expect(error.code).to eq(:securities)
            end
          end
          required_fields.each do |required_key|
            it "raises an error if a security is missing a `#{required_key}` value" do
              security.delete(required_key)
              expect{call_method}.to raise_error(MAPI::Shared::Errors::CustomTypedFieldError, "each security must consist of a hash containing a value for #{required_key}") do |error|
                expect(error.code).to eq(:securities)
                expect(error.type).to eq(required_key)
              end
            end
          end
          describe 'when the `settlement_type` is `vs_payment`' do
            let(:call_method) { securities_request_module.validate_securities([security], 'vs_payment', delivery_type, type) }
            if [:pledge_transfer, :safekept_transfer].include?(type)
              it 'does not raise an error if a security is missing a `payment_amount` value' do
                security.delete('payment_amount')
                expect{call_method}.not_to raise_error
              end
            else
              it 'raises an error if a security is missing a `payment_amount` value' do
                security.delete('payment_amount')
                expect{call_method}.to raise_error(MAPI::Shared::Errors::CustomTypedFieldError, 'each security must consist of a hash containing a value for payment_amount') do |error|
                  expect(error.code).to eq(:securities)
                  expect(error.type).to eq('payment_amount')
                end
              end
            end
          end
          it "raises a `CustomTypedFieldError` if `delivery_type` is `fed` and `original_par` is greater than #{MAPI::Services::Member::SecuritiesRequests::FED_AMOUNT_LIMIT}" do
            security['original_par'] = rand(50000001..99999999)
            expect{securities_request_module.validate_securities([security], settlement_type, 'fed', type)}.to raise_error(CustomTypedFieldError, "original par must be less than $#{MAPI::Services::Member::SecuritiesRequests::FED_AMOUNT_LIMIT}") do |error|
              expect(error.code).to eq(:securities)
              expect(error.type).to eq(:original_par)
            end
          end
        end
      end
    end
    describe '`validate_delivery_instructions` class method' do
      let(:delivery_instructions) {{
        delivery_type: securities_request_module::DELIVERY_TYPE.keys.sample
      }}
      let(:call_method) { securities_request_module.validate_delivery_instructions(delivery_instructions) }
      it 'raises an error if `delivery_instructions` is nil' do
        expect{securities_request_module.validate_delivery_instructions(nil)}.to raise_error(MAPI::Shared::Errors::MissingFieldError, 'delivery_instructions must be a non-empty hash') do |error|
          expect(error.code).to eq(:delivery_instructions)
        end
      end
      it 'raises an error if `delivery_instructions` is an empty hash' do
        expect{securities_request_module.validate_delivery_instructions({})}.to raise_error(MAPI::Shared::Errors::MissingFieldError, 'delivery_instructions must be a non-empty hash') do |error|
          expect(error.code).to eq(:delivery_instructions)
        end
      end
      it 'raises an error if `delivery_type` is out of range' do
        delivery_instructions['delivery_type'] = SecureRandom.hex
        expect{ call_method }.to raise_error(MAPI::Shared::Errors::InvalidFieldError, "delivery_instructions must contain the key delivery_type set to one of #{securities_request_module::DELIVERY_TYPE.keys.join(', ')}") do |error|
          expect(error.code).to eq(:delivery_type)
        end
      end
    end
    describe '`process_delivery_instructions` class method' do
      let(:delivery_type) { instance_double(String) }
      let(:delivery_instructions) {{
        'delivery_type' => delivery_type,
        'account_number' => instance_double(String),
        'aba_number' => instance_double(String)
      }}
      let(:required_keys) { instance_double(Array) }
      let(:delivery_columns) { instance_double(Array) }
      let(:delivery_values) { instance_double(Array) }
      let(:call_method) { securities_request_module.process_delivery_instructions(delivery_instructions) }
      before do
        allow(securities_request_module).to receive(:consolidate_broker_wire_address)
        allow(securities_request_module).to receive(:delivery_keys_for_delivery_type).and_return(required_keys)
        allow(securities_request_module).to receive(:format_delivery_columns).and_return(delivery_columns)
        allow(securities_request_module).to receive(:format_delivery_values).and_return(delivery_values)
      end
      it 'calls `delete(:delivery_type)` on `delivery_instructions`' do
        expect(delivery_instructions).to receive(:delete).with('delivery_type').and_return(delivery_type)
        call_method
      end
      it 'calls `consolidate_broker_wire_address` with the provided `delivery_instructions`' do
        expect(securities_request_module).to receive(:consolidate_broker_wire_address).with(delivery_instructions)
        call_method
      end
      it 'calls `delivery_keys_for_delivery_type` with the `delivery_type`' do
        expect(securities_request_module).to receive(:delivery_keys_for_delivery_type).with(delivery_type)
        call_method
      end
      it 'calls `format_delivery_columns` with the `delivery_type`' do
        expect(securities_request_module).to receive(:format_delivery_columns).with(delivery_type, any_args)
        call_method
      end
      it 'calls `format_delivery_columns` with the results of `delivery_keys_for_delivery_type`' do
        expect(securities_request_module).to receive(:format_delivery_columns).with(anything, required_keys, any_args)
        call_method
      end
      it 'calls `format_delivery_columns` with the keys from the `delivery_instructions` after deleting `delivery_type`' do
        mutated_delivery_instructions = delivery_instructions.reject{|key, value| key == 'delivery_type'}
        expect(securities_request_module).to receive(:format_delivery_columns).with(anything, anything, mutated_delivery_instructions.keys)
        call_method
      end
      it 'calls `format_delivery_values` with the results of `delivery_keys_for_delivery_type`' do
        expect(securities_request_module).to receive(:format_delivery_values).with(required_keys, any_args)
        call_method
      end
      it 'calls `format_delivery_values` with the the `delivery_instructions` after deleting `delivery_type`' do
        mutated_delivery_instructions = delivery_instructions.reject{|key, value| key == 'delivery_type'}
        expect(securities_request_module).to receive(:format_delivery_values).with(anything, mutated_delivery_instructions)
        call_method
      end
      it 'returns a hash with a `delivery_type`' do
        expect(call_method[:delivery_type]).to eq(delivery_type)
      end
      it 'returns a hash with a `delivery_columns` array equal to the result of `format_delivery_columns`' do
        expect(call_method[:delivery_columns]).to eq(delivery_columns)
      end
      it 'returns a hash with a `delivery_values` array equal to the result of `format_delivery_values`' do
        expect(call_method[:delivery_values]).to eq(delivery_values)
      end
    end
    describe '`update_request_header_details_query` class method' do
      let(:request_id) { instance_double(String) }
      let(:username) { instance_double(String) }
      let(:full_name) { instance_double(String) }
      let(:session_id) { instance_double(String) }
      let(:adx_id) { instance_double(String) }
      let(:delivery_columns) { [SecureRandom.hex, SecureRandom.hex] }
      let(:delivery_values) { [SecureRandom.hex, SecureRandom.hex] }
      let(:broker_instructions) { instance_double(Hash, :[] => nil) }
      let(:modification_by) { instance_double(String) }
      let(:broker_instruction_value) { instance_double(String) }
      let(:transaction_code) { securities_request_module::TRANSACTION_CODE.to_a.sample(1).to_h }
      let(:settlement_type) { securities_request_module::SETTLEMENT_TYPE.to_a.sample(1).to_h }
      let(:delivery_type) { securities_request_module::DELIVERY_TYPE.to_a.sample(1).to_h }
      let(:kind) { "#{adx_type}_#{intake_or_release}" }
      let(:sentinel) { SecureRandom.hex }
      let(:today) { Time.zone.today }
      let(:intake_or_release) { [ :intake, :release ].sample }
      let(:form_type) { MAPI::Services::Member::SecuritiesRequests::ADXAccountTypeMapping::SYMBOL_TO_SSK_FORM_TYPE[kind.to_sym] }
      let(:call_method) { securities_request_module.update_request_header_details_query(member_id, request_id, username, full_name, session_id, adx_id, delivery_columns, broker_instructions, delivery_type.keys.first, delivery_values, adx_type, intake_or_release) }

      before do
        allow(securities_request_module).to receive(:quote).and_return(SecureRandom.hex)
        allow(securities_request_module).to receive(:format_modification_by).with(username, session_id).and_return(modification_by)
        allow(Time.zone).to receive(:today).and_return(today)
      end

      it 'returns an UPDATE query' do
        expect(call_method).to match(/\A\s*UPDATE\s+SAFEKEEPING.SSK_WEB_FORM_HEADER\s+SET\s+/i)
      end
      it 'updates the `PLEDGE_TYPE`' do
        allow(broker_instructions).to receive(:[]).with('transaction_code').and_return(transaction_code.keys.first)
        allow(securities_request_module).to receive(:quote).with(transaction_code.values.first).and_return(sentinel)
        expect(call_method).to match(/\sSET(\s+\S+\s+=\s+\S+\s*,)*\s+PLEDGE_TYPE\s+=\s+#{sentinel}(,|\s+WHERE\s)/i)
      end
      it 'updates the `TRADE_DATE`' do
        allow(broker_instructions).to receive(:[]).with('trade_date').and_return(broker_instruction_value)
        allow(securities_request_module).to receive(:quote).with(broker_instruction_value).and_return(sentinel)
        expect(call_method).to match(/\sSET(\s+\S+\s+=\s+\S+\s*,)*\s+TRADE_DATE\s+=\s+#{sentinel}(,|\s+WHERE\s)/i)
      end
      it 'updates the `REQUEST_STATUS`' do
        allow(broker_instructions).to receive(:[]).with('settlement_type').and_return(settlement_type.keys.first)
        allow(securities_request_module).to receive(:quote).with(settlement_type.values.first).and_return(sentinel)
        expect(call_method).to match(/\sSET(\s+\S+\s+=\s+\S+\s*,)*\s+REQUEST_STATUS\s+=\s+#{sentinel}(,|\s+WHERE\s)/i)
      end
      it 'updates the `SETTLE_DATE`' do
        allow(broker_instructions).to receive(:[]).with('settlement_date').and_return(broker_instruction_value)
        allow(securities_request_module).to receive(:quote).with(broker_instruction_value).and_return(sentinel)
        expect(call_method).to match(/\sSET(\s+\S+\s+=\s+\S+\s*,)*\s+SETTLE_DATE\s+=\s+#{sentinel}(,|\s+WHERE\s)/i)
      end
      it 'updates the `DELIVER_TO`' do
        allow(securities_request_module).to receive(:quote).with(delivery_type.values.first).and_return(sentinel)
        expect(call_method).to match(/\sSET(\s+\S+\s+=\s+\S+\s*,)*\s+DELIVER_TO\s+=\s+#{sentinel}(,|\s+WHERE\s)/i)
      end
      it 'updates the `FORM_TYPE`' do
        allow(securities_request_module).to receive(:quote).with(form_type).and_return(sentinel)
        expect(call_method).to match(/\sSET(\s+\S+\s+=\s+\S+\s*,)*\s+FORM_TYPE\s+=\s+#{sentinel}(,|\s+WHERE\s)/i)
      end
      it 'updates the `LAST_MODIFIED_BY`' do
        allow(securities_request_module).to receive(:quote).with(modification_by).and_return(sentinel)
        expect(call_method).to match(/\sSET(\s+\S+\s+=\s+\S+\s*,)*\s+LAST_MODIFIED_BY\s+=\s+#{sentinel}(,|\s+WHERE\s)/i)
      end
      it 'updates the `LAST_MODIFIED_DATE`' do
        allow(securities_request_module).to receive(:quote).with(today).and_return(sentinel)
        expect(call_method).to match(/\sSET(\s+\S+\s+=\s+\S+\s*,)*\s+LAST_MODIFIED_DATE\s+=\s+#{sentinel}(,|\s+WHERE\s)/i)
      end
      it 'updates the `LAST_MODIFIED_BY_NAME`' do
        allow(securities_request_module).to receive(:quote).with(full_name).and_return(sentinel)
        expect(call_method).to match(/\sSET(\s+\S+\s+=\s+\S+\s*,)*\s+LAST_MODIFIED_BY_NAME\s+=\s+#{sentinel}(,|\s+WHERE\s)/i)
      end
      it 'updates the `PLEDGED_ADX_ID` for release' do
        allow(securities_request_module).to receive(:quote).with(adx_id).and_return(sentinel)
        expect(securities_request_module.
          update_request_header_details_query(member_id,
                                              request_id,
                                              username,
                                              full_name,
                                              session_id,
                                              adx_id,
                                              delivery_columns,
                                              broker_instructions,
                                              delivery_type.keys.first,
                                              delivery_values,
                                              :pledged,
                                              :release)).to match(
        /\sSET(\s+\S+\s+=\s+\S+\s*,)*\s+#{MAPI::Services::Member::SecuritiesRequests::ADXAccountTypeMapping::SYMBOL_TO_SQL_COLUMN_NAME[:pledged_release]}\s+=\s+#{sentinel}(,|\s+WHERE\s)/i)
      end
      it 'updates the `PLEDGED_ADX_ID` for intake' do
        allow(securities_request_module).to receive(:quote).with(adx_id).and_return(sentinel)
        expect(securities_request_module.
          update_request_header_details_query(member_id,
                                              request_id,
                                              username,
                                              full_name,
                                              session_id,
                                              adx_id,
                                              delivery_columns,
                                              broker_instructions,
                                              delivery_type.keys.first,
                                              delivery_values,
                                              :pledged,
                                              :intake)).to match(
        /\sSET(\s+\S+\s+=\s+\S+\s*,)*\s+#{MAPI::Services::Member::SecuritiesRequests::ADXAccountTypeMapping::SYMBOL_TO_SQL_COLUMN_NAME[:pledged_intake]}\s+=\s+#{sentinel}(,|\s+WHERE\s)/i)
      end
      it 'updates the `UNPLEDGED_ADX_ID` for release' do
        allow(securities_request_module).to receive(:quote).with(adx_id).and_return(sentinel)
        expect(securities_request_module.
          update_request_header_details_query(member_id,
                                              request_id,
                                              username,
                                              full_name,
                                              session_id,
                                              adx_id,
                                              delivery_columns,
                                              broker_instructions,
                                              delivery_type.keys.first,
                                              delivery_values,
                                              :unpledged,
                                              :release)).to match(
        /\sSET(\s+\S+\s+=\s+\S+\s*,)*\s+#{MAPI::Services::Member::SecuritiesRequests::ADXAccountTypeMapping::SYMBOL_TO_SQL_COLUMN_NAME[:unpledged_release]}\s+=\s+#{sentinel}(,|\s+WHERE\s)/i)
      end
      it 'updates the `UNPLEDGED_ADX_ID` for intake' do
        allow(securities_request_module).to receive(:quote).with(adx_id).and_return(sentinel)
        expect(securities_request_module.
          update_request_header_details_query(member_id,
                                              request_id,
                                              username,
                                              full_name,
                                              session_id,
                                              adx_id,
                                              delivery_columns,
                                              broker_instructions,
                                              delivery_type.keys.first,
                                              delivery_values,
                                              :unpledged,
                                              :intake)).to match(
        /\sSET(\s+\S+\s+=\s+\S+\s*,)*\s+#{MAPI::Services::Member::SecuritiesRequests::ADXAccountTypeMapping::SYMBOL_TO_SQL_COLUMN_NAME[:unpledged_intake]}\s+=\s+#{sentinel}(,|\s+WHERE\s)/i)
      end
      describe 'assigning `delivery_columns`' do
        2.times do |i|
          it "updates the column name found in `delivery_columns` at the `#{i}` index to the `#{i}` indexed value in `delivery_values` " do
            expect(call_method).to match(/\sSET(\s+\S+\s+=\s+\S+\s*,)*\s+#{delivery_columns[i]}\s+=\s+#{delivery_values[i]}(,|\s+WHERE\s)/i)
          end
        end
      end
      it 'includes the `request_id` in the WHERE clause' do
        allow(securities_request_module).to receive(:quote).with(request_id).and_return(sentinel)
        expect(call_method).to match(/\sWHERE(\s+\S+\s+=\s+\S+\s+AND)*\s+HEADER_ID\s+=\s+#{sentinel}(\s+|\z)/)
      end
      it 'includes the `member_id` in the WHERE clause' do
        allow(securities_request_module).to receive(:quote).with(member_id).and_return(sentinel)
        expect(call_method).to match(/\sWHERE(\s+\S+\s+=\s+\S+\s+AND)*\s+FHLB_ID\s+=\s+#{sentinel}(\s+|\z)/)
      end
      it 'restricts the updates to submitted queries' do
        allow(securities_request_module).to receive(:quote).with(securities_request_module::SSKRequestStatus::SUBMITTED).and_return(sentinel)
        expect(call_method).to match(/\sWHERE(\s+\S+\s+=\s+\S+\s+AND)*\s+STATUS\s+=\s+#{sentinel}(\s+|\z)/)
      end
    end
    describe '`update_request_security_query` class method' do
      let(:header_id) { instance_double(String) }
      let(:username) { instance_double(String) }
      let(:session_id) { instance_double(String) }
      let(:security) {{
        'cusip' => instance_double(String),
        'description' => instance_double(String),
        'original_par' => instance_double(Numeric),
        'payment_amount' => instance_double(Numeric)
      }}
      let(:modification_by) { instance_double(String) }
      let(:sentinel) { SecureRandom.hex }
      let(:today) { Time.zone.today }
      let(:call_method) {securities_request_module.update_request_security_query(header_id, username, session_id, security)}

      before do
        allow(securities_request_module).to receive(:quote).and_return(SecureRandom.hex)
        allow(securities_request_module).to receive(:nil_to_zero).and_return(SecureRandom.hex)
        allow(securities_request_module).to receive(:format_modification_by).with(username, session_id).and_return(modification_by)
        allow(Time.zone).to receive(:today).and_return(today)
      end

      it 'returns an UPDATE query' do
        expect(call_method).to match(/\A\s*UPDATE\s+SAFEKEEPING.SSK_WEB_FORM_DETAIL\s+SET\s+/i)
      end
      it 'updates the `DESCRIPTION`' do
        allow(securities_request_module).to receive(:quote).with(security['description']).and_return(sentinel)
        expect(call_method).to match(/\sSET(\s+\S+\s+=\s+\S+\s*,)*\s+DESCRIPTION\s+=\s+#{sentinel}(,|\s+WHERE\s)/i)
      end
      it 'updates the `ORIGINAL_PAR`' do
        allow(securities_request_module).to receive(:nil_to_zero).with(security['original_par']).and_return(security['original_par'])
        allow(securities_request_module).to receive(:quote).with(security['original_par']).and_return(sentinel)
        expect(call_method).to match(/\sSET(\s+\S+\s+=\s+\S+\s*,)*\s+ORIGINAL_PAR\s+=\s+#{sentinel}(,|\s+WHERE\s)/i)
      end
      it 'updates the `PAYMENT_AMOUNT`' do
        allow(securities_request_module).to receive(:nil_to_zero).with(security['payment_amount']).and_return(security['payment_amount'])
        allow(securities_request_module).to receive(:quote).with(security['payment_amount']).and_return(sentinel)
        expect(call_method).to match(/\sSET(\s+\S+\s+=\s+\S+\s*,)*\s+PAYMENT_AMOUNT\s+=\s+#{sentinel}(,|\s+WHERE\s)/i)
      end
      it 'updates the `LAST_MODIFIED_DATE`' do
        allow(securities_request_module).to receive(:quote).with(today).and_return(sentinel)
        expect(call_method).to match(/\sSET(\s+\S+\s+=\s+\S+\s*,)*\s+LAST_MODIFIED_DATE\s+=\s+#{sentinel}(,|\s+WHERE\s)/i)
      end
      it 'updates the `LAST_MODIFIED_BY`' do
        allow(securities_request_module).to receive(:quote).with(modification_by).and_return(sentinel)
        expect(call_method).to match(/\sSET(\s+\S+\s+=\s+\S+\s*,)*\s+LAST_MODIFIED_BY\s+=\s+#{sentinel}(,|\s+WHERE\s)/i)
      end
      it 'includes the `cusip` in the WHERE clause' do
        allow(securities_request_module).to receive(:quote).with(security['cusip']).and_return(sentinel)
        expect(call_method).to match(/\sWHERE(\s+\S+\s+=\s+\S+\s+AND)*\s+CUSIP\s+=\s+UPPER\(#{sentinel}\)(\s+|\z)/)
      end
      it 'includes the `header_id` in the WHERE clause' do
        allow(securities_request_module).to receive(:quote).with(header_id).and_return(sentinel)
        expect(call_method).to match(/\sWHERE(\s+\S+\s+=\s+\S+\s+AND)*\s+HEADER_ID\s+=\s+#{sentinel}(\s+|\z)/)
      end
    end
    describe '`delete_request_securities_by_cusip_query` class method' do
      let(:request_id) { instance_double(String) }
      let(:cusip) { instance_double(String) }
      let(:sentinel) { SecureRandom.hex }
      let(:call_method) { securities_request_module.delete_request_securities_by_cusip_query(request_id, [cusip]) }

      before { allow(securities_request_module).to receive(:quote).and_return(SecureRandom.hex) }

      it 'returns a DELETE query' do
        expect(call_method).to match(/\A\s*DELETE\s+FROM\s+SAFEKEEPING.SSK_WEB_FORM_DETAIL\s+/i)
      end
      it 'includes the `request_id` in the WHERE clause' do
        allow(securities_request_module).to receive(:quote).with(request_id).and_return(sentinel)
        expect(call_method).to match(/\sWHERE(\s+\S+\s+=\s+\S+\s+AND)*\s+HEADER_ID\s+=\s+#{sentinel}(\s+|\z)/)
      end
      it 'includes the `cusip` in the WHERE clause' do
        allow(securities_request_module).to receive(:quote).with(cusip).and_return(sentinel)
        expect(call_method).to match(/\sWHERE(\s+\S+\s+=\s+\S+\s+AND)*\s+CUSIP\s+NOT\s+IN\s+\(#{sentinel}\)(\s+|\z)/)
      end
    end
    describe '`update_release` class method' do
      let(:app) { double(MAPI::ServiceApp, logger: double('logger')) }
      let(:member_id) { rand(9999..99999) }
      let(:request_id) { instance_double(String) }
      let(:adx_type) { [:pledged, :unpledged].sample }
      let(:adx_type_string) { MAPI::Services::Member::SecuritiesRequests::ADXAccountTypeMapping::SYMBOL_TO_STRING[adx_type] }
      let(:username) { instance_double(String) }
      let(:full_name) { instance_double(String) }
      let(:session_id) { instance_double(String) }
      let(:delivery_type) { instance_double(String) }
      let(:delivery_instructions) {{
        'delivery_type' => delivery_type,
        'account_number' => instance_double(String),
        'aba_number' => instance_double(String)
      }}
      let(:processed_delivery_instructions) {{
        delivery_type: delivery_type,
        delivery_columns: instance_double(Array),
        delivery_values: instance_double(Array)
      }}
      let(:broker_instructions) {{
        'transaction_code' => securities_request_module::TRANSACTION_CODE.keys.sample,
        'trade_date' => instance_double(String),
        'settlement_type' => securities_request_module::SETTLEMENT_TYPE.keys.sample,
        'settlement_date' => instance_double(String)
      }}
      let(:security) {{
        'cusip' => SecureRandom.hex,
        'description' => instance_double(String),
        'original_par' => instance_double(Numeric),
        'payment_amount' => instance_double(Numeric)
      }}
      let(:securities) { [security] }
      let(:kind) { double('A Kind') }
      let(:call_method) { securities_request_module.update_release(app, member_id, request_id, username, full_name, session_id, broker_instructions, delivery_instructions, securities, kind) }

      before do
        allow(securities_request_module).to receive(:validate_broker_instructions)
        allow(securities_request_module).to receive(:validate_securities)
        allow(securities_request_module).to receive(:validate_delivery_instructions)
        allow(securities_request_module).to receive(:process_delivery_instructions).and_return(processed_delivery_instructions)
        allow(securities_request_module).to receive(:should_fake?).and_return(true)
        allow(securities_request_module).to receive(:validate_kind).with(:release, kind).and_return(true)
      end

      it 'calls `validate_broker_instructions` with the `broker_instructions` arg' do
        expect(securities_request_module).to receive(:validate_broker_instructions).with(broker_instructions, anything, anything)
        call_method
      end
      it 'calls `validate_broker_instructions` with the app as an arg' do
        expect(securities_request_module).to receive(:validate_broker_instructions).with(anything, app, anything)
        call_method
      end
      it 'calls `validate_delivery_instructions` with the `delivery_instructions` arg' do
        expect(securities_request_module).to receive(:validate_delivery_instructions).with(delivery_instructions)
        call_method
      end
      it 'calls `validate_securities` with the `securities` arg' do
        expect(securities_request_module).to receive(:validate_securities).with(securities, any_args)
        call_method
      end
      it 'calls `validate_securities` with the `settlement_type` arg from the broker instructions' do
        expect(securities_request_module).to receive(:validate_securities).with(anything, broker_instructions['settlement_type'], anything, anything)
        call_method
      end
      it 'calls `validate_securities` with the `delivery_type` arg from the delivery instructions' do
        expect(securities_request_module).to receive(:validate_securities).with(anything, anything, delivery_instructions['delivery_type'], anything)
        call_method
      end
      it 'calls `validate_securities` with `:release`' do
        expect(securities_request_module).to receive(:validate_securities).with(anything, anything, anything, :release)
        call_method
      end
      it 'calls `process_delivery_instructions` with the `delivery_instructions` arg' do
        expect(securities_request_module).to receive(:process_delivery_instructions).with(delivery_instructions)
        call_method
      end
      describe 'when `should_fake?` returns true' do
        it 'returns true' do
          expect(call_method).to be true
        end
      end
      describe 'when `should_fake` returns false' do
        queries = [
          :delete_request_securities_by_cusip_query,
          :adx_query,
          :update_request_security_query,
          :insert_security_query,
          :ssk_id_query,
          :release_request_securities_query,
          :request_header_details_query,
          :update_request_header_details_query
        ]
        queries.each do |query|
          let(query) { instance_double(String) }
        end
        let(:adx_id) { instance_double(String) }
        let(:detail_id) { rand(1000..9999) }
        let(:ssk_id) { rand(1000..9999) }
        let(:existing_header) { instance_double(Hash) }
        let(:old_security) { security.clone.with_indifferent_access }

        before do
          allow(securities_request_module).to receive(:should_fake?).and_return(false)
          allow(securities_request_module).to receive(:execute_sql)
          allow(securities_request_module).to receive(:execute_sql).with(anything, delete_request_securities_by_cusip_query).and_return(true)
          allow(securities_request_module).to receive(:execute_sql_single_result)
          allow(securities_request_module).to receive(:execute_sql_single_result).with(anything, adx_query, any_args).and_return(adx_id)
          allow(securities_request_module).to receive(:execute_sql_single_result).with(anything, ssk_id_query, any_args).and_return(ssk_id)
          allow(securities_request_module).to receive(:execute_sql_single_result).with(anything, securities_request_module::NEXT_ID_SQL, any_args).and_return(detail_id)
          allow(securities_request_module).to receive(:fetch_hashes)
          allow(securities_request_module).to receive(:fetch_hash).with(anything, request_header_details_query).and_return(existing_header)
          allow(securities_request_module).to receive(:map_hash_values).and_return(existing_header)
          allow(securities_request_module).to receive(:header_has_changed)
          allow(securities_request_module).to receive(:format_securities).and_return([old_security])
          allow(securities_request_module).to receive(:security_has_changed).and_return(false)

          queries.each do |query|
            allow(securities_request_module).to receive(query).and_return(send(query))
          end
        end
        it 'executes code within a transaction where the `isolation` has been set to `:read_committed`' do
          expect(ActiveRecord::Base).to receive(:transaction).with(isolation: :read_committed)
          call_method
        end
        it 'calls `get_adx_type_from_security` with the appropriate arguments' do
          expect(securities_request_module).to receive(:get_adx_type_from_security).with(app, security)
          call_method
        end
        describe 'the transaction block' do
          before do
            allow(ActiveRecord::Base).to receive(:transaction).and_yield
            allow(securities_request_module).to receive(:get_adx_type_from_security).and_return(adx_type)
          end
          it 'passes the `logger` whenever it calls `execute_sql`' do
            expect(securities_request_module).to receive(:execute_sql).with(app.logger, any_args)
            call_method
          end
          it 'passes the `logger` whenever it calls `fetch_hashes`' do
            expect(securities_request_module).to receive(:fetch_hashes).with(app.logger, any_args)
            call_method
          end
          it 'passes the app whenever it calls `execute_sql_single_result`' do
            expect(securities_request_module).to receive(:execute_sql_single_result).with(app, any_args)
            call_method
          end
          describe 'deleting the old securities associated with the request_id that are not part of the new securities array' do
            it 'contructs the `delete_request_securities_by_cusip_query` with the `request_id`' do
              expect(securities_request_module).to receive(:delete_request_securities_by_cusip_query).with(request_id, anything)
              call_method
            end
            it 'contructs the `delete_request_securities_by_cusip_query` with an array of cusips from the passed securities' do
              expect(securities_request_module).to receive(:delete_request_securities_by_cusip_query).with(anything, [security['cusip']])
              call_method
            end
            it 'executes the SQL with the results of `delete_request_securities_by_cusip_query`' do
              expect(securities_request_module).to receive(:execute_sql).with(anything, delete_request_securities_by_cusip_query)
              call_method
            end
            describe 'when the SQL execution returns nil' do
              before { allow(securities_request_module).to receive(:execute_sql).with(anything, delete_request_securities_by_cusip_query).and_return(nil) }

              it 'rolls back the transaction by raising an error' do
                expect{call_method}.to raise_error(MAPI::Shared::Errors::SQLError, 'Failed to delete old security release request detail by CUSIP')
              end
            end
          end
          describe 'fetching the `adx_id`' do
            it 'constructs the `adx_query` with the `member_id` and `adx_type`' do
              expect(securities_request_module).to receive(:adx_query).with(member_id, adx_type)
              call_method
            end
            it 'calls `execute_sql_single_result` with the results of `adx_query`' do
              expect(securities_request_module).to receive(:execute_sql_single_result).with(anything, adx_query, any_args)
              call_method
            end
          end
          describe 'fetching `existing_securities`' do
            it 'constructs the `release_request_securities_query` with the `request_id`' do
              expect(securities_request_module).to receive(:release_request_securities_query).with(request_id)
              call_method
            end
            it 'calls `fetch_hashes` with the results of `release_request_securities_query`' do
              expect(securities_request_module).to receive(:fetch_hashes).with(anything, release_request_securities_query)
              call_method
            end
            it 'formats the securities that are returned by `fetch_hashes`' do
              fetched_hashes = instance_double(Array)
              allow(securities_request_module).to receive(:fetch_hashes).with(anything, release_request_securities_query).and_return(fetched_hashes)
              expect(securities_request_module).to receive(:format_securities).with(fetched_hashes)
              call_method
            end
          end
          describe 'handling securities' do
            describe 'when the passed security is new' do
              before do
                allow(securities_request_module).to receive(:format_securities).and_return([])
                allow(securities_request_module).to receive(:execute_sql).with(anything, insert_security_query).and_return(1)
              end

              describe 'fetching the `ssk_id`' do
                it 'constructs the `ssk_id_query` with the `member_id`' do
                  expect(securities_request_module).to receive(:ssk_id_query).with(member_id, any_args)
                  call_method
                end
                it 'constructs the `ssk_id_query` with the `adx_id`' do
                  expect(securities_request_module).to receive(:ssk_id_query).with(anything, adx_id, any_args)
                  call_method
                end
                it 'constructs the `ssk_id_query` with the `cusip` from the security' do
                  expect(securities_request_module).to receive(:ssk_id_query).with(anything, anything, security['cusip'])
                  call_method
                end
                it 'calls `execute_sql_single_result` with the result of `ssk_id_query`' do
                  expect(securities_request_module).to receive(:execute_sql_single_result).with(anything, ssk_id_query, any_args)
                  call_method
                end
                it 'calls `execute_sql_single_result` with `SSK ID`' do
                  expect(securities_request_module).to receive(:execute_sql_single_result).with(anything, anything, 'SSK ID')
                  call_method
                end
                it 'raises an error if the `SSK_ID` can\'t be found' do
                  allow(securities_request_module).to receive(:ssk_id_query).with(member_id, adx_id, security['cusip']).and_return(nil)
                  expect { call_method }.to raise_error(Exception)
                end
              end
              describe 'fetching the `detail_id`' do
                it 'calls `execute_sql_single_result` with the `NEXT_ID_SQL` sql query' do
                  expect(securities_request_module).to receive(:execute_sql_single_result).with(anything, securities_request_module::NEXT_ID_SQL, any_args)
                  call_method
                end
                it 'calls `execute_sql_single_result` with `Next ID Sequence`' do
                  expect(securities_request_module).to receive(:execute_sql_single_result).with(anything, anything, 'Next ID Sequence')
                  call_method
                end
              end
              describe 'adding the new security to the database' do
                it 'constructs the `insert_security_query` with the `request_id`' do
                  expect(securities_request_module).to receive(:insert_security_query).with(request_id, any_args)
                  call_method
                end
                it 'constructs the `insert_security_query` with the `detail_id`' do
                  expect(securities_request_module).to receive(:insert_security_query).with(anything, detail_id, any_args)
                  call_method
                end
                it 'constructs the `insert_security_query` with the `username`' do
                  expect(securities_request_module).to receive(:insert_security_query).with(anything, anything, username, any_args)
                  call_method
                end
                it 'constructs the `insert_security_query` with the `session_id`' do
                  expect(securities_request_module).to receive(:insert_security_query).with(anything, anything, anything, session_id, any_args)
                  call_method
                end
                it 'constructs the `insert_security_query` with the `security`' do
                  expect(securities_request_module).to receive(:insert_security_query).with(anything, anything, anything, anything, security, any_args)
                  call_method
                end
                it 'constructs the `insert_security_query` with the `ssk_id`' do
                  expect(securities_request_module).to receive(:insert_security_query).with(anything, anything, anything, anything, anything, ssk_id)
                  call_method
                end
                it 'calls `execute_sql` with the result of `insert_security_query`' do
                  expect(securities_request_module).to receive(:execute_sql).with(anything, insert_security_query)
                  call_method
                end
                describe 'when the SQL execution returns nil' do
                  before { allow(securities_request_module).to receive(:execute_sql).with(anything, insert_security_query).and_return(nil) }

                  it 'rolls back the transaction by raising an error' do
                    expect{call_method}.to raise_error(MAPI::Shared::Errors::SQLError, 'Failed to insert new security release request detail')
                  end
                end
              end
            end
            describe 'when the passed security already exists and has changed' do
              let(:old_security) { cloned_security =  security.clone; cloned_security['description'] = SecureRandom.hex; cloned_security.with_indifferent_access }

              before do
                allow(securities_request_module).to receive(:format_securities).and_return([old_security])
                allow(securities_request_module).to receive(:security_has_changed).and_return(true)
                allow(securities_request_module).to receive(:execute_sql).with(anything, update_request_security_query).and_return(1)
              end
              it 'calls `security_has_changed` with the new security' do
                expect(securities_request_module).to receive(:security_has_changed).with(security, any_args).and_return(true)
                call_method
              end
              it 'calls `security_has_changed` with the old security' do
                expect(securities_request_module).to receive(:security_has_changed).with(anything, old_security).and_return(true)
                call_method
              end
              it 'constructs the `update_request_security_query` with the `request_id`' do
                expect(securities_request_module).to receive(:update_request_security_query).with(request_id, any_args)
                call_method
              end
              it 'constructs the `update_request_security_query` with the `username`' do
                expect(securities_request_module).to receive(:update_request_security_query).with(anything, username, any_args)
                call_method
              end
              it 'constructs the `update_request_security_query` with the `session_id`' do
                expect(securities_request_module).to receive(:update_request_security_query).with(anything, anything, session_id, any_args)
                call_method
              end
              it 'constructs the `update_request_security_query` with the `security`' do
                expect(securities_request_module).to receive(:update_request_security_query).with(anything, anything, anything, security)
                call_method
              end
              it 'calls `execute_sql` with the result of `update_request_security_query`' do
                expect(securities_request_module).to receive(:execute_sql).with(anything, update_request_security_query)
                call_method
              end
              describe 'when the SQL execution returns nil' do
                before { allow(securities_request_module).to receive(:execute_sql).with(anything, update_request_security_query).and_return(nil) }

                it 'rolls back the transaction by raising an error' do
                  expect{call_method}.to raise_error(MAPI::Shared::Errors::SQLError, 'Failed to update security release request detail')
                end
              end
            end
            describe 'when the passed security already exists but has not changed' do
              let(:old_security) { security.clone.with_indifferent_access }

              before do
                allow(securities_request_module).to receive(:format_securities).and_return([old_security])
                allow(securities_request_module).to receive(:security_has_changed).and_return(false)
              end
              it 'calls `security_has_changed` with the new security' do
                expect(securities_request_module).to receive(:security_has_changed).with(security, any_args).and_return(false)
                call_method
              end
              it 'calls `security_has_changed` with the old security' do
                expect(securities_request_module).to receive(:security_has_changed).with(anything, old_security).and_return(false)
                call_method
              end
              it 'does not execute the `update_request_security_query` sql' do
                expect(securities_request_module).not_to receive(:execute_sql).with(anything, update_request_security_query)
                call_method
              end
            end
          end
          describe 'handling the header details' do
            let(:old_security) { security.clone.with_indifferent_access }

            before do
              allow(securities_request_module).to receive(:format_securities).and_return([old_security])
              allow(securities_request_module).to receive(:security_has_changed).and_return(false)
            end

            describe 'fetching the `existing_header`' do
              it 'constructs the `request_header_details_query` with the `member_id`' do
                expect(securities_request_module).to receive(:request_header_details_query).with(member_id, anything)
                call_method
              end
              it 'constructs the `request_header_details_query` with the `request_id`' do
                expect(securities_request_module).to receive(:request_header_details_query).with(anything, request_id)
                call_method
              end
              it 'calls `fetch_hash` with the `logger`' do
                expect(securities_request_module).to receive(:fetch_hash).with(app.logger, any_args)
                call_method
              end
              it 'calls `fetch_hash` with result of `request_header_details_query`' do
                expect(securities_request_module).to receive(:fetch_hash).with(anything, request_header_details_query)
                call_method
              end
              describe 'when the SQL execution returns nil' do
                before do
                  allow(securities_request_module).to receive(:fetch_hash).with(anything, request_header_details_query).and_return(nil)
                end

                it 'rolls back the transaction by raising an error' do
                  expect{call_method}.to raise_error(MAPI::Shared::Errors::SQLError, 'No header details found to update')
                end
              end
              it 'calls `map_hash_values` with the existing header' do
                expect(securities_request_module).to receive(:map_hash_values).with(existing_header, anything)
                call_method
              end
              it 'calls `map_hash_values` with the `REQUEST_HEADER_MAPPING` mapping' do
                expect(securities_request_module).to receive(:map_hash_values).with(anything, securities_request_module::REQUEST_HEADER_MAPPING)
                call_method
              end
              it 'calls `header_has_changed` with the mapped `existing_header`' do
                expect(securities_request_module).to receive(:header_has_changed).with(existing_header, any_args)
                call_method
              end
              it 'calls `header_has_changed` with the provided `broker_instructions`' do
                expect(securities_request_module).to receive(:header_has_changed).with(anything, broker_instructions, any_args)
                call_method
              end
              it 'calls `header_has_changed` with the pre-processed `delivery_instructions`' do
                expect(securities_request_module).to receive(:header_has_changed).with(anything, anything, delivery_instructions)
                call_method
              end
              describe 'when the header details have changed' do
                before do
                  allow(securities_request_module).to receive(:header_has_changed).and_return(true)
                  allow(securities_request_module).to receive(:execute_sql).with(anything, update_request_header_details_query).and_return(1)
                end

                it 'constructs the `update_request_header_details_query` with the `member_id`' do
                  expect(securities_request_module).to receive(:update_request_header_details_query).with(member_id, any_args)
                  call_method
                end
                it 'constructs the `update_request_header_details_query` with the `request_id`' do
                  expect(securities_request_module).to receive(:update_request_header_details_query).with(anything, request_id, any_args)
                  call_method
                end
                it 'constructs the `update_request_header_details_query` with the `username`' do
                  expect(securities_request_module).to receive(:update_request_header_details_query).with(anything, anything, username, any_args)
                  call_method
                end
                it 'constructs the `update_request_header_details_query` with the `full_name`' do
                  expect(securities_request_module).to receive(:update_request_header_details_query).with(anything, anything, anything, full_name, any_args)
                  call_method
                end
                it 'constructs the `update_request_header_details_query` with the `session_id`' do
                  expect(securities_request_module).to receive(:update_request_header_details_query).with(anything, anything, anything, anything, session_id, any_args)
                  call_method
                end
                it 'constructs the `update_request_header_details_query` with the `adx_id`' do
                  expect(securities_request_module).to receive(:update_request_header_details_query).with(anything, anything, anything, anything, anything, adx_id, any_args)
                  call_method
                end
                it 'constructs the `update_request_header_details_query` with the `delivery_columns` from the processed delivery_instructions' do
                  expect(securities_request_module).to receive(:update_request_header_details_query).with(anything, anything, anything, anything, anything, anything, processed_delivery_instructions[:delivery_columns], any_args)
                  call_method
                end
                it 'constructs the `update_request_header_details_query` with the `broker_instructions`' do
                  expect(securities_request_module).to receive(:update_request_header_details_query).with(anything, anything, anything, anything, anything, anything, anything, broker_instructions, any_args)
                  call_method
                end
                it 'constructs the `update_request_header_details_query` with the `delivery_type` from the processed delivery_instructions' do
                  expect(securities_request_module).to receive(:update_request_header_details_query).with(anything, anything, anything, anything, anything, anything, anything, anything, processed_delivery_instructions[:delivery_type], any_args)
                  call_method
                end
                it 'constructs the `update_request_header_details_query` with the `delivery_values` from the processed delivery_instructions' do
                  expect(securities_request_module).to receive(:update_request_header_details_query).with(anything, anything, anything, anything, anything, anything, anything, anything, anything, processed_delivery_instructions[:delivery_values], adx_type, :release)
                  call_method
                end
                it 'calls `execute_sql` with the result of `update_request_header_details_query`' do
                  expect(securities_request_module).to receive(:execute_sql).with(anything, update_request_header_details_query)
                  call_method
                end
                describe 'when the SQL execution returns nil' do
                  before { allow(securities_request_module).to receive(:execute_sql).with(anything, update_request_header_details_query).and_return(nil) }

                  it 'rolls back the transaction by raising an error' do
                    expect{call_method}.to raise_error(MAPI::Shared::Errors::SQLError, 'No header details found to update')
                  end
                end
                describe 'when the SQL execution effects no records' do
                  before { allow(securities_request_module).to receive(:execute_sql).with(anything, update_request_header_details_query).and_return(0) }

                  it 'rolls back the transaction by raising an error' do
                    expect{call_method}.to raise_error(MAPI::Shared::Errors::SQLError, 'No header details found to update')
                  end
                end
                it 'returns true if the SQL execution effects a record' do
                  allow(securities_request_module).to receive(:execute_sql).with(anything, update_request_header_details_query).and_return(1)
                  expect(call_method).to be true
                end
              end
              describe 'when the header details have not changed' do
                before { allow(securities_request_module).to receive(:header_has_changed).and_return(false) }

                it 'returns true' do
                  expect(call_method).to be true
                end
              end
            end
          end
        end
      end
    end

    describe '`update_intake` class method' do
      let(:app) { double(MAPI::ServiceApp, logger: double('logger')) }
      let(:member_id) { rand(9999..99999) }
      let(:request_id) { instance_double(String) }
      let(:kind) { double('A Kind') }
      let(:username) { instance_double(String) }
      let(:full_name) { instance_double(String) }
      let(:session_id) { instance_double(String) }
      let(:delivery_type) { instance_double(String) }
      let(:delivery_instructions) {{
        'delivery_type' => delivery_type,
        'account_number' => instance_double(String),
        'aba_number' => instance_double(String)
      }}
      let(:processed_delivery_instructions) {{
        delivery_type: delivery_type,
        delivery_columns: instance_double(Array),
        delivery_values: instance_double(Array)
      }}
      let(:broker_instructions) {{
        'transaction_code' => securities_request_module::TRANSACTION_CODE.keys.sample,
        'trade_date' => instance_double(String),
        'settlement_type' => securities_request_module::SETTLEMENT_TYPE.keys.sample,
        'settlement_date' => instance_double(String)
      }}
      let(:security) {{
        'cusip' => SecureRandom.hex,
        'description' => instance_double(String),
        'original_par' => instance_double(Numeric),
        'payment_amount' => instance_double(Numeric),
        'custody_account_type' => MAPI::Services::Member::SecuritiesRequests::ADXAccountTypeMapping::SYMBOL_TO_STRING[pledged_or_unpledged]
      }}
      let(:pledged_or_unpledged) { [ :pledged, :unpledged ].sample }
      let(:securities) { [security] }
      let(:call_method) { securities_request_module.update_intake(app, member_id, request_id, username, full_name, session_id, broker_instructions, delivery_instructions, securities, kind) }

      before do
        allow(securities_request_module).to receive(:validate_broker_instructions)
        allow(securities_request_module).to receive(:validate_securities)
        allow(securities_request_module).to receive(:validate_delivery_instructions)
        allow(securities_request_module).to receive(:process_delivery_instructions).and_return(processed_delivery_instructions)
        allow(securities_request_module).to receive(:should_fake?).and_return(true)
        allow(securities_request_module).to receive(:validate_kind).with(:intake, kind).and_return(true)
      end

      it 'calls `validate_broker_instructions` with the `broker_instructions` arg' do
        expect(securities_request_module).to receive(:validate_broker_instructions).with(broker_instructions, anything, anything)
        call_method
      end
      it 'calls `validate_broker_instructions` with the app as an arg' do
        expect(securities_request_module).to receive(:validate_broker_instructions).with(anything, app, anything)
        call_method
      end
      it 'calls `validate_delivery_instructions` with the `delivery_instructions` arg' do
        expect(securities_request_module).to receive(:validate_delivery_instructions).with(delivery_instructions)
        call_method
      end
      it 'calls `validate_securities` with the `securities` arg' do
        expect(securities_request_module).to receive(:validate_securities).with(securities, any_args)
        call_method
      end
      it 'calls `validate_securities` with the `settlement_type` arg from the broker instructions' do
        expect(securities_request_module).to receive(:validate_securities).with(anything, broker_instructions['settlement_type'], anything, :intake)
        call_method
      end
      it 'calls `validate_securities` with the `delivery_type` arg from the delivery instructions' do
        expect(securities_request_module).to receive(:validate_securities).with(anything, anything, delivery_instructions['delivery_type'], :intake)
        call_method
      end
      it 'calls `process_delivery_instructions` with the `delivery_instructions` arg' do
        expect(securities_request_module).to receive(:process_delivery_instructions).with(delivery_instructions)
        call_method
      end
      describe 'when `should_fake?` returns true' do
        it 'returns true' do
          expect(call_method).to be true
        end
      end
      describe 'when `should_fake` returns false' do
        queries = [
          :delete_request_securities_by_cusip_query,
          :adx_query,
          :update_request_security_query,
          :insert_security_query,
          :release_request_securities_query,
          :request_header_details_query,
          :update_request_header_details_query
        ]
        queries.each do |query|
          let(query) { instance_double(String) }
        end
        let(:adx_id) { instance_double(String) }
        let(:detail_id) { rand(1000..9999) }
        let(:existing_header) { instance_double(Hash) }
        let(:old_security) { security.clone.with_indifferent_access }

        before do
          allow(securities_request_module).to receive(:should_fake?).and_return(false)
          allow(securities_request_module).to receive(:execute_sql)
          allow(securities_request_module).to receive(:execute_sql).with(anything, delete_request_securities_by_cusip_query).and_return(true)
          allow(securities_request_module).to receive(:execute_sql_single_result)
          allow(securities_request_module).to receive(:execute_sql_single_result).with(anything, adx_query, any_args).and_return(adx_id)
          allow(securities_request_module).to receive(:execute_sql_single_result).with(anything, securities_request_module::NEXT_ID_SQL, any_args).and_return(detail_id)
          allow(securities_request_module).to receive(:fetch_hashes)
          allow(securities_request_module).to receive(:fetch_hash).with(anything, request_header_details_query).and_return(existing_header)
          allow(securities_request_module).to receive(:map_hash_values).and_return(existing_header)
          allow(securities_request_module).to receive(:header_has_changed)
          allow(securities_request_module).to receive(:format_securities).and_return([old_security])
          allow(securities_request_module).to receive(:security_has_changed).and_return(false)

          queries.each do |query|
            allow(securities_request_module).to receive(query).and_return(send(query))
          end
        end
        it 'executes code within a transaction where the `isolation` has been set to `:read_committed`' do
          expect(ActiveRecord::Base).to receive(:transaction).with(isolation: :read_committed)
          call_method
        end
        describe 'the transaction block' do
          before do
            allow(ActiveRecord::Base).to receive(:transaction).and_yield
          end
          it 'passes the `logger` whenever it calls `execute_sql`' do
            expect(securities_request_module).to receive(:execute_sql).with(app.logger, any_args)
            call_method
          end
          it 'passes the `logger` whenever it calls `fetch_hashes`' do
            expect(securities_request_module).to receive(:fetch_hashes).with(app.logger, any_args)
            call_method
          end
          it 'passes the app whenever it calls `execute_sql_single_result`' do
            expect(securities_request_module).to receive(:execute_sql_single_result).with(app, any_args)
            call_method
          end
          describe 'deleting the old securities associated with the request_id that are not part of the new securities array' do
            it 'contructs the `delete_request_securities_by_cusip_query` with the `request_id`' do
              expect(securities_request_module).to receive(:delete_request_securities_by_cusip_query).with(request_id, anything)
              call_method
            end
            it 'contructs the `delete_request_securities_by_cusip_query` with an array of cusips from the passed securities' do
              expect(securities_request_module).to receive(:delete_request_securities_by_cusip_query).with(anything, [security['cusip']])
              call_method
            end
            it 'executes the SQL with the results of `delete_request_securities_by_cusip_query`' do
              expect(securities_request_module).to receive(:execute_sql).with(anything, delete_request_securities_by_cusip_query)
              call_method
            end
            describe 'when the SQL execution returns nil' do
              before { allow(securities_request_module).to receive(:execute_sql).with(anything, delete_request_securities_by_cusip_query).and_return(nil) }

              it 'rolls back the transaction by raising an error' do
                expect{call_method}.to raise_error(MAPI::Shared::Errors::SQLError, 'Failed to delete old security release request detail by CUSIP')
              end
            end
          end
          describe 'fetching the `adx_id`' do

            describe 'adx account' do
              before do
                allow(securities_request_module).to receive(:validate_kind).and_return(true)
              end
              it 'constructs the `adx_query` with `pledged` when the kind is `pledge_intake`' do
                expect(securities_request_module).to receive(:adx_query).with(anything, :pledged)
                securities_request_module.update_intake(app, member_id, request_id, username, full_name, session_id, broker_instructions, delivery_instructions, securities, :pledge_intake)
              end
              it 'constructs the `adx_query` with `pledged` when the kind is `safekept_intake`' do
                expect(securities_request_module).to receive(:adx_query).with(anything, :unpledged)
                securities_request_module.update_intake(app, member_id, request_id, username, full_name, session_id, broker_instructions, delivery_instructions, securities, :safekept_intake)
              end
            end
            it 'constructs the `adx_query` with the `member_id`' do
              expect(securities_request_module).to receive(:adx_query).with(member_id, anything)
              call_method
            end
            it 'calls `execute_sql_single_result` with the results of `adx_query`' do
              expect(securities_request_module).to receive(:execute_sql_single_result).with(anything, adx_query, any_args)
              call_method
            end
          end
          describe 'fetching `existing_securities`' do
            it 'constructs the `release_request_securities_query` with the `request_id`' do
              expect(securities_request_module).to receive(:release_request_securities_query).with(request_id)
              call_method
            end
            it 'calls `fetch_hashes` with the results of `release_request_securities_query`' do
              expect(securities_request_module).to receive(:fetch_hashes).with(anything, release_request_securities_query)
              call_method
            end
            it 'formats the securities that are returned by `fetch_hashes`' do
              fetched_hashes = instance_double(Array)
              allow(securities_request_module).to receive(:fetch_hashes).with(anything, release_request_securities_query).and_return(fetched_hashes)
              expect(securities_request_module).to receive(:format_securities).with(fetched_hashes)
              call_method
            end
          end
          describe 'handling securities' do
            describe 'when the passed security is new' do
              before do
                allow(securities_request_module).to receive(:format_securities).and_return([])
                allow(securities_request_module).to receive(:execute_sql).with(anything, insert_security_query).and_return(1)
              end
              describe 'fetching the `detail_id`' do
                it 'calls `execute_sql_single_result` with the `NEXT_ID_SQL` sql query' do
                  expect(securities_request_module).to receive(:execute_sql_single_result).with(anything, securities_request_module::NEXT_ID_SQL, any_args)
                  call_method
                end
                it 'calls `execute_sql_single_result` with `Next ID Sequence`' do
                  expect(securities_request_module).to receive(:execute_sql_single_result).with(anything, anything, 'Next ID Sequence')
                  call_method
                end
              end
              describe 'adding the new security to the database' do
                it 'constructs the `insert_security_query` with the `request_id`' do
                  expect(securities_request_module).to receive(:insert_security_query).with(request_id, any_args)
                  call_method
                end
                it 'constructs the `insert_security_query` with the `detail_id`' do
                  expect(securities_request_module).to receive(:insert_security_query).with(anything, detail_id, any_args)
                  call_method
                end
                it 'constructs the `insert_security_query` with the `username`' do
                  expect(securities_request_module).to receive(:insert_security_query).with(anything, anything, username, any_args)
                  call_method
                end
                it 'constructs the `insert_security_query` with the `session_id`' do
                  expect(securities_request_module).to receive(:insert_security_query).with(anything, anything, anything, session_id, any_args)
                  call_method
                end
                it 'constructs the `insert_security_query` with the `security`' do
                  expect(securities_request_module).to receive(:insert_security_query).with(anything, anything, anything, anything, security, any_args)
                  call_method
                end
                it 'constructs the `insert_security_query` with nil for the the `ssk_id`' do
                  expect(securities_request_module).to receive(:insert_security_query).with(anything, anything, anything, anything, anything, nil)
                  call_method
                end
                it 'calls `execute_sql` with the result of `insert_security_query`' do
                  expect(securities_request_module).to receive(:execute_sql).with(anything, insert_security_query)
                  call_method
                end
                describe 'when the SQL execution returns nil' do
                  before { allow(securities_request_module).to receive(:execute_sql).with(anything, insert_security_query).and_return(nil) }

                  it 'rolls back the transaction by raising an error' do
                    expect{call_method}.to raise_error(MAPI::Shared::Errors::SQLError, 'Failed to insert new security intake request detail')
                  end
                end
              end
            end
            describe 'when the passed security already exists and has changed' do
              let(:old_security) { cloned_security =  security.clone; cloned_security['description'] = SecureRandom.hex; cloned_security.with_indifferent_access }

              before do
                allow(securities_request_module).to receive(:format_securities).and_return([old_security])
                allow(securities_request_module).to receive(:security_has_changed).and_return(true)
                allow(securities_request_module).to receive(:execute_sql).with(anything, update_request_security_query).and_return(1)
              end
              it 'calls `security_has_changed` with the new security' do
                expect(securities_request_module).to receive(:security_has_changed).with(security, any_args).and_return(true)
                call_method
              end
              it 'calls `security_has_changed` with the old security' do
                expect(securities_request_module).to receive(:security_has_changed).with(anything, old_security).and_return(true)
                call_method
              end
              it 'constructs the `update_request_security_query` with the `request_id`' do
                expect(securities_request_module).to receive(:update_request_security_query).with(request_id, any_args)
                call_method
              end
              it 'constructs the `update_request_security_query` with the `username`' do
                expect(securities_request_module).to receive(:update_request_security_query).with(anything, username, any_args)
                call_method
              end
              it 'constructs the `update_request_security_query` with the `session_id`' do
                expect(securities_request_module).to receive(:update_request_security_query).with(anything, anything, session_id, any_args)
                call_method
              end
              it 'constructs the `update_request_security_query` with the `security`' do
                expect(securities_request_module).to receive(:update_request_security_query).with(anything, anything, anything, security)
                call_method
              end
              it 'calls `execute_sql` with the result of `update_request_security_query`' do
                expect(securities_request_module).to receive(:execute_sql).with(anything, update_request_security_query)
                call_method
              end
              describe 'when the SQL execution returns nil' do
                before { allow(securities_request_module).to receive(:execute_sql).with(anything, update_request_security_query).and_return(nil) }

                it 'rolls back the transaction by raising an error' do
                  expect{call_method}.to raise_error(MAPI::Shared::Errors::SQLError, 'Failed to update security intake request detail')
                end
              end
            end
            describe 'when the passed security already exists but has not changed' do
              let(:old_security) { security.clone.with_indifferent_access }

              before do
                allow(securities_request_module).to receive(:format_securities).and_return([old_security])
                allow(securities_request_module).to receive(:security_has_changed).and_return(false)
              end
              it 'calls `security_has_changed` with the new security' do
                expect(securities_request_module).to receive(:security_has_changed).with(security, any_args).and_return(false)
                call_method
              end
              it 'calls `security_has_changed` with the old security' do
                expect(securities_request_module).to receive(:security_has_changed).with(anything, old_security).and_return(false)
                call_method
              end
              it 'does not execute the `update_request_security_query` sql' do
                expect(securities_request_module).not_to receive(:execute_sql).with(anything, update_request_security_query)
                call_method
              end
            end
          end
          describe 'handling the header details' do
            let(:old_security) { security.clone.with_indifferent_access }

            before do
              allow(securities_request_module).to receive(:format_securities).and_return([old_security])
              allow(securities_request_module).to receive(:security_has_changed).and_return(false)
              allow(securities_request_module).to receive(:adx_type_for_intake).and_return(adx_type)
            end

            describe 'fetching the `existing_header`' do
              it 'constructs the `request_header_details_query` with the `member_id`' do
                expect(securities_request_module).to receive(:request_header_details_query).with(member_id, anything)
                call_method
              end
              it 'constructs the `request_header_details_query` with the `request_id`' do
                expect(securities_request_module).to receive(:request_header_details_query).with(anything, request_id)
                call_method
              end
              it 'calls `fetch_hash` with the `logger`' do
                expect(securities_request_module).to receive(:fetch_hash).with(app.logger, any_args)
                call_method
              end
              it 'calls `fetch_hash` with result of `request_header_details_query`' do
                expect(securities_request_module).to receive(:fetch_hash).with(anything, request_header_details_query)
                call_method
              end
              describe 'when the SQL execution returns nil' do
                before do
                  allow(securities_request_module).to receive(:fetch_hash).with(anything, request_header_details_query).and_return(nil)
                end

                it 'rolls back the transaction by raising an error' do
                  expect{call_method}.to raise_error(MAPI::Shared::Errors::SQLError, 'No header details found to update')
                end
              end
              it 'calls `map_hash_values` with the existing header' do
                expect(securities_request_module).to receive(:map_hash_values).with(existing_header, anything)
                call_method
              end
              it 'calls `map_hash_values` with the `REQUEST_HEADER_MAPPING` mapping' do
                expect(securities_request_module).to receive(:map_hash_values).with(anything, securities_request_module::REQUEST_HEADER_MAPPING)
                call_method
              end
              it 'calls `header_has_changed` with the mapped `existing_header`' do
                expect(securities_request_module).to receive(:header_has_changed).with(existing_header, any_args)
                call_method
              end
              it 'calls `header_has_changed` with the provided `broker_instructions`' do
                expect(securities_request_module).to receive(:header_has_changed).with(anything, broker_instructions, any_args)
                call_method
              end
              it 'calls `header_has_changed` with the pre-processed `delivery_instructions`' do
                expect(securities_request_module).to receive(:header_has_changed).with(anything, anything, delivery_instructions)
                call_method
              end
              describe 'when the header details have changed' do
                before do
                  allow(securities_request_module).to receive(:header_has_changed).and_return(true)
                  allow(securities_request_module).to receive(:execute_sql).with(anything, update_request_header_details_query).and_return(1)
                end

                it 'constructs the `update_request_header_details_query` with the `member_id`' do
                  expect(securities_request_module).to receive(:update_request_header_details_query).with(member_id, any_args)
                  call_method
                end
                it 'constructs the `update_request_header_details_query` with the `request_id`' do
                  expect(securities_request_module).to receive(:update_request_header_details_query).with(anything, request_id, any_args)
                  call_method
                end
                it 'constructs the `update_request_header_details_query` with the `username`' do
                  expect(securities_request_module).to receive(:update_request_header_details_query).with(anything, anything, username, any_args)
                  call_method
                end
                it 'constructs the `update_request_header_details_query` with the `full_name`' do
                  expect(securities_request_module).to receive(:update_request_header_details_query).with(anything, anything, anything, full_name, any_args)
                  call_method
                end
                it 'constructs the `update_request_header_details_query` with the `session_id`' do
                  expect(securities_request_module).to receive(:update_request_header_details_query).with(anything, anything, anything, anything, session_id, any_args)
                  call_method
                end
                it 'constructs the `update_request_header_details_query` with the `adx_id`' do
                  expect(securities_request_module).to receive(:update_request_header_details_query).with(anything, anything, anything, anything, anything, adx_id, any_args)
                  call_method
                end
                it 'constructs the `update_request_header_details_query` with the `delivery_columns` from the processed delivery_instructions' do
                  expect(securities_request_module).to receive(:update_request_header_details_query).with(anything, anything, anything, anything, anything, anything, processed_delivery_instructions[:delivery_columns], any_args)
                  call_method
                end
                it 'constructs the `update_request_header_details_query` with the `broker_instructions`' do
                  expect(securities_request_module).to receive(:update_request_header_details_query).with(anything, anything, anything, anything, anything, anything, anything, broker_instructions, any_args)
                  call_method
                end
                it 'constructs the `update_request_header_details_query` with the `delivery_type` from the processed delivery_instructions' do
                  expect(securities_request_module).to receive(:update_request_header_details_query).with(anything, anything, anything, anything, anything, anything, anything, anything, processed_delivery_instructions[:delivery_type], any_args)
                  call_method
                end
                it 'constructs the `update_request_header_details_query` with the `delivery_values` from the processed delivery_instructions' do
                  expect(securities_request_module).to receive(:update_request_header_details_query).with(anything, anything, anything, anything, anything, anything, anything, anything, anything, processed_delivery_instructions[:delivery_values], adx_type, :intake)
                  call_method
                end
                it 'calls `execute_sql` with the result of `update_request_header_details_query`' do
                  expect(securities_request_module).to receive(:execute_sql).with(anything, update_request_header_details_query)
                  call_method
                end
                describe 'when the SQL execution returns nil' do
                  before { allow(securities_request_module).to receive(:execute_sql).with(anything, update_request_header_details_query).and_return(nil) }

                  it 'rolls back the transaction by raising an error' do
                    expect{call_method}.to raise_error(MAPI::Shared::Errors::SQLError, 'No header details found to update')
                  end
                end
                describe 'when the SQL execution effects no records' do
                  before { allow(securities_request_module).to receive(:execute_sql).with(anything, update_request_header_details_query).and_return(0) }

                  it 'rolls back the transaction by raising an error' do
                    expect{call_method}.to raise_error(MAPI::Shared::Errors::SQLError, 'No header details found to update')
                  end
                end
                it 'returns true if the SQL execution effects a record' do
                  allow(securities_request_module).to receive(:execute_sql).with(anything, update_request_header_details_query).and_return(1)
                  expect(call_method).to be true
                end
              end
              describe 'when the header details have not changed' do
                before { allow(securities_request_module).to receive(:header_has_changed).and_return(false) }

                it 'returns true' do
                  expect(call_method).to be true
                end
              end
            end
          end
        end
      end
    end

    describe '`security_has_changed` class method' do
      let(:old_security) {{
        foo: SecureRandom.hex,
        original_par: rand(1000..99999),
        payment_amount: rand(1000..99999)
      }}
      let(:new_security) { old_security.clone }
      let(:call_method) { securities_request_module.security_has_changed(new_security, old_security) }
      it 'returns false if the securities have the same values for their corresponding keys' do
        expect(call_method).to be false
      end
      it 'returns false if the securities have the same values for their corresponding keys, regardless of key type' do
        new_security = {}
        old_security.each do |key, value|
          new_security[key.to_s] = value
        end
        expect(call_method).to be false
      end
      it 'returns false if the `original_par` values are equal after being converted to integers' do
        new_security[:original_par] = old_security[:original_par].to_s
        expect(call_method).to be false
      end
      it 'returns false if the `original_par` values are equal after being converted to integers' do
        new_security[:payment_amount] = old_security[:payment_amount].to_s
        expect(call_method).to be false
      end
      it 'returns true if the securities are different' do
        new_security[:original_par] = old_security[:original_par] + rand(100..999)
        expect(call_method).to be true
      end
    end
    describe '`header_has_changed` class method' do
      let(:broker_instructions) {{
        foo: SecureRandom.hex
      }}
      let(:delivery_instructions) {{
        bar: SecureRandom.hex
      }}
      let(:existing_header) { instance_double(Hash) }
      let(:existing_broker_instructions) { broker_instructions.clone }
      let(:existing_delivery_instructions) { delivery_instructions.clone }
      let(:call_method) {securities_request_module.header_has_changed(existing_header, broker_instructions, delivery_instructions)  }

      before do
        allow(existing_header).to receive(:with_indifferent_access).and_return(existing_header)
        allow(securities_request_module).to receive(:broker_instructions_from_header_details).and_return({})
        allow(securities_request_module).to receive(:delivery_instructions_from_header_details).and_return({})
      end

      describe 'when the broker instructions from the exisiting header matches the passed broker instructions' do
        before { allow(securities_request_module).to receive(:broker_instructions_from_header_details).and_return(existing_broker_instructions) }

        it 'returns false if the delivery instructions also match' do
          allow(securities_request_module).to receive(:delivery_instructions_from_header_details).and_return(existing_delivery_instructions)
          expect(call_method).to be false
        end
        it 'returns false if the delivery instructions also match, regardless of key type' do
          existing_delivery_instructions = {}
          existing_broker_instructions = {}
          delivery_instructions.each { |key, value| existing_delivery_instructions[key.to_s] = value }
          broker_instructions.each { |key, value| existing_broker_instructions[key.to_s] = value }
          allow(securities_request_module).to receive(:delivery_instructions_from_header_details).and_return(existing_delivery_instructions)
          expect(call_method).to be false
        end
        it 'returns true if the delivery instructions do not match' do
          expect(call_method).to be true
        end
      end
      describe 'when the delivery instructions from the exisiting header matches the passed delivery instructions' do
        before { allow(securities_request_module).to receive(:delivery_instructions_from_header_details).and_return(existing_delivery_instructions) }
        it 'returns false if the broker instructions also match' do
          allow(securities_request_module).to receive(:broker_instructions_from_header_details).and_return(existing_broker_instructions)
          expect(call_method).to be false
        end
        it 'returns false if the delivery instructions also match, regardless of key type' do
          existing_delivery_instructions = {}
          existing_broker_instructions = {}
          delivery_instructions.each { |key, value| existing_delivery_instructions[key.to_s] = value }
          broker_instructions.each { |key, value| existing_broker_instructions[key.to_s] = value }
          allow(securities_request_module).to receive(:broker_instructions_from_header_details).and_return(existing_broker_instructions)
          expect(call_method).to be false
        end
        it 'returns true if the delivery instructions do not match' do
          expect(call_method).to be true
        end
      end
    end

    describe 'securities transfer' do
      let(:app) { double(MAPI::ServiceApp, logger: double('logger')) }
      let(:member_id) { rand(9999..99999) }
      let(:header_id) { rand(9999..99999) }
      let(:detail_id) { rand(9999..99999) }
      let(:trade_date) { (Time.zone.today - rand(1..10).days).strftime }
      let(:settlement_date) { (Time.zone.today - rand(1..10).days).strftime }
      let(:broker_instructions) { { 'transaction_code' => rand(0..1) == 0 ? 'standard' : 'repo',
                                    'trade_date' => trade_date,
                                    'settlement_type' => rand(0..1) == 0 ? 'free' : 'vs_payment',
                                    'settlement_date' => settlement_date,
                                    'pledge_to' => SecureRandom.hex } }
      let(:security) { {  'cusip' => SecureRandom.hex,
                          'description' => SecureRandom.hex,
                          'original_par' => rand(1..40000) + rand.round(2),
                          'payment_amount' => rand(1..100000) + rand.round(2) } }
      let(:user_name) {  SecureRandom.hex }
      let(:full_name) { SecureRandom.hex }
      let(:session_id) { SecureRandom.hex }
      let(:adx_id) { [1000..10000].sample }
      let(:un_adx_id) { [1000..10000].sample }
      let(:ssk_id) { [1000..10000].sample }
      let(:pledge_type) { 50 }
      let(:kind) {  SecureRandom.hex }
      let(:delivery_type) {  32 }
      describe '`insert_transfer_header_query`' do
        let(:call_method) { MAPI::Services::Member::SecuritiesRequests.insert_transfer_header_query( member_id,
                                                                                                             header_id,
                                                                                                             user_name,
                                                                                                             full_name,
                                                                                                             session_id,
                                                                                                             adx_id,
                                                                                                             un_adx_id,
                                                                                                             broker_instructions,
                                                                                                             kind) }
        let(:call_method_release) { MAPI::Services::Member::SecuritiesRequests.insert_transfer_header_query( member_id,
                                                                                                     header_id,
                                                                                                     user_name,
                                                                                                     full_name,
                                                                                                     session_id,
                                                                                                     adx_id,
                                                                                                     un_adx_id,
                                                                                                     broker_instructions,
                                                                                                     :safekept_transfer) }
        let(:call_method_intake) { MAPI::Services::Member::SecuritiesRequests.insert_transfer_header_query( member_id,
                                                                                                     header_id,
                                                                                                     user_name,
                                                                                                     full_name,
                                                                                                     session_id,
                                                                                                     adx_id,
                                                                                                     un_adx_id,
                                                                                                     broker_instructions,
                                                                                                     :pledge_transfer) }
        let(:sentinel) { SecureRandom.hex }
        let(:today) { Time.zone.today }

        before do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).and_return(SecureRandom.hex)
          allow(Time.zone).to receive(:today).and_return(today)
        end

        it 'sets the `header_id`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(header_id).and_return(sentinel)
          expect(call_method).to match /VALUES\s\(#{sentinel},/
        end

        it 'sets the `member_id`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(member_id).and_return(sentinel)
          expect(call_method).to match /VALUES\s+\((\S+\s+){1}#{sentinel},/
        end

        it 'sets the `status`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(MAPI::Services::Member::SecuritiesRequests::SSKRequestStatus::SUBMITTED).and_return(sentinel)
          expect(call_method).to match /VALUES\s+\((\S+\s+){2}#{sentinel},/
        end

        it 'sets the `pledge_type`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(pledge_type).and_return(sentinel)
          expect(call_method).to match /VALUES\s+\((\S+\s+){3}#{sentinel},/
        end

        it 'sets the `trade_date`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(broker_instructions['trade_date']).and_return(sentinel)
          expect(call_method).to match /VALUES\s+\((\S+\s+){4}#{sentinel},/
        end

        it 'sets the `request_status`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(MAPI::Services::Member::SecuritiesRequests::SETTLEMENT_TYPE[broker_instructions['settlement_type']]).and_return(sentinel)
          expect(call_method).to match /VALUES\s+\((\S+\s+){5}#{sentinel},/
        end

        it 'sets the `settlement_date`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(broker_instructions['settlement_date']).and_return(sentinel)
          expect(call_method).to match /VALUES\s+\((\S+\s+){6}#{sentinel},/
        end

        it 'sets the `delivery_type`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(delivery_type).and_return(sentinel)
          expect(call_method).to match /VALUES\s+\((\S+\s+){7}#{sentinel},/
        end

        it 'sets the `form_type` for pledged_intake' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(MAPI::Services::Member::SecuritiesRequests::SSKFormType::SECURITIES_PLEDGED).and_return(sentinel)
          expect(call_method_intake).to match /VALUES\s+\((\S+\s+){8}#{sentinel},/
        end

        it 'sets the `form_type` for pledged_release' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(MAPI::Services::Member::SecuritiesRequests::SSKFormType::SECURITIES_RELEASE).and_return(sentinel)
          expect(call_method_release).to match /VALUES\s+\((\S+\s+){8}#{sentinel},/
        end

        it 'sets the `created_date`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(today).and_return(sentinel)
          expect(call_method).to match /VALUES\s+\((\S+\s+){9}#{sentinel},/
        end

        it 'sets the `created_by`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(user_name).and_return(sentinel)
          expect(call_method).to match /VALUES\s+\((\S+\s+){10}#{sentinel},/
        end

        it 'sets the `created_by_name`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(full_name).and_return(sentinel)
          expect(call_method).to match /VALUES\s+\((\S+\s+){11}#{sentinel},/
        end

        it 'sets the `last_modified_by`' do
          formatted_modification_by = double('Formatted Modification By')
          quoted_modification_by = SecureRandom.hex
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:format_modification_by).and_return(formatted_modification_by)
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(formatted_modification_by).and_return(quoted_modification_by)
          expect(call_method).to match /VALUES\s+\((\S+\s+){12}#{quoted_modification_by}/
        end

        it 'sets the `last_modified_date`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).and_return(Time.zone.today)
          expect(call_method).to match /VALUES\s+\((\S+\s+){13}#{Time.zone.today}/
        end

        it 'sets the `last_modified_by_name`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).and_return(full_name)
          expect(call_method).to match /VALUES\s+\((\S+\s+){14}#{full_name}/
        end

        it 'sets the `adx_id`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).and_return(adx_id)
          expect(call_method).to match /VALUES\s+\((\S+\s+){15}#{adx_id}/
        end

        it 'sets the `un_adx_id`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).and_return(un_adx_id)
          expect(call_method).to match /VALUES\s+\((\S+\s+){16}#{un_adx_id}/
        end

      end

      describe '`create_transfer` method' do
        let(:app) { double(MAPI::ServiceApp, logger: double('logger'), settings: nil) }
        let(:member_id) { rand(100000..999999) }
        let(:security) { { 'cusip' => SecureRandom.hex,
                           'description' => instance_double(String),
                           'original_par' => rand(0...50000000),
                           'payment_amount' => instance_double(Numeric),
                           'custodian_name' => instance_double(String) } }
        let(:securities) { [ security, security, security ]}
        let(:method_params) { [ app,
                                member_id,
                                user_name,
                                full_name,
                                session_id,
                                broker_instructions,
                                securities,
                                kind ] }
        let(:kind) { instance_double(Symbol) }
        let(:call_method) { MAPI::Services::Member::SecuritiesRequests.create_transfer(*method_params) }

        before do
          allow(securities_request_module).to receive(:validate_kind).with(:transfer, kind).and_return(true)
          allow(securities_request_module).to receive(:validate_securities)
          allow(securities_request_module).to receive(:validate_broker_instructions)
        end

        context 'validations' do
          before { allow(securities_request_module).to receive(:should_fake?).and_return(true) }

          it 'raises an error if kind is not one of transfer keys' do
            method_params[7] = SecureRandom.hex
            allow(securities_request_module).to receive(:validate_kind).and_call_original
            expect { MAPI::Services::Member::SecuritiesRequests.create_transfer(*method_params)}.to raise_error(/invalid kind/i)
          end

          it 'calls `validate_broker_instructions` with the `broker_instructions` arg' do
            expect(securities_request_module).to receive(:validate_broker_instructions).with(broker_instructions, anything, anything)
            call_method
          end
          it 'calls `validate_broker_instructions` with the app as an arg' do
            expect(securities_request_module).to receive(:validate_broker_instructions).with(anything, app, anything)
            call_method
          end
          it 'calls `validate_broker_instructions` with the adx_type as an arg for pledged securities' do
            allow(securities_request_module).to receive(:validate_kind).and_call_original
            expect(securities_request_module).to receive(:validate_broker_instructions).with(anything, anything, :pledge_transfer)
            method_params[7] = :pledge_transfer
            MAPI::Services::Member::SecuritiesRequests.create_transfer(*method_params)
          end
          it 'calls `validate_broker_instructions` with the adx_type as an arg for unpledged securities' do
            allow(securities_request_module).to receive(:validate_kind).and_call_original
            expect(securities_request_module).to receive(:validate_broker_instructions).with(anything, anything, :safekept_transfer)
            method_params[7] = :safekept_transfer
            MAPI::Services::Member::SecuritiesRequests.create_transfer(*method_params)
          end
          it 'calls `validate_securities` with the `securities` arg' do
            expect(securities_request_module).to receive(:validate_securities).with(securities, anything, anything, anything)
            call_method
          end
          it 'calls `validate_securities` with the `settlement_type` arg from the broker instructions' do
            expect(securities_request_module).to receive(:validate_securities).with(anything, broker_instructions['settlement_type'], anything, anything)
            call_method
          end
          it 'calls `validate_securities` with `:transfer`' do
            expect(securities_request_module).to receive(:validate_securities).with(anything, anything, :transfer, anything)
            call_method
          end
          it 'calls `validate_securities` with `kind`' do
            expect(securities_request_module).to receive(:validate_securities).with(anything, anything, anything, kind)
            call_method
          end
        end

        context 'preparing and executing SQL' do
          let(:next_id) { double('Next ID') }
          let(:adx_sql) { double('ADX SQL') }
          let(:un_adx_sql) { double('ADX SQL') }
          let(:ssk_sql) { double('SSK SQL') }
          let(:sequence_result) { double('Sequence Result', to_i: next_id) }

          before do
            allow(securities_request_module).to receive(:should_fake?).and_return(false)
            allow(securities_request_module).to receive(:adx_query).with(member_id, :pledged).and_return(adx_sql)
            allow(securities_request_module).to receive(:adx_query).with(member_id, :unpledged).and_return(un_adx_sql)
            allow(securities_request_module).to receive(:ssk_id_query).with(member_id, adx_id, security['cusip']).
                                                  exactly(3).times.and_return(ssk_sql)
            allow(securities_request_module).to receive(:execute_sql_single_result).with(
                                                  app,
                                                  MAPI::Services::Member::SecuritiesRequests::NEXT_ID_SQL,
                                                  "Next ID Sequence").and_return(sequence_result)
            allow(securities_request_module).to receive(:execute_sql_single_result).with(
                                                  app,
                                                  adx_sql,
                                                  "ADX ID").and_return(adx_id)
            allow(securities_request_module).to receive(:execute_sql_single_result).with(
                                                  app,
                                                  un_adx_sql,
                                                  "ADX ID").and_return(un_adx_id)
            allow(securities_request_module).to receive(:execute_sql_single_result).with(
                                                  app,
                                                  ssk_sql,
                                                  "SSK ID").and_return(ssk_id)
          end

          it 'returns the inserted request ID' do
            allow(MAPI::Services::Member::SecuritiesRequests).to receive(:execute_sql).with(any_args).and_return(true)
            expect(call_method).to be(next_id)
          end

          context 'prepares SQL' do
            before do
              allow(MAPI::Services::Member::SecuritiesRequests).to receive(:execute_sql).with(any_args).and_return(true)
              allow(securities_request_module).to receive(:validate_kind).and_return(true)
            end

            it 'calls `insert_transfer_header_query` for unpledged securities' do
              expect(MAPI::Services::Member::SecuritiesRequests).to receive(:insert_transfer_header_query).with(
                                                                      member_id,
                                                                      next_id,
                                                                      user_name,
                                                                      full_name,
                                                                      session_id,
                                                                      adx_id,
                                                                      un_adx_id,
                                                                      broker_instructions,
                                                                      :safekept_transfer)
              method_params[7] = :safekept_transfer
              MAPI::Services::Member::SecuritiesRequests.create_transfer(*method_params)
            end

            it 'calls `insert_transfer_header_query` for pledged securities' do
              expect(MAPI::Services::Member::SecuritiesRequests).to receive(:insert_transfer_header_query).with(
                                                                      member_id,
                                                                      next_id,
                                                                      user_name,
                                                                      full_name,
                                                                      session_id,
                                                                      adx_id,
                                                                      un_adx_id,
                                                                      broker_instructions,
                                                                      :pledge_transfer)
              method_params[7] = :pledge_transfer
              MAPI::Services::Member::SecuritiesRequests.create_transfer(*method_params)
            end

            it 'calls `insert_security_query`' do
              expect(MAPI::Services::Member::SecuritiesRequests).to receive(:insert_security_query).with(next_id,
                                                                                                         next_id, user_name, session_id, security, ssk_id).exactly(3).times
              call_method
            end
          end

          context 'calls `execute_sql`' do
            let(:insert_header_sql_release) { double('Insert Header SQL Release') }
            let(:insert_header_sql_intake) { double('Insert Header SQL Intake') }
            let(:insert_security_sql) { double('Insert Security SQL') }

            before do
              allow(MAPI::Services::Member::SecuritiesRequests).to receive(:insert_transfer_header_query).with(
                                                                     member_id,
                                                                     next_id,
                                                                     user_name,
                                                                     full_name,
                                                                     session_id,
                                                                     adx_id,
                                                                     un_adx_id,
                                                                     broker_instructions,
                                                                     :safekept_transfer).and_return(insert_header_sql_release)
              allow(MAPI::Services::Member::SecuritiesRequests).to receive(:insert_transfer_header_query).with(
                                                                     member_id,
                                                                     next_id,
                                                                     user_name,
                                                                     full_name,
                                                                     session_id,
                                                                     adx_id,
                                                                     un_adx_id,
                                                                     broker_instructions,
                                                                     :pledge_transfer).and_return(insert_header_sql_intake)
              allow(MAPI::Services::Member::SecuritiesRequests).to receive(:insert_security_query).with(next_id,
                                                                                                        next_id, user_name, session_id, security, ssk_id).exactly(3).times.and_return(insert_security_sql)
              allow(securities_request_module).to receive(:validate_kind).and_call_original
            end

            it 'inserts the header for release' do
              allow(MAPI::Services::Member::SecuritiesRequests).to receive(:execute_sql).with(app.logger,
                                                                                              insert_security_sql).exactly(3).times.and_return(true)
              expect(MAPI::Services::Member::SecuritiesRequests).to receive(:execute_sql).with(app.logger,
                                                                                               insert_header_sql_release).and_return(true)
              method_params[7] = :safekept_transfer
              MAPI::Services::Member::SecuritiesRequests.create_transfer(*method_params)
            end

            it 'inserts the header for intake' do
              allow(MAPI::Services::Member::SecuritiesRequests).to receive(:execute_sql).with(app.logger,
                                                                                              insert_security_sql).exactly(3).times.and_return(true)
              expect(MAPI::Services::Member::SecuritiesRequests).to receive(:execute_sql).with(app.logger,
                                                                                               insert_header_sql_intake).and_return(true)
              method_params[7] = :pledge_transfer
              MAPI::Services::Member::SecuritiesRequests.create_transfer(*method_params)
            end

            it 'inserts the securities for release' do
              allow(MAPI::Services::Member::SecuritiesRequests).to receive(:execute_sql).with(app.logger,
                                                                                              insert_header_sql_release).and_return(true)
              expect(MAPI::Services::Member::SecuritiesRequests).to receive(:execute_sql).with(app.logger,
                                                                                               insert_security_sql).exactly(3).times.and_return(true)
              method_params[7] = :safekept_transfer
              MAPI::Services::Member::SecuritiesRequests.create_transfer(*method_params)
            end

            it 'inserts the securities for intake' do
              allow(MAPI::Services::Member::SecuritiesRequests).to receive(:execute_sql).with(app.logger,
                                                                                              insert_header_sql_intake).and_return(true)
              expect(MAPI::Services::Member::SecuritiesRequests).to receive(:execute_sql).with(app.logger,
                                                                                               insert_security_sql).exactly(3).times.and_return(true)
              method_params[7] = :pledge_transfer
              MAPI::Services::Member::SecuritiesRequests.create_transfer(*method_params)
            end

            it 'raises errors for SQL failures on header insert for release' do
              allow(MAPI::Services::Member::SecuritiesRequests).to receive(:execute_sql).with(app.logger,
                                                                                              insert_header_sql_release).and_return(false)
              method_params[7] = :safekept_transfer
              expect {  MAPI::Services::Member::SecuritiesRequests.create_transfer(*method_params) }.to raise_error(Exception)
            end

            it 'raises errors for SQL failures on header insert for intake' do
              allow(MAPI::Services::Member::SecuritiesRequests).to receive(:execute_sql).with(app.logger,
                                                                                              insert_header_sql_intake).and_return(false)
              method_params[7] = :pledge_transfer
              expect {  MAPI::Services::Member::SecuritiesRequests.create_transfer(*method_params) }.to raise_error(Exception)
            end

            it 'raises errors for SQL failures on securities insert for release' do
              allow(MAPI::Services::Member::SecuritiesRequests).to receive(:execute_sql).with(app.logger,
                                                                                              insert_header_sql_release).and_return(true)
              allow(MAPI::Services::Member::SecuritiesRequests).to receive(:execute_sql).with(app.logger,
                                                                                              insert_security_sql).and_return(false)
              method_params[7] = :safekept_transfer
              expect {  MAPI::Services::Member::SecuritiesRequests.create_transfer(*method_params) }.to raise_error(Exception)
            end

            it 'raises an error if the `SSK_ID` can\'t be found' do
              allow(securities_request_module).to receive(:ssk_id_query).with(member_id, adx_id, security['cusip']).and_return(nil)
              expect { call_method }.to raise_error(Exception)
            end
          end
        end
      end
    end

    describe '`set_broker_instructions_for_transfer`' do
      let(:kind) { [:pledge_transfer, :safekept_transfer].sample }
      let(:broker_instructions) {{}}
      let(:today) { Time.zone.today.iso8601 }
      let(:value) { SecureRandom.hex }
      let(:call_method) { securities_request_module.set_broker_instructions_for_transfer(broker_instructions, kind) }

      ['settlement_type', 'transaction_code', 'trade_date', 'settlement_date'].each do |attr|
        it "does not change the value for `#{attr}` if there is a previously existing value" do
          broker_instructions[attr] = value
          call_method
          expect(broker_instructions[attr]).to eq(value)
        end
      end
      describe 'when there are no previously exisiting values for the broker_instructions fields' do

      end
      ['trade_date', 'settlement_date'].each do |attr|
        it "sets `#{attr}` to the iso8601 string for today" do
          call_method
          expect(broker_instructions[attr]).to eq(today)
        end
      end
      it 'sets `transaction_code` to `standard`' do
        call_method
        expect(broker_instructions['transaction_code']).to eq('standard')
      end
      it 'sets `settlement_type` to `free` if the kind is `:pledge_transfer`' do
        securities_request_module.set_broker_instructions_for_transfer(broker_instructions, :pledge_transfer)
        expect(broker_instructions['settlement_type']).to eq('free')
      end
      it 'sets `settlement_type` to `vs_payment` if the kind is `:safekept_transfer`' do
        securities_request_module.set_broker_instructions_for_transfer(broker_instructions, :safekept_transfer)
        expect(broker_instructions['settlement_type']).to eq('vs_payment')
      end
    end

    describe 'securities intake' do
      let(:delivery_columns) { [ SecureRandom.hex, SecureRandom.hex, SecureRandom.hex ] }
      let(:sentinel) { SecureRandom.hex }
      let(:today) { Time.zone.today }
      let(:header_id) { rand(9999..99999) }
      let(:user_name) {  SecureRandom.hex }
      let(:full_name) { SecureRandom.hex }
      let(:session_id) { SecureRandom.hex }
      let(:adx_id) { [1000..10000].sample }
      let(:trade_date) { (Time.zone.today - rand(1..10).days).strftime }
      let(:settlement_date) { (Time.zone.today - rand(1..10).days).strftime }
      let(:broker_instructions) { { 'transaction_code' => rand(0..1) == 0 ? 'standard' : 'repo',
                                'trade_date' => trade_date,
                                'settlement_type' => rand(0..1) == 0 ? 'free' : 'vs_payment',
                                'settlement_date' => settlement_date } }
      let(:delivery_type) { [ 'fed', 'dtc', 'mutual_fund', 'physical_securities' ][rand(0..3)] }
      let(:delivery_values) { [ SecureRandom.hex, SecureRandom.hex, SecureRandom.hex ] }
      let(:pledged_or_unpledged) { [:pledged, :unpledged].sample }
      let(:form_type) { MAPI::Services::Member::SecuritiesRequests::ADXAccountTypeMapping::SYMBOL_TO_SSK_FORM_TYPE["#{pledged_or_unpledged}_intake".to_sym] }

      describe '`insert_intake_header_query' do
        let(:call_method) { MAPI::Services::Member::SecuritiesRequests.insert_intake_header_query(member_id,
                                                                                                  header_id,
                                                                                                  user_name,
                                                                                                  full_name,
                                                                                                  session_id,
                                                                                                  adx_id,
                                                                                                  delivery_columns,
                                                                                                  broker_instructions,
                                                                                                  delivery_type,
                                                                                                  delivery_values,
                                                                                                  pledged_or_unpledged ) }
        before do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).and_return(SecureRandom.hex)
          allow(Time.zone).to receive(:today).and_return(today)
        end

        it 'expands delivery columns into the insert statement' do
          expect(call_method).to match(
            /\A\s*INSERT\s+INTO\s+SAFEKEEPING\.SSK_WEB_FORM_HEADER\s+\(HEADER_ID,\s+FHLB_ID,\s+STATUS,\s+PLEDGE_TYPE,\s+TRADE_DATE,\s+REQUEST_STATUS,\s+SETTLE_DATE,\s+DELIVER_TO,\s+FORM_TYPE,\s+CREATED_DATE,\s+CREATED_BY,\s+CREATED_BY_NAME,\s+LAST_MODIFIED_BY,\s+LAST_MODIFIED_DATE,\s+LAST_MODIFIED_BY_NAME,\s+#{MAPI::Services::Member::SecuritiesRequests::ADXAccountTypeMapping::SYMBOL_TO_SQL_COLUMN_NAME[pledged_or_unpledged]},\s+PLEDGE_TO,\s+#{delivery_columns.join(',\s+')}/)
        end

        it 'sets the `header_id`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(header_id).and_return(sentinel)
          expect(call_method).to match /VALUES\s\(#{sentinel},/
        end

        it 'sets the `member_id`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(member_id).and_return(sentinel)
          expect(call_method).to match /VALUES\s+\((\S+\s+){1}#{sentinel},/
        end

        it 'sets the `status`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(MAPI::Services::Member::SecuritiesRequests::SSKRequestStatus::SUBMITTED).and_return(sentinel)
          expect(call_method).to match /VALUES\s+\((\S+\s+){2}#{sentinel},/
        end

        it 'sets the `transaction_code`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(MAPI::Services::Member::SecuritiesRequests::TRANSACTION_CODE[broker_instructions['transaction_code']]).and_return(sentinel)
          expect(call_method).to match /VALUES\s+\((\S+\s+){3}#{sentinel},/
        end

        it 'sets the `trade_date`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(broker_instructions['trade_date']).and_return(sentinel)
          expect(call_method).to match /VALUES\s+\((\S+\s+){4}#{sentinel},/
        end

        it 'sets the `settlement_type`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(MAPI::Services::Member::SecuritiesRequests::SETTLEMENT_TYPE[broker_instructions['settlement_type']]).and_return(sentinel)
          expect(call_method).to match /VALUES\s+\((\S+\s+){5}#{sentinel},/
        end

        it 'sets the `settlement_date`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(broker_instructions['settlement_date']).and_return(sentinel)
          expect(call_method).to match /VALUES\s+\((\S+\s+){6}#{sentinel},/
        end

        it 'sets the `delivery_type`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(MAPI::Services::Member::SecuritiesRequests::DELIVERY_TYPE[delivery_type]).and_return(sentinel)
          expect(call_method).to match /VALUES\s+\((\S+\s+){7}#{sentinel},/
        end

        it 'sets the `form_type`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(form_type).and_return(sentinel)
          expect(call_method).to match /VALUES\s+\((\S+\s+){8}#{sentinel},/
        end

        it 'sets the `created_date`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(today).and_return(sentinel)
          expect(call_method).to match /VALUES\s+\((\S+\s+){9}#{sentinel},/
        end

        it 'sets the `created_by`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(user_name).and_return(sentinel)
          expect(call_method).to match /VALUES\s+\((\S+\s+){10}#{sentinel},/
        end

        it 'sets the `created_by_name`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(full_name).and_return(sentinel)
          expect(call_method).to match /VALUES\s+\((\S+\s+){11}#{sentinel},/
        end

        it 'sets the `last_modified_by`' do
          formatted_modification_by = double('Formatted Modification By')
          quoted_modification_by = SecureRandom.hex
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:format_modification_by).and_return(formatted_modification_by)
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(formatted_modification_by).and_return(quoted_modification_by)
          expect(call_method).to match /VALUES\s+\((\S+\s+){12}#{quoted_modification_by},/
        end

        it 'sets the `last_modified_date`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).and_return(Time.zone.today)
          expect(call_method).to match /VALUES\s+\((\S+\s+){13}#{Time.zone.today},/
        end

        it 'sets the `last_modified_by_name`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).and_return(full_name)
          expect(call_method).to match /VALUES\s+\((\S+\s+){14}#{full_name},/
        end

        it 'sets the `PLEDGED_ADX_ID` or `UNPLEDGED_ADX_ID`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).and_return(adx_id)
          expect(call_method).to match /VALUES\s+\((\S+\s+){15}#{adx_id},/
        end

        it 'sets the `pledge_to`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).and_return(sentinel)
          expect(call_method).to match /VALUES\s+\((\S+\s+){16}#{sentinel}/
        end

        describe 'delivery values' do
          before do
            allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).and_return(broker_instructions['trade_date'])
          end
          it 'sets the `delivery_values`' do
            allow(MAPI::Services::Member::SecuritiesRequests).to receive(:format_delivery_values).and_return(delivery_values.join(', '))
            expect(call_method).to match /VALUES\s+\((\S+\s+){17}#{delivery_values.join(',\s+')}/
          end
        end
      end
      describe '`create_intake` method' do
        let(:app) { double(MAPI::ServiceApp, logger: double('logger'), settings: nil) }
        let(:member_id) { rand(100000..999999) }
        let(:kind) { double('A Kind') }
        let(:delivery_type) { MAPI::Services::Member::SecuritiesRequests::DELIVERY_TYPE.keys[rand(0..3)] }
        let(:delivery_instructions) {
          MAPI::Services::Member::SecuritiesRequests.delivery_keys_for_delivery_type(delivery_type).map do |key|
            [key, SecureRandom.hex]
          end.to_h.merge('delivery_type' => delivery_type) }
        let(:security) { { 'cusip' => SecureRandom.hex,
                           'description' => instance_double(String),
                           'original_par' => rand(0...50000000),
                           'payment_amount' => instance_double(Numeric),
                           'custodian_name' => instance_double(String) } }
        let(:securities) { [ security, security, security ]}
        let(:method_params) { [ app,
                                member_id,
                                user_name,
                                full_name,
                                session_id,
                                broker_instructions,
                                delivery_instructions,
                                securities,
                                kind ] }
        let(:call_method) { MAPI::Services::Member::SecuritiesRequests.create_intake(*method_params) }

        before do
          allow(securities_request_module).to receive(:validate_broker_instructions)
          allow(securities_request_module).to receive(:validate_kind).with(:intake, kind).and_return(true)
        end

        context 'validations' do
          before { allow(securities_request_module).to receive(:should_fake?).and_return(true) }

          it 'calls `validate_broker_instructions` with the `broker_instructions` arg' do
            expect(securities_request_module).to receive(:validate_broker_instructions).with(broker_instructions, anything, anything)
            call_method
          end
          it 'calls `validate_broker_instructions` with the app as an arg' do
            expect(securities_request_module).to receive(:validate_broker_instructions).with(anything, app, anything)
            call_method
          end
          it 'calls `validate_delivery_instructions` with the `delivery_instructions` arg' do
            expect(securities_request_module).to receive(:validate_delivery_instructions).with(delivery_instructions)
            call_method
          end
          it 'calls `validate_securities` with the `securities` arg' do
            expect(securities_request_module).to receive(:validate_securities).with(securities, anything, anything, anything)
            call_method
          end
          it 'calls `validate_securities` with the `settlement_type` arg from the broker instructions' do
            expect(securities_request_module).to receive(:validate_securities).with(anything, broker_instructions['settlement_type'], anything, anything)
            call_method
          end
          it 'calls `validate_securities` with the `delivery_type` arg from the delivery instructions' do
            expect(securities_request_module).to receive(:validate_securities).with(anything, anything, delivery_instructions['delivery_type'], anything)
            call_method
          end
          it 'calls `validate_securities` with `:intake`' do
            expect(securities_request_module).to receive(:validate_securities).with(anything, anything, anything, :intake)
            call_method
          end
          it 'calls `process_delivery_instructions` with the `delivery_instructions` arg' do
            expect(securities_request_module).to receive(:process_delivery_instructions).with(delivery_instructions)
            call_method
          end
        end

        context 'preparing and executing SQL' do
          let(:next_id) { double('Next ID') }
          let(:sequence_result) { double('Sequence Result', to_i: next_id) }
          let(:adx_sql) { double('ADX SQL') }

          before do
            allow(MAPI::Services::Member::SecuritiesRequests).to receive(:format_delivery_columns).and_return(
              delivery_columns)
            allow(MAPI::Services::Member::SecuritiesRequests).to receive(:format_delivery_values).and_return(
              delivery_values)
            allow(securities_request_module).to receive(:should_fake?).and_return(false)
            allow(securities_request_module).to receive(:adx_query).with(member_id, adx_type).and_return(adx_sql)
            allow(securities_request_module).to receive(:execute_sql_single_result).with(
              app,
              MAPI::Services::Member::SecuritiesRequests::NEXT_ID_SQL,
              "Next ID Sequence").and_return(sequence_result)
            allow(securities_request_module).to receive(:execute_sql_single_result).with(
              app,
              adx_sql,
              "ADX ID").and_return(adx_id)
            allow(securities_request_module).to receive(:adx_type_for_intake).and_return(adx_type)
          end

          it 'returns the inserted request ID' do
            allow(MAPI::Services::Member::SecuritiesRequests).to receive(:execute_sql).with(any_args).and_return(true)
            expect(call_method).to be(next_id)
          end

          context 'prepares SQL' do
            before do
              allow(MAPI::Services::Member::SecuritiesRequests).to receive(:execute_sql).with(any_args).and_return(true)
            end

            it 'calls `insert_intake_header_query`' do
              expect(MAPI::Services::Member::SecuritiesRequests).to receive(:insert_intake_header_query).with(
                member_id,
                next_id,
                user_name,
                full_name,
                session_id,
                adx_id,
                delivery_columns,
                broker_instructions,
                delivery_type,
                delivery_values,
                adx_type)
              call_method
            end

            it 'calls `insert_security_query`' do
              expect(MAPI::Services::Member::SecuritiesRequests).to receive(:insert_security_query).with(next_id,
                next_id, user_name, session_id, security, nil).exactly(3).times
              call_method
            end
          end

          context 'calls `execute_sql`' do
            let(:insert_header_sql) { double('Insert Header SQL') }
            let(:insert_security_sql) { double('Insert Security SQL') }

            before do
              allow(securities_request_module).to receive(:adx_type_for_intake).and_return(adx_type)
              allow(MAPI::Services::Member::SecuritiesRequests).to receive(:insert_intake_header_query).with(
                member_id,
                next_id,
                user_name,
                full_name,
                session_id,
                adx_id,
                delivery_columns,
                broker_instructions,
                delivery_type,
                delivery_values,
                adx_type).and_return(insert_header_sql)
              allow(MAPI::Services::Member::SecuritiesRequests).to receive(:insert_security_query).with(next_id,
                next_id, user_name, session_id, security, nil).exactly(3).times.and_return(insert_security_sql)
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

    describe '`authorize_request_query` class method' do
      let(:request_id) { double('A Request ID') }
      let(:username) { double('A Username') }
      let(:full_name) { double('A Full Name') }
      let(:session_id) { double('A Session ID') }
      let(:signer_id) { double('A Signer ID') }
      let(:modification_by) { double('A Modification By') }
      let(:sentinel) { SecureRandom.hex }
      let(:today) { Time.zone.today }
      let(:call_method) { MAPI::Services::Member::SecuritiesRequests.authorize_request_query(member_id, request_id, username, full_name, session_id, signer_id) }

      before do
        allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).and_return(SecureRandom.hex)
        allow(MAPI::Services::Member::SecuritiesRequests).to receive(:format_modification_by).with(username, session_id).and_return(modification_by)
        allow(Time.zone).to receive(:today).and_return(today)
      end

      it 'returns an UPDATE query' do
        expect(call_method).to match(/\A\s*UPDATE\s+SAFEKEEPING.SSK_WEB_FORM_HEADER\s+SET\s+/i)
      end
      it 'updates the `STATUS`' do
        allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(MAPI::Services::Member::SecuritiesRequests::SSKRequestStatus::SIGNED).and_return(sentinel)
        expect(call_method).to match(/\sSET(\s+\S+\s+=\s+\S+\s*,)*\s+STATUS\s+=\s+#{sentinel}(,|\s+WHERE\s)/i)
      end
      it 'updates the `SIGNED_BY`' do
        allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(signer_id).and_return(sentinel)
        expect(call_method).to match(/\sSET(\s+\S+\s+=\s+\S+\s*,)*\s+SIGNED_BY\s+=\s+#{sentinel}(,|\s+WHERE\s)/i)
      end
      it 'updates the `SIGNED_BY_NAME`' do
        allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(full_name).and_return(sentinel)
        expect(call_method).to match(/\sSET(\s+\S+\s+=\s+\S+\s*,)*\s+SIGNED_BY_NAME\s+=\s+#{sentinel}(,|\s+WHERE\s)/i)
      end
      it 'updates the `SIGNED_DATE`' do
        allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(today).and_return(sentinel)
        expect(call_method).to match(/\sSET(\s+\S+\s+=\s+\S+\s*,)*\s+SIGNED_DATE\s+=\s+#{sentinel}(,|\s+WHERE\s)/i)
      end
      it 'updates the `LAST_MODIFIED_BY`' do
        allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(modification_by).and_return(sentinel)
        expect(call_method).to match(/\sSET(\s+\S+\s+=\s+\S+\s*,)*\s+LAST_MODIFIED_BY\s+=\s+#{sentinel}(,|\s+WHERE\s)/i)
      end
      it 'updates the `LAST_MODIFIED_DATE`' do
        allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(today).and_return(sentinel)
        expect(call_method).to match(/\sSET(\s+\S+\s+=\s+\S+\s*,)*\s+LAST_MODIFIED_DATE\s+=\s+#{sentinel}(,|\s+WHERE\s)/i)
      end
      it 'updates the `LAST_MODIFIED_BY_NAME`' do
        allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(full_name).and_return(sentinel)
        expect(call_method).to match(/\sSET(\s+\S+\s+=\s+\S+\s*,)*\s+LAST_MODIFIED_BY_NAME\s+=\s+#{sentinel}(,|\s+WHERE\s)/i)
      end
      it 'includes the `request_id` in the WHERE clause' do
        allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(request_id).and_return(sentinel)
        expect(call_method).to match(/\sWHERE(\s+\S+\s+=\s+\S+\s+AND)*\s+HEADER_ID\s+=\s+#{sentinel}(\s+|\z)/)
      end
      it 'includes the `member_id` in the WHERE clause' do
        allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(member_id).and_return(sentinel)
        expect(call_method).to match(/\sWHERE(\s+\S+\s+=\s+\S+\s+AND)*\s+FHLB_ID\s+=\s+#{sentinel}(\s+|\z)/)
      end
      it 'restricts the updates to unauthorized queries' do
        allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(MAPI::Services::Member::SecuritiesRequests::SSKRequestStatus::SUBMITTED).and_return(sentinel)
        expect(call_method).to match(/\sWHERE(\s+\S+\s+=\s+\S+\s+AND)*\s+STATUS\s+=\s+#{sentinel}(\s+|\z)/)
      end
    end

    describe '`authorize_request` class method' do
      let(:request_id) { double('A Request ID') }
      let(:username) { double('A Username') }
      let(:full_name) { double('A Full Name') }
      let(:session_id) { double('A Session ID') }
      let(:signer_id) { double('A Signer ID') }
      let(:modification_by) { double('A Modification By') }
      let(:authorization_query) { double('An Authorization Query') }
      let(:call_method) { MAPI::Services::Member::SecuritiesRequests.authorize_request(app, member_id, request_id, username, full_name, session_id) }

      before do
        allow(MAPI::Services::Member::SecuritiesRequests).to receive(:authorize_request_query).and_return(authorization_query)
      end

      describe '`should_fake?` returns true' do
        before do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:should_fake?).and_return(true)
        end
        it 'generates an authorization query using `nil` for the signer ID' do
          expect(MAPI::Services::Member::SecuritiesRequests).to receive(:authorize_request_query).with(member_id, request_id, username, full_name, session_id, nil)
          call_method
        end
        it 'does not execute a query' do
          expect(ActiveRecord::Base.connection).to_not receive(:execute)
          call_method
        end
        it 'returns true' do
          expect(call_method).to be(true)
        end
      end
      describe '`should_fake?` returns false' do
        let(:signer_id) { double('A Signer ID') }
        let(:signer_id_query) { double('A Signer ID Query') }
        before do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:should_fake?).and_return(false)
          allow(MAPI::Services::Users).to receive(:signer_id_query).with(username).and_return(signer_id_query)
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:execute_sql_single_result).with(app, signer_id_query, 'Signer ID').and_return(signer_id)
          allow(ActiveRecord::Base.connection).to receive(:execute).with(authorization_query).and_return(1)
        end
        it 'generates a signer ID query' do
          expect(MAPI::Services::Users).to receive(:signer_id_query).with(username).and_return(signer_id_query)
          call_method
        end
        it 'converts the username into a signer ID' do
          expect(MAPI::Services::Member::SecuritiesRequests).to receive(:execute_sql_single_result).with(app, signer_id_query, 'Signer ID').and_return(signer_id)
          call_method
        end
        it 'raises an error if the signer ID is not found' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:execute_sql_single_result).with(app, signer_id_query, 'Signer ID').and_raise(MAPI::Shared::Errors::SQLError)
          expect{call_method}.to raise_error(/signer not found/i)
        end
        it 'generates an authorization query using the signer ID' do
          expect(MAPI::Services::Member::SecuritiesRequests).to receive(:authorize_request_query).with(member_id, request_id, username, full_name, session_id, signer_id).and_return(authorization_query)
          call_method
        end
        it 'returns true if executing the query updates one row' do
          expect(call_method).to be(true)
        end
        it 'returns false if executing the query updates no rows' do
          allow(ActiveRecord::Base.connection).to receive(:execute).with(authorization_query).and_return(0)
          expect(call_method).to be(false)
        end
      end

      describe '`get_adx_type_from_security` class method' do
        let(:connection) { instance_double(ActiveRecord::ConnectionAdapters::OracleEnhancedAdapter, execute: nil) }
        let(:cusip) { SecureRandom.hex }
        let(:security) { instance_double(Hash, :[] => cusip) }
        let(:call_method) { MAPI::Services::Member::SecuritiesRequests.get_adx_type_from_security(app, security) }
        let(:sql) {
              <<-SQL
                SELECT ACCOUNT_TYPE
                FROM SAFEKEEPING.SSK_INTRADAY_SEC_POSITION
                WHERE SSK_CUSIP = #{cusip}
              SQL
            }
        let(:adx_type_string) { ['P', 'U'].sample }
        before do
          allow(ActiveRecord::Base).to receive(:connection).and_return(connection)
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).and_return(cusip)
        end
        it 'raises an `ArgumentError` if security is `nil`' do
          expect { MAPI::Services::Member::SecuritiesRequests.get_adx_type_from_security(app, nil) }.to raise_error(ArgumentError, 'security must not be nil')
        end
        describe 'when `should_fake?` returns true' do
          let(:cusip_bytes) { cusip.bytes }
          let(:rng) { instance_double(Random) }
          let(:seed) { cusip.bytes.inject(0, :+) }
          let(:adx_pledge_types) { [ :pledged, :unpledged ] }
          adx_mapping = { pledged: 'P', unpledged: 'U' }
          before do
            stub_const 'MAPI::Services::Member::SecuritiesRequests::ADXAccountTypeMapping::SYMBOL_TO_STRING', adx_mapping
            allow(MAPI::Services::Member::SecuritiesRequests).to receive(:should_fake?).and_return(true)
          end
          it 'gets the bytes of the cusip' do
            allow(security).to receive(:[]).with('cusip').and_return(cusip)
            expect(cusip).to receive(:bytes).and_return(cusip_bytes)
            call_method
          end
          it 'sums the bytes of the cusip' do
            allow(cusip).to receive(:bytes).and_return(cusip_bytes)
            expect(cusip_bytes).to receive(:inject).with(0, :+).and_return(seed)
            call_method
          end
          it 'seeds a random number generator' do
            allow(cusip_bytes).to receive(:inject).with(0, :+).and_return(seed)
            expect(Random).to receive(:new).with(seed).and_return(rng)
            call_method
          end
          it 'passes the rng to sample' do
            allow(Random).to receive(:new).with(seed).and_return(rng)
            allow(adx_mapping).to receive(:keys).and_return(adx_pledge_types)
            expect(adx_pledge_types).to receive(:sample).with(random: rng)
            call_method
          end
          it 'returns an random ADX type' do
            expect(call_method).to eq(:pledged).or(eq(:unpledged))
          end
        end
        describe 'when `should_fake?` returns false' do
          before do
            allow(MAPI::Services::Member::SecuritiesRequests).to receive(:should_fake?).and_return(false)
            allow(MAPI::Services::Member::SecuritiesRequests).to receive(:adx_type_query).with(cusip).and_return(sql)
          end
          it 'calls `execute_sql_single_result` with the correct SQL' do
            expect(MAPI::Services::Member::SecuritiesRequests).to receive(:execute_sql_single_result).with(anything, sql, 'Get ADX type for a security')
            call_method
          end
          it 'returns the appropriate type mapping' do
            allow(MAPI::Services::Member::SecuritiesRequests).to receive(:execute_sql_single_result).and_return(adx_type_string)
            expect(call_method).to eq(MAPI::Services::Member::SecuritiesRequests::ADXAccountTypeMapping::STRING_TO_SYMBOL[adx_type_string])
          end
        end
      end
    end
    
    describe '`fake_request_id` class method' do
      it 'returns a random number between 100000 and 999999 using the supplied random number generator' do
        value = double(Numeric)
        rng = instance_double(Random)
        allow(rng).to receive(:rand).with(100000..999999).and_return(value)
        expect(MAPI::Services::Member::SecuritiesRequests.fake_request_id(rng)).to be(value)
      end
    end

    describe '`kind_from_details` class method' do
      let(:header_details) { {
        'FORM_TYPE' => double('A Form Type'),
        'DELIVER_TO' => nil,
        'RECEIVE_FROM' => nil
        } }
      let(:call_method) { securities_request_module.kind_from_details(header_details) }
      it 'raises an error if the `FORM_TYPE` is unknown' do
        expect{call_method}.to raise_error(ArgumentError, /unknown form_type/)
      end
      it 'returns `safekept_release` if the `FORM_TYPE` is `SSKFormType::SAFEKEPT_RELEASE`' do
        header_details['FORM_TYPE'] = securities_request_module::SSKFormType::SAFEKEPT_RELEASE
        expect(call_method).to be(:safekept_release)
      end
      it 'returns `safekept_intake` if the `FORM_TYPE` is `SSKFormType::SAFEKEPT_DEPOSIT`' do
        header_details['FORM_TYPE'] = securities_request_module::SSKFormType::SAFEKEPT_DEPOSIT
        expect(call_method).to be(:safekept_intake)
      end
      it 'returns `pledge_intake` if the `FORM_TYPE` is `SSKFormType::SECURITIES_PLEDGED` and the `RECEIVE_FROM` is not `SSKDeliverTo::INTERNAL_TRANSFER`' do
        header_details['FORM_TYPE'] = securities_request_module::SSKFormType::SECURITIES_PLEDGED
        expect(call_method).to be(:pledge_intake)
      end
      it 'returns `pledge_transfer` if the `FORM_TYPE` is `SSKFormType::SECURITIES_PLEDGED` and the `RECEIVE_FROM` is `SSKDeliverTo::INTERNAL_TRANSFER`' do
        header_details['FORM_TYPE'] = securities_request_module::SSKFormType::SECURITIES_PLEDGED
        header_details['RECEIVE_FROM'] = securities_request_module::SSKDeliverTo::INTERNAL_TRANSFER
        expect(call_method).to be(:pledge_transfer)
      end
      it 'returns `safekept_transfer` if the `FORM_TYPE` is `SSKFormType::SECURITIES_RELEASE` and the `DELIVER_TO` is `SSKDeliverTo::INTERNAL_TRANSFER`' do
        header_details['FORM_TYPE'] = securities_request_module::SSKFormType::SECURITIES_RELEASE
        header_details['DELIVER_TO'] = securities_request_module::SSKDeliverTo::INTERNAL_TRANSFER
        expect(call_method).to be(:safekept_transfer)
      end
      it 'returns `pledge_release` if the `FORM_TYPE` is `SSKFormType::SECURITIES_RELEASE` and the `DELIVER_TO` is not `SSKDeliverTo::INTERNAL_TRANSFER`' do
        header_details['FORM_TYPE'] = securities_request_module::SSKFormType::SECURITIES_RELEASE
        expect(call_method).to be(:pledge_release)
      end
    end

    describe '`validate_kind` class method' do
      let(:flow) { double('A Flow') }
      let(:kind) { double('A Kind') }
      let(:call_method) { securities_request_module.validate_kind(flow, kind) }
      it 'raises an error if the `flow` is not :release, :intake or :transfer' do
        expect{call_method}.to raise_error(/unknown flow/i)
      end
      {
        release: [:pledge_release, :safekept_release],
        intake: [:pledge_intake, :safekept_intake],
        transfer: [:pledge_transfer, :safekept_transfer]
      }.each do |flow, kinds|
        it "it raises an error when the `flow` is `#{flow}` and the kind is not #{kinds}" do
          expect{securities_request_module.validate_kind(flow, kind)}.to raise_error(/invalid kind/i)
        end
        kinds.each do |kind|
          it "does not raise an error when `flow` is `#{flow}` and the kind is `#{kind}`" do
            expect{securities_request_module.validate_kind(flow, kind)}.to_not raise_error
          end
          it "returns true when `flow` is `#{flow}` and the kind is `#{kind}`" do
            expect(securities_request_module.validate_kind(flow, kind)).to be(true)
          end
        end
      end
    end

    describe '`adx_type_for_intake` class method' do
      it 'returns `unpledged` when `kind` is `safekept_intake`' do
        expect(securities_request_module.adx_type_for_intake(:safekept_intake)).to be(:unpledged)
      end
      it 'returns `pledged` when `kind` is `pledge_intake`' do
        expect(securities_request_module.adx_type_for_intake(:pledge_intake)).to be(:pledged)
      end
    end
  end
end