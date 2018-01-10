class UpdateUniqueIndexColumnsOnEmailAddresses < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        remove_index :email_addresses, [:email, :person_id]
        add_index :email_addresses, [:email, :person_id, :source], unique: true
      end

      dir.down do
        remove_index :email_addresses, [:email, :person_id, :source]
        add_index :email_addresses, [:email, :person_id], unique: true
      end
    end
  end
end
