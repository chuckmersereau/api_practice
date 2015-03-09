class MakeAppealContactsUnique < ActiveRecord::Migration
  def change
    Appeal.find_each do |appeal|
      contact_ids_so_far = Set.new
      appeal.appeal_contacts.each do |appeal_contact|
        if contact_ids_so_far.include?(appeal_contact.contact_id)
          appeal_contact.destroy
        else
          contact_ids_so_far << appeal_contact.contact_id
        end
      end
    end

    remove_index :appeal_contacts, [:appeal_id, :contact_id]
    add_index :appeal_contacts, [:appeal_id, :contact_id], :unique => true
  end
end
