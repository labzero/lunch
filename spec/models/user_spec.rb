require 'rails_helper'

RSpec.describe User, :type => :model do

  before do
    allow_any_instance_of(User).to receive(:ldap_entry).and_return(nil)
    allow_any_instance_of(User).to receive(:save_ldap_attributes).and_return(true)
  end

  it { is_expected.to callback(:save_ldap_attributes).after(:save) }
  it { is_expected.to callback(:destroy_ldap_entry).after(:destroy) }
  it { is_expected.to callback(:check_password_change).before(:save) }
  it { should validate_confirmation_of(:email).on(:update) }
  it { should validate_presence_of(:email).on(:update) }
  it { subject.email = 'foo' ; should validate_presence_of(:email_confirmation).on(:update) }
  it { should validate_presence_of(:given_name).on(:update) }
  it { should validate_presence_of(:surname).on(:update) }
  ['foo', 'foo@example', 'foo@example.1'].each do |value|
    it { should_not allow_value(value).for(:email) }
  end
  ['foo@example.com', 'foo@example.co', 'bar@example.org'].each do |value|
    it { should allow_value(value).for(:email) }
  end

  describe 'password changes surpress some validations' do
    before do
      subject.password = 'Fooo123!'
      subject.password_confirmation = subject.password
    end

    [:given_name, :surname, :email].each do |attr|
      it "does not validate the presence of `#{attr}`" do
        subject.send("#{attr}=", nil)
        expect(subject.valid?).to be(true)
      end
    end
  end

  describe 'virtual validators' do
    describe 'are disabled' do
      it 'does not validate `current_password`' do
        expect(subject.valid?).to be(true)
      end
    end
    describe 'are enabled' do
      before do
        subject.enable_virtual_validators!
      end
      it 'validates presence of `current_password`' do
        subject.valid?
        expect(subject.errors[:current_password]).to include(I18n.t('activerecord.errors.models.user.attributes.current_password.blank'))
      end
    end
  end

  describe 'validating passwords' do
    it { should validate_confirmation_of(:password) }
    it { should validate_length_of(:password).is_at_least(8) }
    it 'requires at least one capital letter' do
      should_not allow_value('abcder12!').for(:password)
    end
    it 'requires at least one lowercase letter' do
      should_not allow_value('ABCDER12!').for(:password)
    end
    it 'requires at least one number' do
      should_not allow_value('Abcderrr!').for(:password)
    end
    it 'requires at least one symbol' do
      should_not allow_value('Abcder121').for(:password)
    end
    it { should allow_value('Abcder121!').for(:password) }
    it { should allow_value(nil).for(:password) }
  end

  describe '`after_ldap_authentication` method' do
    let(:new_ldap_domain) { double('some domain name') }
    it 'updates its `ldap_domain` attribute with the argument provided' do
      expect(subject).to receive(:update_attribute).with(:ldap_domain, new_ldap_domain)
      subject.after_ldap_authentication(new_ldap_domain)
    end
    it 'does not update `ldap_domain` if it already has a value for that attribute' do
      subject.ldap_domain = 'some existing domain name'
      expect(subject).to_not receive(:update_attribute)
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
    given_name: :givenname,
    deletion_reason: :deletereason
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
      it 'should return the in-memory value if there is one' do
        subject.instance_variable_set(:"@#{method}", attribute_value)
        expect(call_method).to eq(attribute_value)
      end
      it 'should return the in-memory value if there is no ldap_entry' do
        allow(subject).to receive(:ldap_entry).and_return(nil)
        subject.instance_variable_set(:"@#{method}", attribute_value)
        expect(call_method).to eq(attribute_value)
      end
      it "should return nil if the entry had no value for `#{attribute}`" do
        allow(ldap_entry).to receive(:[]).with(attribute)
        expect(call_method).to be_nil
      end
    end
  end

  describe '`locked?` method' do
    let(:attribute_value) { double('An LDAP Entry Attribute', to_i: User::LDAP_LOCK_BIT) }
    let(:ldap_entry) { double('LDAP Entry: User') }
    let(:call_method) { subject.locked? }
    before do
      allow(subject).to receive(:ldap_entry).and_return(ldap_entry)
      allow(ldap_entry).to receive(:[]).with(:userAccountControl).and_return([attribute_value])
    end
    it 'should fetch the backing LDAP entry' do
      expect(subject).to receive(:ldap_entry).and_return(ldap_entry)
      call_method
    end
    it 'should return true if the backing LDAP entry has the LDAP_LOCK_BIT set' do
      expect(call_method).to eq(true)
    end
    it 'should return false if no entry was found' do
      allow(subject).to receive(:ldap_entry).and_return(nil)
      expect(call_method).to eq(false)
    end
    it 'should return false if the LDAP_LOCK_BIT is not set' do
      allow(ldap_entry).to receive(:[]).with(:userAccountControl).and_return(512)
      expect(call_method).to eq(false)
    end
  end

  describe '`lock!` method' do
    let(:call_method) { subject.lock! }
    let(:attribute_value) { double('An LDAP Entry Attribute', to_i: 512) }
    let(:ldap_entry) { double('LDAP Entry: User') }
    before do
      allow(subject).to receive(:reload_ldap_entry)
      allow(subject).to receive(:ldap_domain).and_return(double('An LDAP Domain'))
      allow(Devise::LDAP::Adapter).to receive(:set_ldap_param).and_return(false)
      allow(subject).to receive(:ldap_entry).and_return(ldap_entry)
      allow(ldap_entry).to receive(:[]).with(:userAccountControl).and_return([attribute_value])
    end
    it 'calls `reload_ldap_entry` before it reads the entry and after' do
      expect(subject).to receive(:reload_ldap_entry).ordered
      expect(subject).to receive(:ldap_entry).ordered
      expect(subject).to receive(:reload_ldap_entry).ordered
      call_method
    end
    it 'returns false if the LDAP entry could not be found' do
      allow(subject).to receive(:ldap_entry).and_return(nil)
      expect(call_method).to eq(false)
    end
    it 'calls `Devise::LDAP::Adapter.set_ldap_param` with the User::LDAP_LOCK_BIT set' do
      expect(Devise::LDAP::Adapter).to receive(:set_ldap_param).with(subject.username, :userAccountControl, (attribute_value.to_i | User::LDAP_LOCK_BIT).to_s, nil, subject.ldap_domain)
      call_method
    end
    it 'returns false on failure' do
      expect(call_method).to eq(false)
    end
    it 'returns true on success' do
      allow(Devise::LDAP::Adapter).to receive(:set_ldap_param).and_return(true)
      expect(call_method).to eq(true)
    end
  end

  describe '`unlock!` method' do
    let(:call_method) { subject.unlock! }
    let(:attribute_value) { double('An LDAP Entry Attribute', to_i: 514) }
    let(:ldap_entry) { double('LDAP Entry: User') }
    before do
      allow(subject).to receive(:reload_ldap_entry)
      allow(subject).to receive(:ldap_domain).and_return(double('An LDAP Domain'))
      allow(Devise::LDAP::Adapter).to receive(:set_ldap_param).and_return(false)
      allow(subject).to receive(:ldap_entry).and_return(ldap_entry)
      allow(ldap_entry).to receive(:[]).with(:userAccountControl).and_return([attribute_value])
    end
    it 'calls `reload_ldap_entry` before it reads the entry and after' do
      expect(subject).to receive(:reload_ldap_entry).ordered
      expect(subject).to receive(:ldap_entry).ordered
      expect(subject).to receive(:reload_ldap_entry).ordered
      call_method
    end
    it 'returns false if the LDAP entry could not be found' do
      allow(subject).to receive(:ldap_entry).and_return(nil)
      expect(call_method).to eq(false)
    end
    it 'calls `Devise::LDAP::Adapter.set_ldap_param` with the User::LDAP_LOCK_BIT cleared' do
      expect(Devise::LDAP::Adapter).to receive(:set_ldap_param).with(subject.username, :userAccountControl, (attribute_value.to_i & (~User::LDAP_LOCK_BIT)).to_s, nil, subject.ldap_domain)
      call_method
    end
    it 'returns false on failure' do
      expect(call_method).to eq(false)
    end
    it 'returns true on success' do
      allow(Devise::LDAP::Adapter).to receive(:set_ldap_param).and_return(true)
      expect(call_method).to eq(true)
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
    it 'calls `reload_ldap_attributes`' do
      expect(subject).to receive(:reload_ldap_attributes)
      call_method
    end
    it 'calls `super` and returns the result' do
      result = double('A Result')
      allow_any_instance_of(described_class.superclass).to receive(:reload).and_return(result)
      expect(call_method).to be(result)
    end
  end

  describe '`email=` method' do
    let(:value) { 'foo@example.com' }
    let(:call_method) { subject.email = value }
    it 'should change the email attribute on the model' do
      call_method
      expect(subject.email).to eq(value)
    end
    it 'should mark the email attribute as dirty if the value changed' do
      expect(subject).to receive(:attribute_will_change!).with('email')
      call_method
    end
    it 'should not mark the email attribute as dirty if the value was the same' do
      allow(subject).to receive(:email).and_return(value)
      expect(subject).to_not receive(:attribute_will_change!).with('email')
      call_method
    end
  end

  describe '`surname=` method' do
    let(:value) { 'Foo' }
    let(:call_method) { subject.surname = value }
    before do
      allow(subject).to receive(:attribute_will_change!)
    end
    it 'should change the surname attribute on the model' do
      call_method
      expect(subject.surname).to eq(value)
    end
    it 'should mark the surname attribute as dirty if the value changed' do
      expect(subject).to receive(:attribute_will_change!).with('surname')
      call_method
    end
    it 'should not mark the surname attribute as dirty if the value was the same' do
      allow(subject).to receive(:surname).and_return(value)
      expect(subject).to_not receive(:attribute_will_change!).with('surname')
      call_method
    end
    it 'calls `rebuild_display_name`' do
      expect(subject).to receive(:rebuild_display_name)
      call_method
    end
  end

  describe '`given_name=` method' do
    let(:value) { 'Foo' }
    let(:call_method) { subject.given_name = value }
    before do
      allow(subject).to receive(:attribute_will_change!)
    end
    it 'should change the given_name attribute on the model' do
      call_method
      expect(subject.given_name).to eq(value)
    end
    it 'should mark the given_name attribute as dirty if the value changed' do
      expect(subject).to receive(:attribute_will_change!).with('given_name')
      call_method
    end
    it 'should not mark the given_name attribute as dirty if the value was the same' do
      allow(subject).to receive(:given_name).and_return(value)
      expect(subject).to_not receive(:attribute_will_change!).with('given_name')
      call_method
    end
    it 'calls `rebuild_display_name`' do
      expect(subject).to receive(:rebuild_display_name)
      call_method
    end
  end

  describe '`deletion_reason=` method' do
    let(:value) { 'stole my stapler' }
    let(:call_method) { subject.deletion_reason = value }
    it 'should change the deletion_reason attribute on the model' do
      call_method
      expect(subject.deletion_reason).to eq(value)
    end
    it 'should mark the deletion_reason attribute as dirty if the value changed' do
      expect(subject).to receive(:attribute_will_change!).with('deletion_reason')
      call_method
    end
    it 'should not mark the deletion_reason attribute as dirty if the value was the same' do
      allow(subject).to receive(:deletion_reason).and_return(value)
      expect(subject).to_not receive(:attribute_will_change!).with('deletion_reason')
      call_method
    end
  end

  describe '`email_changed?` method' do
    let(:call_method) { subject.email_changed? }
    it 'returns true if a new email value has been set' do
      subject.email = 'foo@example.com'
      expect(call_method).to be(true)
    end
    it 'returns false if there are no email changes' do
      expect(call_method).to be(false)
    end
    it 'ignores setting the email to the same value' do
      subject.email = subject.email
      expect(call_method).to be(false)
    end
  end

  describe '`surname_changed?` method' do
    let(:call_method) { subject.surname_changed? }
    it 'returns true if a new surname value has been set' do
      subject.surname = 'foo'
      expect(call_method).to be(true)
    end
    it 'returns false if there are no surname changes' do
      expect(call_method).to be(false)
    end
    it 'ignores setting the surname to the same value' do
      subject.surname = subject.surname
      expect(call_method).to be(false)
    end
  end

  describe '`given_name_changed?` method' do
    let(:call_method) { subject.given_name_changed? }
    it 'returns true if a new given_name value has been set' do
      subject.given_name = 'foo'
      expect(call_method).to be(true)
    end
    it 'returns false if there are no given_name changes' do
      expect(call_method).to be(false)
    end
    it 'ignores setting the given_name to the same value' do
      subject.given_name = subject.given_name
      expect(call_method).to be(false)
    end
  end

  describe '`display_name_changed?` method' do
    let(:call_method) { subject.display_name_changed? }
    it 'returns true if a new surname value has been set' do
      subject.surname = 'foo'
      expect(call_method).to be(true)
    end
    it 'returns true if a new given_name value has been set' do
      subject.given_name = 'foo'
      expect(call_method).to be(true)
    end
    it 'returns false if there are no changes' do
      expect(call_method).to be(false)
    end
    it 'ignores setting the surname to the same value' do
      subject.surname = subject.surname
      expect(call_method).to be(false)
    end
    it 'ignores setting the given_name to the same value' do
      subject.given_name = subject.given_name
      expect(call_method).to be(false)
    end
  end

  describe '`deletion_reason_changed?` method' do
    let(:call_method) { subject.deletion_reason_changed? }
    it 'returns true if a new reason value has been set' do
      subject.deletion_reason = 'they ate my lunch'
      expect(call_method).to be(true)
    end
    it 'returns false if there are no reason changes' do
      expect(call_method).to be(false)
    end
    it 'ignores setting the reason to the same value' do
      subject.deletion_reason = subject.deletion_reason
      expect(call_method).to be(false)
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

  describe '`save_ldap_attributes` protected method' do
    let(:call_method) { subject.send(:save_ldap_attributes) }
    before do
      allow_any_instance_of(User).to receive(:save_ldap_attributes).and_call_original
    end
    it 'should not save if there are no changes' do
      expect(Devise::LDAP::Adapter).to_not receive(:set_ldap_params)
      call_method
    end
    describe 'with LDAP attribute changes' do
      let(:email) { 'foo@example.com' }
      let(:username) { double('Username') }
      let(:ldap_domain) { double('LDAP Domain') }
      before do
        subject.email = email
        allow(subject).to receive(:username).and_return(username)
        allow(subject).to receive(:ldap_domain).and_return(ldap_domain)
        allow(Devise::LDAP::Adapter).to receive(:set_ldap_params).and_return(true)
      end
      it 'should save the changes' do
        expect(Devise::LDAP::Adapter).to receive(:set_ldap_params).with(username, {mail: email}, nil, ldap_domain)
        call_method
      end
      it 'should call `reload_ldap_entry`' do
        expect(subject).to receive(:reload_ldap_entry)
        call_method
      end
      it 'should rollback if save fails' do
        allow(Devise::LDAP::Adapter).to receive(:set_ldap_params).and_return(false)
        expect{call_method}.to raise_error(ActiveRecord::Rollback)
      end
      it 'should call `reload_ldap_attributes` if the save succeeds' do
        allow(Devise::LDAP::Adapter).to receive(:set_ldap_params).and_return(true)
        expect(subject).to receive(:reload_ldap_attributes)
        call_method
      end
    end
  end

  describe '`rebuild_display_name` protected method' do
    let(:call_method) { subject.send(:rebuild_display_name) }
    let(:given_name) { SecureRandom.hex }
    let(:surname) { SecureRandom.hex }
    before do
      allow(subject).to receive(:given_name).and_return(given_name)
      allow(subject).to receive(:surname).and_return(surname)
    end
    it 'should rebuild the display_name' do
      call_method
      expect(subject.display_name).to eq("#{given_name} #{surname}")
    end
    it 'should mark the display_name as changed if it changed' do
      expect(subject).to receive(:attribute_will_change!).with('display_name')
      call_method
    end
    it 'should not mark the display_name as changed if it matches the current display_name' do
      allow(subject).to receive(:display_name).and_return("#{given_name} #{surname}")
      expect(subject).to_not receive(:attribute_will_change!).with('display_name')
      call_method
    end
  end

  describe '`reload_ldap_attributes` protected method' do
    let(:call_method) { subject.send(:reload_ldap_attributes) }
    it 'should nil out `@email`' do
      subject.instance_variable_set(:@email, 'foo')
      call_method
      expect(subject.instance_variable_get(:@email)).to be_nil
    end
    it 'should nil out `@given_name`' do
      subject.instance_variable_set(:@given_name, 'foo')
      call_method
      expect(subject.instance_variable_get(:@given_name)).to be_nil
    end
    it 'should nil out `@surname`' do
      subject.instance_variable_set(:@surname, 'foo')
      call_method
      expect(subject.instance_variable_get(:@surname)).to be_nil
    end
    it 'should nil out `@display_name`' do
      subject.instance_variable_set(:@display_name, 'foo')
      call_method
      expect(subject.instance_variable_get(:@display_name)).to be_nil
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
        expect(call_method.instance_variable_get(:@ldap_entry)).to be(ldap_entry)
      end
    end
  end

  describe '`find_or_create_by_ldap_entry` class method' do
    let(:samaccountname) { double('An Account Username') }
    let(:ldap_domain) { double('An LDAP Domain') }
    let(:dn) { double('A DN', end_with?: true) }
    let(:ldap_entry) { double('LDAP Entry: User', is_a?: true, dn: dn) }
    let(:call_method) { described_class.find_or_create_by_ldap_entry(ldap_entry) }
    let(:user) { double(described_class) }
    before do
      allow(ldap_entry).to receive(:[]).with(:samaccountname).and_return([samaccountname])
      allow(Devise::LDAP::Adapter).to receive(:get_ldap_domain_from_dn).with(dn).and_return(ldap_domain)
      allow(described_class).to receive(:find_or_create_by).and_return(user)
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

  describe '`find_or_create_if_valid_login` class method' do
    let(:attributes) { double('Some Attributes', :[] => nil) }
    let(:call_method) { described_class.find_or_create_if_valid_login(attributes) }
    let(:user) { double(described_class) }
    let(:username)  { double('A Username') }
    let(:ldap_domain) { double('An LDAP Domain') }

    before do
      allow(Devise::LDAP::Adapter).to receive(:get_ldap_domain)
      allow(described_class).to receive(:find_or_create_by).and_return(user)
    end

    it 'should call `find_by` passing in the supplied attributes' do
      expect(described_class).to receive(:find_by).with(attributes)
      call_method
    end
    describe 'if a User is found' do
      before do
        allow(described_class).to receive(:find_by).and_return(user)
      end
      it 'returns the found user' do
        expect(call_method).to be(user)
      end
    end
    describe 'if a User is not found' do
      before do
        allow(described_class).to receive(:find_by).and_return(nil)
        allow(attributes).to receive(:[]).with(:username).and_return(username)
        allow(Devise::LDAP::Adapter).to receive(:get_ldap_domain).and_return(ldap_domain)
      end
      it 'looks up the LDAP domain of the username' do
        expect(Devise::LDAP::Adapter).to receive(:get_ldap_domain).with(username)
        call_method
      end
      it 'returns nil if no LDAP domain was found for the username' do
        allow(Devise::LDAP::Adapter).to receive(:get_ldap_domain).and_return(nil)
        expect(call_method).to be_nil
      end
      describe 'if an LDAP domain is found fpr the username' do
        it 'calls `find_or_create_by` with the username and LDAP domain' do
          expect(described_class).to receive(:find_or_create_by).with({username: username, ldap_domain: ldap_domain})
          call_method
        end
        it 'returns the result of the `find_or_create_by` call' do
          allow(described_class).to receive(:find_or_create_by).and_return(user)
          expect(call_method).to be(user)
        end
      end
    end
  end

  describe '`member_id` method' do
    let(:call_method) { subject.member_id }
    let(:member_id_instance_variable) { double('@member_id') }
    let(:bank_id) { rand(9999).to_s }
    let(:ldap_bank) { double('LDAP entry for bank', cn: ["FHLB#{bank_id}"], objectClass: ['group'])}
    let(:ldap_group_object) { double('Some LDAP entry for a non-bank group', cn: ["FOO#{bank_id}"], objectClass: ['group'])}
    let(:ldap_other_object) { double('LDAP entry for a non-group object with a valid bank CN', cn: ["FHLB#{bank_id}"], objectClass: ['top'])}
    let(:ldap_groups_array) { [ldap_group_object, ldap_other_object, ldap_bank] }
    before do
      allow(subject).to receive(:ldap_groups).and_return(ldap_groups_array)
    end
    it 'returns the @member_id attribute if it exists' do
      subject.instance_variable_set(:@member_id, member_id_instance_variable)
      expect(call_method).to eq(member_id_instance_variable)
    end
    it 'ignores groups that do not have an object class of `group`' do
      expect(ldap_other_object).to_not receive(:remove)
      call_method
    end
    it 'ignores groups that do not a CN that begins with `FHLB` and is followed by any number of digits' do
      expect(ldap_other_object.cn.first).to_not receive(:remove)
      call_method
    end
    it 'returns the formatted member_id of a group with an objectClass that includes `group` and a CN that begins with `FHLB` followed by any number of digits' do
      expect(ldap_bank.cn.first).to receive(:remove).and_call_original
      expect(call_method).to eq(bank_id)
    end
    it 'sets the @member_id attribute to the returned bank id' do
      call_method
      expect(subject.instance_variable_get(:@member_id)).to eq(bank_id)
    end
  end

  describe '`ldap_groups` method' do
    let(:ldap_groups_result){ double('ldap groups result') }
    it 'should call `Devise::LDAP::Adapter.get_groups`' do
      allow(Devise::LDAP::Adapter).to receive(:get_groups).and_return(ldap_groups_result)
      expect(subject.ldap_groups).to eq(ldap_groups_result)
    end
  end

  describe '`destroy_ldap_entry` method' do
    let(:call_method) {subject.send(:destroy_ldap_entry)}
    let(:username) { double('username') }
    let(:ldap_domain) { double('ldap_domain') }
    before do
      allow(subject).to receive(:username).and_return(username)
      allow(subject).to receive(:ldap_domain).and_return(ldap_domain)
    end
    it 'should call `Devise::LDAP::Adapter.delete_ldap_entry`' do
      expect(Devise::LDAP::Adapter).to receive(:delete_ldap_entry).with(username, nil, ldap_domain).and_return(true)
      call_method
    end
    it 'should raise an `ActiveRecord::Rollback` if the delete fails' do
      allow(Devise::LDAP::Adapter).to receive(:delete_ldap_entry).and_return(false)
      expect{call_method}.to raise_error(ActiveRecord::Rollback)
    end
  end

  describe '`accepted_terms?` method' do
    let(:stored_value) { double('a stored value') }
    let(:date_time) { DateTime.new(2015,1,1) }
    it 'returns true if there is a value for the `terms_accepted_at` attr' do
      allow(subject).to receive(:terms_accepted_at).and_return(date_time)
      expect(subject.accepted_terms?).to eq(true)
    end
    it 'returns false if there is a value for the `terms_accepted_at` attr' do
      expect(subject.accepted_terms?).to eq(false)
    end
  end

  describe '`virtual_validators?` method' do
    let(:call_method) { subject.virtual_validators? }
    it 'returns false by default' do
      expect(call_method).to be(false)
    end
    it 'returns true after `enable_virtual_validators!` is called' do
      subject.enable_virtual_validators!
      expect(call_method).to be(true)
    end
  end

  describe '`check_password_change` protected method' do
    let(:call_method) { subject.send(:check_password_change) }
    it 'checks if the password has changed' do
      expect(subject).to receive(:password_changed?)
      call_method
    end
    it 'checks if any LDAP backed attributes have changed' do
      attribute = SecureRandom.hex
      ldap_attributes = double('Some LDAP Attributes')
      stub_const("#{described_class.name}::LDAP_ATTRIBUTES_MAPPING", ldap_attributes)
      allow(subject).to receive(:password_changed?).and_return(true)
      allow(subject).to receive(:changed).and_return([attribute])
      expect(ldap_attributes).to receive(:include?).with(attribute)
      call_method
    end
    describe 'if both a password and an LDAP attribute have changed' do
      before do
        allow(subject).to receive(:password_changed?).and_return(true)
        allow(subject).to receive(:changed).and_return([described_class::LDAP_ATTRIBUTES_MAPPING.keys.sample])
      end

      it 'raises an ActiveRecord::Rollback' do
        expect{call_method}.to raise_error(ActiveRecord::Rollback)
      end
      it 'adds an error to the password field if a rollback is raised' do
        expect(subject.errors).to receive(:add).with(:password, :non_atomic)
        call_method rescue ActiveRecord::Rollback
      end
    end
  end

  describe '`clear_password_expiration` protected method' do
    let(:call_method) { subject.send(:clear_password_expiration) }
    it 'calls `Devise::LDAP::Adapter.set_ldap_param` with the `LDAP_PASSWORD_EXPIRATION_ATTRIBUTE` set to `false`' do
      expect(Devise::LDAP::Adapter).to receive(:set_ldap_params).with(subject.username, {described_class::LDAP_PASSWORD_EXPIRATION_ATTRIBUTE => 'false'}, nil, subject.ldap_domain).and_return(true)
      call_method
    end
    it 'calls `reload_ldap_entry` if the update succeeds' do
      allow(Devise::LDAP::Adapter).to receive(:set_ldap_params).and_return(true)
      expect(subject).to receive(:reload_ldap_entry)
      call_method
    end
    it 'raises `ActiveRecord::rollback` if the LDAP update fails' do
      allow(Devise::LDAP::Adapter).to receive(:set_ldap_params).and_return(false)
      expect{call_method}.to raise_error(ActiveRecord::Rollback)
    end
    it 'is called after `ldap_password_save`' do
      callbacks = described_class.send(:get_callbacks, :ldap_password_save).select do |callback|
        callback.kind == :after && callback.filter == :clear_password_expiration
      end
      expect(callbacks.length).to eq(1)
    end
  end

end
