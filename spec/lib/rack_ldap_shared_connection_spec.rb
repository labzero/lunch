require 'rails_helper'

describe FhlbMember::Rack::LDAPSharedConnection do
  let(:application) { double('application') }
  let(:environment) { double('environment') }
  subject { described_class.new(application) }

  describe '`call` method' do
    let(:call_method) { subject.call(environment) }
    it 'calls `call` on the application, passing the supplied environment' do
      expect(application).to receive(:call).with(environment)
      call_method
    end
    it 'calls `shared_connection` on Devise::LDAP::Adapter' do
      expect(Devise::LDAP::Adapter).to receive(:shared_connection)
      call_method
    end
    it 'wraps the `call` in a `shared_connection` block' do
      allow(Devise::LDAP::Adapter).to receive(:shared_connection)
      expect(application).to_not receive(:call)
      call_method
    end
    it 'calls `shared_connection` followed by `call`' do
      expect(Devise::LDAP::Adapter).to receive(:shared_connection).ordered.and_call_original
      expect(application).to receive(:call).ordered
      call_method
    end
    it 'returns the result of calling `call` on the application' do
      result = double('Some Result')
      allow(application).to receive(:call).and_return(result)
      expect(call_method).to be(result)
    end
  end
end