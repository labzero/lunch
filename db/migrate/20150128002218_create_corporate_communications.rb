class CreateCorporateCommunications < ActiveRecord::Migration

  def change
    create_table :corporate_communications do |t|
      t.string :email_id, unique: true
      t.string :title
      t.datetime :date_sent
      t.string :category
      t.text :body
    end

    add_index :corporate_communications, :category
  end

end
