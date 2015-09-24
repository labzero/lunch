module AuthenticationHelpers
  def login_user
    before(:each) do
      @request.env["devise.mapping"] = Devise.mappings[:user]
      user = build_user
      user.save(validate: false)
      sign_in user
    end
  end
end