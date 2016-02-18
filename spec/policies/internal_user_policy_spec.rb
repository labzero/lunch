require 'rails_helper'

describe InternalUserPolicy, type: :policy do
  let(:request) { double('A Request') }
  let(:user) { double('A User') }
  subject { described_class.new(user, request) }

  describe '`cidrs` class method' do
    let(:call_method) { described_class.cidrs }
    it 'returns the `@@cidrs` class variable' do
      old_cidrs = described_class.class_variable_get(:@@cidrs)
      begin
        cidrs = double('Some CIDR Rules')
        described_class.class_variable_set(:@@cidrs, cidrs)
        expect(call_method).to be(cidrs)
      ensure
        described_class.class_variable_set(:@@cidrs, old_cidrs)
      end
    end
    it 'returns a frozen value' do
      expect(call_method.frozen?).to be(true)
    end
    it 'is initialized at class construction' do
      expect{call_method}.to_not raise_error
    end
  end

  describe '`build_cidrs` private class method' do
    let(:call_method) { described_class.send(:build_cidrs) }
    let(:rules) { [double('A CIDR Rule'), double('A CIDR Rule')] }
    let(:converted_rules) { [] }
    before do
      stub_const("#{described_class}::INTERNAL_IPS", rules)
      rules.each do |rule|
        converted_rule = double(IPAddr)
        allow(IPAddr).to receive(:new).with(rule).and_return(converted_rule)
        converted_rules << converted_rule
      end
    end
    it 'converts the rules found in `INTERNAL_IPS` to `IPAddr`' do
      rules.each do |rule|
        expect(IPAddr).to receive(:new).with(rule)
      end
      call_method
    end
    it 'freezes the array' do
      expect(call_method.frozen?).to be(true)
    end
    it 'returns the converted rules' do
      expect(call_method).to match(converted_rules)
    end
  end

  describe '`access?` method' do
    let(:call_method) { subject.access? }
    before do
      allow(described_class).to receive(:cidrs).and_return([IPAddr.new('127.0.0.0/24')])
    end
    it 'returns true if the user is not in the `intranet` domain' do
      allow(user).to receive(:intranet_user?).and_return(false)
      expect(call_method).to be(true)
    end
    describe 'when the user is an `intranet` user' do
      let(:ip) { '127.0.1.0' }
      before do
        allow(user).to receive(:intranet_user?).and_return(true)
        allow(user).to receive(:roles).and_return([])
        allow(request).to receive(:remote_ip).and_return(ip)
      end
      it 'returns true if the request IP is found in the `cidrs`' do
        allow(request).to receive(:remote_ip).and_return('127.0.0.1')
        expect(call_method).to be(true)
      end
      it 'returns true if the user has the role `USER_WITH_EXTERNAL_ACCESS`' do
        allow(user).to receive(:roles).and_return([User::Roles::USER_WITH_EXTERNAL_ACCESS])
        expect(call_method).to be(true)
      end
      it 'returns false if the user lacks the role `USER_WITH_EXTERNAL_ACCESS` and is not in the `cidrs` list' do
        expect(call_method).to be(false)
      end
    end
  end
  
end