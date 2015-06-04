module AuthenticationHelpers
  def login_user
    before(:each) do
      @request.env["devise.mapping"] = Devise.mappings[:user]
      allow_any_instance_of(User).to receive(:ldap_entry).and_return(nil)
      allow_any_instance_of(User).to receive(:save_ldap_attributes).and_return(true)
      allow_any_instance_of(User).to receive(:ldap_groups).and_return([])
      user = ::FactoryGirl.create(:user)
      sign_in user
    end
  end
end