require 'rails_helper'

RSpec.describe MemberProcessQuickReportsJob, type: :job do
  let(:period) { '2015-01' }
  let(:period_date) { '2015-01-01'.to_date }
  let(:member_id) { rand(1..10) }
  let(:member) { Member.new(member_id) }
  let(:report_set) { double(QuickReportSet) }
  let(:run_job) { subject.perform(member_id, period) }

  before do
    allow(Member).to receive(:new).with(member_id).and_return(member)
    allow(member).to receive(:report_set_for_period).and_return(report_set)
    allow(report_set).to receive(:missing_reports).and_return([])
  end

  it 'raises an error if `member_id` is nil' do
    subject.perform(nil, period)
    expect(subject.job_status.failed?).to be(true)
  end
  it 'raises an error if `period` is nil' do
    subject.perform(member_id, nil)
    expect(subject.job_status.failed?).to be(true)
  end
  it 'constructs a Member from the `member_id`' do
    expect(Member).to receive(:new).with(member_id)
    run_job
  end
  it 'fetches the report set for the `period`' do
    expect(member).to receive(:report_set_for_period).with(period)
    run_job
  end
  it 'looks up the `default_dates_hash` for the period date' do
    expect(subject).to receive(:default_dates_hash).with(period_date)
    run_job
  end
  it 'fetches a list of all reports missing from the report set' do
    expect(report_set).to receive(:missing_reports).with(member.quick_report_list).and_return([])
    run_job
  end
  describe 'for each missing report' do
    let(:reports) { ['foo', 'bar'] }
    let(:date_hash) { double('A Date Hash', '[]': nil) }
    before do
      allow(report_set).to receive(:missing_reports).and_return(reports)
      allow(report_set).to receive_message_chain(:quick_reports, :reports_named, :first_or_create!)
      allow(subject).to receive(:default_dates_hash).and_return(date_hash)
      allow(member).to receive(:quick_report_params).and_return({})
    end
    it 'looks up the parameters for the report' do
      reports.each do |report|
        expect(member).to receive(:quick_report_params).with(report).and_return({})
      end
      run_job
    end
    it 'translates the parameter values into dates' do
      reports.each do |report|
        params = {
          double('A Param') => double('A Value'),
          double('A Param') => double('A Value')
        }
        translated_params = {
          params.keys.first => double('A Translated Value'),
          params.keys.last => double('A Translated Value')
        }
        allow(member).to receive(:quick_report_params).with(report).and_return(params)
        allow(date_hash).to receive(:[]).with(params.values.first).and_return(translated_params.values.first)
        allow(date_hash).to receive(:[]).with(params.values.last).and_return(translated_params.values.last)
        expect(FhlbJob).to receive(:perform_now).with(anything, report, anything, translated_params)
      end
      run_job
    end
    it 'renders the report as a PDF' do
      reports.each do |report|
        expect(RenderReportPDFJob).to receive(:perform_now).with(member_id, report, nil, {})
      end
      run_job
    end
    it 'saves the rendered report as a QuickReport' do
      reports.each do |report|
        quick_reports = double('Array of QuickReports')
        rendered_report = double('A Rendered Report')
        allow(RenderReportPDFJob).to receive(:perform_now).with(anything, report, anything, anything).and_return(rendered_report)
        allow(report_set).to receive_message_chain(:quick_reports, :reports_named).with(report).and_return(quick_reports)
        expect(quick_reports).to receive(:first_or_create!).with(report: rendered_report)
      end
      run_job
    end
    it 'continues if a report fails to render' do
      reports.each do |report|
        quick_reports = double('Array of QuickReports')
        allow(RenderReportPDFJob).to receive(:perform_now).with(anything, report, anything, anything).and_return(nil)
        allow(report_set).to receive_message_chain(:quick_reports, :reports_named).with(report).and_return(quick_reports)
        expect(quick_reports).to receive(:first_or_create!).with(report: nil)
      end
      run_job
    end
  end
end