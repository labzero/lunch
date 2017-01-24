module AuthenticationHelpers
  def login_user(no_member: false)
    let(:warden_user) { warden.authenticate(scope: :user) }
    let(:member_id) { 6 } unless respond_to?(:member_id)
    before(:each) do
      @request.env["devise.mapping"] = Devise.mappings[:user]
      user = build_user
      user.save(validate: false)
      sign_in user
      unless no_member
        session[ApplicationController::SessionKeys::MEMBER_ID] = member_id unless session[ApplicationController::SessionKeys::MEMBER_ID]
        session[ApplicationController::SessionKeys::MEMBER_NAME] = SecureRandom.hex unless session[ApplicationController::SessionKeys::MEMBER_NAME]
      end
    end
  end
end