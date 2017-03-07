require 'spec_helper'

describe MAPI::ServiceApp do
  let(:subject) { described_class.new.helpers }
  let(:env) { Hash.new }
  let(:value) { double('A Value') }
  before do
    subject.env = env
  end
  describe '`request_id` method' do
    it 'returns the `mapi.request.id` value from the `env`' do
      env['mapi.request.id'] = value
      expect(subject.request_id).to be(value)
    end
  end
  describe '`request_user_id` method' do
    it 'returns the `mapi.request.user_id` value from the `env`' do
      env['mapi.request.user_id'] = value
      expect(subject.request_user_id).to be(value)
    end    
  end
end