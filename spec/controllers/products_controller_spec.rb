require 'rails_helper'

RSpec.describe ProductsController, :type => :controller do
  login_user

  describe 'GET index' do
    it_behaves_like 'a user required action', :get, :index
    it 'should render the index view' do
      get :index
      expect(response.body).to render_template('index')
    end
  end

  describe 'GET frc' do
    it_behaves_like 'a user required action', :get, :frc
    before { get :frc }
    it 'should render the frc view' do
      expect(response.body).to render_template('frc')
    end
    it 'sets the @last_modified instance variable' do
      expect(assigns[:last_modified]).to be_kind_of(Date)
    end
  end

  describe 'GET frc_embedded' do
    it_behaves_like 'a user required action', :get, :frc_embedded
    before { get :frc_embedded }
    it 'should render the frc_embedded view' do
      expect(response.body).to render_template('frc_embedded')
    end
    it 'sets the @last_modified instance variable' do
      expect(assigns[:last_modified]).to be_kind_of(Date)
    end
  end

  describe 'GET arc' do
    it_behaves_like 'a user required action', :get, :arc
    before { get :arc }
    it 'should render the view' do
      expect(response.body).to render_template('arc')
    end
    it 'sets the @last_modified instance variable' do
      expect(assigns[:last_modified]).to be_kind_of(Date)
    end
    it 'sets the @html_class instance variable' do
      expect(assigns[:html_class]).to eq('white-background')
    end
  end

end
