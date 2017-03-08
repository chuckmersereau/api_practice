class CreatePhoneNumbers < ActiveRecord::Migration
  def change
    create_table :phone_numbers do |t|
      t.belongs_to :person
      t.string :number
      t.string :country_code
      t.string :location
      t.boolean :primary, default: false

      t.timestamps null: false
    end
    add_index :phone_numbers, :person_id
  end
end
