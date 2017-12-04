class AddAppealToTntDonationsWorker
  include Sidekiq::Worker
  include Concerns::TntImport::AppealHelpers

  def perform(import_id)
    load_import(import_id)

    return unless @import

    linked_donations = find_gift_rows.map(&method(:link_donation_to_appeal))
    ids = linked_donations.compact.collect(&:id)

    # because the sidekiq config sets the logging level to Fatal,
    # log to fatal so that we can see these in the logs
    Rails.logger.fatal("AddAppealToTntDonationsWorker linked the following donations to appeals: #{ids.join(', ')}")
  end

  private

  def find_gift_rows
    xml.tables['Gift'].select(&method(:attached_appeal_id)).select(&:present?)
  end

  def load_import(import_id)
    @import = Import.joins(:account_list).find_by(id: import_id, source: 'tnt')
    @import&.file&.cache_stored_file!
  end

  def link_donation_to_appeal(gift_row)
    appeal = find_appeal(gift_row)
    return unless appeal

    donation = find_donation(gift_row)
    return if donation.blank? || donation.appeal_id.present?

    donation.update(appeal: appeal, appeal_amount: appeal_amount(gift_row))
    ensure_summed_pledge_amount(donation)
    donation
  end

  def ensure_summed_pledge_amount(donation)
    pledge = donation.reload.pledges.first
    return unless pledge
    donations = pledge.donations.to_a
    return unless donations.many?
    pledge.update(amount: donations.sum(&:appeal_amount))
  end

  def find_appeal(gift_row)
    tnt_id = attached_appeal_id(gift_row)
    @appeals ||= {}
    return @appeals[tnt_id] if @appeals.key? tnt_id
    @appeals[tnt_id] = account_list.appeals.find_by(tnt_id: tnt_id)
  end

  def find_donation(gift_row)
    exact_donation_match(gift_row) || find_donation_by_contact(gift_row)
  end

  def exact_donation_match(gift_row)
    gift_code = gift_row['OrgGiftCode']
    return unless gift_code.present?

    # in some instances the tnt code is from a different set then what the same donation has in mpdx.
    # This leads to a chance of collisions, so also make sure we are matching based on amount and date.
    donations_scope(gift_row).where(remote_id_match(gift_code).or(tnt_id_match(gift_code))).first
  end

  def find_donation_by_contact(gift_row)
    contact = account_list.contacts.find_by(tnt_id: gift_row['ContactID']) if gift_row['ContactID']
    contact ||= find_contact_by_donor_id(gift_row)
    return unless contact

    matching_donations = donations_scope(gift_row).where(donor_account: contact.donor_accounts).to_a
    resolve_multiple_donations(matching_donations)
  end

  def find_contact_by_donor_id(gift_row)
    account_number = donor_account_number(gift_row['DonorID'])
    return unless account_number

    contacts = account_list.contacts
                           .includes(:donor_accounts)
                           .where(donor_accounts: { account_number: account_number })
                           .to_a

    # if there is more than one contact with this donor account, run.
    return unless contacts.count == 1
    contacts.first
  end

  def resolve_multiple_donations(donations)
    # if 0, return nil
    # if 1, return first
    # if many, only return if none have an appeal id
    return if donations.count > 1 && donations.any?(&:appeal_id)
    donations.first
  end

  def donor_account_number(donor_id)
    return unless donor_id
    donor = xml.find(:Donor, donor_id)
    return unless donor && donor['OrgDonorCode']

    # also include a version padded with zeros to account for Siebel
    # account numbers that may have been truncated in tnt
    [donor['OrgDonorCode'], donor['OrgDonorCode'].to_s.rjust(9, '0')]
  end

  def donations_scope(gift_row)
    @account_list_donations ||= account_list.donations
    @account_list_donations.where(amount: gift_row['Amount'], donation_date: gift_row['GiftDate'])
  end

  def attached_appeal_id(gift_row)
    # Version 3.2 of Tnt changed the relationship beteween Gifts and Appeals:
    # In 3.1 a Gift can only belong to one Appeal, through a foreign key on the Gift table.
    # In 3.2 a Gift can be split and belong to many Appeals, through a new GiftSplit table.
    return gift_row['AppealID'] if @xml.version < 3.2

    split = xml.find(:GiftSplit, 'GiftID' => gift_row['id'])
    return unless split
    split['CampaignID']
  end

  def appeal_amount(gift_row)
    gift_row[appeal_amount_name]
  end

  #
  # Data methods
  #
  def tnt_import
    @tnt_import ||= TntImport.new(@import)
  end

  def xml
    @xml ||= tnt_import.xml
  end

  def account_list
    @account_list ||= @import.account_list
  end

  #
  # Query methods
  #
  def donation_table
    Donation.arel_table
  end

  def remote_id_match(code)
    donation_table[:remote_id].eq(code)
  end

  def tnt_id_match(code)
    donation_table[:tnt_id].eq(code)
  end
end
