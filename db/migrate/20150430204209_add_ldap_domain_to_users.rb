class AddLdapDomainToUsers < ActiveRecord::Migration
  def change
    add_column :users, :ldap_domain, :string
  end
end
