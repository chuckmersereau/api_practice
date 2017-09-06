class CreateAccountListCoaches < ActiveRecord::Migration
  def change
    create_table :account_list_coaches do |t|
      t.belongs_to :coach, index: true
      t.belongs_to :account_list, index: true

      t.timestamps null: false
    end

    add_index :account_list_coaches, [:coach_id, :account_list_id], unique: true
  end
end
