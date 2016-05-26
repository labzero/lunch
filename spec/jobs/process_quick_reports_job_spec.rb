require 'rails_helper'

RSpec.describe ProcessQuickReportsJob, type: :job do
  let(:period) { double('A Period') }
  let(:run_job) { subject.perform(period) }
  let(:members_service) { double(MembersService, all_members: []) }
  before do
    allow(MembersService).to receive(:new).and_return(members_service)
  end
  it 'sets the period to the current period if one is not provided' do
    expect(QuickReportSet).to receive(:current_period)
    subject.perform
  end
  it 'queues its self as `low_priority`' do
    expect(described_class.queue).to eq('low_priority')
  end
  it 'fetches a list of all members from the MembersService' do
    expect(members_service).to receive(:all_members)
    run_job
  end
  it 'uses its Job ID as the UUID of the request when calling MembersService' do
    request = double(ActionDispatch::TestRequest)
    allow(ActionDispatch::TestRequest).to receive(:new).with(include('action_dispatch.request_id' => subject.job_id)).and_return(request)
    expect(MembersService).to receive(:new).with(request).and_return(members_service)
    run_job
  end
  it 'fails the job if the fetch of members fails' do
    allow(members_service).to receive(:all_members).and_return(nil)
    run_job
    expect(subject.job_status.failed?).to be(true)
  end
  describe 'for each found member' do
    let(:members) { (1..10).to_a.sample(3).collect { |id| {id: id}.with_indifferent_access } }
    let(:member_objects) { [] }
    let(:report_set) { double(QuickReportSet, completed?: false) }
    before do
      allow(members_service).to receive(:all_members).and_return(members)
      expect(QuickReportsWatchdogJob).to receive(:perform_later).with(members, period)
      members.each do |member|
        obj = Member.new(member[:id])
        member_objects << obj
      end
      member_objects.each do |member|
        allow(Member).to receive(:new).with(member.id).and_return(member)
        allow(member).to receive(:report_set_for_period).and_return(report_set)
      end
      allow(MemberProcessQuickReportsJob).to receive(:perform_later)
    end
    it 'constructs a Member' do
      members.each do |member|
        expect(Member).to receive(:new).with(member[:id]).and_call_original
      end
      run_job
    end
    it 'fetches the report set for the current period' do
      member_objects.each do |member|
        expect(member).to receive(:report_set_for_period).with(period).and_return(report_set)
      end
      run_job
    end
    it 'enqueues a MemberProcessQuickReportsJob if the report set is not completed' do
      member_objects.each do |member|
        expect(MemberProcessQuickReportsJob).to receive(:perform_later).with(member.id, period)
      end
      run_job
    end
    it 'does not enqueue a MemberProcessQuickReportsJob if the report set is completed' do
      allow(report_set).to receive(:completed?).and_return(true)
      member_objects.each do |member|
        expect(MemberProcessQuickReportsJob).to_not receive(:perform_later).with(member.id, period)
      end
      run_job
    end
  end
end