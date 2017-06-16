class TntImport::GiftsImport
  include Concerns::TntImport::DateHelpers
  attr_reader :contact_ids_by_tnt_contact_id, :xml_tables, :account_list

  def initialize(account_list, contact_ids_by_tnt_contact_id, xml, import)
    @account_list                  = account_list
    @contact_ids_by_tnt_contact_id = contact_ids_by_tnt_contact_id
    @xml                           = xml
    @xml_tables                    = xml.tables
    @import                        = import
  end

  def import
    return {} unless @account_list.organization_accounts.count == 1 && xml_tables['Gift'].present?

    org = @account_list.organization_accounts.first.organization

    xml_tables['Gift'].each do |row|
      tnt_contact_id = row['ContactID']
      contact        = account_list.contacts.find_by(id: contact_ids_by_tnt_contact_id[tnt_contact_id])

      next unless contact
      next if org.api_class != 'OfflineOrg' && row['PersonallyReceived'] == 'false'

      account = donor_account_for_contact(org, contact)

      # If someone re-imports donations, assume that there is just one donation per date per amount;
      # that's not a perfect assumption but it seems reasonable solution for offline orgs for now.
      donation_key_attrs = { amount: row['Amount'], donation_date: parse_date(row['GiftDate'], @import.user).to_date }
      account.donations.find_or_create_by(donation_key_attrs) do |donation|
        donation.update(tendered_currency: currency_code_for_id(row['CurrencyID']), tendered_amount: row['Amount'])

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

  def currency_code_for_id(tnt_currency_id)
    found_currency_row = xml_tables['Currency']&.detect do |currency_row|
      currency_row['id'] == tnt_currency_id
    end
    found_currency_row&.[]('Code').presence || account_list.default_currency
  end
end
