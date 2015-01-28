require 'spec_helper'

describe MessageService do
  subject { MessageService.new }
  it { expect(subject).to respond_to(:corporate_communications) }

  describe '`corporate_communications` method' do
    let(:valid_filters) { %w(misc investor_relations products credit technical_updates community) }
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
    it 'filters CorporateCommunications by `category` if a valid filter argument is passed' do
      valid_filters.each do |filter|
        expect(CorporateCommunication).to receive(:where).with(category: filter)
        subject.corporate_communications(filter)
      end
    end
  end

end
