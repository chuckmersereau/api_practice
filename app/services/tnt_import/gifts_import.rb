require_relative 'concerns/date_helpers'

class TntImport::GiftsImport
  include TntImport::DateHelpers
  attr_reader :contact_ids_by_tnt_contact_id, :xml_tables

  def initialize(account_list, contact_ids_by_tnt_contact_id, xml, import)
    @account_list                  = account_list
    @contact_ids_by_tnt_contact_id = contact_ids_by_tnt_contact_id
    @xml                           = xml
    @xml_tables                    = xml.tables
    @import                        = import
  end

  def import
    return unless @account_list.organization_accounts.count == 1
    org = @account_list.organization_accounts.first.organization

    xml_tables['Gift'].each do |row|
      tnt_contact_id = row['ContactID']
      contact        = Contact.find_by(id: contact_ids_by_tnt_contact_id[tnt_contact_id])

      next unless contact
      next if org.api_class != 'OfflineOrg' && row['PersonallyReceived'] == 'false'

      account = donor_account_for_contact(org, contact)

      # If someone re-imports donations, assume that there is just one donation per date per amount;
      # that's not a perfect assumption but it seems reasonable solution for offline orgs for now.
      donation_key_attrs = { amount: row['Amount'], donation_date: parse_date(row['GiftDate'], @import.user).to_date }
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
      max = org.donor_accounts.where("account_number ~ '^[0-9]+$'").maximum('CAST(account_number AS bigint)')
      org.donor_accounts.create!(account_number: (max.to_i + 1).to_s, name: contact.name)
    end
    contact.donor_accounts << donor_account
    donor_account
  end
end
