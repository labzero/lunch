require 'rails_helper'

RSpec.describe CorporateCommunicationsController, :type => :controller do
  login_user

  describe 'before_filter methods' do
    let(:current_user) { FactoryGirl.build(User) }
    let(:message_service_instance) { double('MessageServiceInstance') }
    let(:corporate_communications_zero) { double('Array of Messages', count: 0) }
    let(:corporate_communications_non_zero) { double('Array of Messages', count: 7) }
    before do
      allow(controller).to receive(:reset_new_announcements_count)
      allow(controller).to receive(:current_user).and_return(current_user)
      allow(current_user).to receive(:announcements_viewed!)
    end
    it 'should set @sidebar_options as an array of options with a label and a value' do
      get :category, category: 'all'
      expect(assigns(:sidebar_options)).to be_kind_of(Array)
      assigns(:sidebar_options).each do |option|
        expect(option[0]).to be_kind_of(String)
        expect(option[1]).to be_kind_of(String)
        expect(option[2]).to be_kind_of(TrueClass).or be_kind_of(FalseClass)
      end
    end
    CorporateCommunication::VALID_CATEGORIES.each do |category|
      it "should set @filter to #{category} if that is passed in as an argument" do
        get :category, category: category
        expect(assigns(:filter)).to eq(category)
      end
    end
    it 'should raise an error if the passed category argument is not valid' do
      expect{get :category, category: 'asdffsd'}.to raise_error
    end
    it 'should raise an error if nothing is passed as a category argument' do
      expect{get :category}.to raise_error
    end
    it 'should return true if the number of messages is zero' do
      allow(MessageService).to receive(:new).and_return(message_service_instance)
      allow(message_service_instance).to receive(:corporate_communications).and_return(corporate_communications_zero)
      get :category, category: 'all'
      assigns(:sidebar_options).each do |option|
        expect(option[2]).to be_kind_of(TrueClass)
      end
    end
    it 'should return false if the number of messages is not zero' do
      allow(MessageService).to receive(:new).and_return(message_service_instance)
      allow(message_service_instance).to receive(:corporate_communications).and_return(corporate_communications_non_zero)
      get :category, category: 'all'
      assigns(:sidebar_options).each do |option|
        expect(option[2]).to be_kind_of(FalseClass)
      end
    end
  end

  describe 'GET category' do
    it_behaves_like 'a user required action', :get, :category, category: 'all'
    let(:current_user) { FactoryGirl.build(User) }
    let(:perform_action) { get :category, category: 'all' }
    let(:message_service_instance) { double('MessageServiceInstance') }
    let(:corporate_communications) { double('Array of Messages', count: 7 ) }
    before do
      allow(controller).to receive(:reset_new_announcements_count)
      allow(controller).to receive(:current_user).and_return(current_user)
      allow(current_user).to receive(:announcements_viewed!)
    end
    it 'should render the category view' do
      perform_action
      expect(response.body).to render_template('category')
    end
    it 'should call `announcements_viewed!` on the current user' do
      expect(current_user).to receive(:announcements_viewed!)
      perform_action
    end
    it 'should call `reset_new_announcements_count`' do
      expect(controller).to receive(:reset_new_announcements_count)
      perform_action
    end
    it 'should pass @filter to MessageService#corporate_communications as an argument' do
      allow(message_service_instance).to receive(:corporate_communications).with(kind_of(String)).and_return(corporate_communications)
      allow(MessageService).to receive(:new).and_return(message_service_instance)
      expect(message_service_instance).to receive(:corporate_communications).with('all').at_least(2).and_return(corporate_communications)
      perform_action
    end
    it 'should set @messages to the value returned by MessageService#corporate_communications' do
      allow(MessageService).to receive(:new).and_return(message_service_instance)
      allow(message_service_instance).to receive(:corporate_communications).and_return(corporate_communications)
      perform_action
      expect(assigns[:messages]).to eq(corporate_communications)
    end
  end

  describe 'GET show' do
    let(:make_request) { get :show, category: 'all', id: corporate_communication }
    it_behaves_like 'a user required action', :get, :category, category: 'all', id: ::FactoryGirl.build(:corporate_communication)
    let(:corporate_communication) { ::FactoryGirl.create(:corporate_communication, category: 'accounting', body: "<img src=\"cid:#{image_fingerprint}\">Foo") }
    let(:image_url) { SecureRandom.hex }
    let(:image_fingerprint) { SecureRandom.hex }
    before do
      allow(controller).to receive(:attachment_download_path).and_return(image_url)
    end
    it 'sets @message to the appropriate CorporateCommunication record if `all` is given as the category argument' do
      expect(CorporateCommunication).to receive(:find).with(corporate_communication.id.to_s).and_call_original
      make_request
      expect(assigns[:message]).to eq(corporate_communication)
    end
    it 'sets @message to the appropriate CorporateCommunication record given the proper category' do
      expect(CorporateCommunication).to receive(:find_by!).with({:id => corporate_communication.id.to_s, :category => 'accounting'}).and_call_original
      get :show, category: 'accounting', id: corporate_communication
      expect(assigns[:message]).to eq(corporate_communication)
    end
    it 'sets the @message_body' do
      allow(CorporateCommunication).to receive(:find).and_return(corporate_communication)
      allow(corporate_communication).to receive(:body).and_return(SecureRandom.hex)
      make_request
      expect(assigns[:message_body]).to eq(corporate_communication.body)
    end
    it 'substitutes CID references in the @message_body' do
      allow(CorporateCommunication).to receive(:find).and_return(corporate_communication)
      allow(corporate_communication).to receive(:images).and_return([double(Attachment, fingerprint: image_fingerprint, data: double(Paperclip::Attachment, original_filename: nil))])
      make_request
      expect(assigns[:message_body]).to_not match('cid:')
      expect(assigns[:message_body]).to match(image_url)
    end
    describe 'setting the @prior_message and @next_message instance variables' do
      before do
        @message_1 = ::FactoryGirl.create(:corporate_communication)
        @message_2 = ::FactoryGirl.create(:corporate_communication)
        @message_3 = ::FactoryGirl.create(:corporate_communication)
      end
      it 'sets @prior_message to the message just before the currently selected message in a given category' do
        get :show, category: 'all', id: @message_2.id
        expect(assigns[:prior_message]).to eq(@message_1)
      end
      it 'does not set @prior_message if the currently selected message is the first in a given category' do
        get :show, category: 'all', id: @message_1.id
        expect(assigns[:prior_message]).to be_nil
      end
      it 'sets @next_message to the message just after the currently selected message in a given category' do
        get :show, category: 'all', id: @message_2.id
        expect(assigns[:next_message]).to eq(@message_3)
      end
      it 'does not set @next_message if the currently selected message is the last in a given category' do
        get :show, category: 'all', id: @message_3.id
        expect(assigns[:next_message]).to be_nil
      end
    end
  end

end