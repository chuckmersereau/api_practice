class CreateContactNotesLog < ActiveRecord::Migration
  def change
    create_table :contact_notes_logs do |t|
      t.integer :contact_id
      t.date :recorded_on
      t.text :notes
      t.timestamps null: false
    end

    add_index :contact_notes_logs, :contact_id
    add_index :contact_notes_logs, :recorded_on
  end
end
