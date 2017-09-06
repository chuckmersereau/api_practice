class TntImport::GiftsImport
  include Concerns::TntImport::DateHelpers
  include LocalizationHelper
  attr_reader :contact_ids_by_tnt_contact_id, :xml_tables, :account_list, :organization, :user

  def initialize(account_list, contact_ids_by_tnt_contact_id, xml, import)
    @account_list                  = account_list
    @contact_ids_by_tnt_contact_id = contact_ids_by_tnt_contact_id
    @xml                           = xml
    @xml_tables                    = xml.tables
    @import                        = import
    @user                          = import&.user
    @organization                  = account_list&.organization_accounts&.first&.organization
  end

  def import
    return {} unless @account_list.organization_accounts.count == 1 && xml_tables['Gift'].present?

    xml_tables['Gift'].each do |row|
      tnt_contact_id = row['ContactID']
      contact        = account_list.contacts.find_by(id: contact_ids_by_tnt_contact_id[tnt_contact_id])

      next unless contact
      next if organization.api_class != 'OfflineOrg' && row['PersonallyReceived'] == 'false'

      donor_account = donor_account_for_contact(contact)

      add_or_update_donation_and_link_to_appeal(row, donor_account, contact)
    end
  end

  private

  def designation_account
    return @designation_account if @designation_account
    name = user.to_s.strip
    @designation_account = account_list.designation_accounts.where(organization: organization, name: "#{name} (Imported from TntConnect)").first_or_create!
  end

  def add_or_update_donation_and_link_to_appeal(row, donor_account, contact)
    # If someone re-imports donations, assume that there is just one donation per date per amount;
    # that's not a perfect assumption but it seems reasonable solution for offline orgs for now.
    donation_key_attrs = { amount: row['Amount'], donation_date: parse_date(row['GiftDate'], @import.user).to_date }
    donor_account.donations.find_or_create_by(donation_key_attrs) do |donation|
      donation.update(tendered_currency: currency_code_for_id(row['CurrencyID']), tendered_amount: row['Amount'], designation_account: designation_account)

      add_donation_to_first_appeal_and_add_other_appeals_to_memo(donation, row)

      contact.update_donation_totals(donation)
    end
  end

  def add_donation_to_first_appeal_and_add_other_appeals_to_memo(mpdx_donation, tnt_gift)
    gift_splits = account_list_appeals.map do |appeal|
      gift_splits_by_gift_and_campaign(tnt_gift['id'], appeal.tnt_id.to_s)
    end.flatten.compact

    gift_split_with_appeal = gift_splits.find { |gift_split| account_list_appeal_by_tnt_id(gift_split['CampaignID']).present? }

    appeal = gift_split_with_appeal ? account_list_appeal_by_tnt_id(gift_split_with_appeal['CampaignID']) : nil

    new_memo = generate_donation_memo(mpdx_donation, (gift_splits - [gift_split_with_appeal]))

    mpdx_donation.update(appeal: appeal, memo: new_memo)
  end

  def generate_donation_memo(donation, gift_splits)
    [donation.memo, _('This donation was imported from Tnt.'), generate_gift_splits_memo(gift_splits)].select(&:present?)
                                                                                                      .join("\n\n")
                                                                                                      .gsub('&quot;', '"')
  end

  def generate_gift_splits_memo(gift_splits)
    gift_splits.map do |gift_split|
      current_appeal = account_list_appeal_by_tnt_id(gift_split['CampaignID'])
      current_currency_symbol = currency_symbol(currency_code_for_id(gift_split['CurrencyID']))

      "#{current_currency_symbol}#{gift_split['Amount']}" +
        _(' is designated to the "%{appeal_name}" appeal.').localize % { appeal_name: current_appeal.name }
    end.join
  end

  def gift_splits_by_gift_and_campaign(gift_id, campaign_id)
    @gift_splits ||= xml_tables['GiftSplit']

    return unless @gift_splits

    @gift_splits.select do |gift_split|
      gift_split['GiftID'] == gift_id && gift_split['CampaignID'] == campaign_id
    end
  end

  def account_list_appeals
    @account_list_appeals ||= @account_list.appeals
  end

  def account_list_appeal_by_tnt_id(tnt_id)
    account_list_appeals.find { |appeal| appeal.tnt_id == tnt_id.to_i }
  end

  def donor_account_for_contact(contact)
    donor_account = contact.donor_accounts.first
    return donor_account if donor_account

    donor_account = Retryable.retryable(tries: 3) do
      # Find a unique donor account_number for this contact. Try the current max numeric account number
      # plus one. If that is a collision due to a race condition, an exception will be raised as there is a
      # unique constraint on (organization_id, account_number) for donor_accounts. Just wait and try
      # again in that case.
      max = organization.donor_accounts.where("account_number ~ '^[0-9]+$'").maximum('CAST(account_number AS bigint)')
      organization.donor_accounts.create!(account_number: (max.to_i + 1).to_s, name: contact.name)
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
