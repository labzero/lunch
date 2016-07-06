class ChangeTimestampsOnCorporateCommunications < ActiveRecord::Migration
  def change
    change_column_null(:corporate_communications, :updated_at, false)
    change_column_null(:corporate_communications, :created_at, false)
  end
end
