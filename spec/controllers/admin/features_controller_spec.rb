require 'rails_helper'

RSpec.describe Admin::FeaturesController, :type => :controller do

  login_user(admin: true)
  it_behaves_like 'an admin controller'

  describe 'GET index' do
    let(:features) {
      [
        instance_double('Flipper::Feature', name: double('A Feature Name'), state: double('A Feature State')),
        instance_double('Flipper::Feature', name: double('A Feature Name'), state: double('A Feature State')),
        instance_double('Flipper::Feature', name: double('A Feature Name'), state: double('A Feature State'))
      ]
    }
    before do
      allow(Rails.application.flipper).to receive(:features).and_return(features)
      get :index
    end
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
        include(columns: match([
          include(value: feature.state, type: :feature_status),
          include(value: feature.name),
          include(value: [I18n.t('admin.features.index.actions.edit')], type: :actions)
        ]))
      end
      raise 'this test requires at least one feature' unless features_matcher.length > 0
      expect(assigns[:features_table]).to include(rows: match(features_matcher))
    end
  end

end