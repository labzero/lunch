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
  end
end