module UserHelpers
  def build_user
    allow_any_instance_of(User).to receive(:ldap_entry).and_return(nil)
    allow_any_instance_of(User).to receive(:save_ldap_attributes).and_return(true)
    allow_any_instance_of(User).to receive(:ldap_groups).and_return([])
    allow_any_instance_of(User).to receive(:accepted_terms?).and_return(true)
    ::FactoryGirl.build(:user)
  end
end