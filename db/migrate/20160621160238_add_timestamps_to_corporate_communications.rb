class AddTimestampsToCorporateCommunications < ActiveRecord::Migration
  def change
    change_table :corporate_communications do |t|
      t.timestamps null: true, default: nil
    end
  end
end
