require 'rails_helper'

RSpec.describe QuickReport, type: :model do
  it { should belong_to(:quick_report_set) }
  it { should have_attached_file(:report) }
  it { should validate_presence_of(:report_name) }
  it { should have_db_index([:quick_report_set_id, :report_name]).unique(true) }
  it { should have_db_index(:report_name).unique(false) }

  it 'includes PaperclipAttachmentAsString' do
    expect(described_class.included_modules).to include(PaperclipAttachmentAsString)
  end

  describe 'scopes' do
    let(:result) { double(ActiveRecord::Relation) }
    describe '`reports_named`' do
      let(:report_names) { double('A Set of Report Names') }
      let(:call_method) { described_class.reports_named(report_names) }
      it_behaves_like 'an ActiveRecord scope', :reports_named
      it 'limits the scope to only records with one of the supplied report names' do
        expect(described_class).to receive(:where).with(report_name: report_names)
        call_method
      end
      it 'returns the result' do
        allow(described_class).to receive(:where).and_return(result)
        expect(call_method).to be(result)
      end
    end
    describe '`completed`' do
      let(:call_method) { described_class.completed }
      it_behaves_like 'an ActiveRecord scope', :completed
      it 'limits the scope to only records that have an attached report' do
        expect(described_class).to receive(:where).with(no_args).and_return(result)
        expect(result).to receive(:not).with(report_file_name: nil)
        call_method
      end
      it 'returns the found record' do
        allow(described_class).to receive_message_chain(:where, :not).and_return(result)
        expect(call_method).to be(result)
      end
    end
    describe '`for_period`' do
      let(:period) { '2014-04' }
      let(:call_method) { described_class.for_period(period) }
      it_behaves_like 'an ActiveRecord scope', :for_period
      it 'limits the scope to only records that have an assocaition to a QuickReportSet for the provided period' do
        expect(described_class).to receive(:joins).with(:quick_report_set).and_return(result)
        expect(result).to receive(:where).with({quick_report_sets: {period: period}})
        call_method
      end
      it 'returns the found record' do
        allow(described_class).to receive_message_chain(:joins, :where).and_return(result)
        expect(call_method).to be(result)
      end
      it 'finds the quick reports for that period' do
        bad_report_set = QuickReportSet.create(period: '2015-01', member_id: 2)
        bad_report_set.quick_reports.create(report_name: 'foo', report_file_name: 'foo.pdf')
        good_report_set = QuickReportSet.create(period: period, member_id: 3)
        good_report_set.quick_reports.create(report_name: 'foo', report_file_name: 'foo.pdf')
        good_report_set.quick_reports.create(report_name: 'bar', report_file_name: 'bar.pdf')
        good_report_set.quick_reports.create(report_name: 'woo', report_file_name: nil)
        expect(call_method.all).to match(good_report_set.quick_reports)
      end
    end
  end
end
