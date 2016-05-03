class CreateAppealExcludedAppealContact < ActiveRecord::Migration
  def change
    create_table :appeal_excluded_appeal_contacts do |t|
      t.integer :appeal_id
      t.integer :contact_id
      t.text :reasons, array: true
    end

    add_index :appeal_excluded_appeal_contacts, [:appeal_id, :contact_id], unique: true, name: 'index_excluded_appeal_contacts_on_appeal_and_contact'
    add_foreign_key :appeal_excluded_appeal_contacts, :contacts, dependent: :delete
    add_foreign_key :appeal_excluded_appeal_contacts, :appeals, dependent: :delete
  end
end
