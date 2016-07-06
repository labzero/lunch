require 'rails_helper'

describe SecuritiesRequestService do
  let(:member_id) { rand(1..1000) }
  let(:request) { ActionDispatch::TestRequest.new }
  let(:requests) { double(Array) }
  let(:processed_requests) { double(Array) }
  subject { described_class.new(member_id, request) }

  before do
    allow(subject).to receive(:get_json).and_return(requests)
  end

  describe '`initialize`' do
    it 'stores the supplied `member_id`' do
      expect(subject.member_id).to be(member_id)
    end
    it 'stores the supplied `request`' do
      expect(subject.request).to be(request)
    end
    it 'raises an error if `member_id` is nil' do
      expect{ described_class.new(nil, request) }.to raise_error(ArgumentError)
    end
  end

  describe '`authorized`' do
    let(:call_method) { subject.authorized }
    it_should_behave_like 'a MAPI backed service object method', :authorized

    it 'calls `get_json` with the securities requests end point' do
      expect(subject).to receive(:get_json).with(:authorized, "/member/#{member_id}/securities/requests", anything)
      call_method
    end
    it 'calls `get_json` with a parameter `status` set to `authorized`' do
      expect(subject).to receive(:get_json).with(anything, anything, include(status: :authorized))
      call_method
    end
    it 'calls `get_json` with a parameter `settle_start_date` set to 7 days ago' do
      today = Time.zone.today
      allow(Time.zone).to receive(:today).and_return(today)
      expect(subject).to receive(:get_json).with(anything, anything, include(settle_start_date: today - 7.days))
      call_method
    end
    it 'calls `process_securities_requests` with the reponse from `get_json`' do
      expect(subject).to receive(:process_securities_requests).with(requests)
      call_method
    end
    it 'returns the result of calling `process_securities_requests`' do
      allow(subject).to receive(:process_securities_requests).and_return(processed_requests)
      expect(call_method).to be(processed_requests)
    end
  end

  describe '`awaiting_authorization`' do
    let(:call_method) { subject.awaiting_authorization }

    it_behaves_like 'a MAPI backed service object method', :awaiting_authorization
    
    it 'calls `get_json` with the securities requests end point' do
      expect(subject).to receive(:get_json).with(:awaiting_authorization, "/member/#{member_id}/securities/requests", anything)
      call_method
    end
    it 'calls `get_json` with a parameter `status` set to `awaiting_authorization`' do
      expect(subject).to receive(:get_json).with(anything, anything, include(status: :awaiting_authorization))
      call_method
    end
    it 'calls `process_securities_requests` with the reponse from `get_json`' do
      expect(subject).to receive(:process_securities_requests).with(requests)
      call_method
    end
    it 'returns the result of calling `process_securities_requests`' do
      allow(subject).to receive(:process_securities_requests).and_return(processed_requests)
      expect(call_method).to be(processed_requests)
    end
  end

  describe '`submit_release_for_authorization`' do
    let(:broker_instructions) { SecureRandom.hex }
    let(:delivery_instructions) { SecureRandom.hex }
    let(:securities) { SecureRandom.hex }
    let(:session_id) { SecureRandom.hex }
    let(:session) { instance_double(ActionDispatch::Request::Session, id: session_id) }
    let(:user) { instance_double(User, username: SecureRandom.hex, display_name: SecureRandom.hex) }
    let(:securities_release_request) { instance_double(SecuritiesReleaseRequest, broker_instructions: broker_instructions, delivery_instructions: delivery_instructions, securities: securities) }
    let(:call_method) { subject.submit_release_for_authorization(securities_release_request, user) }

    before do
      allow(request).to receive(:session).and_return(session)
    end

    it_behaves_like 'a MAPI backed service object method', :submit_release_for_authorization do
      let(:user) { instance_double(User, username: SecureRandom.hex, display_name: SecureRandom.hex) }
      let(:securities_release_request) { instance_double(SecuritiesReleaseRequest, broker_instructions: nil, delivery_instructions: nil, securities: nil) }
      let(:call_method) { subject.submit_release_for_authorization(securities_release_request, user) }
    end
    it 'calls `post` with `:securities_submit_release_for_authorization` for the name arg' do
      expect(subject).to receive(:post).with(:securities_submit_release_for_authorization, any_args)
      call_method
    end
    it 'calls `post` with `{member_id}/securities/release` for the endpoint arg' do
      expect(subject).to receive(:post).with(anything, "/member/#{member_id}/securities/release", anything)
      call_method
    end
    it 'calls `post` with a JSON body argument including the broker instructions from the security_release_request' do
      expect(subject).to receive(:post).with(anything, anything, satisfy { |arg| JSON.parse(arg)['broker_instructions'] == broker_instructions })
      call_method
    end
    it 'calls `post` with a body argument including the delivery instructions from the security_release_request' do
      expect(subject).to receive(:post).with(anything, anything, satisfy { |arg| JSON.parse(arg)['delivery_instructions'] == delivery_instructions })
      call_method
    end
    it 'calls `post` with a body argument including the securities from the security_release_request' do
      expect(subject).to receive(:post).with(anything, anything, satisfy { |arg| JSON.parse(arg)['securities'] == securities })
      call_method
    end
    it 'calls `post` with a body argument including the `username` of the passed user' do
      expect(subject).to receive(:post).with(anything, anything, satisfy { |arg| JSON.parse(arg)['user']['username'] == user.username })
      call_method
    end
    it 'calls `post` with a body argument including the `full_name` of the passed user' do
      expect(subject).to receive(:post).with(anything, anything, satisfy { |arg| JSON.parse(arg)['user']['full_name'] == user.display_name })
      call_method
    end
    it 'calls `post` with a body argument including the `session_id` of the passed user\'s session' do
      expect(subject).to receive(:post).with(anything, anything, satisfy { |arg| JSON.parse(arg)['user']['session_id'] == session_id })
      call_method
    end
    describe 'when the POST to MAPI succeeds' do
      before { allow_any_instance_of(RestClient::Resource).to receive(:post).and_return(instance_double(RestClient::Response, code: 200)) }
      it 'returns true' do
        expect(call_method).to be(true)
      end
    end
    describe 'when there is a RestClient error in the 400 range' do
      let(:status) { rand(400...500) }
      let(:error) { RestClient::Exception.new(nil, status) }
      before { allow_any_instance_of(RestClient::Resource).to receive(:post).and_raise(error) }
      it 'calls the error handler with the error if an error handler was supplied' do
        expect{|error_handler| subject.submit_release_for_authorization(securities_release_request, user, &error_handler)}.to yield_with_args(error)
      end
      it 'returns nil' do
        expect(call_method).to be_nil
      end
    end
  end

  describe 'private methods' do
    describe '`process_securities_requests`' do
      let(:requests) { [ double(Hash), double(Hash) ] }
      let(:indifferent_requests) do
        requests.collect do |request| 
          indifferent = double('An Indifferent Securities Request')
          allow(request).to receive(:with_indifferent_access).and_return(indifferent)
          indifferent
        end
      end
      let!(:fixed_requests) do
        indifferent_requests.collect do |request|
          fixed = double('A Fixed Securities Request')
          allow(subject).to receive(:fix_date).with(request, anything).and_return(fixed)
          fixed
        end
      end
      let(:call_method) { subject.send(:process_securities_requests, requests) }

      it 'returns `nil` if passed `nil`' do
        expect(subject.send(:process_securities_requests, nil)).to be_nil
      end
      it 'converts each request to a hash with indifferent access' do
        requests.each do |request|
          expect(request).to receive(:with_indifferent_access)
        end
        call_method
      end
      it 'calls `fix_date` on each request' do
        indifferent_requests.each do |request|
          expect(subject).to receive(:fix_date).with(request, match([:authorized_date, :settle_date, :submitted_date]))
        end
        call_method
      end
      it 'returns the processed requests' do
        expect(call_method).to eq(fixed_requests)
      end
    end
  end
end