require 'rails_helper'

RSpec.describe QuickReportsWatchdogJob, type: :job do
  let(:now) { Time.zone.now }
  let(:total) { rand(10..100) }
  let(:completed) { rand(0..9) }
  let(:period) { double('A Period') }
  let(:member_hash) { { id: SecureRandom.hex } }
  let(:members) { Array.new(rand(1..5)) { member_hash } }
  let(:member) { instance_double(Member, quick_report_list: Array.new(rand(1..5)) { quick_report }) }
  let(:run_job) { subject.perform(members, period) }
  let(:message_instance) { instance_double(ActionMailer::MessageDelivery) }
  describe 'class level behavior' do
    it 'queues itself as `high_priority`' do
      expect(described_class.queue).to eq('high_priority')
    end
  end
  describe 'protected methods' do
    describe '`get_start_time`' do
      let(:start_time) { double(Time) }
      before do
        allow(Time.zone).to receive(:now).and_return(now)
      end
      it 'assigns `@start_time` to now' do
        expect(subject.send(:get_start_time)).to eq(now)
      end
      it 'assigns `@start_time` to the same time if called more than once' do
        allow(Time.zone).to receive(:now).and_return(now, now + 10.seconds)
        start_time = subject.send(:get_start_time)
        expect(start_time).to eq(subject.send(:get_start_time))
      end
    end

    describe '`batch_completed?`' do
      let(:quick_report_period) { class_double(QuickReport, completed: []) }
      let(:call_method) { subject.send(:batch_completed?) }

      before do
        allow(QuickReport).to receive(:for_period).with(period).and_return(quick_report_period)
        allow(quick_report_period.completed).to receive(:count).and_return(completed)
        subject.send(:period=, period)
        subject.send(:total=, total)
      end

      it 'gets the current count of completed reports from the DB for the `period`' do
        expect(quick_report_period.completed).to receive(:count)
        call_method
      end

      it 'returns true if the number of completed reports is equal to the total reports expected' do
        subject.send(:total=, completed)
        expect(call_method).to be(true)
      end
      it 'returns true if the number of completed reports is greater than the total reports expected' do
        subject.send(:total=, completed - 1)
        expect(call_method).to be(true)
      end
      it 'returns false if the number of completed reports is less than the total reports expected' do
        subject.send(:total=, completed + 1)
        expect(call_method).to be(false)
      end
      it 'sets `completed` to the number of completed reports' do
        call_method
        expect(subject.send(:completed)).to eq(completed)
      end
      it 'sets `last_completed_at` to the current time if the completed count has changed' do
        allow(Time.zone).to receive(:now).and_return(now)
        subject.send(:completed=, completed - 1)
        call_method
        expect(subject.send(:last_completed_at)).to eq(now)
      end
      it 'does not set `last_completed_at` if the completed count has not changed' do
        old_last_completed_at = instance_double(Time)
        subject.send(:completed=, completed)
        subject.send(:last_completed_at=, old_last_completed_at)
        call_method
        expect(subject.send(:last_completed_at)).to be(old_last_completed_at)
      end
    end

    describe '`stalled?`' do
      let(:call_method) { subject.send(:stalled?) }
      before do
        allow(Time.zone).to receive(:now).and_return(now)
      end
      it 'returns true if the last completed report was more than `TIMEOUT` ago' do
        subject.send(:last_completed_at=, now - (described_class::TIMEOUT + 1))
        expect(call_method).to be(true)
      end
      it 'returns false if the last completed report was less than `TIMEOUT` ago' do
        subject.send(:last_completed_at=, now - (described_class::TIMEOUT - 1))
        expect(call_method).to be(false)
      end
      it 'returns false if the last completed report was exactly `TIMEOUT` ago' do
        subject.send(:last_completed_at=, now - described_class::TIMEOUT)
        expect(call_method).to be(false)
      end
    end

    describe '`long_run?`' do
      let(:call_method) { subject.send(:long_run?) }
      before do
        allow(Time.zone).to receive(:now).and_return(now)
      end
      it 'returns true if its after the `long_run_threshold`' do
        subject.send(:long_run_threshold=, now - 1.second)
        expect(call_method).to be(true)
      end
      it 'returns false if its before the `long_run_threshold`' do
        subject.send(:long_run_threshold=, now + 1.second)
        expect(call_method).to be(false)
      end
      it 'returns false if its exactly the `long_run_threshold`' do
        subject.send(:long_run_threshold=, now)
        expect(call_method).to be(false)
      end
      it 'returns false if the `long_run_threshold` is not set' do
        subject.send(:long_run_threshold=, nil)
        expect(call_method).to be(false)
      end
    end

    describe '`done?`' do
      let(:call_method) { subject.send(:done?) }

      before do
        allow(subject).to receive(:batch_completed?).and_return(false)
        allow(subject).to receive(:stalled?).and_return(false)
      end

      it 'returns true if `batch_completed?` returns true' do
        allow(subject).to receive(:batch_completed?).and_return(true)
        expect(call_method).to be(true)
      end
      it 'returns true if `stalled?` returns true' do
        allow(subject).to receive(:stalled?).and_return(true)
        expect(call_method).to be(true)
      end
      it 'returns false if both `batch_completed?` and `stalled?` return false' do
        expect(call_method).to be(false)
      end
      it 'calls `batch_completed?` before calling `stalled?`' do
        expect(subject).to receive(:batch_completed?).ordered
        expect(subject).to receive(:stalled?).ordered
        call_method
      end
    end

    describe '`sleep_until`' do
      let(:wake_time) { now }
      let(:call_method) { subject.send(:sleep_until, wake_time) }
      it 'sleeps until the supplied time' do
        seconds_ago = rand(1..30).seconds
        allow(Time.zone).to receive(:now).and_return(wake_time - seconds_ago)
        expect(subject).to receive(:sleep).with(seconds_ago)
        call_method
      end
      it 'does not sleep if the supplied time is in the past' do
        allow(Time.zone).to receive(:now).and_return(wake_time + rand(1..20).seconds)
        expect(subject).to_not receive(:sleep)
        call_method
      end
    end
  end
  describe '`perform` method' do
      let(:current_time) { now }
      let(:start_time) { current_time - rand(1..3).seconds }
      let(:end_time) { start_time + 5.minutes }
    let(:quick_report_period) { class_double(QuickReport, completed: []) }
    before do
      allow(QuickReportSet).to receive(:current_period).and_return(period)
      allow(members).to receive(:sum).and_yield(member_hash).and_return(total)
      allow(subject).to receive(:done?).and_return(true)
      allow(subject).to receive(:get_start_time).and_return(start_time)
      allow(subject).to receive(:sleep_until)
    end
    it 'invokes job with an array of members' do
      expect(subject).to receive(:perform).with(members, period)
      run_job
    end
    it 'calls `sum` and yields' do
      expect(members).to receive(:sum).and_yield(member_hash)
      run_job
    end
    it "calls sum on members' `quick_report_list`s" do
      allow(members).to receive(:sum) do |*args, &block|
        expect(Member.class).to receive(:new).with(args[0]['id']).and_return(member)
        expect(member.quick_report_list).to receive(:size)
        block.call
      end
      run_job
    end
    it 'returns the sum of `quick_report_list`s from the block' do
      allow(members).to receive(:sum) do |*args, &block|
        expect(block.call).to eq(members.sum { |m| Member.new(m['id']).quick_report_list.size })
      end
      run_job
    end
    it 'sets the period to the current period if one is not provided' do
      expect(QuickReportSet).to receive(:current_period)
      subject.perform(members)
    end

    describe 'initial attribute setup' do
      it 'sets the `period` attribute to the current period' do
        expect(subject).to receive(:period=).with(period)
        run_job
      end
      it 'sets the `total` attribute to the total reports expected' do
        expect(subject).to receive(:total=).with(total)
        run_job
      end
      it 'sets the `completed` attribute to zero' do
        expect(subject).to receive(:completed=).with(0)
        run_job
      end
      it 'sets the `last_completed_at` attribute to the start time' do
        expect(subject).to receive(:last_completed_at=).with(start_time)
        run_job
      end
      it 'sets the `long_run_threshold` attribute to `MAX_RUN_TIME` hours after the start time' do
        expect(subject).to receive(:long_run_threshold=).with(start_time + QuickReportsWatchdogJob::MAX_RUN_TIME)
        run_job
      end
    end

    it 'calls `done?` until it returns true' do
      times = rand(3..10)
      expect(subject).to receive(:done?).and_return(*(Array.new(times - 1, false) << true)).exactly(times)
      run_job
    end
    it 'calls `sleep_until` with the next poll time if `done?` returns false' do
      allow(subject).to receive(:done?).and_return(false, true)
      expect(subject).to receive(:sleep_until).with(start_time + described_class::POLLING_INTERVAL)
      run_job
    end
    it 'increments the poll time every time `done?` returns false' do
      times = rand(3..10)
      polling_intervals = (1..(times - 1)).collect {|i| start_time + (i * described_class::POLLING_INTERVAL)}
      allow(subject).to receive(:done?).and_return(*(Array.new(times - 1, false) << true))
      polling_intervals.each do |interval|
        expect(subject).to receive(:sleep_until).with(interval).ordered
      end
      run_job
    end
    it 'send an email after `done?` returns true' do
      expect(subject).to receive(:done?).and_return(true).ordered
      expect(InternalMailer).to receive(:quick_report_status).ordered
      run_job
    end
    it 'calls `InternalMailer` to send a status email' do
      allow(Time.zone).to receive(:now).and_return(end_time)
      allow(subject).to receive(:done?) do
        subject.send(:completed=, completed)
        true
      end

      allow(InternalMailer).to receive(:quick_report_status).with(start_time, end_time, completed, total).and_return(message_instance)
      expect(message_instance).to receive(:deliver_now)
      run_job
    end

    describe 'long run warning' do
      before do
        allow(subject).to receive(:done?).and_return(false, true)
      end
      it 'calls `long_run?` if `done?` returns false' do
        expect(subject).to receive(:long_run?)
        run_job
      end
      it 'calls `long_run?` each time `done?` returns false' do
        times = rand(3..10)
        allow(subject).to receive(:done?).and_return(*(Array.new(times - 1, false) << true))
        expect(subject).to receive(:long_run?).exactly(times - 1)
        run_job
      end
      describe 'if `long_run?` returns true' do
        before do
          allow(subject).to receive(:long_run?).and_return(true)
        end
        it 'sets `long_run_threshold` to nil' do
          allow(subject).to receive(:long_run_threshold=)
          expect(subject).to receive(:long_run_threshold=).with(nil)
          run_job
        end
        it 'sends a warning email if `long_run?` returns true' do
          returns = [false, true]
          allow(subject).to receive(:done?) do
            subject.send(:completed=, completed)
            returns.shift
          end
          expect(subject).to receive(:long_run?)
          allow(InternalMailer).to receive(:quick_report_long_run).with(completed, total).and_return(message_instance)
          expect(message_instance).to receive(:deliver_now)
          run_job
        end
      end
    end
  end
end