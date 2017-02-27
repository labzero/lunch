class Admin::FeaturesController < Admin::BaseController

  before_action do
    set_active_nav(:features)
  end

  def index
    rows = Rails.application.flipper.features.collect do |feature|
      {
        columns: [
          { value: feature.state, type: :feature_status },
          { value: feature.name },
          { value: [[t('admin.features.index.actions.edit'), feature_admin_path(feature: feature.name)]], type: :actions }
        ]
      }
    end

    @features_table = {
      column_headings: [{title: t('common_table_headings.status'), sortable: true}, {title: t('admin.features.index.columns.feature_name'), sortable: true}, {title: t('global.actions'), sortable: false}],
      rows: rows
    }
  end

  def view
    raise ActiveRecord::RecordNotFound unless Rails.application.flipper.features.collect(&:name).collect(&:to_s).include?(params[:feature])
    feature = Rails.application.flipper[params[:feature]]
    @feature_name = feature.name
    @feature_status = feature.state
    @enabled_members = []
    @enabled_users = []
    feature.actors_value.each do |actor|
      if actor[0..4] == Member::FLIPPER_PREFIX
        @enabled_members << Member.new(actor[5..-1]).name
      else
        @enabled_users << actor
      end
    end
  end

end