class CreateWeeklies < ActiveRecord::Migration
  def change
    create_table :weeklies, id: :uuid do |t|
      t.integer :question_id
      t.text :answer
      t.integer :sid

      t.timestamps null: false
    end
  end
end
