require 'rails_helper'

describe FhlbMember::ActionDispatch::Request do
  subject { mock_context(described_class, instance_methods: [:session]) }
  let(:session) { Hash.new }

  before do
    allow(subject).to receive(:session).and_return(session)
  end

  describe 'public methods' do
    describe '`user_id`' do
      it 'returns the user ID found in the session if present' do
        user_id = double('A User ID')
        session[ApplicationController::SessionKeys::WARDEN_USER] = [[user_id]]
        expect(subject.user_id).to be(user_id)
      end
      it 'returns nil if the user ID was not found in the session' do
        expect(subject.user_id).to be_nil
      end
    end
    describe '`member_id`' do
      it 'returns the member ID found in the session if present' do
        member_id = double('A Member ID')
        session[ApplicationController::SessionKeys::MEMBER_ID] = member_id
        expect(subject.member_id).to be(member_id)
      end
      it 'returns nil if the member ID was not found in the session' do
        expect(subject.member_id).to be_nil
      end
    end
    describe '`member_name`' do
      it 'returns the member name found in the session if present' do
        member_name = double('A Member Name')
        session[ApplicationController::SessionKeys::MEMBER_NAME] = member_name
        expect(subject.member_name).to be(member_name)
      end
      it 'returns nil if the member name was not found in the session' do
        expect(subject.member_name).to be_nil
      end
    end
  end
end