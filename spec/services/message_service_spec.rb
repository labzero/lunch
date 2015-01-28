require 'spec_helper'

describe MessageService do
  subject { MessageService.new }
  it { expect(subject).to respond_to(:corporate_communications) }

  describe '`corporate_communications` method' do
    let(:messages) { subject.corporate_communications }
    it "should return an array of messages" do
      expect(messages.length).to be >= 1
      expect(messages).to be_kind_of(Array)
      messages.each do |message|
        expect(message[:date]).to be_kind_of(Date)
        expect(message[:category]).to be_kind_of(String)
        expect(message[:title]).to be_kind_of(String)
        expect(message[:body]).to be_kind_of(String)
      end
    end
    it 'returns nil if there is a JSON parsing error' do
      expect(File).to receive(:read).and_return('some malformed json!')
      expect(Rails.logger).to receive(:warn)
      expect(messages).to be(nil)
    end
  end
end
