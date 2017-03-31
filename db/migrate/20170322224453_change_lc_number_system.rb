class ChangeLcNumberSystem < ActiveRecord::Migration
  def up
    drop_sequence
  end

  def down
    cursor = ActiveRecord::Base.connection.execute("SELECT * FROM ALL_SEQUENCES WHERE SEQUENCE_NAME = 'LC_#{Time.zone.now.year}'")
    raise ActiveRecord::IrreversibleMigration if cursor.fetch
  end

  def drop_sequence
    begin
      ActiveRecord::Base.connection.execute("DROP SEQUENCE LC_#{Time.zone.now.year}")
    rescue ActiveRecord::StatementInvalid => e
      raise e unless e.original_exception.code == 2289
    end
  end
end