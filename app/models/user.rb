class User < ActiveRecord::Base
  INTERNAL_ROLES = {
    :'FCN-MemberSite-Users' => 'CN=FCN-MemberSite-Users,CN=Security Groups,OU=Client Services,DC=fhlbsf-i,DC=com',
    :'FCN-MemberSite-ExternalAccess' => 'CN=FCN-MemberSite-ExternalAccess,CN=Security Groups,OU=Client Services,DC=fhlbsf-i,DC=com',
    :'FCN-MemberSite-AccessManagers-R' => 'CN=FCN-MemberSite-AccessManagers-R,CN=Security Groups,OU=Client Services,DC=fhlbsf-i,DC=com',
    :'FCN-MemberSite-Admins' => 'CN=FCN-MemberSite-Admins,CN=Security Groups,OU=Client Services,DC=fhlbsf-i,DC=com'
  }
  EXTRANET_ROLES = {
    :'FCN-MemberSite-Users'  => 'CN=FCN-MemberSite-Users,CN=Groups,OU=eBiz,DC=extranet,DC=fhlbsf,DC=com',
    :'FCN-MemberSite-AccessManagers' => 'CN=FCN-MemberSite-AccessManagers,CN=Groups,OU=eBiz,DC=extranet,DC=fhlbsf,DC=com'
  }
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :ldap_authenticatable, :recoverable, :trackable

  attr_accessor :roles

  def after_ldap_authentication(new_ldap_domain)
    self.update_attributes!(ldap_domain: new_ldap_domain) if self.ldap_domain.nil?
  end

  def roles(request = nil)
    @roles ||= (
      roles = []
      # Hits ldap_groups and gets an array of the CN's of all the groups the user belongs to.
      ldap_roles = self.ldap_groups
      roles << ldap_roles.collect{|object| object.cn} unless ldap_roles.nil?
      # Hit the MAPI endpoint to check if user is a signer.
      user_service = UserService.new(request)
      user_service_roles = user_service.user_roles(username)
      roles << user_service_roles unless user_service_roles.nil?
      # roles << 'advance-signer'
      roles.flatten )
  end

end
