class CreatePersonOptions < ActiveRecord::Migration
  def up
    unless table_exists?(:person_options)
      create_table :person_options do |t|
        t.string :key, null: false
        t.string :value
        t.integer :user_id
        t.uuid :uuid, null: false, default: 'uuid_generate_v4()'
        t.timestamps null: false
      end
      add_index :person_options, [:key, :user_id], unique: true
      add_index :person_options, :uuid, unique: true
    end
  end

  def down
    if table_exists?(:person_options)
      drop_table(:person_options)
    end
  end
end
