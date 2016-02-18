require 'rails_helper'

describe MessageService do
  subject { MessageService.new }
  it { expect(subject).to respond_to(:corporate_communications) }
  it { expect(subject).to respond_to(:todays_quick_advance_message) }

  describe '`corporate_communications` method' do
    let(:invalid_filter) { 'some_invalid_filter' }
    let(:active_record_relation) { double('ActiveRecord_Relation', order: nil) }
    it 'returns all CorporateCommunications if no filter argument is passed' do
      expect(CorporateCommunication).to receive(:all).and_return(active_record_relation)
      subject.corporate_communications
    end
    it 'returns all CorporateCommunications if `all` is passed as a filter argument' do
      expect(CorporateCommunication).to receive(:all).and_return(active_record_relation)
      subject.corporate_communications('all')
    end
    it 'returns all CorporateCommunications if an invalid filter argument is passed' do
      expect(CorporateCommunication).to receive(:all).and_return(active_record_relation)
      subject.corporate_communications(invalid_filter)
    end
    CorporateCommunication::VALID_CATEGORIES.each do |filter|
      it "filters CorporateCommunications by the #{filter} category" do
        expect(CorporateCommunication).to receive(:where).with(category: filter).and_return(active_record_relation)
        subject.corporate_communications(filter)
      end
    end
    it 'orders the CorporateCommunications by descending `date_sent`' do
      allow(CorporateCommunication).to receive(:all).and_return(active_record_relation)
      expect(active_record_relation).to receive(:order).with(date_sent: :desc)
      subject.corporate_communications
    end
  end
  
  describe '`todays_quick_advance_message` method' do
    let(:today) { double('today') }
    let(:message) { double('message') }
    let(:todays_quick_advance_message) { subject.todays_quick_advance_message }
    before do
      allow(Time.zone).to receive(:today).and_return(today)
    end
    it 'calls the `quick_advance_message_for` class method on AdvanceMessage with today\'s date' do
      expect(AdvanceMessage).to receive(:quick_advance_message_for).with(today)
      todays_quick_advance_message
    end 
    it 'returns the result of `quick_advance_message_for`' do
      allow(AdvanceMessage).to receive(:quick_advance_message_for).and_return(message)
      expect(todays_quick_advance_message).to eq(message)
    end
  end

end
