require 'rails_helper'

RSpec.describe Admin::FeaturesController, :type => :controller do

  let(:features) {
    [
      instance_double('Flipper::Feature', name: double('A Feature Name'), state: double('A Feature State')),
      instance_double('Flipper::Feature', name: double('A Feature Name'), state: double('A Feature State')),
      instance_double('Flipper::Feature', name: double('A Feature Name'), state: double('A Feature State'))
    ]
  }
  
  login_user(admin: true)
  it_behaves_like 'an admin controller'

  describe 'GET index' do
    before do
      allow(Rails.application.flipper).to receive(:features).and_return(features)
      get :index
    end

    it_behaves_like 'a controller action with an active nav setting', :index, :features
    it_behaves_like 'an authorization required method', :get, :index, :web_admin, :show?

    it 'builds a table in `@features_table` with a Status column, Features column and Actions column' do
      expect(assigns[:features_table]).to include(
        rows: kind_of(Array),
        column_headings: match([
          include(title: I18n.t('common_table_headings.status')),
          include(title: I18n.t('admin.features.index.columns.feature_name')),
          include(title: I18n.t('global.actions')
          )]
        )
      )
    end
    it 'enables sorting of the Status and Feature columns' do
      expect(assigns[:features_table]).to include(column_headings: match([
        include(sortable: true),
        include(sortable: true),
        anything
      ]))
    end
    it 'disables sorting of the Actions columns' do
      expect(assigns[:features_table]).to include(column_headings: match([
        anything,
        anything,
        include(sortable: false)
      ]))
    end
    it 'has one row per `Flipper::Feature`' do
      features_matcher = features.collect do |feature|
        path = controller.feature_admin_path(feature: feature.name)
        include(columns: match([
          include(value: feature.state, type: :feature_status),
          include(value: feature.name),
          include(value: [[I18n.t('admin.features.index.actions.edit'), path]], type: :actions)
        ]))
      end
      raise 'this test requires at least one feature' unless features_matcher.length > 0
      expect(assigns[:features_table]).to include(rows: match(features_matcher))
    end
  end

  describe 'GET view' do
    let(:feature_name) { SecureRandom.hex }
    let(:make_request) { get :view, feature: feature_name }

    before do
      allow(MembersService).to receive(:new).and_return(instance_double(MembersService, all_members: []))
    end

    it_behaves_like 'a controller action with an active nav setting', :view, :features, feature: :foo
    it_behaves_like 'an authorization required method', :get, :view, :web_admin, :show?, feature: :foo

    it 'calls `find_feature`' do
      expect(controller).to receive(:find_feature).with(feature_name).and_return(instance_double('Flipper::Feature', name: nil, state: nil, actors_value: []))
      make_request
    end

    describe 'with a valid feature name' do
      let(:usernames) { [SecureRandom.hex, SecureRandom.hex, SecureRandom.hex] }
      let(:member_ids) { ['1', '3456', '007'] }
      let(:members) { [] }
      let(:member_actors) { member_ids.collect {|id| "FHLB-#{id}"} }
      let(:feature) { instance_double('Flipper::Feature', name: feature_name, state: double('A Feature State'), actors_value: [*usernames, *member_actors]) }
      before do
        member_ids.each do |id|
          member = instance_double(Member, name: "Member-#{id}", id: id.to_i)
          members << member
          allow(Member).to receive(:new).with(id).and_return(member)
        end
        allow(controller).to receive(:find_feature).with(feature_name).and_return(feature)
      end

      shared_examples 'assigns the feature' do
        it 'assigns `@feature` to the feature' do
          expect(assigns[:feature]).to be(feature)
        end
        it 'assigns `@feature_name` to the feature name' do
          expect(assigns[:feature_name]).to be(feature.name)
        end
        it 'assigns `@feature_status` to the feature state' do
          expect(assigns[:feature_status]).to be(feature.state)
        end
        it 'assigns `@enabled_users` to the list of usernames who have that feature enabled at an individual level' do
          expect(assigns[:enabled_users]).to contain_exactly(*usernames)
        end
        it 'assigns `@enabled_members` to the list of members name who have that feature enabled' do
          expect(assigns[:enabled_members]).to contain_exactly(*members.collect {|m| {name: m.name, id: m.id}} )
        end
        it 'orders the @enabled_users by ascending username' do
          expect(assigns[:enabled_users]).to match(usernames.sort)
        end
        it 'orders the @enabled_members by ascending name' do
          expect(assigns[:enabled_members].collect { |m| m[:name] }.sort).to match(members.collect(&:name).sort)
        end
      end

      context 'and feature names as strings' do
        before do
          make_request
        end
        
        include_examples 'assigns the feature'
      end

      context 'and feature names as symbols' do
        before do
          allow(feature).to receive(:name).and_return(feature_name.to_sym)
          make_request
        end
        
        include_examples 'assigns the feature'
      end

      describe 'rendering the view' do
        before do
          allow(controller).to receive(:render)
        end
        it 'uses a layout if the request is not an XHR' do
          expect(controller).to receive(:render).with(include(layout: true))
          make_request
        end
        it 'does not use a layout if the request is an XHR' do
          allow(request).to receive(:xhr?).and_return(true)
          expect(controller).to receive(:render).with(include(layout: false))
          make_request
        end
      end
    end
  end
  
  describe 'PUT enable_feature' do
    let(:feature_name) { SecureRandom.hex }
    let(:feature) { instance_double(Flipper::Feature, name: feature_name, enable: true) }
    let(:make_request) { put :enable_feature, feature: feature_name }

    allow_policy(:web_admin, :edit_features?)

    it_behaves_like 'an authorization required method', :put, :enable_feature, :web_admin, [:show?, :edit_features?], feature: :foo

    it 'calls `find_feature`' do
      expect(controller).to receive(:find_feature).with(feature_name).and_return(feature)
      make_request
    end

    describe 'when it finds the feature' do
      before do
        allow(controller).to receive(:find_feature).with(feature_name).and_return(feature)
      end

      it 'calls `enable` on the feature' do
        expect(feature).to receive(:enable).and_return(true)
        make_request
      end
      it 'redirects to the `view` action on success' do
        expect(make_request).to redirect_to(feature_admin_path(feature_name))
      end
      it 'redirects with a 303 status code' do
        expect(make_request.status).to be(303)
      end
      it 'raises an error on failure' do
        allow(feature).to receive(:enable).and_return(false)
        expect { make_request }.to raise_error(/failed to enable feature/i)
      end
    end
  end

  describe 'PUT disable_feature' do
    let(:feature_name) { SecureRandom.hex }
    let(:feature) { instance_double(Flipper::Feature, name: feature_name, disable: true) }
    let(:make_request) { put :disable_feature, feature: feature_name }

    allow_policy(:web_admin, :edit_features?)
    allow_policy(:web_admin, :show?)

    it_behaves_like 'an authorization required method', :put, :disable_feature, :web_admin, [:show?, :edit_features?], feature: :foo

    it 'calls `find_feature`' do
      expect(controller).to receive(:find_feature).with(feature_name).and_return(feature)
      make_request
    end

    describe 'when it finds the feature' do
      before do
        allow(controller).to receive(:find_feature).with(feature_name).and_return(feature)
      end

      it 'calls `disable` on the feature' do
        expect(feature).to receive(:disable).and_return(true)
        make_request
      end
      it 'redirects to the `view` action on success' do
        expect(make_request).to redirect_to(feature_admin_path(feature_name))
      end
      it 'redirects with a 303 status code' do
        expect(make_request.status).to be(303)
      end
      it 'raises an error on failure' do
        allow(feature).to receive(:disable).and_return(false)
        expect { make_request }.to raise_error(/failed to disable feature/i)
      end
    end
  end

  describe 'POST add_member' do
    let(:feature_name) { SecureRandom.hex }
    let(:member_id) { SecureRandom.hex }
    let(:feature) { instance_double(Flipper::Feature, name: feature_name, enable_actor: true) }
    let(:member) { instance_double(Member) }
    let(:make_request) { post :add_member, feature: feature_name, member_id: member_id }

    allow_policy(:web_admin, :edit_features?)
    allow_policy(:web_admin, :show?)

    it_behaves_like 'an authorization required method', :post, :add_member, :web_admin, [:show?, :edit_features?], feature: :foo, member_id: :bar

    it 'calls `find_feature`' do
      expect(controller).to receive(:find_feature).with(feature_name).and_return(feature)
      allow(controller).to receive(:find_member)
      make_request
    end

    describe 'when it finds the feature' do
      before do
        allow(controller).to receive(:find_feature).with(feature_name).and_return(feature)
      end

      it 'calls `find_member`' do
        expect(controller).to receive(:find_member).with(member_id).and_return(member)
        make_request
      end

      describe 'when it finds the member' do
        before do
          allow(controller).to receive(:find_member).and_return(member)
        end


        it 'calls `enable_actor` on the feature' do
          expect(feature).to receive(:enable_actor).with(member).and_return(true)
          make_request
        end
        it 'redirects to the `view` action on success' do
          expect(make_request).to redirect_to(feature_admin_path(feature_name))
        end
        it 'redirects with a 303 status code' do
          expect(make_request.status).to be(303)
        end
        it 'raises an error on failure' do
          allow(feature).to receive(:enable_actor).with(member).and_return(false)
          expect { make_request }.to raise_error(/failed to add member/i)
        end
      end
    end
  end
  
  describe 'DELETE remove_member' do
    let(:feature_name) { SecureRandom.hex }
    let(:member_id) { SecureRandom.hex }
    let(:feature) { instance_double(Flipper::Feature, name: feature_name, disable_actor: true) }
    let(:member) { instance_double(Member) }
    let(:make_request) { delete :remove_member, feature: feature_name, member_id: member_id }

    allow_policy(:web_admin, :edit_features?)
    allow_policy(:web_admin, :show?)

    it_behaves_like 'an authorization required method', :delete, :remove_member, :web_admin, [:show?, :edit_features?], feature: :foo, member_id: :bar

    it 'calls `find_feature`' do
      expect(controller).to receive(:find_feature).with(feature_name).and_return(feature)
      allow(controller).to receive(:find_member)
      make_request
    end

    describe 'when it finds the feature' do
      before do
        allow(controller).to receive(:find_feature).with(feature_name).and_return(feature)
      end

      it 'calls `find_member`' do
        expect(controller).to receive(:find_member).with(member_id).and_return(member)
        make_request
      end

      describe 'when it finds the member' do
        before do
          allow(controller).to receive(:find_member).and_return(member)
        end

        it 'calls `disable_actor` on the feature' do
          expect(feature).to receive(:disable_actor).with(member).and_return(true)
          make_request
        end
        it 'redirects to the `view` action on success' do
          expect(make_request).to redirect_to(feature_admin_path(feature_name))
        end
        it 'redirects with a 303 status code' do
          expect(make_request.status).to be(303)
        end
        it 'raises an error on failure' do
          allow(feature).to receive(:disable_actor).with(member).and_return(false)
          expect { make_request }.to raise_error(/failed to remove member/i)
        end
      end
    end
  end

  describe 'POST add_user' do
    let(:feature_name) { SecureRandom.hex }
    let(:username) { SecureRandom.hex }
    let(:feature) { instance_double(Flipper::Feature, name: feature_name, enable_actor: true) }
    let(:user) { instance_double(User) }
    let(:make_request) { post :add_user, feature: feature_name, username: username }

    allow_policy(:web_admin, :edit_features?)
    allow_policy(:web_admin, :show?)

    it_behaves_like 'an authorization required method', :post, :add_user, :web_admin, [:show?, :edit_features?], feature: :foo, username: :bar

    it 'calls `find_feature`' do
      expect(controller).to receive(:find_feature).with(feature_name).and_return(feature)
      allow(controller).to receive(:find_user)
      make_request
    end

    describe 'when it finds the feature' do
      before do
        allow(controller).to receive(:find_feature).with(feature_name).and_return(feature)
      end

      it 'calls `find_user`' do
        expect(controller).to receive(:find_user).with(username).and_return(user)
        make_request
      end

      describe 'when it finds the user' do
        before do
          allow(controller).to receive(:find_user).and_return(user)
        end


        it 'calls `enable_actor` on the feature' do
          expect(feature).to receive(:enable_actor).with(user).and_return(true)
          make_request
        end
        it 'redirects to the `view` action on success' do
          expect(make_request).to redirect_to(feature_admin_path(feature_name))
        end
        it 'redirects with a 303 status code' do
          expect(make_request.status).to be(303)
        end
        it 'raises an error on failure' do
          allow(feature).to receive(:enable_actor).with(user).and_return(false)
          expect { make_request }.to raise_error(/failed to add user/i)
        end
      end
    end
  end
  
  describe 'DELETE remove_user' do
    let(:feature_name) { SecureRandom.hex }
    let(:username) { SecureRandom.hex }
    let(:feature) { instance_double(Flipper::Feature, name: feature_name, disable_actor: true) }
    let(:user) { instance_double(User) }
    let(:make_request) { delete :remove_user, feature: feature_name, username: username }

    allow_policy(:web_admin, :edit_features?)
    allow_policy(:web_admin, :show?)

    it_behaves_like 'an authorization required method', :delete, :remove_user, :web_admin, [:show?, :edit_features?], feature: :foo, username: :bar

    it 'calls `find_feature`' do
      expect(controller).to receive(:find_feature).with(feature_name).and_return(feature)
      allow(controller).to receive(:find_user)
      make_request
    end

    describe 'when it finds the feature' do
      before do
        allow(controller).to receive(:find_feature).with(feature_name).and_return(feature)
      end

      it 'calls `find_user`' do
        expect(controller).to receive(:find_user).with(username).and_return(user)
        make_request
      end

      describe 'when it finds the user' do
        before do
          allow(controller).to receive(:find_user).and_return(user)
        end

        it 'calls `disable_actor` on the feature' do
          expect(feature).to receive(:disable_actor).with(user).and_return(true)
          make_request
        end
        it 'redirects to the `view` action on success' do
          expect(make_request).to redirect_to(feature_admin_path(feature_name))
        end
        it 'redirects with a 303 status code' do
          expect(make_request.status).to be(303)
        end
        it 'raises an error on failure' do
          allow(feature).to receive(:disable_actor).with(user).and_return(false)
          expect { make_request }.to raise_error(/failed to remove user/i)
        end
      end
    end
  end

  describe '`find_feature` protected method' do
    let(:feature) { instance_double(Flipper::Feature, name: feature_name) }
    let(:feature_name) { SecureRandom.hex }
    let(:call_method) { subject.send(:find_feature, feature_name) }

    it 'raises a `RecordNotFound` if a feature is not found' do
      allow(Rails.application.flipper).to receive(:features).and_return([])
      expect{ call_method }.to raise_error(ActiveRecord::RecordNotFound)
    end

    describe 'with a valid feature name' do
      before do
        allow(Rails.application.flipper).to receive(:features).and_return([feature])
        allow(Rails.application.flipper).to receive(:[]).with(feature_name).and_return(feature)
      end

      context 'when feature name is a string' do
        it 'returns the feature if found' do
          expect(call_method).to be(feature)
        end
      end

      context 'when feature name is a symbol' do
        it 'returns the feature if found' do
          expect(subject.send(:find_feature, feature_name.to_sym)).to be(feature)
        end
      end
    end
  end

  describe '`find_member` protected method' do
    let(:member_id) { SecureRandom.hex }
    let(:member) { instance_double(Member, found?: true) }
    let(:request) { ActionDispatch::TestRequest.new }
    let(:call_method) { subject.send(:find_member, member_id) }

    before do
      allow(Member).to receive(:new).with(member_id).and_return(member)
      allow(subject).to receive(:request).and_return(request)
    end

    it 'constructs a Member with the member_id' do
      expect(Member).to receive(:new).with(member_id).and_return(member)
      call_method
    end

    it 'calls `found?` on the member, passing the request' do
      expect(member).to receive(:found?).with(request).and_return(true)
      call_method
    end

    it 'raises a `RecordNotFound` if a member is not found' do
      allow(member).to receive(:found?).and_return(false)
      expect{ call_method }.to raise_error(ActiveRecord::RecordNotFound)
    end

    describe 'with a valid member id' do
      it 'returns the member' do
        expect(call_method).to be(member)
      end
    end
    
  end

  describe '`find_user` protected method' do
    let(:username) { SecureRandom.hex }
    let(:user) { instance_double(User) }
    let(:call_method) { subject.send(:find_user, username) }

    before do
      allow(User).to receive(:find_or_create_if_valid_login).with(username: username).and_return(user)
    end

    it 'finds or creates the user by the username' do
      expect(User).to receive(:find_or_create_if_valid_login).with(username: username).and_return(user)
      call_method
    end

    it 'raises a `RecordNotFound` if a user is not found' do
      allow(User).to receive(:find_or_create_if_valid_login).with(username: username).and_return(nil)
      expect{ call_method }.to raise_error(ActiveRecord::RecordNotFound)
    end

    describe 'with a valid username' do
      it 'returns the user' do
        expect(call_method).to be(user)
      end
    end
    
  end

end