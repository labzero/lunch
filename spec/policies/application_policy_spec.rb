require 'rails_helper'

RSpec.describe ApplicationPolicy, :type => :policy do

  describe 'initialize method' do
    let(:user) { double('user') }
    let(:record) { double('some record') }
    let (:request) { ApplicationPolicy.new(user, record) }

    it 'sets a @user instance variable' do
      expect(request.instance_variable_get(:@user)).to eq(user)
    end
    it 'sets a @record instance variable' do
      expect(request.instance_variable_get(:@record )).to eq(record)
    end

  end
end