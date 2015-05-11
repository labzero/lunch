require 'rails_helper'

RSpec.describe User, :type => :model do
  let(:user) { create(:user) }
  it "should be able to be instantiated" do
    expect(User.new).to be_kind_of(User)
  end

  describe '`after_ldap_authentication` method' do
    let(:new_ldap_domain) { double('some domain name') }
    it 'updates its `ldap_domain` attribute with the argument provided' do
      expect(user).to receive(:update_attributes!).with({ldap_domain: new_ldap_domain})
      user.after_ldap_authentication(new_ldap_domain)
    end
    it 'does not update `ldap_domain` if it already has a value for that attribute' do
      user = create(:user, ldap_domain: 'some existing domain name')
      expect(user).to_not receive(:update_attributes!).with({ldap_domain: new_ldap_domain})
      user.after_ldap_authentication(new_ldap_domain)
    end
  end

  describe '`roles` method' do
    let(:user_service) { double('user service instance') }
    let(:ldap_role_cn) { double('the cn of the ldap role') }
    let(:ldap_role) { double('some ldap role', cn: ldap_role_cn) }
    let(:ldap_roles) { [ldap_role] }
    let(:signer_role) { double('some signer role from mapi')}
    let(:mapi_roles) { [signer_role] }
    let(:request) { double('some request object') }
    let(:session_roles) { double('roles set from the session') }
    before do
      allow(user).to receive(:ldap_groups).and_return(ldap_roles)
      allow(UsersService).to receive(:new).and_return(user_service)
      allow(user_service).to receive(:user_roles).and_return(mapi_roles)
    end
    it 'will create an instance of UsersService with a request argument if one is provided' do
      expect(UsersService).to receive(:new).with(request).and_return(user_service)
      user.roles(request)
    end
    it 'will not create an instance of UsersService if no request argument is provided' do
      expect(UsersService).to_not receive(:new)
      user.roles
    end
    it 'returns an array containing the CN of LDAP roles and roles from the MAPI endpoint' do
      expect(user.roles(request)).to include(ldap_role_cn)
      expect(user.roles(request)).to include(signer_role)
    end
    it 'returns its `roles` attribute if it exists without hitting LDAP or MAPI' do
      expect(user).to_not receive(:ldap_groups)
      expect(UsersService).to_not receive(:new)
      user.roles = session_roles
      expect(user.roles).to eq(session_roles)
    end
  end
end
