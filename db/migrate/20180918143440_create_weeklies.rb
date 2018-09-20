class CreateWeeklies < ActiveRecord::Migration
  def change
    create_table :weeklies do |t|
      t.integer :record_id
      #t.integer :question_id
      #t.text :answer

      t.timestamps null: false
    end
  end
end
