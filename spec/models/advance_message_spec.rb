require 'rails_helper'

RSpec.describe AdvanceMessage, :type => :model do
  it { should validate_presence_of(:content) }
  it { should validate_presence_of(:date) }
  
  describe 'the `all` class method' do
    it 'returns an array of AdvanceMessage instances' do
      AdvanceMessage.all.each do |message|
        expect(message).to be_a_kind_of(AdvanceMessage)
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