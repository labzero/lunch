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
end
