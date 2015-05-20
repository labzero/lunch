class User < ActiveRecord::Base

  module Roles
    MEMBER_USER = 'member_user'
    ADVANCE_SIGNER = 'advance_signer'
    USER_WITH_EXTERNAL_ACCESS = 'user_with_external_access'
    ACCESS_MANAGER_READ_ONLY = 'access_manager_read_only'
    ACCESS_MANAGER = 'access_manager'
    ADMIN = 'admin'
    AUTHORIZED_SIGNER = 'authorized_signer'
  end

  ROLE_MAPPING = {
    'FCN-MemberSite-Users' => Roles::MEMBER_USER,
    'signer-advances' => Roles::ADVANCE_SIGNER,
    'signer' => Roles::AUTHORIZED_SIGNER,
    'FCN-MemberSite-ExternalAccess' => Roles::USER_WITH_EXTERNAL_ACCESS,
    'FCN-MemberSite-AccessManagers-R' => Roles::ACCESS_MANAGER_READ_ONLY,
    'FCN-MemberSite-AccessManagers' => Roles::ACCESS_MANAGER,
    'FCN-MemberSite-Admins' => Roles::ADMIN
  }.freeze

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :ldap_authenticatable, :recoverable, :trackable

  attr_accessor :roles

  def display_name
    ldap_entry[:displayname].try(:first) if ldap_entry
  end

  def email
    ldap_entry[:mail].try(:first) if ldap_entry
  end

  def surname
    ldap_entry[:sn].try(:first) if ldap_entry
  end

  def given_name
    ldap_entry[:givenname].try(:first) if ldap_entry
  end

  def locked?
    ldap_entry.present? && ldap_entry[:lockouttime].try(:first).to_i > 0
  end

  def lock!
    reload_ldap_entry
    Devise::LDAP::Adapter.set_ldap_param(username, :lockoutTime, Time.now.to_i.to_s, nil, ldap_domain)
  end

  def unlock!
    reload_ldap_entry
    Devise::LDAP::Adapter.set_ldap_param(username, :lockoutTime, '0', nil, ldap_domain)
  end

  def reload
    reload_ldap_entry
    super
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
      record.instance_variable_set(:@ldap_entry, ldap_entry) # avoid a second trip to LDAP when possible
      record
    else
      super
    end
  end

  def self.find_or_create_by_ldap_entry(entry)
    record = self.find_or_create_by({
      username: entry[:samaccountname].try(:first),
      ldap_domain: Devise::LDAP::Adapter.get_ldap_domain_from_dn(entry.dn)
    })
    record.instance_variable_set(:@ldap_entry, entry) # avoid a second trip to LDAP when possible
    record
  end

  def after_ldap_authentication(new_ldap_domain)
    self.update_attributes!(ldap_domain: new_ldap_domain) if self.ldap_domain.nil?
  end

  def roles(request = ActionDispatch::TestRequest.new)
    @roles ||= (
      roles = []
      # Hits ldap_groups and gets an array of the CN's of all the groups the user belongs to.
      ldap_roles = self.ldap_groups
      roles << ldap_roles.collect{|object| object.cn} unless ldap_roles.nil?
      # Hit the MAPI endpoint to check if user is a signer. Need request object to connect to MAPI
      user_service = UsersService.new(request)
      user_service_roles = user_service.user_roles(username)
      roles << user_service_roles unless user_service_roles.nil?
      roles.flatten.collect{ |role| ROLE_MAPPING[role] }.compact
    )
  end

  protected

  def reload_ldap_entry
    @ldap_entry = nil
  end

end
