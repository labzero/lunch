require 'rails_helper'

RSpec.describe UsersService, :type => :service do
  subject { UsersService.new(double('request', uuid: '12345')) }

  describe '`user_roles` method', :vcr  do
    let(:user_roles) {subject.user_roles('local')}
    context 'API errors' do
      before { allow_any_instance_of(RestClient::Resource).to receive(:get).and_raise(RestClient::InternalServerError) }
      it 'should return nil if there was an API error' do
        expect(user_roles).to eq(nil)
      end
      it 'should log an error if there was an API error' do
        expect(Rails.logger).to receive(:warn)
        user_roles
      end
    end
    it 'should not log an error if an API error was caused by a user not being found' do
      expect(Rails.logger).to_not receive(:warn)
      subject.user_roles('foo')
    end
    context 'connection errors' do
      before { allow_any_instance_of(RestClient::Resource).to receive(:get).and_raise(Errno::ECONNREFUSED) }
      it 'should return nil if there was a connection error' do
        expect(user_roles).to eq(nil)
      end
      it 'should log an error if there was a connection error' do
        expect(Rails.logger).to receive(:warn)
        user_roles
      end
    end
    it 'should return an array of user roles from the MAPI endpoint' do
      expect(user_roles).to be_kind_of(Array)
    end
  end

  describe '`user_details` method'  do
    let(:email) { SecureRandom.hex }
    let(:call_method) {subject.user_details(email)}
    let(:response) { double(Hash) }
    it_should_behave_like 'a MAPI backed service object method', :user_details, :user_email

    describe 'end point access' do
      before do
        allow(subject).to receive(:get_hash).with(:user_details, anything).and_return(response)
      end

      it 'calls the `get_hash` method with the proper method name' do
        expect(subject).to receive(:get_hash).with(:user_details, "customers/#{email}/")
        call_method
      end
      it 'returns the results of `get_hash`' do
        expect(call_method).to be(response)
      end
    end
  end
end