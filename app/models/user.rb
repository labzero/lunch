class User < ActiveRecord::Base

  validates :given_name, presence: {on: :update, unless: :password_changed?}
  validates :surname, presence: {on: :update, unless: :password_changed?}
  validates :email, presence: {on: :update, unless: :password_changed?}, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i, allow_blank: true }, confirmation: {if: :email_changed?, on: :update}
  validates :email_confirmation, presence: {if: :email_changed?, on: :update}
  validates :current_password, {presence: true, if: :virtual_validators?}
  validates :password, confirmation: true, length: {minimum: 8, allow_nil: true}
  validates :username, presence: {on: :update, unless: :password_changed?}, length: {on: :update, minimum: 4, maximum: 20, unless: :password_changed? }, format: {on: :update, with: /\A(?!fhlbsf)[a-zA-Z]\w+\Z/i, unless: :password_change_or_update? }

  UPPER = '(?=.*[A-Z])'.freeze
  LOWER = '(?=.*[a-z])'.freeze
  NUMBER = '(?=.*\d)'.freeze
  SYMBOL = '(?=.*[!@#$%*])'.freeze

  SUN = SYMBOL + UPPER + NUMBER + '.*'.freeze
  NUL = NUMBER + UPPER + LOWER + '.*'.freeze
  SUL = SYMBOL + UPPER + LOWER + '.*'.freeze
  LNS = LOWER + NUMBER + SYMBOL + '.*'.freeze

  CRITERIA_REGEX = Regexp.new('\A' + [SUN, NUL, SUL, LNS].join('|') + '\z').freeze

  validates :password, format: { with: CRITERIA_REGEX, message: :criteria_not_met, allow_nil: true }

  def self.policy_class
    AccessManagerPolicy
  end

  LDAP_EXTRANET_DOMAIN = 'extranet'.freeze

  LDAP_INTERNAL_DOMAIN = 'intranet'.freeze

  LDAP_EXTRANET_EBIZ_USERS_DN ='CN=Users,OU=eBiz,DC=extranet,DC=fhlbsf,DC=com'

  AD_GROUP_NAME_PREFIX = "FHLB"

  LDAP_ATTRIBUTES_MAPPING = {
    email: :mail,
    surname: :sn,
    given_name: :givenname,
    display_name: :displayname,
    deletion_reason: :deletereason
  }.with_indifferent_access.freeze

  LDAP_LOCK_BIT = 0x2
  LDAP_PASSWORD_EXPIRATION_ATTRIBUTE = :passwordExpired

  module Roles
    MEMBER_USER = 'member_user'
    ADVANCE_SIGNER = 'advance_signer'
    USER_WITH_EXTERNAL_ACCESS = 'user_with_external_access'
    ACCESS_MANAGER_READ_ONLY = 'access_manager_read_only'
    ACCESS_MANAGER = 'access_manager'
    USER_WITH_EXTENDED_INFO_ACCESS = 'user_with_extended_info_access'
    ADMIN = 'admin'
    AUTHORIZED_SIGNER = 'authorized_signer'
    SIGNER_MANAGER = 'signer_manager'
    SIGNER_ENTIRE_AUTHORITY = 'signer_entire_authority'
    AFFORDABILITY_SIGNER = 'affordability_signer'
    COLLATERAL_SIGNER = 'collateral_signer'
    MONEYMARKET_SIGNER = 'moneymarket_signer'
    DERIVATIVES_SIGNER = 'derivatives_signer'
    SECURITIES_SIGNER = 'securities_signer'
    WIRE_SIGNER = 'wire_signer'
    ETRANSACT_SIGNER = 'etransact_signer'
  end

  LDAP_GROUPS_TO_ROLES = {
    'FCN-MemberSite-Users' => Roles::MEMBER_USER,
    'FCN-MemberSite-ExternalAccess' => Roles::USER_WITH_EXTERNAL_ACCESS,
    'FCN-MemberSite-AccessManagers-R' => Roles::ACCESS_MANAGER_READ_ONLY,
    'FCN-MemberSite-AccessManagers' => Roles::ACCESS_MANAGER,
    'FCN-MemberSite-Admins' => Roles::ADMIN,
    'FCN-MemberSite-ExtendedInfo-User' => Roles::USER_WITH_EXTENDED_INFO_ACCESS,
    'signer' => Roles::AUTHORIZED_SIGNER,
    'signer-manager' => Roles::SIGNER_MANAGER,
    'signer-entire-authority' => Roles::SIGNER_ENTIRE_AUTHORITY,
    'signer-advances' => Roles::ADVANCE_SIGNER,
    'signer-affordability' => Roles::AFFORDABILITY_SIGNER,
    'signer-collateral' => Roles::COLLATERAL_SIGNER,
    'signer-moneymarket' => Roles::MONEYMARKET_SIGNER,
    'signer-creditswap' => Roles::DERIVATIVES_SIGNER,
    'signer-securities' => Roles::SECURITIES_SIGNER,
    'signer-wiretransfers' => Roles::WIRE_SIGNER,
    'signer-etransact' => Roles::ETRANSACT_SIGNER
  }.freeze

  ROLES_TO_LDAP_GROUPS = LDAP_GROUPS_TO_ROLES.invert.freeze

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :ldap_authenticatable, :recoverable, :trackable, :timeoutable, case_insensitive_keys: [:username]

  attr_accessor :roles, :email, :surname, :given_name, :member_id, :deletion_reason

  after_save :save_ldap_attributes
  after_destroy :destroy_ldap_entry
  before_save :check_password_change
  set_callback :ldap_password_save, :after, :clear_password_expiration

  def display_name
    @display_name ||= (ldap_entry[:displayname].try(:first) if ldap_entry)
  end

  def display_name_changed?
    changed.include?('display_name')
  end

  def email
    @email ||= (ldap_entry[:mail].try(:first) if ldap_entry)
  end

  def email=(value)
    attribute_will_change!('email') unless value == email
    @email = value
  end

  def email_changed?
    changed.include?('email')
  end

  def surname
    @surname ||= (ldap_entry[:sn].try(:first) if ldap_entry)
  end

  def surname_changed?
    changed.include?('surname')
  end

  def surname=(value)
    attribute_will_change!('surname') unless value == surname
    @surname = value
    rebuild_display_name
  end

  def given_name
    @given_name ||= (ldap_entry[:givenname].try(:first) if ldap_entry)
  end

  def given_name=(value)
    attribute_will_change!('given_name') unless value == given_name
    @given_name = value
    rebuild_display_name
  end

  def given_name_changed?
    changed.include?('given_name')
  end

  def deletion_reason
    @deletion_reason ||= (ldap_entry[:deletereason].try(:first) if ldap_entry)
  end

  def deletion_reason=(value)
    attribute_will_change!('deletion_reason') unless value == deletion_reason
    @deletion_reason = value
  end

  def deletion_reason_changed?
    changed.include?('deletion_reason')
  end

  def locked?
    ldap_entry.present? && (ldap_entry[:userAccountControl].try(:first).to_i & LDAP_LOCK_BIT) == LDAP_LOCK_BIT
  end

  def lock!
    reload_ldap_entry
    if ldap_entry
      access_flags = ldap_entry[:userAccountControl].try(:first).to_i | LDAP_LOCK_BIT
      reload_ldap_entry
      Devise::LDAP::Adapter.set_ldap_param(username, :userAccountControl, access_flags.to_s, nil, ldap_domain)
    else
      false
    end
  end

  def unlock!
    reload_ldap_entry
    if ldap_entry
      access_flags = ldap_entry[:userAccountControl].try(:first).to_i & (~LDAP_LOCK_BIT)
      reload_ldap_entry
      Devise::LDAP::Adapter.set_ldap_param(username, :userAccountControl, access_flags.to_s, nil, ldap_domain)
    else
      false
    end
  end

  def password_expired?
    ldap_entry[LDAP_PASSWORD_EXPIRATION_ATTRIBUTE].try(:first).try(:downcase) == 'true' if ldap_entry
  end

  def reload
    reload_ldap_entry
    reload_ldap_attributes
    super
  end

  def valid_ldap_authentication?(password, strategy)
    result = super
    result && InternalUserPolicy.new(self, strategy.request).access?
  end

  def self.create_ldap_user(member_id, creator, username, email, given_name, surname)
    dn = "CN=#{username},#{LDAP_EXTRANET_EBIZ_USERS_DN}"
    attributes = {
        CreatedBy: creator,
        description: "Created by #{creator}",
        sAMAccountName: username,
        mail: email,
        LDAP_PASSWORD_EXPIRATION_ATTRIBUTE => 'true',
        givenname: given_name,
        sn: surname,
        displayname: "#{given_name} #{surname}",
        objectClass: %w(user top person)
      }
    groups = [AD_GROUP_NAME_PREFIX + member_id, ROLES_TO_LDAP_GROUPS[Roles::MEMBER_USER]]
    Devise::LDAP::Adapter.shared_connection do
      Devise::LDAP::Connection.admin(LDAP_EXTRANET_DOMAIN).open do |ldap|
        group_dns = groups.map{ |group| ldap.search(filter: "(&(CN=#{group})(objectClass=group))").first.try(:dn) }
        group_dns.all? && ldap.add(dn: dn, attributes: attributes) && group_dns.all?{ |group_dn| ldap.add_attribute(group_dn, 'member', dn) }
      end
    end
  end

  def self.add_extranet_user(member_id, creator, username, email, given_name=nil, surname=nil)
    find_or_create_by_with_retry(username: username, ldap_domain: LDAP_EXTRANET_DOMAIN) if create_ldap_user(member_id, creator, username, email, given_name, surname)
  end

  def self.create(*args, &block)
    ldap_entry = args.try(:first)
    if ldap_entry.is_a?(Net::LDAP::Entry)
      raise 'Net::LDAP::Entry must have an objectClass of `user`' unless ldap_entry[:objectclass].include?('user')
      attrs = {
        username: ldap_entry[:samaccountname].try(:first),
        ldap_domain: Devise::LDAP::Adapter.get_ldap_domain_from_dn(ldap_entry.dn)
      }
      record = super attrs, &block
      record.instance_variable_set(:@ldap_entry, ldap_entry) if record # avoid a second trip to LDAP when possible
      record
    else
      super
    end
  end

  def self.find_or_create_by_ldap_entry(entry)
    record = self.find_or_create_by_with_retry({
      username: entry[:samaccountname].try(:first),
      ldap_domain: Devise::LDAP::Adapter.get_ldap_domain_from_dn(entry.dn)
    })
    record.instance_variable_set(:@ldap_entry, entry) if record # avoid a second trip to LDAP when possible
    record
  end

  def self.find_or_create_if_valid_login(attributes)
    record = self.find_by(attributes)
    unless record
      username = attributes[:username]
      ldap_domain = Devise::LDAP::Adapter.get_ldap_domain(username)
      record = self.find_or_create_by_with_retry(username: username, ldap_domain: ldap_domain) if ldap_domain
    end
    record
  end

  def self.find_or_create_by_with_retry(*args, &block)
    tries ||= 2
    find_or_create_by(*args, &block)
  rescue ActiveRecord::RecordNotUnique => e
    tries = tries - 1
    if tries <= 0
      raise e
    else
      retry
    end
  end

  def self.extranet_logins
    where(ldap_domain: 'extranet').where(['sign_in_count > 0'])
  end

  def after_ldap_authentication(new_ldap_domain)
    self.update_attribute(:ldap_domain, new_ldap_domain) if self.ldap_domain.nil?
  end

  def roles(request = ActionDispatch::TestRequest.new)
    @roles ||= (
      roles = []
      Devise::LDAP::Adapter.shared_connection do
        # Hits ldap_groups and gets an array of the CN's of all the groups the user belongs to.
        ldap_roles = self.ldap_groups
        roles << ldap_roles.collect{|object| object.cn} unless ldap_roles.nil?
        # Hit the MAPI endpoint to check if user is a signer. Need request object to connect to MAPI
        user_service = UsersService.new(request)
        user_service_roles = user_service.user_roles(username)
        roles << user_service_roles unless user_service_roles.nil?
        roles.flatten.collect{ |role| LDAP_GROUPS_TO_ROLES[role] }.compact
      end
    )
  end

  def member_id
    @member_id ||= (
      member_id = nil
      ldap_groups = self.ldap_groups || []
      ldap_groups.each do |group|
        if !(group.cn.first=~/\AFHLB\d+\z/).nil? && group.objectClass.include?('group')
          member_id = group.cn.first.remove(/fhlb/i)
          break
        end
      end
      member_id.to_s if member_id
    )
  end

  def ldap_groups
    Devise::LDAP::Adapter.get_groups(login_with, self.ldap_domain)
  end

  def accepted_terms?
    self.terms_accepted_at.present?
  end

  def enable_virtual_validators!
    @virtual_validators = true
  end

  def virtual_validators?
    @virtual_validators || false
  end

  def intranet_user?
    self.ldap_domain == LDAP_INTERNAL_DOMAIN
  end

  def flipper_id
    username
  end

  def member
    @member ||= (Member.new(member_id) if member_id)
  end

  def new_announcements_count
    last_viewed = self.last_viewed_announcements_at
    if last_viewed
      CorporateCommunication.where('date_sent >= ?', last_viewed).count
    else
      CorporateCommunication.count
    end
  end

  def announcements_viewed!
    self.update_attribute(:last_viewed_announcements_at, Time.zone.now)
  end

  protected

  def reload_ldap_entry
    @ldap_entry = nil
  end

  def reload_ldap_attributes
    LDAP_ATTRIBUTES_MAPPING.each do |ar_attr, ldap_attr|
      instance_variable_set(:"@#{ar_attr}", nil)
    end
  end

  def rebuild_display_name
    if surname || given_name
      new_display_name = "#{given_name} #{surname}"
      attribute_will_change!('display_name') unless display_name == new_display_name
      @display_name = new_display_name
    end
  end

  def save_ldap_attributes
    attributes = {}
    changes.each do |attribute, values|
      key = LDAP_ATTRIBUTES_MAPPING[attribute]
      attributes[key] = values.last if key
    end

    return unless attributes.present?

    reload_ldap_entry

    if Devise::LDAP::Adapter.set_ldap_params(username, attributes, nil, ldap_domain)
      reload_ldap_attributes
    else
      raise ActiveRecord::Rollback
    end
  end

  def destroy_ldap_entry
    raise ActiveRecord::Rollback unless Devise::LDAP::Adapter.delete_ldap_entry(username, nil, ldap_domain)
  end

  # this is needed for devise recoverable since we don't have the column on our table
  def encrypted_password_changed?
    false
  end

  def password_change_or_update?
    password_changed? || !new_record?
  end

  def check_password_change
    user_policy = UserPolicy.new(self, nil)
    if password_changed?
      if (changed.select{|key| LDAP_ATTRIBUTES_MAPPING.include?(key)}).count > 0 # we don't allow password changes to be mixed with other LDAP changes
        errors.add(:password, :non_atomic)
        raise ActiveRecord::Rollback
      elsif !user_policy.change_password?
        errors.add(:password, :intranet)
        raise ActiveRecord::Rollback
      end
    end
  end

  def clear_password_expiration
    if Devise::LDAP::Adapter.set_ldap_params(username, {LDAP_PASSWORD_EXPIRATION_ATTRIBUTE => 'false'}, nil, ldap_domain)
      reload_ldap_entry
    else
      raise ActiveRecord::Rollback
    end
  end

end
