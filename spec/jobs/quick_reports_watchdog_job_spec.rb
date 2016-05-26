require 'rails_helper'

RSpec.describe QuickReportsWatchdogJob, type: :job do
  let(:now) { double(Time) }
  let(:total) { rand(10..100) }
  let(:completed) { rand(0..9) }
  let(:period) { double('A Period') }
  let(:quick_report) { double('A Quick Report') }
  let(:member) { double('A Member', quick_report_list: Array.new(rand(1..5)) { quick_report }) }
  let(:members) { Array.new(rand(1..5)) { member } }
  let(:run_job) { subject.perform(members, period) }
  let(:quick_report_status) { double('A QuickReport Status') }
  describe 'class level behavior' do
    it 'queues itself as `high_priority`' do
      expect(described_class.queue).to eq('high_priority')
    end
  end
  describe 'protected methods' do
    let(:start_time) { double(Time) }
    before do
      allow(Time.zone).to receive(:now).and_return(now)
    end
    it 'assigns `@start_time` to now' do
      expect(subject.send(:get_start_time)).to eq(now)
    end
    it 'assigns `@start_time` to the same time if called more than once' do
      start_time = subject.send(:get_start_time)
      begin
        Timecop.travel(30.seconds)
        expect(start_time).to eq(subject.send(:get_start_time))
      ensure
        Timecop.return
      end
    end
  end
  describe '`perform` method' do
    before do
      allow(members).to receive(:sum).and_yield(member).and_return(total)
    end
    it 'calls sum and yields' do
      expect(members).to receive(:sum).and_yield(member)
      run_job
    end
    it "calls sum on members' `quick_report_list`s" do
      allow(members).to receive(:sum) do |*args, &block|
        expect(args[0].quick_report_list).to receive(:size)
        block.call
      end
      run_job
    end
    it 'returns the sum of `quick_report_list`s fromt the block' do
      allow(members).to receive(:sum) do |*args, &block|
        expect(block.call).to eq(members.sum { |m| m.quick_report_list.size })
      end
      run_job
    end
    it 'sets the period to the current period if one is not provided' do
      expect(QuickReportSet).to receive(:current_period)
      subject.perform(members)
    end
    describe 'continuous loop' do
      let(:quick_report_period) { double('A QuickReport Period', completed: []) }
      let(:current_time) { Time.zone.now }
      let(:start_time) { current_time - rand(1..3).seconds }
      let(:end_time) { start_time + 5.minutes }
      before do
        allow(Time.zone).to receive(:now).and_return(current_time)
        allow(subject).to receive(:get_start_time).and_return(start_time)
        allow(QuickReportSet).to receive(:for_period).with(period).and_return(quick_report_period)
        allow(quick_report_period.completed).to receive(:count).and_return(completed)
        allow(subject).to receive(:sleep).with(any_args).and_return(nil)
      end
      it '`loop`s' do
        expect(subject).to receive(:loop)
        run_job
      end
      describe 'break conditions' do
        it 'goes to sleep if `completed < total`' do
          allow(subject).to receive(:loop) do |*args, &block|
            expect(subject).to receive(:sleep).with(adjusted_polling_interval)
            block.call
          end
          run_job
        end
        it 'does not call sleep with a negative value' do
          allow(subject).to receive(:get_start_time).and_return(Time.zone.now - 5.minutes)
          allow(subject).to receive(:loop) do |*args, &block|
            expect(subject).to receive(:sleep).with(0)
            block.call
          end
          run_job
        end
        it 'completes loop if `completed == total`' do
          allow(QuickReportSet.for_period(period).completed).to receive(:count).and_return(total)
          allow(subject).to receive(:loop) do |*args, &block|
            expect(subject).not_to receive(:sleep)
            block.call
          end
          run_job
        end
        it 'completes loop if `completed > total`' do
          allow(QuickReportSet.for_period(period).completed).to receive(:count).and_return(total + 1)
          allow(subject).to receive(:loop) do |*args, &block|
            expect(subject).not_to receive(:sleep)
            block.call
          end
          run_job
        end
        describe 'timing out' do
          let(:now) { double(Time) }
          it 'completes loop if `TIMEOUT` exceeded' do
            allow(now).to receive(:>).with(start_time + QuickReportsWatchdogJob::TIMEOUT).and_return(true)
            allow(subject).to receive(:loop) do |*args, &block|
              expect(subject).not_to receive(:sleep)
            end
            run_job
          end
        end
      end
      describe 'email' do
        let(:completed) { total }
        it 'calls `InternalMailer` to send a status email' do
          allow(Time.zone).to receive(:now).and_return(end_time)
          allow(InternalMailer).to receive(:quick_report_status).with(start_time, end_time, completed, total).and_return(quick_report_status)
          expect(quick_report_status).to receive(:deliver_now)
          run_job
        end
      end
    end
  end
end