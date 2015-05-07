class User < ActiveRecord::Base
  DOMAIN_ITERATOR_MAPPING = [:extranet, :intranet]
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

  def roles
    self.ldap_groups
  end

  # ldap_entry defined on model.rb in devise_ldap_authenticatable
end
