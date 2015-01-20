RSpec.shared_examples 'a user required action' do |method, action|
  describe 'unauthenticated access' do
      it 'should redirect to the sign in page' do
        sign_out :user
        expect{self.send(method, action)}.to throw_symbol(:warden)
      end
    end
end