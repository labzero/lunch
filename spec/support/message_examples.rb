RSpec.shared_examples 'a controller action with quick advance messaging' do |action|
  describe 'the @quick_advance_message instance variable' do
    let(:message) { double('message') }
    let(:service_instance) { double('service instance') }
    before { allow(MessageService).to receive(:new).and_return(service_instance) }
    it 'is set to the value returned by the `todays_quick_advance_message` MessageService instance method' do
      allow(service_instance).to receive(:todays_quick_advance_message).and_return(message)
      get action
      expect(assigns[:quick_advance_message]).to eq(message)
    end
    it 'is nil if the `todays_quick_advance_message` MessageService instance method returns nil' do
      allow(service_instance).to receive(:todays_quick_advance_message)
      get action
      expect(assigns[:quick_advance_message]).to be_nil
    end
  end
end