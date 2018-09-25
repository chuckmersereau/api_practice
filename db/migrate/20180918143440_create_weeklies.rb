class CreateWeeklies < ActiveRecord::Migration
  def change
    create_table :weeklies, id: :uuid do |t|
      t.integer :question_id
      t.text :answer
      t.integer :session_id

      t.timestamps null: false
    end
  end
end
