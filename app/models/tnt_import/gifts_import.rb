class TntImport::GiftsImport
  def initialize(account_list, tnt_contacts, xml)
    @account_list = account_list
    @tnt_contacts = tnt_contacts
    @xml = xml
  end

  def import
    return unless @account_list.organization_accounts.count == 1
    org = @account_list.organization_accounts.first.organization
    return unless org.api_class == 'OfflineOrg'

    Array.wrap(xml['Gift']['row']).each do |row|
      contact = tnt_contacts[row['ContactID']]
      next unless contact
      account = donor_account_for_contact(org, contact)

      # If someone re-imports donations, assume that there is just one donation per date per amount;
      # that's not a perfect assumption but it seems reasonable solution for offline orgs for now.
      donation_key_attrs = { amount: row['Amount'], donation_date: parse_date(row['GiftDate']) }
      account.donations.find_or_create_by(donation_key_attrs) do |donation|
        # Assume the currency is USD. Tnt doesn't have great currency support and USD is a decent default.
        donation.update(tendered_currency: 'USD', tendered_amount: row['Amount'])

        contact.update_donation_totals(donation)
      end
    end
  end

  private

  def donor_account_for_contact(org, contact)
    account = contact.donor_accounts.first
    return account if account

    donor_account = Retryable.retryable(sleep: 60, tries: 3) do
      # Find a unique donor account_number for this contact. Try the current max numeric account number
      # plus one. If that is a collision due to a race condition, an exception will be raised as there is a
      # unique constraint on (organization_id, account_number) for donor_accounts. Just wait and try
      # again in that case.
      max = org.donor_accounts.where("account_number ~ '^[0-9]+$'").maximum('CAST(account_number AS int)')
      org.donor_accounts.create!(account_number: (max.to_i + 1).to_s, name: contact.name)
    end
    contact.donor_accounts << donor_account
    donor_account
  end

  def parse_date(val)
    Date.parse(val)
  rescue
  end

  attr_reader :tnt_contacts, :xml
end
