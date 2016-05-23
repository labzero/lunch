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
        end

        module SSKFormType
          SECURITIES_PLEDGED = 70
          SECURITIES_RELEASE = 71
          SAFEKEPT_DEPOST = 72
          SAFEKEPT_RELEASE = 73
        end

        module MAPIRequestStatus
          AUTHORIZED = [SSKRequestStatus::SIGNED, SSKRequestStatus::ACKNOWLEDGED]
          AWAITING_AUTHORIZATION = [SSKRequestStatus::AWAITING_AUTHORIZATION]
        end

        REQUEST_STATUS_MAPPING = {
          authorized: MAPIRequestStatus::AUTHORIZED,
          awaiting_authorization: MAPIRequestStatus::AWAITING_AUTHORIZATION
        }.with_indifferent_access.freeze

        REQUEST_FORM_TYPE_MAPPING = {
          SSKFormType::SECURITIES_PLEDGED => :pledge_intake,
          SSKFormType::SECURITIES_RELEASE => :pledge_release,
          SSKFormType::SAFEKEPT_DEPOST => :safekept_intake,
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
      end
    end
  end
end