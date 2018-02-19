class IndexTablesOnCreatedAt < ActiveRecord::Migration
  disable_ddl_transaction!

  def up
    # we don't want running this to prevent production from starting
    return if Rails.env.production?

    tables_query = "SELECT DISTINCT table_name
                    FROM information_schema.columns
                    WHERE table_schema = 'public'
                    and column_name = 'id' and data_type = 'uuid'"
    ActiveRecord::Base.connection.execute(tables_query).each do |foreign_table_row|
      table = foreign_table_row['table_name']

      next if index_exists?(table, :created_at)
      next unless column_exists?(table, :created_at)
      add_index table, :created_at, algorithm: :concurrently
    end
  end
end
