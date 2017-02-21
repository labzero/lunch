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
      allow(Rails.application.flipper).to receive(:features).and_return(features)
    end

    it_behaves_like 'a controller action with an active nav setting', :view, :features, feature: :foo

    describe 'with a valid feature name' do
      let(:usernames) { [SecureRandom.hex, SecureRandom.hex, SecureRandom.hex] }
      let(:member_ids) { ['1', '3456', '007'] }
      let(:members) { [] }
      let(:member_actors) { member_ids.collect {|id| "FHLB-#{id}"} }
      let(:feature) { instance_double('Flipper::Feature', name: feature_name, state: double('A Feature State'), actors_value: [*usernames, *member_actors]) }
      before do
        member_ids.each do |id|
          member = instance_double(Member, name: double('A Name'))
          members << member
          allow(Member).to receive(:new).with(id).and_return(member)
        end
        features << feature
        allow(Rails.application.flipper).to receive(:[]).with(feature_name).and_return(feature)
        make_request
      end

      it 'assigns `@feature_name` to the feature name' do
        expect(assigns[:feature_name]).to be(feature.name)
      end
      it 'assigns `@feature_status` to the feature state' do
        expect(assigns[:feature_status]).to be(feature.state)
      end
      it 'assigns `@enabled_users` to the list of usernames who have that feature enabled at an individual level' do
        expect(assigns[:enabled_users]).to match(usernames)
      end
      it 'assigns `@enabled_members` to the list of members name who have that feature enabled' do
        expect(assigns[:enabled_members]).to match(members.collect(&:name))
      end
    end

    it 'returns a 404 if a feature is not found' do
      expect{ make_request }.to raise_error(ActiveRecord::RecordNotFound)
    end


  end

end