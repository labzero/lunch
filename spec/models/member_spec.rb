require 'rails_helper'

RSpec.describe Member, type: :model do
  let(:id) { SecureRandom.hex }
  subject { described_class.new(id) }
  describe '`initializer` method' do
    it 'stores the supplied ID' do
      member = described_class.new(id)
      expect(member.instance_variable_get(:@id)).to eq(id)
    end
    it 'raises an error if a nil ID is provided' do
      expect{described_class.new(nil)}.to raise_error(ArgumentError)
    end
    it 'raises an error if a false ID is provided' do
      expect{described_class.new(false)}.to raise_error(ArgumentError)
    end
  end
  describe 'instance methods' do
    let(:report_set) { double(QuickReportSet) }
    let(:report_sets) { class_double(QuickReportSet) }
    let(:report_list) { described_class::DEFAULT_REPORT_LIST }
    describe '`flipper_id`' do
      it 'returns a string representing the members ID' do
        expect(subject.flipper_id).to eq("FHLB-#{id}")
      end
    end
    describe '`id`' do
      it 'returns the stored ID' do
        expect(subject.id).to eq(id)
      end
    end
    describe '`member_id`' do
      it 'returns the stored ID' do
        expect(subject.member_id).to eq(id)
      end
    end

    describe '`latest_report_set`' do
      let(:call_method) { subject.latest_report_set }
      before do
        allow(QuickReportSet).to receive(:for_member).with(id).and_return(report_sets)
        allow(report_sets).to receive(:latest).and_return(report_set)
      end
      it 'finds the report sets for the member' do
        expect(QuickReportSet).to receive(:for_member).with(id).and_return(report_sets)
        call_method
      end
      it 'finds the latest report set from the members report sets' do
        expect(report_sets).to receive(:latest).and_return(report_set)
        call_method
      end
      it 'returns the report set' do
        expect(call_method).to be(report_set)
      end
    end
    describe '`report_set_for_period`' do
      let(:period) { double('A Period') }
      let(:call_method) { subject.report_set_for_period(period) }
      let(:report_sets_for_period) { class_double(QuickReportSet) }
      before do
        allow(QuickReportSet).to receive(:for_member).with(id).and_return(report_sets)
        allow(report_sets).to receive(:for_period).and_return(report_sets_for_period)
        allow(report_sets_for_period).to receive(:first_or_create).and_return(report_set)
      end
      it 'finds the report sets for the member' do
        expect(QuickReportSet).to receive(:for_member).with(id).and_return(report_sets)
        call_method
      end
      it 'finds the report set for the supplied period' do
        expect(report_sets).to receive(:for_period).with(period).and_return(report_sets_for_period)
        call_method
      end
      it 'finds the first report set or creates a new one' do
        expect(report_sets_for_period).to receive(:first_or_create).and_return(report_sets)
        call_method
      end
      it 'returns the found or created report set' do
        expect(call_method).to be(report_set)
      end
    end
    describe '`quick_report_list`' do
      it 'returns the report names found in DEFAULT_REPORT_LIST' do
        expect(subject.quick_report_list).to eq(report_list.keys)
      end
    end
    describe '`quick_report_params`' do
      it 'returns the report params found in DEFAULT_REPORT_LIST for the named report' do
        report_name = report_list.keys.sample
        expect(subject.quick_report_params(report_name)).to eq(report_list[report_name])
      end
      it 'returns nil if the report name is not recognized' do
        expect(subject.quick_report_params(double('A Name'))).to be_nil
      end
    end
    describe '`requires_dual_signers?`' do
      let(:call_method) { subject.requires_dual_signers? }
      let(:request) { double('request object') }
      let(:member_details) { {dual_signers_required: double('dual_signers_required')} }
      before { allow_any_instance_of(MembersService).to receive(:member).and_return({}) }
      describe 'when @member_details are not present' do
        it 'fetches details with the request object it was passed' do
          expect(subject).to receive(:fetch_details).with(request).and_call_original
          subject.requires_dual_signers?(request)
        end
        it 'fetches details with no request object if none was passed' do
          expect(subject).to receive(:fetch_details).with(nil).and_call_original
          call_method
        end
      end
      it 'does not fetch details if @member_details are present' do
        call_method
        expect(subject).not_to receive(:fetch_details)
        call_method
      end
      it 'returns the value of `dual_signers_required` from member details' do
        allow_any_instance_of(MembersService).to receive(:member).and_return(member_details)
        expect(call_method).to eq(member_details[:dual_signers_required])
      end
    end
  end

  describe 'protected methods' do
    describe '`fetch_details`' do
      let(:call_method) { subject.send(:fetch_details) }
      let(:members_service_instance) { double(MembersService, member: nil) }
      let(:request) { double('request') }
      let(:member_details) { double('member details') }
      before do
        allow(MembersService).to receive(:new).and_return(members_service_instance)
      end
      it 'creates a new instance of MembersService with the request it was passed' do
        expect(MembersService).to receive(:new).with(request).and_return(members_service_instance)
        subject.send(:fetch_details, request)
      end
      it 'creates a new instance of MembersService with a test request if none was passed' do
        allow(ActionDispatch::TestRequest).to receive(:new).and_return(request)
        expect(MembersService).to receive(:new).with(request).and_return(members_service_instance)
        call_method
      end
      it 'sets @member_details to the result of calling `member` on the MembersService instance' do
        allow(members_service_instance).to receive(:member).and_return(member_details)
        call_method
        expect(subject.instance_variable_get('@member_details')).to eq(member_details)
      end
    end
  end
end