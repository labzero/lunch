class CreateAttachments < ActiveRecord::Migration
  def change
    create_table :attachments do |t|
      t.string :owner_type
      t.integer :owner_id
      t.string :category
      t.attachment :data
      t.string :fingerprint

      t.timestamps null: false
      t.index [:owner_type, :owner_id]
    end
  end
end
