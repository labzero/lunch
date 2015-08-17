class AddTermsAcceptedAtToUser < ActiveRecord::Migration
  def change
    add_column :users, :terms_accepted_at, :datetime

    add_index :users, :terms_accepted_at
  end
end
