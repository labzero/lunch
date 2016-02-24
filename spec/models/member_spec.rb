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
      expect{described_class.new(nil)}.to raise_error
    end
    it 'raises an error if a false ID is provided' do
      expect{described_class.new(false)}.to raise_error
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
  end
end