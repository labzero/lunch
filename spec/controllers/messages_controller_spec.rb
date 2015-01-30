require 'rails_helper'

RSpec.describe MessagesController, :type => :controller do
  login_user

  describe 'GET index' do
    it_behaves_like 'a user required action', :get, :index
    let(:message_service_instance) { double('MessageServiceInstance') }
    let(:messages) { double('Array of Messages') }
    it 'should render the index view' do
      get :index
      expect(response.body).to render_template('index')
    end
    it 'should set @sidebar_options as an array of options with a label and a value' do
      get :index
      expect(assigns[:sidebar_options]).to be_kind_of(Array)
      assigns[:sidebar_options].each do |option|
        expect(option.first).to be_kind_of(String)
        expect(option.last).to be_kind_of(String)
      end
    end
    CorporateCommunication::VALID_CATEGORIES.each do |category|
      it "should set @filter to #{category} if that is passed in as the `messages_filter` param" do
        get :index, messages_filter: category
        expect(assigns[:filter]).to eq(category)
      end
    end
    it 'should set @filter to `all` if the `messages_filter` param is not valid based on the values in @sidebar_options' do
      get :index, messages_filter: 'some_invalid_param'
      expect(assigns[:filter]).to eq('all')
    end
    it 'should set @filter to `all` if there is no `messages_filter` param' do
      get :index
      expect(assigns[:filter]).to eq('all')
    end
    it 'should pass @filter to MessageService#corporate_communications as an argument' do
      expect(message_service_instance).to receive(:corporate_communications).with('all')
      expect(MessageService).to receive(:new).and_return(message_service_instance)
      get :index
    end
    it 'should set @messages to the value returned by MessageService#corporate_communications' do
      expect(message_service_instance).to receive(:corporate_communications).and_return(messages)
      expect(MessageService).to receive(:new).and_return(message_service_instance)
      get :index
      expect(assigns[:messages]).to eq(messages)
    end
  end

end