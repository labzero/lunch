class Admin::FeaturesController < Admin::BaseController

  def index
    rows = Rails.application.flipper.features.collect do |feature|
      {
        columns: [
          { value: feature.state, type: :feature_status },
          { value: feature.name },
          { value: [t('admin.features.index.actions.edit')], type: :actions }
        ]
      }
    end

    @features_table = {
      column_headings: [{title: t('common_table_headings.status'), sortable: true}, {title: t('admin.features.index.columns.feature_name'), sortable: true}, {title: t('global.actions'), sortable: false}],
      rows: rows
    }
  end

end