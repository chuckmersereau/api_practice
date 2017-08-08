class CreateExportLogs < ActiveRecord::Migration
  def change
    create_table :export_logs do |t|
      t.string :type
      t.text :params
      t.integer :user_id
      t.datetime :export_at

      t.timestamps null: false
    end
  end
end
