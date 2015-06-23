require 'rails_helper'

RSpec.describe ResourcesController, type: :controller do
  login_user

  describe 'GET guides' do
    it_behaves_like 'a user required action', :get, :guides
    it "should render the guides view" do
      get :guides
      expect(response.body).to render_template('guides')
    end
  end

  describe 'GET download' do
    it_behaves_like 'a user required action', :get, :download, file: 'foo'
    it 'should raise `ActiveRecord::RecordNotFound` if an unknown file is requested' do
      expect { get :download, file: 'foo' }.to raise_error(ActiveRecord::RecordNotFound)
    end
    {
      'creditguide' => 'creditguide.pdf',
      'collateralguide' => 'collateralguide.pdf',
      'collateralreviewguide' => 'collateralreviewguide.pdf'
    }.each do |name, file|
      it "should send the file `#{file}` when `#{name}` is requested" do
        expect(subject).to receive(:send_file).with(Rails.root.join('private', file), filename: file).and_call_original
        get :download, file: name
      end
    end
  end
end
