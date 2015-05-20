class User < ActiveRecord::Base

  module Roles
    MEMBER_USER = 'member_user'
    ADVANCE_SIGNER = 'advance_signer'
    USER_WITH_EXTERNAL_ACCESS = 'user_with_external_access'
    ACCESS_MANAGER_READ_ONLY = 'access_manager_read_only'
    ACCESS_MANAGER = 'access_manager'
    ADMIN = 'admin'
  end

  ROLE_MAPPING = {
    'FCN-MemberSite-Users' => Roles::MEMBER_USER,
    'signer-advances' => Roles::ADVANCE_SIGNER,
    'FCN-MemberSite-ExternalAccess' => Roles::USER_WITH_EXTERNAL_ACCESS,
    'FCN-MemberSite-AccessManagers-R' => Roles::ACCESS_MANAGER_READ_ONLY,
    'FCN-MemberSite-AccessManagers' => Roles::ACCESS_MANAGER,
    'FCN-MemberSite-Admins' => Roles::ADMIN
  }.freeze

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :ldap_authenticatable, :recoverable, :trackable

  attr_accessor :roles

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

end
