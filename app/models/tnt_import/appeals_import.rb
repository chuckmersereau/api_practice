class TntImport::AppealsImport
  def initialize(account_list, contacts_by_tnt_appeal_id, xml)
    @account_list = account_list
    @contacts_by_tnt_appeal_id = contacts_by_tnt_appeal_id
    @xml = xml
  end

  def import
    appeals_by_tnt_id = find_or_create_appeals_by_tnt_id

    donor_contacts_by_appeal_id = import_appeal_amounts(appeals_by_tnt_id)

    appeals_by_tnt_id.each do |appeal_tnt_id, appeal|
      appeal.bulk_add_contacts((contacts_by_tnt_appeal_id[appeal_tnt_id] || []) +
                               (donor_contacts_by_appeal_id[appeal.id] || []))
    end
  end

  private

  attr_reader :xml, :contacts_by_tnt_appeal_id

  def find_or_create_appeals_by_tnt_id
    return {} unless xml['Appeal'].present?
    appeals = {}
    Array.wrap(xml['Appeal']['row']).each do |row|
      appeal = @account_list.appeals.find_by(tnt_id: row['id'])
      if appeal
        # This allows staff who imported from Tnt earlier before we added the LastEdit import
        # to re-run the import and get the dates for the previous appeals for the sake of the sort order.
        appeal.update(created_at: row['LastEdit'])
      else
        appeal = @account_list.appeals.create(name: row['Description'],
                                              created_at: row['LastEdit'],
                                              tnt_id: row['id'])
      end
      appeals[row['id']] = appeal
    end
    appeals
  end

  def import_appeal_amounts(appeals_by_tnt_id)
    return {} unless xml['Gift'].present?

    donor_contacts_by_appeal_id = {}
    donor_accounts_by_tnt_id = find_donor_accounts_by_tnt_id
    designation_account_ids = @account_list.designation_accounts.pluck(:id)

    Array.wrap(xml['Gift']['row']).each do |row|
      next if row['AppealID'].blank?
      appeal = appeals_by_tnt_id[row['AppealID']]
      donor_account = donor_accounts_by_tnt_id[row['DonorID']]
      next unless donor_account

      donor_contacts = @account_list.contacts.joins(:donor_accounts)
                                    .where(donor_accounts: { id: donor_account.id }).to_a
      donor_contacts_by_appeal_id[appeal.id] ||= []
      donor_contacts_by_appeal_id[appeal.id].push(*donor_contacts)

      donation = donor_account.donations.where(donation_date: row['GiftDate'], amount: row['Amount'])
                              .where(designation_account_id: designation_account_ids)
                              .find_by('appeal_id is null or appeal_id = ?', appeal.id)
      next if donation.blank?
      donation.update(appeal: appeal, appeal_amount: row['AppealAmount'])
    end

    donor_contacts_by_appeal_id
  end

  def find_donor_accounts_by_tnt_id
    return {} unless xml['Donor'].present?
    donors = {}
    Array.wrap(xml['Donor']['row']).each do |row|
      donors[row['id']] = @account_list.donor_accounts.find_by(account_number: row['OrgDonorCode'])
    end
    donors
  end
end
