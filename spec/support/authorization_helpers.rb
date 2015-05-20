module AuthorizationHelpers
  def allow_policy(policy, query)
    before(:each) do
      allow(subject).to receive(:authorize).with(policy, query)
    end
  end
end