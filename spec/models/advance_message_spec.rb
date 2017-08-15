require 'rails_helper'

RSpec.describe AdvanceMessage, :type => :model do
  it { should validate_presence_of(:content) }
  it { should validate_presence_of(:date) }
  
  describe 'the `all` class method' do
    let(:early_shutoff_date) { Time.zone.today + rand(0..99).days }
    let(:future_early_shutoff_date) { early_shutoff_date + 1.day }
    let(:earlier_shutoff) {{
      early_shutoff_date: early_shutoff_date,
      day_of_message: double('some message')
    }}
    let(:future_shutoff) {{
      early_shutoff_date: future_early_shutoff_date,
      day_of_message: double('some message'),
      day_before_message: double('some other message')
    }}
    let(:previous_business_day) { early_shutoff_date }
    let(:calendar_service) { instance_double(CalendarService, find_previous_business_day: previous_business_day) }
    let(:etransact_service) { instance_double(EtransactAdvancesService, early_shutoffs: [])}
    let(:call_method) { AdvanceMessage.all }
    before do
      allow(CalendarService).to receive(:new).and_return(calendar_service)
      allow(EtransactAdvancesService).to receive(:new).and_return(etransact_service)
    end
    context 'when there are no early shutoffs scheduled' do
      it 'returns an empty array' do
        expect(call_method).to eq([])
      end
    end
    context 'when there are early shutoffs scheduled' do
      before { allow(etransact_service).to receive(:early_shutoffs).and_return([earlier_shutoff]) }
      it 'returns an array of AdvanceMessage instances' do
        messages = call_method
        expect(messages.size).to be > 0
        messages.each do |message|
          expect(message).to be_a_kind_of(AdvanceMessage)
        end
      end
      it 'creates a new instance of the CalendarService with nil for the request arg' do
        expect(CalendarService).to receive(:new).with(nil).and_return(calendar_service)
        call_method
      end
      it 'creates a new instance of the EtransactAdvancesService with nil for the request arg' do
        expect(EtransactAdvancesService).to receive(:new).and_return(etransact_service)
        call_method
      end
      it 'creates a message with a date equal to the `early_shutoff_date`' do
        expect(call_method.first.date).to eq(early_shutoff_date)
      end
      context 'when there is an early shutoff with a `day_of` message' do
        context 'when there is a conflict with the `day_before` message of an early shutoff date occurring the next business day' do
          before do
            allow(etransact_service).to receive(:early_shutoffs).and_return([earlier_shutoff, future_shutoff])
          end
          it 'always sets the `content` of the message to the `day_of_message` for the given date' do
            message = call_method.find { |message| message.date == early_shutoff_date }
            expect(message.content).to eq(earlier_shutoff[:day_of_message])
          end
        end
        context 'when there are no conflicts with any `day_before` messages from other early shutoffs' do
          before do
            future_shutoff[:early_shutoff_date] = early_shutoff_date + rand(2..99).days
            allow(etransact_service).to receive(:early_shutoffs).and_return([earlier_shutoff, future_shutoff])
          end
          it 'always sets the `content` of the message to the `day_of_message` for the given date' do
            message = call_method.find { |message| message.date == early_shutoff_date }
            expect(message.content).to eq(earlier_shutoff[:day_of_message])
          end
        end
      end
      context 'when there is an early shutoff with a `day_before` message' do
        before { allow(etransact_service).to receive(:early_shutoffs).and_return([earlier_shutoff, future_shutoff]) }
        it 'calls `find_previous_business_day` on the instance of the CalendarService with a start date equal to the day before the `early_shutoff_date`' do
          expect(calendar_service).to receive(:find_previous_business_day).with(future_shutoff[:early_shutoff_date] - 1.day, anything).and_return(early_shutoff_date - 1.day)
          call_method
        end
        it 'calls `find_previous_business_day` with a delta of 1 day' do
          expect(calendar_service).to receive(:find_previous_business_day).with(anything, 1.day).and_return(early_shutoff_date - 1.day)
          call_method
        end
        it 'creates a message with a date equal to the previous business day from the `early_shutoff_date` of the shutoff with the `day_before_message`' do
          message = call_method.find{ |message| message.date == previous_business_day}
          expect(message).to be_a_kind_of(AdvanceMessage)
        end
        context 'when there is a conflict with the `day_of` message of an early shutoff occurring the previous business day' do
          context 'when there are no intervening days between the `day_of` and the previous business day' do
            let(:future_early_shutoff_date) { early_shutoff_date + 1.day}
            before { allow(etransact_service).to receive(:early_shutoffs).and_return([earlier_shutoff, future_shutoff]) }

            it 'ignores the `day_before_message` and sets the `content` of the message for conflicting day to the `day_of_message` of the earlier shutoff' do
              message = call_method.find { |message| message.date == early_shutoff_date }
              expect(message.content).to eq(earlier_shutoff[:day_of_message])
            end
          end
          context 'when there are intervening days (e.g. weekends/holidays) between the `day_of` and the previous business day' do
            let(:future_early_shutoff_date) { early_shutoff_date + 3.days}
            before { allow(etransact_service).to receive(:early_shutoffs).and_return([earlier_shutoff, future_shutoff]) }

            describe 'the message for the conflicting date' do
              it 'always sets the `content` of the message to the `day_of_message` for the given date' do
                message = call_method.find { |message| message.date == early_shutoff_date }
                expect(message.content).to eq(earlier_shutoff[:day_of_message])
              end
            end
            describe 'the message for the future date' do
              it 'sets the `content` of the message to the `day_of_message` for the given date' do
                message = call_method.find { |message| message.date == future_early_shutoff_date }
                expect(message.content).to eq(future_shutoff[:day_of_message])
              end
            end
            describe 'the intervening days' do
              it 'sets the `content` of the message for the intervening days to the `day_before_message` of the shutoff occurring on the next business day' do
                intervening_days = (early_shutoff_date...future_early_shutoff_date).to_a - [early_shutoff_date]
                expect(intervening_days.size).to eq(2)
                intervening_days.each do |date|
                  message = call_method.find { |message| message.date == date }
                  expect(message.content).to eq(future_shutoff[:day_before_message])
                end
              end
            end
          end
        end
      end
    end
  end

  describe 'the `quick_advance_message_for` class method' do
    let(:date) { double('a date') }
    let(:content) { double('some content') }
    let(:message_1) { double('a message', date: nil) }
    let(:message_2) { double('another message', date: nil) }
    let(:message_array) { [message_1, message_2] }
    let(:call_method) { AdvanceMessage.send(:quick_advance_message_for, date) }
    before { allow(AdvanceMessage).to receive(:all).and_return(message_array) }
    it 'calls ``all` on the AdvanceMessage class`' do
      expect(AdvanceMessage).to receive(:all)
      call_method
    end
    it 'returns the content of the message it finds whose date matches the passed argument' do
      allow(message_1).to receive(:date).and_return(date)
      allow(message_1).to receive(:content).and_return(content)
      expect(call_method).to eq(content)
    end
    it 'only returns the content of the first message it finds' do
      allow(message_1).to receive(:date).and_return(date)
      allow(message_1).to receive(:content).and_return(content)
      allow(message_2).to receive(:date).and_return(date)
      allow(message_2).to receive(:content).and_return(double('different content'))
      expect(call_method).to eq(content)
    end
    it 'returns nil if it does not find any messages whose date matches the passed argument' do
      expect(call_method).to be_nil
    end
    it 'returns nil if there are no messages' do
      allow(AdvanceMessage).to receive(:all).and_return([])
      expect(call_method).to be_nil
    end
  end
end