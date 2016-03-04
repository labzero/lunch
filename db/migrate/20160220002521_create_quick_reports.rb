class CreateQuickReports < ActiveRecord::Migration
  def change
    create_table :quick_report_sets do |t|
      t.integer :member_id, null: false
      t.string :period, limit: 7, null: false

      t.timestamps null: false
    end
    add_index :quick_report_sets, [:member_id, :period], unique: true

    create_table :quick_reports do |t|
      t.integer :quick_report_set_id, null: false
      t.string :report_name, null: false
      t.attachment :report

      t.timestamps null: false
    end
    add_index :quick_reports, [:quick_report_set_id, :report_name], unique: true
    add_index :quick_reports, [:report_name]
  end
end
