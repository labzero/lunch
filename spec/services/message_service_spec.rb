require 'spec_helper'

describe MessageService do
  subject { MessageService.new }
  it { expect(subject).to respond_to(:corporate_communications) }

  describe '`corporate_communications` method' do
    let(:invalid_filter) { 'some_invalid_filter' }
    it 'returns all CorporateCommunications if no filter argument is passed' do
      expect(CorporateCommunication).to receive(:all)
      subject.corporate_communications
    end
    it 'returns all CorporateCommunications if `all` is passed as a filter argument' do
      expect(CorporateCommunication).to receive(:all)
      subject.corporate_communications('all')
    end
    it 'returns all CorporateCommunications if an invalid filter argument is passed' do
      expect(CorporateCommunication).to receive(:all)
      subject.corporate_communications(invalid_filter)
    end
    CorporateCommunication::VALID_CATEGORIES.each do |filter|
      it "filters CorporateCommunications by the #{filter} category" do
        expect(CorporateCommunication).to receive(:where).with(category: filter)
        subject.corporate_communications(filter)
      end
    end
  end

end
