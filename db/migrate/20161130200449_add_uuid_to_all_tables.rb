class AddUuidToAllTables < ActiveRecord::Migration
  def up
    enable_extension 'uuid-ossp'

    db_tables.each do |table|
      add_column table, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
      add_index table, :uuid, unique: true
    end
  end

   def down
    disable_extension 'uuid-ossp'

    db_tables.each do |table|
      remove_column table, :uuid, :uuid
    end
  end

  private

  def db_tables
    ActiveRecord::Base.connection.tables - ["schema_migrations"]
  end
end
