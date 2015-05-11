class CreateJobStatuses < ActiveRecord::Migration
  def change
    create_table :job_statuses do |t|
      t.integer :user_id
      t.string :job_id
      t.integer :status, default: 0
      t.datetime :finished_at
      t.attachment :result

      t.index :job_id, unique: true
      t.index :status
      t.index :finished_at
    end
  end
end
