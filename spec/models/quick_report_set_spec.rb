require 'rails_helper'

RSpec.describe QuickReportSet, type: :model do
  it { should have_many(:quick_reports).dependent(:destroy) }
  it { should validate_presence_of(:member_id) }
  it { should validate_presence_of(:period) }
  it { should have_db_index([:member_id, :period]).unique(true) }
  it { should delegate_method(:reports_named).to(:quick_reports) }

  describe '`period` format' do
    ['2000-01', '2001-10', '2002-11', '1999-12', '0000-04'].each do |value|
      it { should allow_value(value).for(:period) }
    end
    ['2000-13', '2001-00', '20-1100', '1999-31', 'abce-01', '2000-cf'].each do |value|
      it { should_not allow_value(value).for(:period) }
    end
  end

  describe 'scopes' do
    let(:result) { double(ActiveRecord::Relation) }
    describe '`for_member`' do
      let(:member_id) { double('A Member ID') }
      let(:call_method) { described_class.for_member(member_id) }
      it_behaves_like 'an ActiveRecord scope', :for_member
      it 'limits the scope to only records for that member' do
        expect(described_class).to receive(:where).with(member_id: member_id)
        call_method
      end
      it 'returns the result' do
        allow(described_class).to receive(:where).and_return(result)
        expect(call_method).to be(result)
      end
    end
    describe '`for_period`' do
      let(:period) { double('A Period') }
      let(:call_method) { described_class.for_period(period) }
      it_behaves_like 'an ActiveRecord scope', :for_period
      it 'finds all records with the provided period' do
        expect(described_class).to receive(:where).with(period: period)
        call_method
      end
      it 'returns the found records' do
        allow(described_class).to receive(:where).and_return(result)
        expect(call_method).to be(result)
      end
    end
  end
  describe 'class methods' do
    describe '`current_period`' do
      let(:call_method) { described_class.current_period }
      it 'returns a string of the format `YYYY-MM`' do
        expect(call_method).to match(/\A\d\d\d\d-\d\d\z/)
      end
      it 'returns the year and month from one month ago' do
        Timecop.freeze do
          now = Date.current - 1.month
          period_string = now.year.to_s + '-' + (now.month < 10 ? '0' : '') + now.month.to_s
          expect(call_method).to match(period_string)
        end
      end
    end
    describe '`latest`' do
      let(:result) { double(ActiveRecord::Relation) }
      let(:call_method) { described_class.latest }
      it_behaves_like 'an ActiveRecord scope', :latest
      it 'orders the records by `period`, descending' do
        expect(described_class).to receive(:order).with('period DESC').and_return([])
        call_method
      end
      it 'finds the first record from the ordered list' do
        ordered_list = double(ActiveRecord::Relation)
        allow(described_class).to receive(:order).and_return(ordered_list)
        expect(ordered_list).to receive(:first)
        call_method
      end
      it 'returns the found record' do
        allow(described_class).to receive_message_chain(:order, :first).and_return(result)
        expect(call_method).to be(result)
      end
    end
    describe '`latest_with_reports`' do
      let(:call_method) { described_class.latest_with_reports }
      let(:empty_report_set) { QuickReportSet.create(period: '2015-01', member_id: 1) }
      let(:latest_empty_report_set) { QuickReportSet.create(period: '2015-05', member_id: 1) }
      let(:full_report_set) do 
        report_set = QuickReportSet.create(period: '2015-01', member_id: 2)
        report_set.quick_reports.create(report_name: 'foo', report_file_name: 'foo.pdf')
        report_set
      end
      let(:partial_report_set) do
        report_set = QuickReportSet.create(period: '2015-02', member_id: 3)
        report_set.quick_reports.create(report_name: 'foo', report_file_name: 'foo.pdf')
        report_set.quick_reports.create(report_name: 'bar')
        report_set
      end
      let(:no_completed_report_set) do
        report_set = QuickReportSet.create(period: '2015-01', member_id: 4)
        report_set.quick_reports.create(report_name: 'foo')
        report_set.quick_reports.create(report_name: 'bar')
        report_set
      end
      let(:all_report_sets) { [empty_report_set, latest_empty_report_set, full_report_set, partial_report_set, no_completed_report_set] }
      it_behaves_like 'an ActiveRecord scope', :latest_with_reports
      it 'returns the latest quick report that has a populated report' do
        all_report_sets
        expect(call_method).to eq(partial_report_set)
      end
      it 'ignores QuickReportSets that lack any QuickReports' do
        empty_report_set
        full_report_set
        expect(call_method).to eq(full_report_set)
      end
      it 'ignores QuickReportSets that lack populated QuickReports' do
        empty_report_set
        no_completed_report_set
        full_report_set
        expect(call_method).to eq(full_report_set)
      end
      it 'ignores the latest QuickReportSet if its empty' do
        latest_empty_report_set
        partial_report_set
        expect(call_method).to eq(partial_report_set)
      end
    end
  end
  describe 'instance methods' do
    describe '`has_reports?`' do
      let(:report_names) { [:foo, :bar] }
      let(:quick_reports) { subject.quick_reports }
      let(:call_method) { subject.has_reports?(report_names) }
      it 'filters the quick reports list by the supplied report names' do
        expect(quick_reports).to receive(:reports_named).with(report_names).and_return(quick_reports)
        call_method
      end
      it 'supports a single report name' do
        expect(quick_reports).to receive(:reports_named).with([:bar]).and_return(quick_reports)
        subject.has_reports?(:bar)
      end
      it 'supports multiple report name arguments' do
        expect(quick_reports).to receive(:reports_named).with(report_names).and_return(quick_reports)
        subject.has_reports?(*report_names)
      end
      it 'checks if the found reports have been completed' do
        allow(quick_reports).to receive(:reports_named).and_return(quick_reports)
        expect(quick_reports).to receive(:completed).and_return(quick_reports)
        call_method
      end
      it 'returns true if there is a completed quick report for each supplied name' do
        allow(quick_reports).to receive_message_chain(:reports_named, :completed).and_return(report_names)
        expect(call_method).to be(true)
      end
      it 'returns false if at least one quick report is missing or uncompleted' do
        allow(quick_reports).to receive_message_chain(:reports_named, :completed).and_return(report_names[0..-2])
        expect(call_method).to be(false)
      end
    end
    describe '`missing_reports`' do
      let(:report_names) { [:foo, :bar] }
      let(:stringified_report_names) { report_names.collect(&:to_s) }
      let(:quick_reports) { subject.quick_reports }
      let(:call_method) { subject.missing_reports(report_names) }

      it 'filters the quick reports list by the supplied report names' do
        expect(quick_reports).to receive(:reports_named).with(stringified_report_names).and_return(quick_reports)
        call_method
      end
      it 'supports a single report name' do
        expect(quick_reports).to receive(:reports_named).with(['bar']).and_return(quick_reports)
        subject.missing_reports(:bar)
      end
      it 'supports multiple report name arguments' do
        expect(quick_reports).to receive(:reports_named).with(stringified_report_names).and_return(quick_reports)
        subject.missing_reports(*report_names)
      end
      it 'returns a list of report names that havent been completed yet' do
        allow(quick_reports).to receive_message_chain(:reports_named, :completed).and_return([QuickReport.new(report_name: 'foo')])
        expect(call_method).to eq(['bar'])
      end
      it 'returns an empty list if all the report names passed have been completed' do
        reports = report_names.collect { |name| QuickReport.new(report_name: name) }
        allow(quick_reports).to receive_message_chain(:reports_named, :completed).and_return(reports)
        expect(call_method).to eq([])
      end
    end
    describe '`completed?`' do
      let(:report_names) { [:foo, :bar] }
      let(:call_method) { subject.completed?(report_names) }
      it 'returns true if all the named reports have been completed' do
        allow(subject).to receive(:missing_reports).with(report_names).and_return([])
        expect(call_method).to be(true)
      end
      it 'returns false if not all the named reports have been completed' do
        allow(subject).to receive(:missing_reports).with(report_names).and_return(report_names.sample)
        expect(call_method).to be(false)
      end
      it 'defaults the list of report names to the members `quick_report_list`' do
        subject.member_id = rand(1..10)
        allow(subject.member).to receive(:quick_report_list).and_return(report_names)
        expect(subject).to receive(:missing_reports).with(report_names).and_return([])
        subject.completed?
      end
    end
    describe '`member`' do
      let(:member_id) { rand(1..10) }
      let(:call_method) { subject.member }
      before do
        allow(subject).to receive(:member_id).and_return(member_id)
      end
      it 'returns a Member' do
        expect(call_method).to be_kind_of(Member)
      end
      it 'returns the Member associated with this QuickReportSet' do
        expect(call_method.id).to eq(member_id)
      end
      it 'caches the Member' do
        member = call_method
        expect(call_method).to be(member)
      end
    end
  end

  describe 'ActiveRecord strangeness' do
    it 'returns nil when `for_member` and `latest_with_reports` are combined and there is a QuickReportSet with no QuickReports' do
      member_id = rand(1..10)
      QuickReportSet.create(member_id: member_id)
      expect(QuickReportSet.for_member(member_id).latest_with_reports).to be_nil
    end
    it 'returns nil when `for_member` and `latest` are combined and there are no QuickReportSets' do
      member_id = rand(1..10)
      expect(QuickReportSet.for_member(member_id).latest).to be_nil
    end
  end

end
