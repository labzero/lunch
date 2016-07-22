module NavigationExamples
  RSpec.shared_examples 'a controller action with an active nav setting' do |action, active_nav, params={}|
    it "sets the active nav to #{active_nav}" do
      expect(controller).to receive(:set_active_nav).with(active_nav)
      get action, params
    end
  end
end