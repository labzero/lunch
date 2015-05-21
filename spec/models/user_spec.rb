require 'rails_helper'

RSpec.describe User, :type => :model do

  it "should be able to be instantiated" do
    expect(subject).to be_kind_of(User)
  end

  describe '`after_ldap_authentication` method' do
    let(:new_ldap_domain) { double('some domain name') }
    it 'updates its `ldap_domain` attribute with the argument provided' do
      expect(subject).to receive(:update_attributes!).with({ldap_domain: new_ldap_domain})
      subject.after_ldap_authentication(new_ldap_domain)
    end
    it 'does not update `ldap_domain` if it already has a value for that attribute' do
      subject.ldap_domain = 'some existing domain name'
      expect(subject).to_not receive(:update_attributes!)
      subject.after_ldap_authentication(new_ldap_domain)
    end
  end

  describe '`roles` method' do
    let(:user_service) { double('user service instance') }
    let(:ldap_role_cn) { 'FCN-MemberSite-Users' }
    let(:ldap_role) { double('some ldap role', cn: ldap_role_cn) }
    let(:ldap_roles) { [ldap_role] }
    let(:signer_role) { 'signer-advances' }
    let(:mapi_roles) { [signer_role] }
    let(:request) { double('some request object') }
    let(:session_roles) { double('roles set from the session') }
    before do
      allow(subject).to receive(:ldap_groups).and_return(ldap_roles)
      allow(UsersService).to receive(:new).and_return(user_service)
      allow(user_service).to receive(:user_roles).and_return(mapi_roles)
    end
    it 'will create an instance of UsersService with a request argument if one is provided' do
      expect(UsersService).to receive(:new).with(request).and_return(user_service)
      subject.roles(request)
    end
    it 'will create an instance of UsersService with a test request if no request argument is provided' do
      expect(UsersService).to receive(:new).with(an_instance_of(ActionDispatch::TestRequest))
      subject.roles
    end
    it 'returns an array containing roles based on the CNs it receives from LDAP' do
      expect(subject.roles(request)).to include(User::ROLE_MAPPING[ldap_role_cn])
    end
    it 'returns an array containing roles based on the values it receives from the MAPI endpoint' do
      expect(subject.roles(request)).to include(User::ROLE_MAPPING[signer_role])
    end
    it 'ignores any roles it receives if they do not correspond to ROLE_MAPPING' do
      allow(subject).to receive(:ldap_groups).and_return([ldap_role, double('another ldap role', cn: 'some role we do not care about')])
      expect(subject.roles(request).length).to eq(2)
    end
    it 'does not hit LDAP if its `roles` attribute already exists' do
      expect(subject).to_not receive(:ldap_groups)
      subject.roles = session_roles
      subject.roles
    end
    it 'returns its `roles` attribute if it exists without hitting MAPI' do
      expect(UsersService).to_not receive(:new)
      subject.roles = session_roles
      subject.roles
    end
    it 'returns its `roles` attribute if it has already been set' do
      subject.roles = session_roles
      expect(subject.roles).to eq(session_roles)
    end
  end

  {
    display_name: :displayname,
    email: :mail,
    surname: :sn,
    given_name: :givenname
  }.each do |method, attribute|
    describe "`#{method}` method" do
      let(:attribute_value) { double('An LDAP Entry Attribute') }
      let(:ldap_entry) { double('LDAP Entry: User') }
      let(:call_method) { subject.send(method) }
      before do
        allow(subject).to receive(:ldap_entry).and_return(ldap_entry)
        allow(ldap_entry).to receive(:[]).with(attribute).and_return([attribute_value])
      end
      it 'should fetch the backing LDAP entry' do
        expect(subject).to receive(:ldap_entry).and_return(ldap_entry)
        call_method
      end
      it "should return the `#{attribute}` of the backing LDAP entry" do
        expect(call_method).to eq(attribute_value)
      end
      it 'should return nil if no entry was found' do
        allow(subject).to receive(:ldap_entry).and_return(nil)
        expect(call_method).to be_nil
      end
      it "should return nil if the entry had no value for `#{attribute}`" do
        allow(ldap_entry).to receive(:[]).with(attribute)
        expect(call_method).to be_nil
      end
    end
  end

  describe '`locked?` method' do
    let(:attribute_value) { double('An LDAP Entry Attribute', to_i: Time.now.to_i) }
    let(:ldap_entry) { double('LDAP Entry: User') }
    let(:call_method) { subject.locked? }
    before do
      allow(subject).to receive(:ldap_entry).and_return(ldap_entry)
      allow(ldap_entry).to receive(:[]).with(:lockouttime).and_return([attribute_value])
    end
    it 'should fetch the backing LDAP entry' do
      expect(subject).to receive(:ldap_entry).and_return(ldap_entry)
      call_method
    end
    it 'should return true if the backing LDAP entry has a value for `lockouttime`' do
      expect(call_method).to eq(true)
    end
    it 'should return false if no entry was found' do
      allow(subject).to receive(:ldap_entry).and_return(nil)
      expect(call_method).to eq(false)
    end
    it 'should return false if the entry had no value for `lockouttime`' do
      allow(ldap_entry).to receive(:[]).with(:lockouttime)
      expect(call_method).to eq(false)
    end
  end

  describe '`lock!` method' do
    let(:call_method) { subject.lock! }
    before do
      allow(subject).to receive(:reload_ldap_entry)
      allow(subject).to receive(:ldap_domain).and_return(double('An LDAP Domain'))
      allow_any_instance_of(Time).to receive(:to_i).and_return(rand(1..999))
      allow(Devise::LDAP::Adapter).to receive(:set_ldap_param)
    end
    it 'calls `reload_ldap_entry`' do
      expect(subject).to receive(:reload_ldap_entry)
      call_method
    end
    it 'calls `Devise::LDAP::Adapter.set_ldap_param`' do
      expect(Devise::LDAP::Adapter).to receive(:set_ldap_param).with(subject.username, :lockoutTime, Time.now.to_i.to_s, nil, subject.ldap_domain)
      call_method
    end
  end

  describe '`unlock!` method' do
    let(:call_method) { subject.unlock! }
    before do
      allow(subject).to receive(:reload_ldap_entry)
      allow(subject).to receive(:ldap_domain).and_return(double('An LDAP Domain'))
      allow(Devise::LDAP::Adapter).to receive(:set_ldap_param)
    end
    it 'calls `reload_ldap_entry`' do
      expect(subject).to receive(:reload_ldap_entry)
      call_method
    end
    it 'calls `Devise::LDAP::Adapter.set_ldap_param`' do
      expect(Devise::LDAP::Adapter).to receive(:set_ldap_param).with(subject.username, :lockoutTime, '0', nil, subject.ldap_domain)
      call_method
    end
  end

  describe '`reload` method' do
    let(:call_method) { subject.reload }
    before do
      allow_any_instance_of(described_class.superclass).to receive(:reload)
    end
    it 'calls `reload_ldap_entry`' do
      expect(subject).to receive(:reload_ldap_entry)
      call_method
    end
    it 'calls `super` and returns the result' do
      result = double('A Result')
      allow_any_instance_of(described_class.superclass).to receive(:reload).and_return(result)
      expect(call_method).to be(result)
    end
  end

  describe '`reload_ldap_entry` protected method' do
    let(:call_method) { subject.send(:reload_ldap_entry) }
    it 'should nil out the `@ldap_entry` instance variable' do
      subject.instance_variable_set(:@ldap_entry, double('LDAP Entry: User'))
      call_method
      expect(subject.instance_variable_get(:@ldap_entry)).to be_nil
    end
  end

  describe '`create` class method' do
    it 'calls `super` if not passed a Net::LDAP::Entry' do
      arguments = double('Some Arguments')
      expect(described_class.superclass).to receive(:create).with(arguments)
      described_class.create(arguments)
    end
    describe 'passing a Net::LDAP::Entry' do
      let(:samaccountname) { double('An Account Username') }
      let(:ldap_domain) { double('An LDAP Domain') }
      let(:dn) { double('A DN', end_with?: true) }
      let(:ldap_entry) { double('LDAP Entry: User', is_a?: true, dn: dn) }
      let(:call_method) { described_class.create(ldap_entry) }
      before do
        allow(ldap_entry).to receive(:[]).with(:objectclass).and_return(['user', 'foo'])
        allow(ldap_entry).to receive(:[]).with(:samaccountname).and_return([samaccountname])
        allow(Devise::LDAP::Adapter).to receive(:get_ldap_domain_from_dn).with(dn).and_return(ldap_domain)
      end
      it 'should raise an error if the Entry doesn\'t have an `objectclass` of `user`' do
        allow(ldap_entry).to receive(:[]).with(:objectclass).and_return(['foo'])
        expect{call_method}.to raise_error
      end
      it 'should call `super` with a `username` of the Entry\'s `samaccountname`' do
        expect(described_class.superclass).to receive(:create).with(hash_including(username: samaccountname))
        call_method
      end
      it 'should call `super` with an `ldap_domain` of where the Entry was found' do
        expect(described_class.superclass).to receive(:create).with(hash_including(ldap_domain: ldap_domain))
        call_method
      end
      it 'should call `Devise::LDAP::Adapter.get_ldap_domain_from_dn` to find the `ldap_domain`' do
        expect(Devise::LDAP::Adapter).to receive(:get_ldap_domain_from_dn).with(dn).and_return(ldap_domain)
        call_method
      end
      it 'should set the `@ldap_entry` on the new User instance' do
        expect(call_method.ldap_entry).to eq(ldap_entry)
      end
    end
  end

  describe '`find_or_create_by_ldap_entry` class method' do
    let(:samaccountname) { double('An Account Username') }
    let(:ldap_domain) { double('An LDAP Domain') }
    let(:dn) { double('A DN', end_with?: true) }
    let(:ldap_entry) { double('LDAP Entry: User', is_a?: true, dn: dn) }
    let(:call_method) { described_class.find_or_create_by_ldap_entry(ldap_entry) }
    before do
      allow(ldap_entry).to receive(:[]).with(:samaccountname).and_return([samaccountname])
      allow(Devise::LDAP::Adapter).to receive(:get_ldap_domain_from_dn).with(dn).and_return(ldap_domain)
    end
    it 'calls `find_or_create_by` with a `username` of the entries `samaccountname`' do
      expect(described_class).to receive(:find_or_create_by).with(hash_including(username: samaccountname))
      call_method
    end
    it 'calls `find_or_create_by` with a `ldap_domain` of where the Entry was found' do
      expect(described_class).to receive(:find_or_create_by).with(hash_including(ldap_domain: ldap_domain))
      call_method
    end
    it 'should call `Devise::LDAP::Adapter.get_ldap_domain_from_dn` to find the `ldap_domain`' do
      expect(Devise::LDAP::Adapter).to receive(:get_ldap_domain_from_dn).with(dn).and_return(ldap_domain)
      call_method
    end
  end
end
