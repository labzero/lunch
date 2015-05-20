module AuthorizationHelpers
  def allow_policy(policy, query)
    before(:each) do
      allow(subject).to receive(:authorize).with(policy, query)
      allow(subject.policy(policy)).to receive(query).and_return(true)
    end
  end

  def deny_policy(policy, query)
    before(:each) do
      allow(subject).to receive(:authorize).with(policy, query).and_raise(Pundit::NotAuthorizedError)
      allow(subject.policy(policy)).to receive(query).and_return(false)
    end
  end
end