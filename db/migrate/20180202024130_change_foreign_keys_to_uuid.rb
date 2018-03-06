class ChangeForeignKeysToUuid < ActiveRecord::Migration
  def up
    fix_uuid_columns

    remove_foreign_key_constraints

    find_indexes

    migrate_foreign_keys

    convert_primary_keys_to_uuids

    save_indexes

    readd_foreign_key_constraints
  end

  def fix_uuid_columns
    add_column :export_logs, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :export_logs, :uuid, unique: true
    add_column :account_list_coaches, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :account_list_coaches, :uuid, unique: true

    tables_for_uuid_fill = %w(activities activity_comments activity_contacts appeal_contacts appeal_excluded_appeal_contacts)
    tables_for_uuid_fill.each do |table_name|
      execute "UPDATE #{table_name} SET uuid = uuid_generate_v4() WHERE uuid IS NULL;"
    end
  end

  def find_indexes
    @indexes = quiet_execute "select * from pg_indexes where schemaname = 'public'"
  end

  def migrate_foreign_keys
    foreign_keys = CSV.read(Rails.root.join('db','foriegn_key_to_class_map.csv'))

    keys_grouped_by_table = foreign_keys.group_by { |fk| fk[0] }

    create_temp_tables

    # make sure tmp'ed table has it's rows copied over
    query_duplicated_table_names.each { |table_name| keys_grouped_by_table[table_name] ||= [] }

    keys_grouped_by_table.each do |table_name, group|
      copy_rows(table_name, group)
    end
  end

  def create_temp_tables
    temp_table_file = Rails.root.join('db','create_temp_tables.sql')
    sql = File.open(temp_table_file) { |file| file.read }
    execute sql
  end

  def drop_indexes_for(table_name)
    @indexes.each do |index_row|
      next unless index_row['tablename'] == table_name
      next if index_row['indexname'].ends_with?('_pkey')

      execute "DROP INDEX IF EXISTS #{index_row['indexname']}"
    end
  end

  def copy_rows(table_name, foreign_keys_list)
    # if foreign relation is polymorphic, we have to do some more complicated work.
    poly_relation = foreign_keys_list.find { |fk| fk[2] == 'Poly' }
    if table_name == 'imports'
      imports_uuid_convert(table_name, foreign_keys_list)
    elsif poly_relation
      relation_name = poly_relation[1].sub(/_id$/, '')
      poly_id_to_uuid(table_name, relation_name, foreign_keys_list)
    else
      execute_row_load(table_name, foreign_keys_list)
    end
  end

  def poly_id_to_uuid(table_name, relation_name, foreign_keys)
    foreign_tables = quiet_execute("SELECT DISTINCT #{relation_name}_type as type from #{table_name} where #{relation_name}_type is not null")
    foreign_tables.each do |foreign_table_row|
      poly_class = foreign_table_row['type']
      next unless poly_class.present?
      execute_row_load(table_name, foreign_keys, poly_class)
    end
  end

  def imports_uuid_convert(table_name, foreign_keys)
    foreign_tables = quiet_execute("SELECT DISTINCT source as type from #{table_name} where source is not null")
    foreign_tables.each do |foreign_table_row|
      poly_class = foreign_table_row['type']
      next unless poly_class.present?
      execute_row_load(table_name, foreign_keys, poly_class)
    end
  end

  def execute_row_load(table_name, foreign_keys, poly_class = nil)
    join_list = {}
    foreign_keys.each do |fk|
      foreign_class = fk[2] == 'Poly' ? poly_class : fk[2]
      join_list[fk[1]] = {
        foreign_table_name: table_name(foreign_class),
        alias: "#{fk[1]}_table",
        join_type: fk[3] == 'drop' ? 'INNER' : 'LEFT OUTER'
      }
    end

    columns_query = "SELECT column_name FROM information_schema.columns where table_name = '#{table_name}'"
    columns = quiet_execute(columns_query).collect { |r| r['column_name'] } - ['uuid']

    select_columns = columns.map do |col|
      next "#{table_name}.uuid as id" if col == 'id'
      next "#{table_name}.#{col}" unless join_list[col]
      "#{join_list[col][:alias]}.uuid as #{col}"
    end
    select_columns = select_columns.join(', ')

    where_clause = ''
    if poly_class
      poly_foreign_key = foreign_keys.find { |fk| fk[2] == 'Poly'}
      where_clause = "WHERE #{table_name}.#{poly_type_field(poly_foreign_key[1])} = '#{poly_class}'"
    end

    joins_list = join_list.map do |col, info|
      "#{info[:join_type]} JOIN #{info[:foreign_table_name]} #{info[:alias]} on #{table_name}.#{col} = #{info[:alias]}.id"
    end.join(' ')

    query = "INSERT INTO tmp_#{table_name}(\"#{columns.join('","')}\") ("\
              "SELECT #{select_columns} FROM #{table_name} "\
              "#{joins_list} "\
              "#{where_clause}"\
            ")"
    execute query
  end

  def poly_type_field(poly_foreign_key)
    return 'source' if poly_foreign_key == 'source_account_id'
    poly_foreign_key.sub(/_id$/, '_type')
  end

  def table_name(string)
    return 'addresses' if string == 'Addressable'
    return Person.const_get(string).table_name if string.starts_with? 'Person::'
    return Person::OrganizationAccount.table_name if string == 'tnt_data_sync'

    # any tnt or csv imports don't have source_account_id, so it doesn't matter what table it's joined to
    return Person.table_name if %w(tnt csv).include? string

    return "person_#{string}_accounts" if %w(google facebook).include? string
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
    query_duplicated_table_names.each do |good_name|
      table = "tmp_#{good_name}"
      execute "DROP TABLE #{good_name};"
      execute "ALTER TABLE #{table} RENAME TO #{good_name};"
      execute "ALTER TABLE #{good_name} ADD PRIMARY KEY (id);"
    end
  end

  def remove_foreign_key_constraints
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


  def save_indexes
    CSV.open(Rails.root.join('db','dropped_indexes.csv'), 'wb') do |csv|
      csv << @indexes.fields
      @indexes = @indexes.each do |index_row|
        next if index_row['indexname'].ends_with?('_pkey') ||
          index_row['indexdef'].ends_with?(' (uuid)') ||
          %w(active_admin_comments admin_users schema_migrations versions).include?(index_row['tablename'])

        # execute index_row['indexdef']
        csv << index_row.values
      end
    end
  end

  def query_duplicated_table_names
    tables_sql = "SELECT DISTINCT table_name
                  FROM information_schema.columns
                  WHERE table_schema = 'public'
                  and table_name LIKE 'tmp_%'"
    quiet_execute(tables_sql).collect { |row| row['table_name'].sub('tmp_', '') }
  end

  def quiet_execute(query)
    ActiveRecord::Base.connection.execute(query)
  end
end
