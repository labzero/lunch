class SecuritiesRequestService < MAPIService
  attr_reader :member_id

  def initialize(member_id, request)
    super(request)
    @member_id = member_id
    raise ArgumentError.new('`member_id` must not be blank') if member_id.blank?
  end

  def authorized
    requests = get_json(:authorized, "/member/#{member_id}/securities/requests", status: :authorized, settle_start_date: Time.zone.today - 7.days)
    process_securities_requests(requests)
  end

  def awaiting_authorization
    requests = get_json(:awaiting_authorization, "/member/#{member_id}/securities/requests", status: :awaiting_authorization)
    process_securities_requests(requests)
  end

  def submit_release_for_authorization(securities_release_request, user, &error_handler)
    body = {
      broker_instructions: securities_release_request.broker_instructions,
      delivery_instructions: securities_release_request.delivery_instructions,
      securities: securities_release_request.securities,
      user: user_details(user)
    }
    response = post(:securities_submit_release_for_authorization, "/member/#{member_id}/securities/release", body.to_json, 'application/json') do |name, msg, err|
      if err.is_a?(RestClient::Exception) && err.http_code >= 400 && err.http_code < 500 && error_handler
        error_handler.call(err)
      end
    end
    response.code == 200 if response
  end

  def submitted_release(request_id)
    response_hash = get_hash(:submitted_release, "/member/#{member_id}/securities/release/#{request_id}")
    if response_hash
      securities_release_hash = map_response_to_securities_release_hash(response_hash)
      SecuritiesReleaseRequest.from_hash(securities_release_hash)
    end
  end

  def delete_request(request_id)
    delete(:delete_request, "/member/#{member_id}/securities/request/#{request_id}")
  end

  def authorize_request(request_id, user)
    put(:authorize_securities_request, "/member/#{member_id}/securities/authorize", {request_id: request_id, user: user_details(user)}.to_json, 'application/json')
  end

  private

  def user_details(user, request=self.request)
    {
      username: user.username,
      full_name: user.display_name,
      session_id: request.session.id
    }
  end

  def map_response_to_securities_release_hash(response_hash)
    securities_release = {}
    response_hash[:broker_instructions].each do |key, value|
      securities_release[key] = value
    end
    response_hash[:delivery_instructions].each do |key, value|
      key = SecuritiesReleaseRequest::ACCOUNT_NUMBER_TYPE_MAPPING[response_hash[:delivery_instructions][:delivery_type].to_sym] if key.to_sym == :account_number
      securities_release[key] = value
    end
    securities_release[:request_id] = response_hash[:request_id]
    securities_release[:securities] = response_hash[:securities]
    securities_release
  end

  def process_securities_requests(requests)
    requests.try(:collect) do |request|
      fix_date(request.with_indifferent_access, [:authorized_date, :settle_date, :submitted_date])
    end
  end

end