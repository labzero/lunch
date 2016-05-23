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

    it_should_behave_like 'a MAPI backed service object method', :awaiting_authorization
    
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