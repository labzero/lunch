class AddIndexOnDateSentToCorporateCommunications < ActiveRecord::Migration
  def change
    add_index :corporate_communications, :date_sent
  end
end
