class AddNoDownloadFlagToJobStatuses < ActiveRecord::Migration
  def change
    add_column :job_statuses, :no_download, :boolean, :default => false
  end
end
