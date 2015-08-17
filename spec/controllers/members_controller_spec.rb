require 'rails_helper'

RSpec.describe MembersController, type: :controller do
  login_user

  describe 'GET select_member' do
    let(:make_request) { get :select_member }
    let(:members_list) { double('A List of Members', collect!: []) }
    it_behaves_like 'a user required action', :get, :select_member
    it 'calls MemberServices.all_members' do
      expect_any_instance_of(MembersService).to receive(:all_members).and_return(members_list)
      make_request
    end
    it 'raises an error if MemberServices.all_members returns no members' do
      expect_any_instance_of(MembersService).to receive(:all_members).and_return(nil)
      expect{make_request}.to raise_error
    end
    it 'assigns `@members` to be a list of members', :vcr do
      make_request
      expect(assigns[:members]).to be_kind_of(Array)
      expect(assigns[:members].length).to be > 0
      assigns[:members].each do |member|
        expect(member).to be_kind_of(Array)
        expect(member.length).to eq(2)
        expect(member.first).to be_kind_of(String)
        expect(member.last).to be_kind_of(Fixnum)
      end
    end
    it 'redirects to the `after_sign_in_path_for` if the session already has a selected member' do
      allow(subject).to receive(:current_member_id).and_return(123)
      expect(subject).to receive(:after_sign_in_path_for).and_return(dashboard_path)
      expect(make_request).to redirect_to(dashboard_path)
    end
    it 'should use the `external` layout', :vcr do
      expect(make_request).to render_template("layouts/external")
    end
  end

  describe 'POST set_member' do
    let(:member_id) { rand(1..1000) }
    let(:member_name) { double('A Member Name') }
    let(:make_request) { post :set_member, member_id: member_id }
    let(:member) { double('A Member', :[] => nil) }
    let(:members_list) { double('A List of Members', find: member) }
    it_behaves_like 'a user required action', :get, :select_member
    before do
      allow_any_instance_of(MembersService).to receive(:all_members).and_return(members_list)
    end
    it 'calls MemberServices.all_members' do
      expect_any_instance_of(MembersService).to receive(:all_members).and_return(members_list)
      make_request
    end
    it 'raises an error if the passed `member_id` is invalid' do
      allow(members_list).to receive(:find).and_return(nil)
      expect{make_request}.to raise_error
    end
    it 'assigns `member_id` in the session' do
      allow(subject.session).to receive(:[]=)
      expect(subject.session).to receive(:[]=).with('member_id', member_id)
      make_request
    end
    it 'assigns `member_name` in the session' do
      allow(subject.session).to receive(:[]=)
      allow(member).to receive(:[]).with(:name).and_return(member_name)
      expect(subject.session).to receive(:[]=).with('member_name', member_name)
      make_request
    end
    it 'redirects to the `after_sign_in_path_for` on success' do
      expect(subject.session).to receive(:[]=).at_least(2).ordered # success
      expect(subject).to receive(:after_sign_in_path_for).and_return(dashboard_path).ordered
      expect(make_request).to redirect_to(dashboard_path)
    end
    it 'redirects to the `after_sign_in_path_for` if the session already has a selected member' do
      allow(subject).to receive(:current_member_id).and_return(1001)
      expect(subject).to receive(:after_sign_in_path_for).and_return(dashboard_path)
      expect(subject.session).to_not receive(:[]=) # did we abort early?
      expect(make_request).to redirect_to(dashboard_path)
    end
  end

  describe 'GET terms' do
    let (:make_request) { get :terms}
    it_behaves_like 'a user required action', :get, :terms
    it 'should use the `external` layout', :vcr do
      expect(make_request).to render_template("layouts/external")
    end
  end

  describe 'POST accept_terms' do
    let(:make_request) {post :accept_terms}
    let(:now) { DateTime.new(2015,1,1)}
    let(:user) { double('user', member_id: nil, :'[]=' => nil, accepted_terms?: nil) }
    before { allow(DateTime).to receive(:now).and_return(now) }
    it_behaves_like 'a user required action', :post, :accept_terms
    it 'updates the `terms_accepted_at` attribute of the current_user with the current DateTime', :vcr do
      allow(controller).to receive(:current_user).and_return(user)
      expect(user).to receive(:update_attribute).with(:terms_accepted_at, now)
      make_request
    end
    it 'redirects to the `after_sign_in_path_for` on success', :vcr do
      allow(subject).to receive(:after_sign_in_path_for).and_return(dashboard_path).ordered
      expect(make_request).to redirect_to(dashboard_path)
    end
  end
end
