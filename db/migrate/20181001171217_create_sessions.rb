class CreateSessions < ActiveRecord::Migration
  def change
    create_table :sessions, id: :uuid do |t|
      t.uuid :user
      t.integer :sid

      t.timestamps null: false
    end
  end
end
