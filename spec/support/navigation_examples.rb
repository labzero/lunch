module NavigationExamples
  RSpec.shared_examples 'a controller action with an active nav setting' do |action, active_nav|
    it "sets the active nav to #{active_nav}" do
      expect(controller).to receive(:set_active_nav).with(active_nav)
      get action
    end
  end
end