class AddLastViewedAnnouncementsAtToUsers < ActiveRecord::Migration
  def change
    add_column :users, :last_viewed_announcements_at, :datetime
  end
end
