require 'rails_helper'

RSpec.describe CorporateCommunicationsController, :type => :controller do
  login_user

  describe 'GET category' do
    it_behaves_like 'a user required action', :get, :category, category: 'all'
    let(:message_service_instance) { double('MessageServiceInstance') }
    let(:corporate_communications) { double('Array of Messages') }
    it 'should render the category view' do
      get :category, category: 'all'
      expect(response.body).to render_template('category')
    end
    it 'should pass @filter to MessageService#corporate_communications as an argument' do
      expect(message_service_instance).to receive(:corporate_communications).with('all')
      expect(MessageService).to receive(:new).and_return(message_service_instance)
      get :category, category: 'all'
    end
    it 'should set @messages to the value returned by MessageService#corporate_communications' do
      expect(message_service_instance).to receive(:corporate_communications).and_return(corporate_communications)
      expect(MessageService).to receive(:new).and_return(message_service_instance)
      get :category, category: 'all'
      expect(assigns[:messages]).to eq(corporate_communications)
    end
  end

  describe 'GET show' do
    it_behaves_like 'a user required action', :get, :category, category: 'all', id: ::FactoryGirl.build(:corporate_communication)
    let(:corporate_communication) { ::FactoryGirl.create(:corporate_communication) }
    it 'sets @message to the appropriate CorporateCommunication record' do
      expect(CorporateCommunication).to receive(:find).with(corporate_communication.id.to_s).and_call_original
      get :show, category: 'all', id: corporate_communication
      expect(assigns[:message]).to eq(corporate_communication)
    end
  end

  describe '`set_standard_corp_com_instance_variables` method' do
    before do
      subject.request = ActionController::TestRequest.new(:host => 'test_domain')
    end
    let(:subject) { CorporateCommunicationsController.new}
    it 'should set @sidebar_options as an array of options with a label and a value' do
      subject.send(:set_standard_corp_com_instance_variables, 'all')
      expect(subject.instance_variable_get(:@sidebar_options)).to be_kind_of(Array)
      subject.instance_variable_get(:@sidebar_options).each do |option|
        expect(option.first).to be_kind_of(String)
        expect(option.last).to be_kind_of(String)
      end
    end
    CorporateCommunication::VALID_CATEGORIES.each do |category|
      it "should set @filter to #{category} if that is passed in as an argument" do
        subject.send(:set_standard_corp_com_instance_variables, category)
        expect(subject.instance_variable_get(:@filter)).to eq(category)
      end
    end
    it 'should set @filter to `all` if the passed argument is not valid' do
      subject.send(:set_standard_corp_com_instance_variables, 'some_invalid_param')
      expect(subject.instance_variable_get(:@filter)).to eq('all')
    end
    it 'should set @filter to `all` if nil is passed as an argument' do
      subject.send(:set_standard_corp_com_instance_variables, nil)
      expect(subject.instance_variable_get(:@filter)).to eq('all')
    end
  end

end