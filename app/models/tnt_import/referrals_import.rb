class TntImport::ReferralsImport
  def initialize(tnt_contacts, contact_rows)
    @tnt_contacts = tnt_contacts
    @contact_rows = contact_rows
  end

  def import
    # Loop over the whole list again now that we've added everyone and try to link up referrals
    @contact_rows.each do |row|
      referred_by = @tnt_contacts.find do |_tnt_id, c|
        c.name == row['ReferredBy'] || c.full_name == row['ReferredBy'] || c.greeting == row['ReferredBy']
      end
      next unless referred_by
      contact = @tnt_contacts[row['id']]
      contact.referrals_to_me << referred_by[1] unless contact.referrals_to_me.include?(referred_by[1])
    end
  end
end
