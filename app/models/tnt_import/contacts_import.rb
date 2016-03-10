class TntImport::ContactsImport
  def initialize(import, designation_profile, xml)
    @import = import
    @account_list = import.account_list
    @override = import.override?
    @tags_for_all = import.tags
    @designation_profile = designation_profile
    @xml = xml
  end

  def import_contacts
    tags_by_contact_id = TntImport::GroupTagsLoader.tags_by_tnt_contact_id(@xml)
    donors_by_tnt_id = donor_accounts_by_tnt_contact_id

    rows = Array.wrap(@xml['Contact']['row'])
    tnt_contacts = {}
    rows.each do |row|
      tnt_id = row['id']
      tags = (Array.wrap(@tags_for_all) + Array.wrap(tags_by_contact_id[tnt_id]))
      donor_accounts = donors_by_tnt_id[tnt_id]
      tnt_contacts[tnt_id] = import_contact(row, tags.compact, donor_accounts)
    end

    tnt_contacts
  end

  def import_contact(row, tags, donor_accounts)
    TntImport::ContactImport.new(@import, tags, donor_accounts)
      .import_contact(row)
  end

  def donor_accounts_by_tnt_contact_id
    @donor_accounts_by_contact_id ||=
      TntImport::DonorAccountsImport.new(@xml, orgs_by_tnt_id).import
  end

  def orgs_by_tnt_id
    TntImport::OrgsFinder
      .orgs_by_tnt_id(@xml, @designation_profile.try(:organization))
  end
end
