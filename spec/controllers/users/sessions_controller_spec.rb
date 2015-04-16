require 'rails_helper'

RSpec.describe Users::SessionsController, :type => :controller do
  describe 'layout' do
    it 'should use the `external` layout' do
      expect(subject.class._layout).to eq('external')
    end
  end
end