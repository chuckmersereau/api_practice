class UpdateAllTimestampColumnsToBeNonNull < ActiveRecord::Migration
  def up
    tables.each do |table|
      next unless model = model_for_table(table)

      columns(table).each do |column|
        next unless timestamp_column?(column)
        next unless allows_null_values?(column)

        say_with_time "Updating #{column.name} on #{table} to be NOT NULL" do
          affected_rows = set_null_values_to_current_timestamp!(model, column)
          change_column table, column.name, :datetime, null: false

          affected_rows
        end
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  TIMESTAMP_COLUMN_NAMES = %w(created_at updated_at).freeze

  def model_for_table(table_name)
    models_by_table[table_name]
  end

  def timestamp_column?(column)
    column.name.in? TIMESTAMP_COLUMN_NAMES
  end

  def allows_null_values?(column)
    column.null
  end

  def models_by_table
    @models_by_table ||= fetch_and_build_models_by_table_name
  end

  def fetch_and_build_models_by_table_name
    Rails.application.eager_load!

    ActiveRecord::Base.descendants.each_with_object({}) do |klass, hash|
      hash[klass.table_name] = klass
    end
  end

  def set_null_values_to_current_timestamp!(model, column)
    query     = column_is_null_query(column)           # Ex: { created_at: nil }
    changeset = timestamp_changeset_for_column(column) # Ex: { created_at: DateTime.current }

    model.where(query).update_all(changeset)
  end

  def column_is_null_query(column)
    {
      "#{column.name}": nil
    }
  end

  def timestamp_changeset_for_column(column)
    {
      "#{column.name}": DateTime.current
    }
  end
end
