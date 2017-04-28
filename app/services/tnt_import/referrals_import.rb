class TntImport::ReferralsImport
  def initialize(contact_ids_by_tnt_contact_id, tnt_contact_rows)
    attributes_for_contacts = Contact.where(id: contact_ids_by_tnt_contact_id.values)
                                     .pluck(:id, :name, :full_name, :greeting)

    @contact_attributes_by_tnt_contact_id = contact_ids_by_tnt_contact_id.transform_values do |id|
      attributes_for_contacts.find do |(contact_id, _name, _full_name, _greeting)|
        contact_id == id
      end
    end

    @tnt_contact_rows = tnt_contact_rows
  end

  def import
    # Loop over the whole list again now that we've added everyone and try to link up referrals
    @tnt_contact_rows.each do |row|
      referred_by_id, *_the_rest = @contact_attributes_by_tnt_contact_id.values.find do |(_contact_id, name, full_name, greeting)|
        name == row['ReferredBy'] || full_name == row['ReferredBy'] || greeting == row['ReferredBy']
      end

      next unless referred_by_id

      contact_id, *_the_rest = @contact_attributes_by_tnt_contact_id[row['id']]

      ContactReferral.where(referred_to_id: contact_id, referred_by_id: referred_by_id).first_or_create!
    end
  end
end
