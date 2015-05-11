require 'spec_helper'

RSpec.describe UsersService do
  let(:user) { create(:user) }
  subject { UsersService.new(double('request', uuid: '12345')) }

  describe '`user_roles` method', :vcr  do
    let(:user_roles) {subject.user_roles(user.username)}
    it 'should return nil if there was an API error' do
      expect_any_instance_of(RestClient::Resource).to receive(:get).and_raise(RestClient::InternalServerError)
      expect(user_roles).to eq(nil)
    end
    it 'should return nil if there was a connection error' do
      expect_any_instance_of(RestClient::Resource).to receive(:get).and_raise(Errno::ECONNREFUSED)
      expect(user_roles).to eq(nil)
    end
    it 'should return an array of user roles from the MAPI endpoint' do
      expect(user_roles).to be_kind_of(Array)
    end
  end
end