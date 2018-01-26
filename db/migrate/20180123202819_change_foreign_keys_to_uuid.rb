class ChangeForeignKeysToUuid < ActiveRecord::Migration
  def up
    remove_foreign_key_constrains

    find_indexes

    migrate_foreign_keys

    convert_primary_keys_to_uuids

    readd_indexes

    readd_foreign_key_constraints
  end

  def find_indexes
    @indexes = execute "select * from pg_indexes where schemaname = 'public'"
  end

  def migrate_foreign_keys
    foreign_keys = CSV.read(Rails.root.join('db','foriegn_key_to_class_map.csv'))

    keys_grouped_by_table = foreign_keys.group_by { |fk| fk[0] }

    keys_grouped_by_table.each do |table_name, group|
      drop_indexes_for(table_name)

      group.each { |fk| id_to_uuid(*fk) }
    end
  end

  def drop_indexes_for(table_name)
    @indexes.each do |index_row|
      next unless index_row['tablename'] == table_name
      next if index_row['indexname'].ends_with?('_pkey')

      execute "DROP INDEX IF EXISTS #{index_row['indexname']}"
    end
  end

  def id_to_uuid(table_name, relation_name, relation_klass)
    relation_name = relation_name.sub(/_id$/, '')
    foreign_key = "#{relation_name}_id".to_sym
    new_foreign_key = "#{relation_name}_uuid".to_sym

    add_column table_name, new_foreign_key, :uuid

    # if foreign relation is polymorphic, we have to do some more complicated work.
    if relation_klass == 'Poly'
      poly_id_to_uuid(table_name, relation_name, foreign_key, new_foreign_key)
    else
      execute_foreign_key_load(foreign_key, new_foreign_key, relation_klass, table_name)
    end

    remove_column table_name, foreign_key
    rename_column table_name, new_foreign_key, foreign_key
  end

  def poly_id_to_uuid(table_name, relation_name, foreign_key, new_foreign_key)
    foreign_tables = ActiveRecord::Base.connection.execute("SELECT DISTINCT #{relation_name}_type as type from #{table_name}")
    foreign_tables.each do |foreign_table_row|
      execute_foreign_key_load(foreign_key, new_foreign_key, foreign_table_row['type'], table_name)
    end
  end

  def execute_foreign_key_load(foreign_key, new_foreign_key, relation_klass, table_name)
    relation_table = table_name(relation_klass)
    query = "UPDATE #{table_name} "\
            "SET #{new_foreign_key} = #{relation_table}.uuid "\
            "FROM #{relation_table} "\
            "WHERE #{table_name}.#{foreign_key} = #{relation_table}.id"
    execute query
  end

  def table_name(string)
    return 'addresses' if string == 'Addressable'
    return Person.const_get(string).table_name if string.starts_with? 'Person::'
    string.classify.constantize.table_name
  end

  def try_class(string)
    return Person.const_get(string) if string.starts_with? 'Person::'
    string.classify.constantize
  rescue NameError
    nil
  end

  private

  def convert_primary_keys_to_uuids
    tables_sql = "SELECT DISTINCT table_name
                  FROM information_schema.columns
                  WHERE table_schema = 'public'
                  and column_name = 'uuid'
                  and data_type = 'uuid'"
    tables = ActiveRecord::Base.connection.execute(tables_sql).collect { |row| row['table_name'] }

    tables.each do |table|
      remove_column table, :id
      execute "UPDATE #{table} SET uuid = uuid_generate_v4() WHERE uuid IS NULL;"
      rename_column table, :uuid, :id
      execute "ALTER TABLE #{table} ADD PRIMARY KEY (id);"
    end
  end

  def remove_foreign_key_constrains
    remove_foreign_key :appeal_excluded_appeal_contacts, :contacts
    remove_foreign_key :appeal_excluded_appeal_contacts, :appeals
    remove_foreign_key :background_batch_requests, :background_batches
    remove_foreign_key :background_batches, :users
    remove_foreign_key :donation_amount_recommendations, :donor_accounts
    remove_foreign_key :donation_amount_recommendations, :designation_accounts
    remove_foreign_key :master_person_sources, :master_people
    remove_foreign_key :notification_preferences, :users
    remove_foreign_key :people, :master_people
  end

  def readd_foreign_key_constraints
    add_foreign_key :appeal_excluded_appeal_contacts, :contacts, dependent: :delete
    add_foreign_key :appeal_excluded_appeal_contacts, :appeals, dependent: :delete
    add_foreign_key :background_batch_requests, :background_batches
    add_foreign_key :background_batches, :people, column: :user_id
    add_foreign_key :donation_amount_recommendations, :donor_accounts, dependent: :nullify
    add_foreign_key :donation_amount_recommendations, :designation_accounts, dependent: :nullify
    add_foreign_key :master_person_sources, :master_people
    add_foreign_key :notification_preferences, :people, dependent: :delete, column: :user_id
    add_foreign_key :people, :master_people, dependent: :restrict
  end


  def readd_indexes
    @indexes.each do |index_row|
      next if index_row['indexname'].ends_with?('_pkey')

      execute index_row['indexdef']
    end
  end
end
